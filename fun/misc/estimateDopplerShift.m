function [relativeShift,initTimeDelay] = estimateDopplerShift(signal1,signal2,M)
%Signals need to have a relative delay <<M on any arbitrarily chosen window of time:
%this could be fixed by time-aligning previously, assuming that the doppler
%shift is << M during the time signal length
%MAximum detectable relative shift is ~ 1/M
%It is also recommended that signals be high-pass filtered, as it gives
%better results

if nargin<3
    k=sqrt(length(signal2))/4; %Approx number of windows that is optimal for the estimation
    if k>128
        k=128;
    end
    M=ceil(length(signal2)/k);
end

N=ceil(max([length(signal2) length(signal1)])/M);
signal1=signal1-mean(signal1);
signal2=signal2-mean(signal2);
signal1(end+1:N*M)=0;
signal2(end+1:N*M)=0; %Padding zeros to have a number of samples that is multiple of the window size (M)
signal1=signal1-mean(signal1);

E1=sum(signal1.^2);
E2=sum(signal2.^2);

%% Two step approach: identify outliers, and fit a line. Repeat identifying outliers through the residuals to the line fit, until convergence.
firstStep=true;
differences=true;
while differences
    
    clear s x t lineFit
    for i=1:N
        aux2=signal2((i-1)*M+1:i*M); %Getting a portion of signal2
        aux1=signal1((i-1)*M+1:i*M);
        [~,~,t(i)]=findTimeLag(aux1,aux2,1,Inf);
%         F1=fft(aux1);
%         F2=fft(aux2);
%         F=F1.*conj(F2);
%         P=ifft(F);
%         [s(i),t(i)]=max(abs(P));
%     %     [acor,lag]=xcorr(aux1,aux2,'unbiased');
%     %     [~,ii]=max(abs(acor));
%     %     t(i)=lag(ii);
        x(i)=M/2 + (i-1)*M;
        
%         if 5*N*sqrt(sum(aux1.^2)*sum(aux2.^2))<sqrt(E1*E2) %Reject intervals of the signal with too little activity compared to overall
%             t(i)=NaN;
%         end
    end
    auxI=~isnan(t);
    properX=x(auxI);
    properT=t(auxI);
    if firstStep
        lineFit=polyfit(properX,properT,1);
        firstStep=false;
        iiOld=[];
    else
        auxX=x(ii);
        auxT=t(ii);
        lineFit=polyfit(auxX(auxI(ii)),auxT(auxI(ii)),1);
        iiOld=ii;
    end
    residuals=abs(t-x*lineFit(1) - lineFit(2));
    pp=prctile(residuals,[50]);
    if pp(1)<.5
        pp(1)=.5; %Because of quantization, we would expect to see at least .5 samples errors even on the best of fits
    end
    ii=find(residuals<pp(1) & auxI); %Rejecting outliers
    
        if length(ii)>0 && (length(iiOld)~=length(ii) || any(ii~=iiOld))
            differences=true;
        else
            differences=false;
        end

end
% figure(1)
% plot(x,t,'.')
% hold on
% plot(x(ii),t(ii),'g.')
% plot(x,x*lineFit(1)+lineFit(2),'r')
% hold off
% legend('Rejected samples','Used samples','Line fit')
relativeShift=lineFit(1);
initTimeDelay=lineFit(2); %In samples
end


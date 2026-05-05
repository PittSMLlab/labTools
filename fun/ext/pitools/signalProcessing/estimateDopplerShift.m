function [relativeShift,initTimeDelay] = estimateDopplerShift(signal1,signal2,M)
%ESTIMATEDOPPLERSHIFT Estimate relative sampling-rate mismatch via STFT.
%
%   Divides both signals into windows of length M, estimates the time
% lag between each window pair using FINDTIMELAG, then fits a line to
% the lag-vs-time relationship. The slope of that line is the relative
% Doppler shift (fractional sampling-rate difference). Outlier windows
% are iteratively rejected until convergence.
%
%   Signals should be pre-aligned (relative delay << M) and high-pass
% filtered for best results. The maximum detectable relative shift is
% approximately 1/M.
%
% Inputs:
%   signal1 - 1-D reference signal (row vector)
%   signal2 - 1-D secondary signal (row vector)
%   M       - (optional) window length in samples; defaults to a value
%             that yields approximately sqrt(N)/4 windows, capped at 128
%
% Outputs:
%   relativeShift  - fractional sampling-rate difference (slope of lag
%                    vs. time line); positive means signal2 is faster
%   initTimeDelay  - intercept of the lag-vs-time line, in samples
%
% Toolbox Dependencies: None
%
% See also MATCHSIGNALS, FINDTIMELAG.

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
    t=nan(1,N);
    for i=1:N
        aux2=signal2((i-1)*M+1:i*M); %Getting a portion of signal2
        aux1=signal1((i-1)*M+1:i*M);
        [~,~,t(i)]=findTimeLag(aux1,aux2);
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


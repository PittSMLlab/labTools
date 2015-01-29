function [timeDiff,corrCoef,lagInSamples] = findTimeLag(referenceSignal,secondarySignal,sampFreq,winSize)
if nargin<4 || isempty(winSize)
    warning('Window size (max possible lag time) not given. Defaulting to 10 secs.')
    winSize=10;
end
if nargin<3 || isempty(sampFreq)
    warning('Sampling frequency not given. Defaulting to 1 Hz.')
    sampFreq=1;
end

%% Original way:
% [acor,lag] = xcorr(referenceSignal,secondarySignal,round(winSize*sampFreq),'none');
% [~,I1] = max(abs(acor));
% 
% corrCoef=acor(I1);
% lagInSamples=lag(I1);


%% Alternative way:
%Pad zeros to shortest signal:
M=max([length(referenceSignal) length(secondarySignal)]);
referenceSignal(end+1:M)=0;
secondarySignal(end+1:M)=0;

%Find max lag
F1=fft(referenceSignal);
F2=fft(fftshift(secondarySignal));
F=F1.*conj(F2);
P=ifft(F);
aux=0:.01:length(P)-1;
P2=interp1(0:length(P)-1,P,aux,'spline'); %For sub-sample resolution
[~,t]=max(abs(P2));
lagInSamples=aux(t)-floor(M/2); %The -floor(M/2) term accounts for the fftshift
corrCoef=P2(t);


%% All:
timeDiff = lagInSamples/sampFreq; %Positive time diff means that the second signal started recording after the reference signal
if abs(lagInSamples)>=round(winSize*sampFreq) %Match found at edge of interval, means no match
    lagInSamples=NaN;
    timeDiff=NaN;
    corrCoef=0;
end

end


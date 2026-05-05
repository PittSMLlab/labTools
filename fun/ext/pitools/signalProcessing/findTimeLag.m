function [timeDiff,corrCoef,lagInSamples] = findTimeLag(referenceSignal,secondarySignal)
%FINDTIMELAG Estimate the sample lag between two signals via correlation.
%
%   Zero-pads both signals to the same length, computes their cross-
% correlation in the frequency domain, then interpolates at 100x
% resolution to obtain a sub-sample lag estimate. Issues a warning
% when the peak correlation is below 0.3, indicating unreliable
% synchronization.
%
% Inputs:
%   referenceSignal  - 1-D reference signal (row or column vector)
%   secondarySignal  - 1-D signal to align to referenceSignal
%
% Outputs:
%   timeDiff     - reserved; always returns NaN
%   corrCoef     - normalized peak cross-correlation coefficient
%   lagInSamples - sub-sample lag of secondarySignal relative to
%                  referenceSignal (positive = secondarySignal leads)
%
% Toolbox Dependencies: None
%
% See also MATCHSIGNALS, ESTIMATEDOPPLERSHIFT.

%First: truncate:
M=max([length(referenceSignal) length(secondarySignal)]);
referenceSignal(end+1:M)=0;
secondarySignal(end+1:M)=0;

%Second: correlate
F1=fft(referenceSignal);
F2=fft(fftshift(secondarySignal));
F=F1.*conj(F2);
P=ifft(F);

%Third: sub-sample:
aux=0:.01:length(P)-1;
P2=interp1(0:length(P)-1,P,aux,'spline')/sqrt(sum(referenceSignal.^2)*sum(secondarySignal.^2)); %For sub-sample resolution

%Fourth: find max correlation
[~,t]=max(abs(P2));
lagInSamples=aux(t)-floor(M/2); %The -floor(M/2) term accounts for the fftshift
corrCoef=P2(t);

if abs(corrCoef)<.3
    warning(['Could not synch signals: r^2= ' num2str(abs(corrCoef))])
end
timeDiff = NaN;

end


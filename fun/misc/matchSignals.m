function [alignedSignal2,timeScaleFactor,lagInSamples,gain] = matchSignals(signal1,signal2)
%alignSignals takes two 1-D time signals and finds a transformation of
%signal 2 that best matches signal 1. This transformation includes
%re-sampling (by timeScaleFactor), a delay, and a gain.
%
%INPUTS:
%
%OUTPUTS:
%alignedSignal2: a version of signal2 that is aligned (best matches) signal
%1. It contains NaN for time points where the signal2 was not available. 
%timeScaleFactor: resampling factor of signal2 to best match signal1. A
%factor larger than 1 means that the original signal had a lower sampling
%rate and needed to be interpolated, while a factor lesser than 1 means
%that the sampling rate was higher (strictly speaking:the signal is always
%resampled, unless this factor is exactly 1, to a tolerance of 0.5/N, where N
%is the number of samples of signal 1.
%Delay: measures the delay in samples of signal2 with respect to signal 1.
%Because of the resampling, it is interpretation might be a little funky,
%but esentially it measures how many samples later the initial timepoint
%of signal1 happens in signal2, assuming that the sampling rate of signal1
%is the correct one. A positive number means that signal2 started recording
%EARLIER than signal1, and a negative number means the opposite.
%Gain: a scaling factor so that signal2 matches signal1 the best possible,
%after the resampling and time-shifting.

%% Step 1: determine mis-match in sampling rates & time delay
[relativeShift,lagInSamples] = estimateDopplerShift(signal1,signal2);
timeScaleFactor=1-relativeShift;
newSignal2 = resampleShiftAndScale(signal2,timeScaleFactor,0,1);

[~,~,lagInSamples] = findTimeLag(signal1,newSignal2,1,Inf);
newSignal2 = resampleShiftAndScale(newSignal2,1,lagInSamples,1);

%% Step 2: make signals of same length and determine best-gain
newSignal2(end+1:length(signal1))=0;
newSignal2(length(signal1)+1:end)=[];

gain=newSignal2'/signal1';
alignedSignal2=newSignal2/gain;


%% Step 3: Check/debug

%Re-estimate parameters and hope they are 0
[relativeShift,~] = estimateDopplerShift(signal1,alignedSignal2);
[~,~,initTimeDelay] = findTimeLag(signal1,alignedSignal2,1,Inf);
if abs(relativeShift)>1/length(signal2)
    warning('Signal resampling did not seem to work properly')
end
if abs(initTimeDelay)>1
    warning('Time shifting did not seem to work properly')
end

% gain=newSignal2'/signal1';
% 
% figure
% hold on
% plot(signal1)
% plot(alignedSignal2,'r')
% hold off
% 
% E=sum((signal1-alignedSignal2).^2);
% figure
% plot(signal1-alignedSignal2)
% 

end


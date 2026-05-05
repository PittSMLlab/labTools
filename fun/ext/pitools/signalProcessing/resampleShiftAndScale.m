function newSignals = resampleShiftAndScale(signals,timeScaleFactor,lagInSamples,scaleGain)
%RESAMPLESHIFTANDSCALE Apply resampling, time shift, and gain scaling.
%
%   Transforms signals by resampling at timeScaleFactor, shifting by
% lagInSamples samples, and dividing by scaleGain. Resampling uses
% linear interpolation and is skipped when the scale factor would
% produce less than half a sample of drift over the full signal length.
% The integer portion of lagInSamples is applied by padding or
% truncating; sub-sample correction is reserved for future use.
%
% Inputs:
%   signals         - (M x N) double array of N time series, each M
%                     samples long
%   timeScaleFactor - resampling factor; values > 1 interpolate (upscale),
%                     values < 1 decimate (downscale)
%   lagInSamples    - time shift in samples; positive pads leading zeros,
%                     negative trims leading samples
%   scaleGain       - divisive gain applied after time shifting
%
% Outputs:
%   newSignals - transformed signal array
%
% Toolbox Dependencies: None
%
% See also MATCHSIGNALS, TRUNCATETOSAMELENGTH.


[M,N]=size(signals);

%% Resample: (not using 'resample' function because i'm interested in very
%small resampling rates, on the order of 1+-1e-6
if abs(timeScaleFactor-1)>.5/M %Only resampling if there is at least a half a sample shift during the full timecourse
    for i=1:N
        newSignals(:,i)=interp1(1:M,signals(:,i),timeScaleFactor*[1:floor(M/timeScaleFactor)],'linear')';
        newSignals(1,i)=signals(1,i); %For same reason interp1 returns NaN when evaluating at same position
    end
else
    newSignals=signals;
end

%% Time-shift
aux=round(lagInSamples); 
d=lagInSamples-aux;
%First shift an integer number of samples:
if lagInSamples<0
    newSignals=newSignals(abs(aux)+1:end,:); %Throw first samples
else
    newSignals=[zeros(abs(aux),N); newSignals]; %Pad zeros to add samples
end

%Then, correct for sub-sample interpolation.
% k=1000;
% F=fft([newSignals;zeros(k,size(newSignals,2))]);
% Fd=exp(1i*2*pi*[0:size(F,1)-1]/size(F,1)).^d;
% newSignals=ifft(bsxfun(@times,F,Fd'),'symmetric');
% newSignals=newSignals(1:end-k,:);


%% Scale:
newSignals=newSignals/scaleGain;

end


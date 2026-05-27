function newSignals = resampleShiftAndScale( ...
    signals, timeScaleFactor, lagInSamples, scaleGain)
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

arguments
    signals         (:,:) double
    timeScaleFactor (1,1) double
    lagInSamples    (1,1) double
    scaleGain       (1,1) double
end

[M, N] = size(signals);

%% Resample Signal
% NOTE: Not using 'resample' because this targets very small resampling
% rates on the order of 1 +/- 1e-6. Only resamples when the cumulative
% drift exceeds half a sample over the full signal length.
if abs(timeScaleFactor - 1) > 0.5 / M
    for ch = 1:N
        newSignals(:, ch) = interp1( ...
            1:M, signals(:, ch), ...
            timeScaleFactor * (1:floor(M / timeScaleFactor)), ...
            'linear')';
        % interp1 returns NaN when evaluating at the first boundary point
        newSignals(1, ch) = signals(1, ch);
    end
else
    newSignals = signals;
end

%% Apply Integer Time Shift
lagInt  = round(lagInSamples);
lagFrac = lagInSamples - lagInt;
% Sub-sample correction (frequency-domain phase shift) is stubbed out
% below; only integer-sample shifting is applied for now.
% k=1000;
% F=fft([newSignals;zeros(k,size(newSignals,2))]);
% Fd=exp(1i*2*pi*[0:size(F,1)-1]/size(F,1)).^lagFrac;
% newSignals=ifft(bsxfun(@times,F,Fd'),'symmetric');
% newSignals=newSignals(1:end-k,:);
if lagInSamples < 0
    newSignals = newSignals(abs(lagInt) + 1:end, :); % trim leading samples
else
    newSignals = [zeros(abs(lagInt), N); newSignals]; % pad leading zeros
end

%% Apply Gain Scaling
newSignals = newSignals / scaleGain;

end

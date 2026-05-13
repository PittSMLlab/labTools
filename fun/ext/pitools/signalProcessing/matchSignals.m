function [alignedSignal2, timeScaleFactor, lagInSamples, gain] = ...
        matchSignals(signal1, signal2)
%MATCHSIGNALS Find and apply the transformation that best aligns signal2
%to signal1.
%
%   Estimates and applies three transformations in sequence: (1) a time
% shift to align the signals' start times, (2) a resampling factor to
% correct for sampling-rate mismatch (Doppler shift), and (3) a
% multiplicative gain. Returns the aligned version of signal2 and the
% estimated transformation parameters.
%
%   timeScaleFactor > 1 means signal2 had a lower sampling rate and was
% interpolated; < 1 means it was decimated. lagInSamples > 0 means
% signal2 started recording earlier than signal1.
%
% Inputs:
%   signal1 - 1-D reference signal (row or column vector)
%   signal2 - 1-D signal to align to signal1 (row or column vector)
%
% Outputs:
%   alignedSignal2  - transformed signal2 aligned to signal1; NaN where
%                     signal2 data were unavailable
%   timeScaleFactor - resampling factor applied to signal2
%   lagInSamples    - total sample delay corrected (positive = signal2
%                     led signal1)
%   gain            - divisive gain applied to signal2
%
% Toolbox Dependencies: None
%
% See also FINDTIMELAG, ESTIMATEDOPPLERSHIFT, RESAMPLESHIFTANDSCALE.

arguments
    signal1 (:,1) double
    signal2 (:,1) double
end

%% Align Start Times and Correct Sampling-Rate Mismatch

% Find initial lag, align, and make equal length
[~, ~, lagInSamples] = findTimeLag(signal1, signal2);
newSignal2 = resampleShiftAndScale(signal2, 1, lagInSamples, 1);
if length(newSignal2) > length(signal1)
    newSignal2(length(signal1) + 1:end) = [];
else
    signal1(length(newSignal2) + 1:end) = [];
end

% Correct for Doppler shift (sampling-rate mismatch)
[relativeShift, ~] = estimateDopplerShift(signal1, newSignal2);
timeScaleFactor    = 1 - relativeShift;
newSignal2         = resampleShiftAndScale(newSignal2, timeScaleFactor, 0, 1);

% Refine lag after resampling
[~, ~, lagInSamples2] = findTimeLag(signal1, newSignal2);
newSignal2 = resampleShiftAndScale(newSignal2, 1, lagInSamples2, 1);
if length(newSignal2) > length(signal1)
    newSignal2(length(signal1) + 1:end) = [];
else
    signal1(length(newSignal2) + 1:end) = [];
end
lagInSamples = lagInSamples + lagInSamples2;

%% Compute Best-Fit Gain
gain = newSignal2' / signal1';
if ~isfinite(gain) || gain == 0
    warning('matchSignals:degenerateGain', ...
        'Gain is %g (non-finite or zero); returning identity.', gain);
    alignedSignal2  = signal2;
    timeScaleFactor = 1;
    lagInSamples    = 0;
    gain            = 1;
    return
end
alignedSignal2 = newSignal2 / gain;

end

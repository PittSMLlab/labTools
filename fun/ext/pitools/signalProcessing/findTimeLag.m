function [timeDiff, corrCoef, lagInSamples] = findTimeLag( ...
    referenceSignal, secondarySignal)
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

arguments
    referenceSignal  (1,:) double
    secondarySignal  (1,:) double
end

%% Early Exit for Degenerate Inputs
if ~any(isfinite(referenceSignal) & (referenceSignal ~= 0)) || ...
        ~any(isfinite(secondarySignal) & (secondarySignal ~= 0))
    warning('findTimeLag:degenerateInput', ...
        ['At least one input signal is all-zero, NaN, or Inf; ' ...
        'returning lagInSamples=0, corrCoef=0.']);
    timeDiff     = NaN;
    corrCoef     = 0;
    lagInSamples = 0;
    return
end

minCorrWarningThresh = 0.3; % below this, synchronization is unreliable

%% Zero-Pad to Equal Length
M = max([length(referenceSignal) length(secondarySignal)]);
referenceSignal(end+1:M)  = 0;
secondarySignal(end+1:M)  = 0;

%% Compute Cross-Correlation
F1 = fft(referenceSignal);
F2 = fft(fftshift(secondarySignal));
F  = F1 .* conj(F2);
P  = ifft(F);

%% Interpolate for Sub-Sample Resolution
% 100× resolution spline interpolation; load-bearing for accuracy —
% do not reduce without re-validating sync parameter outputs.
interpResolution = 0.01; % sub-sample lag resolution (fraction of a sample)
fineLags = 0:interpResolution:length(P) - 1;
P2       = interp1(0:length(P) - 1, P, fineLags, 'spline') ...
    / sqrt(sum(referenceSignal.^2) * sum(secondarySignal.^2));

%% Find Peak Correlation
[~, t]       = max(abs(P2));
lagInSamples = fineLags(t) - floor(M / 2); % fftshift offset correction
corrCoef     = P2(t);

if abs(corrCoef) < minCorrWarningThresh
    warning('findTimeLag:lowCorrelation', ...
        'Could not synch signals: r^2= %.3f', abs(corrCoef));
end
timeDiff = NaN;

end

function signals = clipSignals(signals, percentile)
% clipSignals  Clip the top and bottom of each signal column by percentile.
%
%   Replaces all samples below the lower percentile threshold and above
% the upper percentile threshold with the respective threshold value,
% acting independently on each column of the input matrix. This is
% used to suppress isolated large-amplitude outliers before sync signal
% processing.
%
%   Inputs:
%     signals    - Numeric matrix of signals to clip (samples × channels).
%                  May also be a column vector (samples × 1).
%     percentile - Scalar percentile (%) defining the symmetric clip
%                  bounds. Samples below the p-th percentile are clamped
%                  to that percentile value, and samples above the
%                  (100-p)-th percentile are clamped to that value.
%                  Must be in the range (0, 50). Typical value: 0.1
%                  (clips the outermost 0.1% at each end of the
%                  distribution). A value of 0 is a no-op and returns
%                  the input unchanged.
%
%   Outputs:
%     signals - Clipped signal matrix, same size as the input.
%
%   Toolbox Dependencies:
%     Statistics and Machine Learning Toolbox  (prctile)
%
%   See also: loadTrials, prctile

arguments
    signals    (:, :) {mustBeNumeric}
    percentile (1, 1) {mustBeNumeric, mustBeReal, ...
        mustBeNonnegative, mustBeLessThan(percentile, 50)}
end

% A percentile of zero returns the data min/max as bounds, so clamping
% has no effect; return immediately to avoid an unnecessary loop.
if percentile == 0
    return;
end

% Compute clip bounds for all columns simultaneously. prctile returns
% a 2 × N matrix when given a two-element percentile vector and a
% matrix input: row 1 holds lower bounds, row 2 holds upper bounds.
lims    = prctile(signals, [percentile; 100 - percentile], 1);
signals = min(max(signals, lims(1, :)), lims(2, :));

end


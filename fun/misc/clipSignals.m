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
%                  Typical value: 0.1 (clips the outermost 0.1% at each
%                  end of the distribution).
%
%   Outputs:
%     signals - Clipped signal matrix, same size as the input.
%
%   Toolbox Dependencies:
%     Statistics and Machine Learning Toolbox  (prctile)
%
%   See also: loadTrials, prctile

for i = 1:size(signals, 2)
    lims = prctile(signals(:, i), [percentile, 100 - percentile]);
    signals(signals(:, i) < lims(1), i) = lims(1);
    signals(signals(:, i) > lims(2), i) = lims(2);
end

end


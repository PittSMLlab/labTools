function phaseShift = circCorr(trace1, trace2)
%CIRCCORR Estimate the phase shift between two sinusoidal traces.
%
%   Performs a circular (cyclic) correlation by iteratively shifting
% trace2 and computing the normalized inner product with trace1 at each
% lag. The peak-lag index is returned as a fraction of the cycle length.
% NOTE: the formula is equivalent to Pearson r only when both inputs are
% zero-mean; callers must center traces before calling if needed.
%
% Inputs:
%   trace1 - (n x 1) reference sinusoidal trace (zero-mean assumed)
%   trace2 - (n x 1) sinusoidal trace to shift (zero-mean assumed);
%            both vectors must have the same length n
%
% Outputs:
%   phaseShift - phase shift as a fraction of cycle length (0 to 1),
%                or NaN if peak correlation falls below quality
%                threshold (0.5) or inputs have zero variance
%
% Toolbox Dependencies:
%   None
%
% See also COMPUTESPATIALPARAMETERS.

stdTrace1 = std(trace1);
stdTrace2 = std(trace2);
nSamples  = length(trace1);
circCorrs = zeros(1, nSamples);

for sh = 1:nSamples
    circCorrs(sh) = (trace1' * trace2) ./ ...
        ((nSamples - 1) * stdTrace1 * stdTrace2);  % n-1: unbiased std
    trace2 = circshift(trace2, 1);
end

[maxCorr, maxShift] = max(circCorrs);
phaseShift = maxShift / nSamples;

% Return NaN if peak correlation is below empirical quality threshold
% or undefined (e.g., zero-variance input)
if maxCorr < 0.5 || isnan(maxCorr)
    phaseShift = NaN;
end

end

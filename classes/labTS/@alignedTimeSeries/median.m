function medianTS = median(this, strideIdxs)
%median  Computes median
%
%   medianTS = median(this) computes median across all strides
%
%   medianTS = median(this, strideIdxs) computes for specified strides
%
%   Inputs:
%       this - alignedTimeSeries object
%       strideIdxs - vector of stride indices (optional, default: all)
%
%   Outputs:
%       medianTS - alignedTimeSeries with median values
%
%   See also: mean, prctile

if nargin < 2 || isempty(strideIdxs)
    strideIdxs = [];
end
medianTS = prctile(this, 50, strideIdxs);
end


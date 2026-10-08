function medianTS = median(this, strideIdxs)
%MEDIAN Computes median.
%
%   medianTS = median(this) computes median across all strides
%
%   medianTS = median(this, strideIdxs) computes for specified strides
%
% Inputs:
%   this       - alignedTimeSeries object
%   strideIdxs - vector of stride indices (optional, default: all)
%
% Outputs:
%   medianTS - alignedTimeSeries with median values
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
%
% See also MEAN, PRCTILE.

if nargin < 2 || isempty(strideIdxs)
    strideIdxs = [];
end
medianTS = prctile(this, 50, strideIdxs);
end


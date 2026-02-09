function iqrTS = iqr(this, strideIdxs)
%iqr  Computes interquartile range
%
%   iqrTS = iqr(this) computes interquartile range across all strides
%
%   iqrTS = iqr(this, strideIdxs) computes for specified strides
%
%   Inputs:
%       this - alignedTimeSeries object
%       strideIdxs - vector of stride indices (optional, default: all)
%
%   Outputs:
%       iqrTS - alignedTimeSeries with IQR values
%
%   See also: prctile, std, stdRobust

if nargin > 1 && ~isempty(strideIdxs)
    this.Data = this.Data(:, :, strideIdxs);
else
    strideIdxs = [];
end
if ~islogical(this.Data(1))
    iqrTS = this.prctile(75) - this.prctile(25);
else
    % Logical timeseries. Will find events and average appropriately.
    % Assuming the SAME number of events per stride, and in the same
    % ORDER. % FIXME: check event order.
    histogram = logicalHist(this);
    iqrTS = iqr(histogram); % Not really a tS
end
end


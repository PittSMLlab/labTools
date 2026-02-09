function stdTS = std(this, strideIdxs)
%std  Computes standard deviation
%
%   stdTS = std(this) computes standard deviation across all strides
%
%   stdTS = std(this, strideIdxs) computes for specified strides
%
%   Inputs:
%       this - alignedTimeSeries object
%       strideIdxs - vector of stride indices (optional, default: all)
%
%   Outputs:
%       stdTS - alignedTimeSeries with standard deviation (for numeric)
%               or vector (for logical)
%
%   See also: mean, stdRobust, iqr

if nargin > 1 && ~isempty(strideIdxs)
    this.Data = this.Data(:, :, strideIdxs);
end
if ~islogical(this.Data(1))
    % stdTS = labTimeSeries(nanstd(this.Data, [], 3), this.Time(1),
    %     this.Time(2) - this.Time(1), this.labels);
    stdTS = alignedTimeSeries(this.Time(1), ...
        this.Time(2) - this.Time(1), nanstd(this.Data, [], 3), ...
        this.labels, this.alignmentVector, this.alignmentLabels);
else
    % Logical timeseries. Will find events and average appropriately.
    % Assuming the SAME number of events per stride, and in the same
    % ORDER. % FIXME: check event order.
    histogram = logicalHist(this);
    stdTS = std(histogram); % Not really a tS
end
end


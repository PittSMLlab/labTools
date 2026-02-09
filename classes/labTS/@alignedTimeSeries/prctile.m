function prctileTS = prctile(this, p, strideIdxs)
%prctile  Computes percentile
%
%   prctileTS = prctile(this, p) computes specified percentile across
%   all strides
%
%   prctileTS = prctile(this, p, strideIdxs) computes for specified strides
%
%   Inputs:
%       this - alignedTimeSeries object
%       p - percentile value (0-100)
%       strideIdxs - vector of stride indices (optional, default: all)
%
%   Outputs:
%       prctileTS - alignedTimeSeries with percentile values
%
%   See also: median, iqr, mean

if nargin > 2 && ~isempty(strideIdxs)
    this.Data = this.Data(:, :, strideIdxs);
end
if ~islogical(this.Data(1))
    % prctileTS = labTimeSeries(prctile(this.Data, p, 3),
    %     this.Time(1), this.Time(2) - this.Time(1), this.labels);
    prctileTS = alignedTimeSeries(this.Time(1), ...
        this.Time(2) - this.Time(1), prctile(this.Data, p, 3), ...
        this.labels, this.alignmentVector, this.alignmentLabels);
else % Logical timeseries.
    error('alignedTimeSeries:prctile', ...
        'Prctile not yet implemented for logical alignedTimeSeries.');
    % TODO
end
end


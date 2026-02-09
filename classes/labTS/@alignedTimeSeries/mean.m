function [meanTS, stds] = mean(this, strideIdxs)
%mean  Computes mean across strides
%
%   [meanTS, stds] = mean(this) computes mean and standard deviation
%   across all aligned timeseries
%
%   [meanTS, stds] = mean(this, strideIdxs) computes for specified
%   strides
%
%   Inputs:
%       this - alignedTimeSeries object
%       strideIdxs - vector of stride indices (optional, default: all)
%
%   Outputs:
%       meanTS - alignedTimeSeries with mean data (single stride)
%       stds - standard deviations (for logical data) or empty
%
%   Note: For logical data (events), assumes all aligned timeSeries
%         have same number of events in same order. Returns median
%         event times.
%
%   See also: median, std, prctile

if nargin > 1 && ~isempty(strideIdxs)
    this.Data = this.Data(:, :, strideIdxs);
end
if ~islogical(this.Data(1))
    % meanTS = labTimeSeries(nanmean(this.Data, 3), this.Time(1),
    %     this.Time(2) - this.Time(1), this.labels);
    meanTS = alignedTimeSeries(this.Time(1), ...
        this.Time(2) - this.Time(1), nanmean(this.Data, 3), ...
        this.labels, this.alignmentVector, this.alignmentLabels);
    stds = [];
else
    % Logical timeseries. Will find events and average appropriately.
    % Assuming the SAME number of events per stride, and in the same
    % ORDER. % FIXME: check event order.
    [histogram, newLabels] = logicalHist(this);
    % Compute mean/median:
    newData = sparse([], [], false, size(this.Data, 1), ...
        length(newLabels), size(this.Data, 1));
    mH = nanmedian(histogram);
    for i = 1:size(histogram, 2)
        if mod(mH(i), 1) ~= 0
            mH(i) = floor(mH(i));
            warning(['Median event ' num2str(i) ...
                ' falls between two samples']);
        end
        newData(mH(i), i) = true;
    end
    % meanTS = labTimeSeries(newData, this.Time(1),
    %     this.Time(2) - this.Time(1), newLabels);
    meanTS = alignedTimeSeries(this.Time(1), ...
        this.Time(2) - this.Time(1), newData, newLabels, ...
        this.alignmentVector, this.alignmentLabels);
    stds = nanstd(histogram);
end
end


function [DTS, bad] = discretize(this, eventTS, eventLabel, N, ...
    summaryFunction)
%discretize  Discretizes by averaging across phases
%
%   [DTS, bad] = discretize(this, eventTS, eventLabel, N,
%   summaryFunction) discretizes timeseries by averaging data across
%   different gait phases
%
%   Inputs:
%       this - labTimeSeries object
%       eventTS - labTimeSeries with event markers
%       eventLabel - cell array of event labels (optional)
%       N - vector of sample counts per phase (optional)
%       summaryFunction - function to apply to each phase (optional,
%                         default: 'nanmean')
%
%   Outputs:
%       DTS - alignedTimeSeries with discretized data
%       bad - logical vector indicating strides with incomplete events
%
%   Note: Phases are defined by intervals between given events, and can
%         be divided into sub-phases
%
%   See also: align, alignedTimeSeries

if nargin < 3 || isempty(eventLabel)
    eventLabel = eventTS.labels(1);
end
% New attempt, no alignment:
eventTimes = labTimeSeries.getArrayedEvents(eventTS, eventLabel);
bad = any(isnan(eventTimes(1:end - 1, :)), 2);
expEventTimes = alignedTimeSeries.expandEventTimes(eventTimes', N);
ee = [expEventTimes(:); eventTimes(end, 1)];
slicedTS = this.sliceTS(ee, 0);
if nargin < 5 || isempty(summaryFunction)
    % nanmean, only along columns, so that if we have NaNs, and to account
    % for odd instance when we only have one row or data in our slicedTS
    summaryFunction = 'nanmean';
end
eval(['myfun = @(x) ' summaryFunction '(x, 1);']);
d = cell2mat( ...
    cellfun(@(x) myfun(x.Data), slicedTS, 'UniformOutput', false)');
[M, N1] = size(expEventTimes);
M2 = size(d, 2);
d = permute(reshape(d, sum(N), N1, M2), [1, 3, 2]);
DTS = alignedTimeSeries(0, 1, d, this.labels, N, eventLabel, eventTimes');
end


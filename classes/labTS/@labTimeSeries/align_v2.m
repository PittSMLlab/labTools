function [ATS, bad, Data] = align_v2(this, eventTS, eventLabel, N)
%align_v2  Efficient and robust alignment to events
%
%   [ATS, bad, Data] = align_v2(this, eventTS, eventLabel, N) is an
%   efficient substitute for legacy align()
%
%   Inputs:
%       this - labTimeSeries object
%       eventTS - labTimeSeries with event markers
%       eventLabel - cell array of event labels
%       N - vector of sample counts between events
%
%   Outputs:
%       ATS - alignedTimeSeries object
%       bad - logical vector indicating strides with issues
%       Data - 3D data array (samples x labels x strides)
%
%   See also: align, alignedTimeSeries

eventTimes = labTimeSeries.getArrayedEvents(eventTS, eventLabel);
expEventTimes = alignedTimeSeries.expandEventTimes(eventTimes', N);
Data = permute(this.getSample(expEventTimes), [1, 3, 2]);
bad = any(isnan(eventTimes(1:end - 1, :)), 2);
ATS = ...
    alignedTimeSeries(0, 1, Data, this.labels, N, eventLabel, eventTimes');
end


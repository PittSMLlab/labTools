function [steppedDataArray, bad, initTime, eventTimes] = ...
    splitByEvents(this, eventTS, eventLabel, timeMargin)
%splitByEvents  Separates by events in boolean timeseries
%
%   [steppedDataArray, bad, initTime, eventTimes] = splitByEvents(
%   this, eventTS, eventLabel, timeMargin) separates the timeseries
%   according to events in a boolean event timeseries
%
%   Inputs:
%       this - labTimeSeries object
%       eventTS - labTimeSeries with binary events as data
%       eventLabel - label of event column to use (optional, default:
%                    first column)
%       timeMargin - time margin to add before/after each segment
%                    (optional, default: 0)
%
%   Outputs:
%       steppedDataArray - cell array (strides x phases) of split
%                          timeseries
%       bad - logical vector indicating strides with event issues
%       initTime - vector of initial times for each stride
%       eventTimes - matrix of event times (strides x events)
%
%   Note: eventTS needs to be a labTimeSeries with binary events as data
%
%   See also: sliceTS, split, getArrayedEvents

% If eventLabel is not given, the first data column is used as the
% relevant event marker. If given, eventLabel must be the label of one
% of the data columns in eventTS

% Check needed: is eventTS a labTimeSeries?
if nargin > 2
    eventList = eventTS.getDataAsVector(eventLabel);
else
    eventList = eventTS.Data(:, 1);
end
% Check needed: is eventList binary?
N = size(eventList, 2); % Number of events & intervals to be found
% List all events in a single vector, by numbering them differently.
auxList = double(eventList) * 2.^[0:N - 1]';
if nargin < 4 || isempty(timeMargin)
    timeMargin = 0;
end

% TODO: this needs to call on getArrayedEvents() to avoid duplicating
% the event-finding logic

refIdxLst = find(auxList == 1);
M = length(refIdxLst) - 1;
auxTime = eventTS.Time;
aa = auxTime(refIdxLst);
initTime = aa(1:M); % Initial time of each interval identified
eventTimes = nan(M, N); % Duration of each interval
eventTimes(:, 1) = initTime;
steppedDataArray = cell(M, N);
bad = false(M, 1);
for i = 1:M % Going over strides
    t0 = auxTime(refIdxLst(i));
    nextT0 = auxTime(refIdxLst(i + 1));
    lastEventIdx = refIdxLst(i);
    for j = 1:N - 1 % Going over events
        nextEventIdx = lastEventIdx + ...
            find(auxList(lastEventIdx + 1:refIdxLst(i + 1) - 1) == ...
            2^mod(j, N), 1, 'first');
        t1 = auxTime(nextEventIdx); % Look for next event
        if ~isempty(t1) && ~isempty(t0)
            eventTimes(i, j + 1) = t1;
            steppedDataArray{i, j} = this.split(t0 - timeMargin, ...
                t1 + timeMargin);
            t0 = t1;
            lastEventIdx = nextEventIdx;
        else
            warning(['Events were not in order on stride ' ...
                num2str(i) ', returning empty labTimeSeries.']);
            if islogical(this.Data)
                steppedDataArray{i, j} = labTimeSeries(...
                    false(0, size(this.Data, 2)), 0, 1, this.labels);
            else
                % Empty labTimeSeries
                steppedDataArray{i, j} = labTimeSeries(...
                    zeros(0, size(this.Data, 2)), 0, 1, this.labels);
            end
            bad(i) = true;
        end

    end
    % This line is executed for the last interval btw events, which is
    % the only one when there is a single event separating (N = 1).
    steppedDataArray{i, N} = this.split(t0 - timeMargin, ...
        nextT0 + timeMargin);
end
end


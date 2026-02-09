function eventTimes = getArrayedEvents(eventTS, eventLabel)
%getArrayedEvents  Extracts event times as array
%
%   eventTimes = getArrayedEvents(eventTS) extracts times of all
%   events in first column
%
%   eventTimes = getArrayedEvents(eventTS, eventLabel) extracts times
%   for specified event labels
%
%   Inputs:
%       eventTS - labTimeSeries with boolean event data
%       eventLabel - cell array of event label strings (optional,
%                    default: first column)
%
%   Outputs:
%       eventTimes - matrix of event times (strides + 1) x events,
%                    with NaN for missing events
%
%   See also: splitByEvents, align

if nargin > 1
    eventList = eventTS.getDataAsVector(eventLabel);
else
    eventList = eventTS.Data(:, 1);
end
% Check needed: is eventList binary?
N = size(eventList, 2); % Number of events & intervals to be found
% List all events in a single vector, by numbering them differently.
% auxList = double(eventList) * 2.^[0:N - 1]';
% refIdxLst = find(auxList == 1);
% Alt definition, to match what is returned if a single event was provided
refIdxLst = find(eventList(:, 1));
M = length(refIdxLst) - 1;
auxTime = eventTS.Time;
initTime = auxTime(refIdxLst); % Initial time of each interval identified
eventTimes = nan(M + 1, N); % Duration of each interval
eventTimes(:, 1) = initTime;
for i = 1:M % Going over strides
    t0 = auxTime(refIdxLst(i));
    lastEventIdx = refIdxLst(i);
    for j = 1:N - 1 % Going over events
        % nextEventIdx = lastEventIdx +
        %     find(auxList(lastEventIdx + 1:refIdxLst(i + 1) - 1) ==
        %     2^mod(j, N), 1, 'first');
        nextEventIdx = lastEventIdx + find(eventList( ...
            lastEventIdx + 1:refIdxLst(i + 1) - 1, j + 1), 1, 'first');
        t1 = auxTime(nextEventIdx); % Look for next event
        if ~isempty(t1) && ~isempty(t0)
            eventTimes(i, j + 1) = t1;
            lastEventIdx = nextEventIdx;
        end

    end
end
end


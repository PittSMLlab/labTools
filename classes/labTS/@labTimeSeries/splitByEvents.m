function [steppedDataArray, bad, initTime, eventTimes] = ...
    splitByEvents(this, eventTS, eventLabel, timeMargin)
%SPLITBYEVENTS Separates by events in boolean timeseries.
%
%   [steppedDataArray, bad, initTime, eventTimes] = splitByEvents( this,
% eventTS, eventLabel, timeMargin) separates the timeseries according to
% events in a boolean event timeseries
%
% Inputs:
%   this       - labTimeSeries object
%   eventTS    - labTimeSeries with binary events as data
%   eventLabel - label of event column to use (optional, default: first
%                column)
%   timeMargin - time margin to add before/after each segment (optional,
%                default: 0)
%
% Outputs:
%   steppedDataArray - cell array (strides x phases) of split timeseries
%   bad              - logical vector indicating strides with event issues
%   initTime         - vector of initial times for each stride
%   eventTimes       - matrix of event times (strides x events)
%
%   Note: eventTS needs to be a labTimeSeries with binary events as data
%
% Toolbox Dependencies: None
%
% See also SLICETS, SPLIT, GETARRAYEDEVENTS.

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

refIdxLst  = find(auxList == 1);
M          = length(refIdxLst) - 1;
auxTime    = eventTS.Time;
aa         = auxTime(refIdxLst);
initTime   = aa(1:M); % Initial time of each interval identified
eventTimes = nan(M, N); % Duration of each interval
eventTimes(:, 1) = initTime;
steppedDataArray = cell(M, N);
bad = false(M, 1);
for ii = 1:M % Going over strides
    t0           = auxTime(refIdxLst(ii));
    nextT0       = auxTime(refIdxLst(ii + 1));
    lastEventIdx = refIdxLst(ii);
    for jj = 1:N - 1 % Going over events
        nextEventIdx = lastEventIdx + ...
            find(auxList(lastEventIdx + 1:refIdxLst(ii + 1) - 1) == ...
            2^mod(jj, N), 1, 'first');
        t1 = auxTime(nextEventIdx); % Look for next event
        if ~isempty(t1) && ~isempty(t0)
            eventTimes(ii, jj + 1) = t1;
            steppedDataArray{ii, jj} = this.split(t0 - timeMargin, ...
                t1 + timeMargin);
            t0           = t1;
            lastEventIdx = nextEventIdx;
        else
            warning(['Events were not in order on stride ' ...
                num2str(ii) ', returning empty labTimeSeries.']);
            if islogical(this.Data)
                steppedDataArray{ii, jj} = labTimeSeries(...
                    false(0, size(this.Data, 2)), 0, 1, this.labels);
            else
                % Empty labTimeSeries
                steppedDataArray{ii, jj} = labTimeSeries(...
                    zeros(0, size(this.Data, 2)), 0, 1, this.labels);
            end
            bad(ii) = true;
        end

    end
    % This line is executed for the last interval btw events, which is
    % the only one when there is a single event separating (N = 1).
    steppedDataArray{ii, N} = this.split(t0 - timeMargin, ...
        nextT0 + timeMargin);
end
end


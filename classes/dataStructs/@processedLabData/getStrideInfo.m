function [numStrides, initTime, endTime] = getStrideInfo(this, ...
    triggerEvent, endEvent)
%getStrideInfo  Returns stride count and timing information
%
%   [numStrides, initTime, endTime] = getStrideInfo(this) returns stride
%   information using the reference leg heel strike as the default trigger
%   event
%
%   [numStrides, initTime, endTime] = getStrideInfo(this, triggerEvent)
%   returns stride information using the specified trigger event
%
%   [numStrides, initTime, endTime] = getStrideInfo(this, triggerEvent,
%   endEvent) returns stride information where each stride is defined from
%   triggerEvent to endEvent
%
%   Inputs:
%       this - processedLabData object
%       triggerEvent - event label for stride start
%                      (default: [refLeg 'HS'])
%       endEvent - event label for stride end
%                  (default: same as triggerEvent)
%
%   Outputs:
%       numStrides - number of complete strides
%       initTime - vector of stride start times
%       endTime - vector of stride end times
%
%   See also: getStepInfo, separateIntoStrides

if nargin < 2 || isempty(triggerEvent)
    triggerEvent = [this.metaData.refLeg 'HS'];
    % Using refLeg's HS as default event for striding.
end

% TODO: call onto arrayedEvents, for uniformity:
if nargin < 3 || isempty(endEvent)
    % using triggerEvent for endEvent
    arrayedEvents = getArrayedEvents(this, {triggerEvent});
    initTime = arrayedEvents(1:end - 1, 1);
    endTime = arrayedEvents(2:end, 1);
else
    arrayedEvents = getArrayedEvents(this, {triggerEvent, endEvent});
    if ~isnan(arrayedEvents(end, 2)) % Last stride is incomplete
        arrayedEvents = arrayedEvents(1:end - 1, :);
    end
    initTime = arrayedEvents(:, 1);
    endTime = arrayedEvents(:, 2);
end
numStrides = size(initTime, 1);

% refLegEventList = this.getPartialGaitEvents(triggerEvent);
% refIdxLst = find(refLegEventList == 1);
% auxTime = this.gaitEvents.Time;
% initTime = auxTime(refIdxLst(1:end - 1));
% numStrides = length(initTime);
% if nargin < 3 || isempty(endEvent) % using triggerEvent for endEvent
%     endTime = auxTime(refIdxLst(2:end));
% else % End of interval depends on another event
%     endEventList = this.getPartialGaitEvents(endEvent);
%     endIdxLst = find(endEventList == 1);
%     i = 0;
%     noEnd = true;
%     while i < numStrides && noEnd % This is an infinite loop...
%         i = i + 1;
%         aux = auxTime(find(endIdxLst > refIdxLst(i), 1, 'first'));
%         if ~isempty(aux)
%             endTime(i) = aux;
%         else
%             endTime(i) = NaN;
%         end
%     end
% end
end


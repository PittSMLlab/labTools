function [arrayedEvents]=getArrayedEvents(this,eventList)
%getArrayedEvents  Retrieves events organized as an array
%
%   arrayedEvents = getArrayedEvents(this,eventList) returns
%   the specified events as a structured array
%
%   Inputs:
%       eventList - cell array of event label strings
%
%   Outputs:
%       arrayedEvents - array of event times organized by type
%
%   See also: labTimeSeries/getArrayedEvents

arrayedEvents=labTimeSeries.getArrayedEvents(this.gaitEvents,eventList);
end


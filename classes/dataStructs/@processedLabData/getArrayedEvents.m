function arrayedEvents = getArrayedEvents(this, eventList)
%GETARRAYEDEVENTS Retrieves events organized as an array
%
%   arrayedEvents = getArrayedEvents(this, eventList) returns the specified
% events as a structured array
%
% Inputs:
%   this      - processedLabData object
%   eventList - cell array of event label strings
%
% Outputs:
%   arrayedEvents - array of event times organized by type
%
% Toolbox Dependencies: None
%
% See also LABTIMESERIES.GETARRAYEDEVENTS.

arrayedEvents = labTimeSeries.getArrayedEvents(this.gaitEvents, eventList);
end


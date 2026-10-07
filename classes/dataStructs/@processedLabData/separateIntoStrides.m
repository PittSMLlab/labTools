function [steppedDataArray, initTime, endTime] = ...
    separateIntoStrides(this, triggerEvent)
%SEPARATEINTOSTRIDES Splits data into individual stride segments
%
%   [steppedDataArray, initTime, endTime] = separateIntoStrides(this,
% triggerEvent) splits the data into single stride segments based on the
% specified trigger event
%
% Inputs:
%   this         - processedLabData object
%   triggerEvent - event label to use for stride boundaries (e.g., 'RHS',
%                  'LHS')
%
% Outputs:
%   steppedDataArray - cell array of strideData objects
%   initTime         - vector of stride start times
%   endTime          - vector of stride end times
%
% Toolbox Dependencies: None
%
% See also SEPARATEINTOSUPERSTRIDES, GETSTRIDEINFO.

% triggerEvent needs to be one of the valid gaitEvent labels
[numStrides, initTime, endTime] = getStrideInfo(this, triggerEvent);
steppedDataArray = {};
for ii = 1:numStrides
    steppedDataArray{ii} = ...
        this.split(initTime(ii), endTime(ii), 'strideData');
end
end


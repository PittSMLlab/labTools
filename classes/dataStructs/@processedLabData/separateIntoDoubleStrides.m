function [steppedDataArray, initTime, endTime] = ...
    separateIntoDoubleStrides(this, triggerEvent)
%SEPARATEINTODOUBLESTRIDES Splits data into 2-stride segments
%
%   [steppedDataArray, initTime, endTime] = separateIntoDoubleStrides(this,
% triggerEvent) splits the data into "double-stride" segments of 2 full
% strides. This is the minimum unit needed to get parameters consistently
% for an individual stride cycle.
%
% NOTE: Version deprecated on Apr 2nd 2015
%
% Inputs:
%   this         - processedLabData object
%   triggerEvent - event label to use for stride boundaries (e.g., 'RHS',
%                  'LHS')
%
% Outputs:
%   steppedDataArray - cell array of strideData objects
%   initTime         - vector of double-stride start times
%   endTime          - vector of double-stride end times
%
% Toolbox Dependencies: None
%
% See also SEPARATEINTOSTRIDES, SEPARATEINTOSUPERSTRIDES.

% triggerEvent needs to be one of the valid gaitEvent labels
[strideIdxs, initTime, endTime] = getStrideInfo(this, triggerEvent);
steppedDataArray = {};
for ii = strideIdxs(1:end - 1)
    steppedDataArray{ii} = ...
        this.split(initTime(ii), endTime(ii + 1), 'strideData');
end
end


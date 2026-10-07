function [steppedDataArray, initTime, endTime] = ...
    separateIntoSuperStrides(this, triggerEvent)
%SEPARATEINTOSUPERSTRIDES Splits data into 1.5-stride segments
%
%   [steppedDataArray, initTime, endTime] = separateIntoSuperStrides(this,
% triggerEvent) splits the data into "super-stride" segments of 1.5 strides.
% This is the minimum unit needed to get parameters consistently for an
% individual stride cycle.
%
% Inputs:
%   this         - processedLabData object
%   triggerEvent - event label to use for stride boundaries (e.g., 'RHS',
%                  'LHS')
%
% Outputs:
%   steppedDataArray - cell array of strideData objects
%   initTime         - vector of super-stride start times
%   endTime          - vector of super-stride end times
%
% Toolbox Dependencies: None
%
% See also SEPARATEINTOSTRIDES, GETSTRIDEINFO.

% triggerEvent needs to be one of the valid gaitEvent labels
% Determine end event (ex: if triggerEvent = 'LHS' then we need 'RHS')
if strcmp(triggerEvent(1), 'L')
    contraLeg = 'R';
else
    contraLeg = 'L';
end
contraLateralTriggerEvent = [contraLeg triggerEvent(2:end)];
[strideIdxs, initTime, endTime] = getStrideInfo(this, triggerEvent);
[CstrideIdxs, CinitTime, CendTime] = ...
    getStrideInfo(this, contraLateralTriggerEvent);
steppedDataArray = {};
for ii = strideIdxs - 1
    steppedDataArray{ii} = this.split(initTime(ii), ...
        CendTime(find(CendTime > initTime(ii), 1, 'first')), 'strideData');
end
end


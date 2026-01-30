function [steppedDataArray, initTime, endTime] = ...
    separateIntoDoubleStrides(this, triggerEvent)
%separateIntoDoubleStrides  Splits data into 2-stride segments
%
%   [steppedDataArray, initTime, endTime] =
%   separateIntoDoubleStrides(this, triggerEvent) splits the
%   data into "double-stride" segments of 2 full strides. This
%   is the minimum unit needed to get parameters consistently
%   for an individual stride cycle.
%
%   Inputs:
%       this - processedLabData object
%       triggerEvent - event label to use for stride boundaries
%                      (e.g., 'RHS', 'LHS')
%
%   Outputs:
%       steppedDataArray - cell array of strideData objects
%       initTime - vector of double-stride start times
%       endTime - vector of double-stride end times
%
%   Note: Version deprecated on Apr 2nd 2015
%
%   See also: separateIntoStrides, separateIntoSuperStrides

% Version deprecated on Apr 2nd 2015
% triggerEvent needs to be one of the valid gaitEvent labels
[strideIdxs, initTime, endTime] = getStrideInfo(this, triggerEvent);
steppedDataArray = {};
for i = strideIdxs(1:end - 1)
    steppedDataArray{i} = ...
        this.split(initTime(i), endTime(i + 1), 'strideData');
end
end


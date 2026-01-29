function [steppedDataArray,initTime,endTime]=...
    separateIntoStrides(this,triggerEvent)
%separateIntoStrides  Splits data into individual stride
%segments
%
%   [steppedDataArray,initTime,endTime] =
%   separateIntoStrides(this,triggerEvent) splits the data into
%   single stride segments based on the specified trigger event
%
%   Inputs:
%       triggerEvent - event label to use for stride boundaries
%                      (e.g., 'RHS', 'LHS')
%
%   Outputs:
%       steppedDataArray - cell array of strideData objects
%       initTime - vector of stride start times
%       endTime - vector of stride end times
%
%   See also: separateIntoSuperStrides, getStrideInfo

%triggerEvent needs to be one of the valid gaitEvent labels

[numStrides,initTime,endTime]=getStrideInfo(this,...
    triggerEvent);
steppedDataArray={};
for i=1:numStrides
    steppedDataArray{i}=this.split(initTime(i),endTime(i),...
        'strideData');
end
end


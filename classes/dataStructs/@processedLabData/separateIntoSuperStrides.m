function [steppedDataArray,initTime,endTime]=...
    separateIntoSuperStrides(this,triggerEvent)
%separateIntoSuperStrides  Splits data into 1.5-stride segments
%
%   [steppedDataArray,initTime,endTime] =
%   separateIntoSuperStrides(this,triggerEvent) splits the data
%   into "super-stride" segments of 1.5 strides. This is the
%   minimum unit needed to get parameters consistently for an
%   individual stride cycle.
%
%   Inputs:
%       triggerEvent - event label to use for stride boundaries
%                      (e.g., 'RHS', 'LHS')
%
%   Outputs:
%       steppedDataArray - cell array of strideData objects
%       initTime - vector of super-stride start times
%       endTime - vector of super-stride end times
%
%   See also: separateIntoStrides, getStrideInfo

%triggerEvent needs to be one of the valid gaitEvent labels
%Determine end event (ex: if triggerEvent='LHS' then we
%need 'RHS')
if strcmp(triggerEvent(1),'L')
    contraLeg='R';
else
    contraLeg='L';
end
contraLateralTriggerEvent=[contraLeg triggerEvent(2:end)];
[strideIdxs,initTime,endTime]=getStrideInfo(this,...
    triggerEvent);
[CstrideIdxs,CinitTime,CendTime]=getStrideInfo(this,...
    contraLateralTriggerEvent);
steppedDataArray={};
for i=strideIdxs-1
    steppedDataArray{i}=this.split(initTime(i),...
        CendTime(find(CendTime>initTime(i),1,'first')),...
        'strideData');
end
end


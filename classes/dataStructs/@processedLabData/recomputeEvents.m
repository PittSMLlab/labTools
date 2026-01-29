function newThis=recomputeEvents(this)
%recomputeEvents  Re-computes gait events and adaptation
%parameters
%
%   newThis = recomputeEvents(this) re-computes gait events
%   from angle data and recalculates adaptation parameters
%
%   See also: getEvents, calcParameters

events = getEvents(this,this.angleData);
this.gaitEvents=events;
this.adaptParams=calcParameters(processedData,subData,...
    eventClass);
newThis=this;
end


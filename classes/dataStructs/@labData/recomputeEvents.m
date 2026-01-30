function newThis = recomputeEvents(this)
%recomputeEvents  Re-calculates gait events from angle data
%
%   newThis = recomputeEvents(this) re-computes gait events
%   from the angle data and updates the object
%
%   Inputs:
%       this - labData object
%
%   Outputs:
%       newThis - updated labData object with recomputed events
%
%   See also: getEvents

events = getEvents(this, this.angleData);
this.gaitEvents = events;
newThis = this;
end


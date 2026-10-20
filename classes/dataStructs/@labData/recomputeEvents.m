function newThis = recomputeEvents(this)
%RECOMPUTEEVENTS Re-calculates gait events from angle data.
%
%   newThis = recomputeEvents(this) re-computes gait events from the angle
% data and updates the object
%
% Inputs:
%   this - labData object
%
% Outputs:
%   newThis - updated labData object with recomputed events
%
% Toolbox Dependencies: None
%
% See also GETEVENTS.

events = getEvents(this, this.angleData);
this.gaitEvents = events;
newThis = this;
end


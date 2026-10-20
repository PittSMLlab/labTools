function newThis = recomputeEvents(this)
%RECOMPUTEEVENTS Re-computes gait events and adaptation parameters
%
%   newThis = recomputeEvents(this) re-computes gait events from angle data
% and recalculates adaptation parameters
%
% NOTE: currently errors: processedData, subData and eventClass are
%   undefined in the calcParameters call, and getEvents needs more inputs.
%
% Inputs:
%   this - processedLabData object
%
% Outputs:
%   newThis - updated processedLabData object with recomputed events and
%             parameters
%
% Toolbox Dependencies: None
%
% See also GETEVENTS, CALCPARAMETERS.

events = getEvents(this, this.angleData);
this.gaitEvents = events;
this.adaptParams = calcParameters(processedData, subData, eventClass);
newThis = this;
end


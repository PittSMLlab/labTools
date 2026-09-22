function tf = hasStimTrigger(HreflexPin, threshStim)
%HASSTIMTRIGGER Check whether recorded stim trigger pins carry pulses.
%
%   Some H-reflex Vicon Nexus configurations record the stimulator
% trigger channels (Stimulator_Trigger_Sync_*) even for sessions that
% never stimulate, leaving the channels present but flat (near 0 V).
% This checks all columns of HreflexPin against threshStim and returns
% true if any sample anywhere in the object exceeds it, without
% assuming any particular channel name or leg count.
%   A single sample above threshStim implies at least one rising edge
% by construction, so this check is a strict superset of the rising-
% edge detector in EXTRACTSTIMARTIFACTINDSFROMTRIGGER: it can never
% return false for a trial in which that detector would have found a
% pulse. Empty, zero-column, and all-NaN data all return false, since
% NaN comparisons are false in MATLAB.
%
% Inputs:
%   HreflexPin - labTimeSeries with H-reflex stimulator trigger
%                channels, or [] if none were recorded
%   threshStim - stim trigger pulse detection threshold, V (optional;
%                default: 2.5, matching
%                EXTRACTSTIMARTIFACTINDSFROMTRIGGER's threshStim
%                default)
%
% Outputs:
%   tf - true if any sample in HreflexPin exceeds threshStim
%
% Toolbox Dependencies:
%   None
%
% See also EXTRACTSTIMARTIFACTINDSFROMTRIGGER, COMPUTEHREFLEXPARAMETERS.

arguments
    HreflexPin
    threshStim (1,1) double {mustBePositive} = 2.5   % V
end

if isempty(HreflexPin) || isempty(HreflexPin.Data)
    tf = false;
    return;
end

tf = any(HreflexPin.Data(:) > threshStim);

end

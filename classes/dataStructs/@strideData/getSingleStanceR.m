function [int, dur] = getSingleStanceR(this)
%GETSINGLESTANCER Extracts right single stance phase.
%
%   [int, dur] = getSingleStanceR(this) extracts the phase from left toe off
% to left heel strike (right single stance)
%
% Inputs:
%   this - strideData object
%
% Outputs:
%   int - strideData object containing single stance phase
%   dur - duration of phase in seconds
%
% Toolbox Dependencies: None
%
% See also GETSINGLESTANCEL, GETSWINGL, GETINTERVALBTWEVENTS.

int = getIntervalBtwEvents(this, 'LTO', 'LHS');
dur = int.gaitEvents.timeRange;
end


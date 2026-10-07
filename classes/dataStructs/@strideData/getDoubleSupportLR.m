function [dsLR, duration] = getDoubleSupportLR(this)
%GETDOUBLESUPPORTLR Extracts left-to-right double support phase.
%
%   [dsLR, duration] = getDoubleSupportLR(this) extracts the phase from left
% heel strike to right toe off
%
% Inputs:
%   this - strideData object
%
% Outputs:
%   dsLR     - strideData object containing double support phase
%   duration - duration of phase in seconds
%
% Toolbox Dependencies: None
%
% See also GETDOUBLESUPPORTRL, GETSINGLESTANCEL, GETINTERVALBTWEVENTS.

dsLR     = getIntervalBtwEvents(this, 'LHS', 'RTO');
duration = dsLR.gaitEvents.timeRange;
end


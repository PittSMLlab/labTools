function [dsRL, duration] = getDoubleSupportRL(this)
%GETDOUBLESUPPORTRL Extracts right-to-left double support phase.
%
%   [dsRL, duration] = getDoubleSupportRL(this) extracts the phase from
% right heel strike to left toe off
%
% Inputs:
%   this - strideData object
%
% Outputs:
%   dsRL     - strideData object containing double support phase
%   duration - duration of phase in seconds
%
% Toolbox Dependencies: None
%
% See also GETDOUBLESUPPORTLR, GETSINGLESTANCER, GETINTERVALBTWEVENTS.

dsRL     = getIntervalBtwEvents(this, 'RHS', 'LTO');
duration = dsRL.gaitEvents.timeRange;
end


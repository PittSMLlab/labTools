function [dsLR, duration] = getDoubleSupportLR(this)
%getDoubleSupportLR  Extracts left-to-right double support phase
%
%   [dsLR, duration] = getDoubleSupportLR(this) extracts the
%   phase from left heel strike to right toe off
%
%   Inputs:
%       this - strideData object
%
%   Outputs:
%       dsLR - strideData object containing double support phase
%       duration - duration of phase in seconds
%
%   See also: getDoubleSupportRL, getSingleStanceL,
%             getIntervalBtwEvents

dsLR = getIntervalBtwEvents(this, 'LHS', 'RTO');
duration = dsLR.gaitEvents.timeRange;
end


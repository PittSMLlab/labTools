function slowLeg = getSlowLeg(this)
%GETSLOWLEG Returns leg that was on slow belt
%
%   slowLeg = getSlowLeg(this) determines which leg is the slow leg, simply
% the opposite of the fast leg
%
% NOTE: Be sure to call get.fastLeg() first
%
% Inputs:
%   this - experimentData object
%
% Outputs:
%   slowLeg - 'R' or 'L'
%
% Toolbox Dependencies: None
%
% See also GETREFLEG, GETNONREFLEG.

if strcmpi(this.fastLeg, 'L')
    slowLeg = 'R';
elseif strcmpi(this.fastLeg, 'R')
    slowLeg = 'L';
else
    slowLeg = [];
end
end


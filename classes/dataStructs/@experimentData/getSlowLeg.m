function slowLeg = getSlowLeg(this)
%getSlowLeg  Returns leg that was on slow belt
%
%   slowLeg = getSlowLeg(this) determines which leg is the slow leg,
%   simply the opposite of the fast leg
%
%   Inputs:
%       this - experimentData object
%
%   Outputs:
%       slowLeg - 'R' or 'L'
%
%   Note: Be sure to call get.fastLeg() first
%
%   See also: getRefLeg, getNonRefLeg

% determine which leg is the slow leg, simply the opposite of the fast
% leg, be sure to call get.fastLeg() first
%
% returns 'R' or 'L'
if strcmpi(this.fastLeg, 'L')
    slowLeg = 'R';
elseif strcmpi(this.fastLeg, 'R')
    slowLeg = 'L';
else
    slowLeg = [];
end
end


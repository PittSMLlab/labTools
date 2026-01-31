function fL = getNonRefLeg(this)
%getNonRefLeg  Returns non-reference leg
%
%   fL = getNonRefLeg(this) returns the leg opposite to the reference
%   leg
%
%   Inputs:
%       this - experimentData object
%
%   Outputs:
%       fL - 'R' or 'L'
%
%   See also: getRefLeg, getSlowLeg

% returns the non-reference leg, 'R' or 'L'
sL = this.getRefLeg;
if strcmp(sL, 'R')
    fL = 'L';
else
    fL = 'R';
end
end


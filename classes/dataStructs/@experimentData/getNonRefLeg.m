function fL = getNonRefLeg(this)
%GETNONREFLEG Returns non-reference leg
%
%   fL = getNonRefLeg(this) returns the leg opposite to the reference leg
%
% Inputs:
%   this - experimentData object
%
% Outputs:
%   fL - 'R' or 'L'
%
% Toolbox Dependencies: None
%
% See also GETREFLEG, GETSLOWLEG.

sL = this.getRefLeg();
if strcmp(sL, 'R')
    fL = 'L';
else
    fL = 'R';
end
end


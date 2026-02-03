function [int, dur] = getSwingL(this)
%getSwingL  Extracts left swing phase
%
%   [int, dur] = getSwingL(this) extracts the left swing phase,
%   which corresponds to right single stance
%
%   Inputs:
%       this - strideData object
%
%   Outputs:
%       int - strideData object containing swing phase
%       dur - duration of phase in seconds
%
%   See also: getSwingR, getSingleStanceR

[int, dur] = getSingleStanceR(this);
end


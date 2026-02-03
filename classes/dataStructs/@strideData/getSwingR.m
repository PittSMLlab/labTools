function [int, dur] = getSwingR(this)
%getSwingR  Extracts right swing phase
%
%   [int, dur] = getSwingR(this) extracts the right swing phase,
%   which corresponds to left single stance
%
%   Inputs:
%       this - strideData object
%
%   Outputs:
%       int - strideData object containing swing phase
%       dur - duration of phase in seconds
%
%   See also: getSwingL, getSingleStanceL

[int, dur] = getSingleStanceL(this);
end


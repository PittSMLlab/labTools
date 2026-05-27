function [newP] = effconvn(pValues1,pValues2,shape)
%EFFCONVN Convolve N-D arrays via FFT.
%
%   Implements convn using FFTs; equivalent to convn(A, B, shape).
%   Note: FFT-based convolution is generally faster only for large arrays.
%   Only 'full' output is currently implemented; passing 'valid' or 'same'
%   triggers a warning and returns an empty array.
%
% Inputs:
%   pValues1 - first N-D numeric array
%   pValues2 - second N-D numeric array
%   shape    - (optional) output shape: 'full' (default), 'valid', 'same'
%
% Outputs:
%   newP - convolution result (full shape only; empty for other shapes)
%
% Toolbox Dependencies: None
%
% See also EFFCONVNFULL, CONVN.

[newP] = effconvnfull(pValues1,pValues2);

if nargin>2
    warning('Shape argument still not implemented.')
    if strcmp(shape,'valid')
        newP=[];
    elseif strcmp(shape,'same')
        newP=[];
    end %Assumes method='full'
end


end


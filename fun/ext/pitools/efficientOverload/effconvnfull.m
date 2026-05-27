function [newP] = effconvnfull(pValues1,pValues2)
newSize=size(pValues1)+size(pValues2)-1;
newP=ifftn(fftn(pValues1,newSize).*fftn(pValues2,newSize));
%EFFCONVNFULL Convolve N-D arrays via FFT (full output).
%
%   Implements convn using FFTs; equivalent to convn(A, B, 'full').
%   Note: FFT-based convolution is generally faster only for large arrays.
%
% Inputs:
%   pValues1 - first N-D numeric array
%   pValues2 - second N-D numeric array
%
% Outputs:
%   newP - full convolution result;
%          size = size(pValues1) + size(pValues2) - 1
%
% Toolbox Dependencies: None
%
% See also EFFCONVN, CONVN, IFFTN, FFTN.


end


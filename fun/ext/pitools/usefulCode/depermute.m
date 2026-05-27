function [B] = depermute(A,order)
newOrder(order)=order;
B=permute(A,newOrder);
%DEPERMUTE Invert a prior permute() call given the same order vector.
%
%   If A = permute(C, order), then B = depermute(A, order) recovers C.
%
% Inputs:
%   A     - array produced by permute(C, order)
%   order - permutation order vector originally passed to permute
%
% Outputs:
%   B - array with dimensions restored to their original arrangement
%
% Toolbox Dependencies: None
%
% See also PERMUTE.


end


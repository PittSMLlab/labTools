function [w] = columnNorm(X,p,dim)
%COLUMNNORM Compute the p-norm of matrix elements along a given dimension.
%
%   Returns the p-norm of each slice of X along dimension dim. By default
% computes the Euclidean (L2) norm of each column.
%
% Inputs:
%   X   - numeric array, input data
%   p   - scalar double, norm order (default 2)
%   dim - scalar integer, dimension to operate along (default 1)
%
% Outputs:
%   w - numeric array, p-norms; size matches X with dimension dim collapsed
%
% Toolbox Dependencies: None
%
% See also DEMEAN.

if nargin<3
    dim=1;
end
if nargin<2
    p=2;
end
w = sum(abs(X).^p,dim).^(1/p);

end


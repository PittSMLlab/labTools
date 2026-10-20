function D = computeDiffMatrix(pos)
%COMPUTEDIFFMATRIX Pairwise differences between marker components.
%
%   D = COMPUTEDIFFMATRIX(pos) computes, for every frame, the difference
% between each pair of markers along each coordinate: D(a,k,b,m) =
% pos(a,k,m) - pos(b,k,m).
%
% Inputs:
%   pos - N markers x dim coordinates x M frames position array
%
% Outputs:
%   D - N x dim x N x M array of pairwise component differences
%
% Toolbox Dependencies: None
%
% See also COMPUTEDISTANCEMATRIX.

[N,dim,M] = size(pos);
D = bsxfun(@minus,reshape(pos,[N,dim,1,M]), ...
    reshape(permute(pos,[2,1,3]),[1,dim,N,M]));
end


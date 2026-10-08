function D = computeDistanceMatrix(pos)
%COMPUTEDISTANCEMATRIX Pairwise Euclidean distances between markers.
%
%   D = COMPUTEDISTANCEMATRIX(pos) computes, for every frame, the distance
% between each pair of markers.
%
% Inputs:
%   pos - N markers x dim coordinates x M frames position array
%
% Outputs:
%   D - N x N x M array of pairwise distances (N x N when M is 1)
%
% Toolbox Dependencies: None
%
% See also COMPUTEDIFFMATRIX.

E = computeDiffMatrix(pos);
D = sqrt(squeeze(sum(E.^2,2)));
end


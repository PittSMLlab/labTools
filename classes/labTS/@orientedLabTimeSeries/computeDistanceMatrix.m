function [distMatrix, labels, labels2, Time] = computeDistanceMatrix(...
    this, t0, t1, labels, labels2)
%computeDistanceMatrix  Computes inter-marker distances
%
%   [distMatrix, labels, labels2, Time] = computeDistanceMatrix(this,
%   t0, t1, labels, labels2) computes Euclidean distances between
%   markers
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       t0 - start time (optional)
%       t1 - end time (optional)
%       labels - markers to compute from (optional)
%       labels2 - markers to compute to (optional)
%
%   Outputs:
%       distMatrix - 3D matrix (time x markers1 x markers2) of distances
%       labels - cell array of marker1 labels used
%       labels2 - cell array of marker2 labels used
%       Time - time vector
%
%   See also: computeDifferenceMatrix

if nargin < 2 || isempty(t0)
    t0 = [];
end
if nargin < 3 || isempty(t1)
    t1 = [];
end
if nargin < 4 || isempty(labels)
    labels = [];
end
if nargin < 5 || isempty(labels2)
    labels2 = [];
end
[diffMatrix, labels, labels2, Time] = computeDifferenceMatrix(this, ...
    t0, t1, labels, labels2);
distMatrix = sqrt(sum(diffMatrix.^2, 4));
end


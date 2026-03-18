function [diffMatrix, labels, labels2, Time] = computeDifferenceMatrix( ...
    this, t0, t1, labels, labels2)
%computeDifferenceMatrix  Computes inter-marker differences
%
%   [diffMatrix, labels, labels2, Time] = computeDifferenceMatrix(
%   this, t0, t1, labels, labels2) computes difference vectors between
%   markers for time interval [t0, t1]
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       t0 - start time (optional, default: beginning)
%       t1 - end time (optional, default: end)
%       labels - markers to compute from (optional, default: all)
%       labels2 - markers to compute to (optional, default: all)
%
%   Outputs:
%       diffMatrix - 4D matrix (time x markers1 x markers2 x 3)
%       labels - cell array of marker1 labels used
%       labels2 - cell array of marker2 labels used
%       Time - time vector for computed differences
%
%   See also: computeDistanceMatrix, computeDifferenceOTS

[data, label] = getOrientedData(this, this.getLabelPrefix);
[T, N, M] = size(data); % M = 3

% Inefficient way: compute the difference matrix for all times and
% markers, and then reduce it
diffMatrix = nan(T, N, M, N);
for i = 1:N
    diffMatrix(:, :, :, i) = bsxfun(@minus, data, data(:, i, :));
end
diffMatrix = permute(diffMatrix, [1, 2, 4, 3]);
if nargin < 2 || isempty(t0)
    t0 = this.Time(1);
end
if nargin < 3 || isempty(t1)
    t1 = this.Time(end);
end
if nargin < 4 || isempty(labels)
    labels = this.getLabelPrefix;
end
if nargin < 5 || isempty(labels2)
    labels2 = this.getLabelPrefix;
end
% Reduce it:
timeIdxs = find(this.Time <= t1 & this.Time >= t0);
[~, labelIdxs] = isaLabelPrefix(this, labels);
[~, label2Idxs] = isaLabelPrefix(this, labels2);
diffMatrix = diffMatrix(timeIdxs, labelIdxs, label2Idxs, :);
Time = this.Time(timeIdxs);

end


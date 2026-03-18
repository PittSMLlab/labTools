function diffOTS = computeDifferenceOTS(this, t0, t1, labels, labels2)
%computeDifferenceOTS  Difference matrix as OTS
%
%   diffOTS = computeDifferenceOTS(this, t0, t1, labels, labels2)
%   computes difference matrix and returns as orientedLabTimeSeries
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       t0 - start time (optional, default: beginning)
%       t1 - end time (optional, default: end)
%       labels - markers to compute from (optional, default: all)
%       labels2 - markers to compute to (optional, default: all)
%
%   Outputs:
%       diffOTS - orientedLabTimeSeries with difference vectors
%
%   See also: computeDifferenceMatrix, computeDistanceMatrix

if nargin < 2 || isempty(t0)
    t0 = this.Time(1);
end
if nargin < 3 || isempty(t1)
    t1 = this.Time(end) + eps;
end
if nargin < 4 || isempty(labels)
    labels = this.getLabelPrefix;
end
if nargin < 5 || isempty(labels2)
    labels2 = this.getLabelPrefix;
end
[diffMatrix, labels, labels2, Time] = computeDifferenceMatrix(this, ...
    t0, t1, labels, labels2);
newLabels = cell(1, length(labels) * length(labels2));
for i = 1:length(labels2)
    newLabels((i - 1) * length(labels) + 1:i * length(labels)) = ...
        strcat(labels, [' - ' labels2{i}]);
end
newLabels2 = [strcat(newLabels, 'x'); strcat(newLabels, 'y'); ...
    strcat(newLabels, 'z')];
aux = reshape(diffMatrix, size(diffMatrix, 1), ...
    size(diffMatrix, 2) * size(diffMatrix, 3), size(diffMatrix, 4));
aux = permute(aux, [1, 3, 2]);
diffOTS = orientedLabTimeSeries(aux(:, :), Time(1), this.sampPeriod, ...
    newLabels2(:), this.orientation);

end


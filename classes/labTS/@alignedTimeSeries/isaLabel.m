function [boolFlag, labelIdx] = isaLabel(this, label)
%isaLabel  Checks if labels exist
%
%   [boolFlag, labelIdx] = isaLabel(this, label) checks whether
%   specified labels are present
%
%   Inputs:
%       this - alignedTimeSeries object
%       label - cell array of label strings to check
%
%   Outputs:
%       boolFlag - logical vector indicating which labels exist
%       labelIdx - vector of label indices
%
%   See also: getLabelsThatMatch

boolFlag = false(size(label));
labelIdx = zeros(size(label));
[bool, idx] = compareListsFast(label, this.labels);
for j = 1:length(label)
    if any(idx == j)
        boolFlag(j) = true;
        labelIdx(j) = find(idx == j);
    end
end
end


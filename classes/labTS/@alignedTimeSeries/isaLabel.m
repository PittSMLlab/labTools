function [boolFlag, labelIdx] = isaLabel(this, label)
%ISALABEL Checks if labels exist.
%
%   [boolFlag, labelIdx] = isaLabel(this, label) checks whether specified
% labels are present
%
% Inputs:
%   this  - alignedTimeSeries object
%   label - cell array of label strings to check
%
% Outputs:
%   boolFlag - logical vector indicating which labels exist
%   labelIdx - vector of label indices
%
% Toolbox Dependencies: None
%
% See also GETLABELSTHATMATCH.

boolFlag = false(size(label));
labelIdx = zeros(size(label));
[bool, idx] = compareListsFast(label, this.labels);
for jj = 1:length(label)
    if any(idx == jj)
        boolFlag(jj) = true;
        labelIdx(jj) = find(idx == jj);
    end
end
end


function [score, auxLabel] = getScore(this, label)
%getScore  Retrieves scores for specified test(s)
%
%   [score, auxLabel] = getScore(this) returns all scores and labels
%
%   [score, auxLabel] = getScore(this, label) returns scores for
%   specified test(s)
%
%   Inputs:
%       this - cognitiveData object
%       label - string or cell array of test name(s) to retrieve
%               (optional, default: all tests)
%
%   Outputs:
%       score - matrix of scores for requested test(s)
%       auxLabel - cell array of labels for returned scores
%
%   Note: Issues warning if requested label does not exist
%
%   See also: isaLabel

if nargin < 2 || isempty(label)
    label = this.labels;
end
if isa(label, 'char')
    auxLabel = {label};
else
    auxLabel = label;
end
[boolFlag, labelIdx] = this.isaLabel(auxLabel);
for i = 1:length(boolFlag)
    if boolFlag(i) == 0
        warning(['Label ' auxLabel{i} ...
            ' is not a labeled value in this data set.']);
    end
end
score = this.scores(:, labelIdx(boolFlag == 1));
auxLabel = this.labels(labelIdx(boolFlag == 1));
end


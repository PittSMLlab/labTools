function labelList = getLabelsThatMatch(this, exp)
%GETLABELSTHATMATCH Finds labels matching pattern.
%
%   labelList = getLabelsThatMatch(this, exp) returns labels matching
% regular expression
%
% Inputs:
%   this - alignedTimeSeries object
%   exp  - regular expression string
%
% Outputs:
%   labelList - cell array of matching labels
%
% Toolbox Dependencies: None
%
% See also REGEXP, ISALABEL.

labelList = this.labels;
flags     = cellfun(@(x) ~isempty(x), regexp(labelList, exp));
labelList = labelList(flags);
end


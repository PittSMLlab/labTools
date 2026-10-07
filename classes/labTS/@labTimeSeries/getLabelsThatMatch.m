function labelList = getLabelsThatMatch(this, exp)
%GETLABELSTHATMATCH Returns labels matching regular expression.
%
%   labelList = getLabelsThatMatch(this, exp) returns labels on this labTS
% that match the regular expression exp
%
% Inputs:
%   this - labTimeSeries object
%   exp  - any regular expression (as string)
%
% Outputs:
%   labelList - cell array containing matching labels
%
% Toolbox Dependencies: None
%
% See also REGEXP, ISALABEL, GETLABELS.

labelList = this.labels;
flags     = cellfun(@(x) ~isempty(x), regexp(labelList, exp));
labelList = labelList(flags);
end


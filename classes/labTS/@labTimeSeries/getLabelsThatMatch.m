function labelList = getLabelsThatMatch(this, exp)
%getLabelsThatMatch  Returns labels matching regular expression
%
%   labelList = getLabelsThatMatch(this, exp) returns labels on this
%   labTS that match the regular expression exp
%
%   Inputs:
%       this - labTimeSeries object
%       exp - any regular expression (as string)
%
%   Outputs:
%       labelList - cell array containing matching labels
%
%   See also: regexp, isaLabel, getLabels

labelList = this.labels;
flags = cellfun(@(x) ~isempty(x), regexp(labelList, exp));
labelList = labelList(flags);
end


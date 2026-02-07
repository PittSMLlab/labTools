function labelList = getLabelsThatMatch(this, exp)
%getLabelsThatMatch  Finds labels matching pattern
%
%   labelList = getLabelsThatMatch(this, exp) returns labels matching
%   regular expression
%
%   Inputs:
%       this - alignedTimeSeries object
%       exp - regular expression string
%
%   Outputs:
%       labelList - cell array of matching labels
%
%   See also: regexp, isaLabel

% Returns labels on this labTS that match the regular expression exp.
% labelList = getLabelsThatMatch(this, exp)
% INPUT:
% this: labTS object
% exp: any regular expression (as string).
% OUTPUT:
% labelList: cell array containing labels of this labTS that match
% See also regexp
labelList = this.labels;
flags = cellfun(@(x) ~isempty(x), regexp(labelList, exp));
labelList = labelList(flags);
end


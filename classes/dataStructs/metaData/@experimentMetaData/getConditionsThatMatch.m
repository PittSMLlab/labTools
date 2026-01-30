function condNames = getConditionsThatMatch(this, name, type)
%getConditionsThatMatch  Returns condition names matching pattern
%
%   condNames = getConditionsThatMatch(this, name) returns all
%   condition names that contain the specified pattern
%
%   condNames = getConditionsThatMatch(this, name, type) returns
%   condition names matching both name pattern and type pattern
%
%   Inputs:
%       this - experimentMetaData object
%       name - string pattern to search for in condition names
%       type - string pattern for additional filtering (optional)
%
%   Outputs:
%       condNames - cell array of matching condition names
%
%   Example:
%       condNames = getConditionsThatMatch('base', 'TM')
%       % Returns all treadmill baseline conditions
%
%   See also: getConditionsThatMatchV2, getConditionIdxsFromName

% Returns condition names that match certain patterns

if nargin < 2 || isempty(name) || ~isa(name, 'char')
    error('Pattern name to search for needs to be a string')
end

ccNames = this.conditionName;
idx = cellfun(@(x) isempty(x), ccNames);
if sum(idx) >= 1
    r = find(idx == 1);
    for q = 1:length(r)
        % Need a more elegant solution for empty condition names
        ccNames{r(q)} = ['awsdfasdas' num2str(q)];
    end
end
patternMatches = cellfun(@(x) ~isempty(x), (strfind(lower(ccNames), ...
    lower(name))));
if nargin > 2 && ~isempty(type) && isa(type, 'char')
    typeMatches = cellfun(@(x) ~isempty(x), (strfind(lower(ccNames), ...
        lower(type))));
else
    typeMatches = true(size(patternMatches));
end

% patternMatches = cellfun(@(x) ~isempty(x), (strfind(lower(this.conditionName), lower(name))));
% if nargin > 2 && ~isempty(type) && isa(type, 'char')
%     typeMatches = cellfun(@(x) ~isempty(x), (strfind(lower(this.conditionName), lower(type))));
% else
%     typeMatches = true(size(patternMatches));
% end
condNames = this.conditionName(patternMatches & typeMatches);
end


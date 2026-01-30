function condNames = getConditionsThatMatchV2(this, name, type)
%getConditionsThatMatchV2  Returns condition names matching pattern
%with fallback
%
%   condNames = getConditionsThatMatchV2(this, name, type) returns
%   condition names matching both name and type patterns, with fallback
%   to 'TR' (training) type if no matches found for 'NIM' or 'TM' types
%
%   Inputs:
%       this - experimentMetaData object
%       name - string pattern to search for in condition names
%       type - string pattern for type filtering (optional)
%
%   Outputs:
%       condNames - cell array of matching condition names
%
%   Note: This is a variant of getConditionsThatMatch with special
%         handling for training conditions. When searching for 'NIM' or
%         'TM' type conditions and finding none, it falls back to
%         searching for 'TR' (training) conditions.
%
%   See also: getConditionsThatMatch, getConditionIdxsFromName

% Returns condition names that match certain patterns, but when its
% empty it will look for a "training" or "TR" base condition

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
    % if sum(typeMatches) == 0 || strcmp(type, 'TM') % Marcela: I am not sure if this is the best way to do this but its a temporal fix for R01
    %     typeMatches = cellfun(@(x) ~isempty(x), (strfind(lower(ccNames), lower('TR'))));
    % end
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

% Marcela & DMMO: I am not sure if this is the best way to do this but
% its a temporal fix for R01
if isempty(condNames) && strcmp(type, 'NIM') || ...
        isempty(condNames) && strcmp(type, 'TM')
    typeMatches = cellfun(@(x) ~isempty(x), (strfind(lower(ccNames), ...
        lower('TR'))));
    condNames = this.conditionName(patternMatches & typeMatches);

end
end


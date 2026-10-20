function condNames = getConditionsThatMatchV2(this, name, type)
%GETCONDITIONSTHATMATCHV2 Return matching condition names, with fallback.
%
%   condNames = getConditionsThatMatchV2(this, name, type) returns
% condition names matching both name and type patterns, with fallback
% to 'TR' (training) type if no matches found for 'NIM' or 'TM' types
%
% Inputs:
%   this - experimentMetaData object
%   name - string pattern to search for in condition names
%   type - string pattern for type filtering (optional)
%
% Outputs:
%   condNames - cell array of matching condition names
%
% NOTE: This is a variant of getConditionsThatMatch with special handling
%       for training conditions. When searching for 'NIM' or 'TM' type
%       conditions and finding none, it falls back to searching for 'TR'
%       (training) conditions.
%       The matching itself is delegated to GETCONDITIONSTHATMATCH.
%
% Toolbox Dependencies: None
%
% See also GETCONDITIONSTHATMATCH, GETCONDITIONIDXSFROMNAME.

if nargin < 2 || isempty(name) || ~isa(name, 'char')
    error('Pattern name to search for needs to be a string');
end

% Delegate the matching to getConditionsThatMatch; only the fallback
% below is specific to this version.
if nargin < 3
    condNames = getConditionsThatMatch(this, name);
else
    condNames = getConditionsThatMatch(this, name, type);
end

% Earlier inline version of the matching (kept as comments):
% Need a more elegant solution for empty condition names
% if sum(typeMatches) == 0 || strcmp(type, ...
%    'TM')
% (disabled alternative of the 'TR' fallback below)
%     typeMatches = cellfun(@(x) ~isempty(x), ...
%    (strfind(lower(ccNames), lower('TR'))));
% end
% patternMatches = cellfun(@(x) ~isempty(x), ...
%    (strfind(lower(this.conditionName), lower(name))));
% if nargin > 2 && ~isempty(type) && isa(type, 'char')
%     typeMatches = cellfun(@(x) ~isempty(x), ...
%    (strfind(lower(this.conditionName), lower(type))));
% else
%     typeMatches = true(size(patternMatches));
% end

% TODO: temporary fix for R01; confirm the 'TR' fallback is the best
% approach.
if isempty(condNames) && strcmp(type, 'NIM') || ...
        isempty(condNames) && strcmp(type, 'TM')
    condNames = getConditionsThatMatch(this, name, 'TR');
end
end


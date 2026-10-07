function [newThis, change] = replaceConditionNames(this, currentName, ...
    newName)
%replaceConditionNames  Replaces condition names
%
%   [newThis, change] = replaceConditionNames(this, currentName,
%   newName) looks for conditions whose names match options in
%   currentName and changes them to newName
%
%   Inputs:
%       this - experimentMetaData object
%       currentName - cell array of current condition names to replace
%       newName - cell array of new condition names (same length as
%                 currentName)
%
%   Outputs:
%       newThis - experimentMetaData object with replaced names
%       change - logical flag indicating if any changes were made
%
%   Note: Only exact matches are replaced, partial matches ignored
%
%   See also: numerateRepeatedConditionNames,
%             getConditionIdxsFromName

change = false;
% Check currentName and newName are cell arrays of same length
% Exact matches only, but allows not finding matches (does not accept
% partial matches)
conditionIdxs = this.getConditionIdxsFromName(currentName, 1, 1);
% this.conditionName(conditionIdxs) = newName;
for ii = 1:length(currentName)
    if ~isnan(conditionIdxs(ii)) && ...
            ~strcmp(this.conditionName{conditionIdxs(ii)}, newName{ii})
        this.conditionName{conditionIdxs(ii)} = newName{ii};
        change = true;
    end
end
newThis = this;
end


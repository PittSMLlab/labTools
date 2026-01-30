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

% Looks for conditions whose name match the options in currentName &
% changes them to newName
change = false;
% Check currentName and newName are cell arrays of same length
% Exact matches only, but allows not finding matches (does not accept
% partial matches)
conditionIdxs = this.getConditionIdxsFromName(currentName, 1, 1);
% this.conditionName(conditionIdxs) = newName;
for i = 1:length(currentName)
    if ~isnan(conditionIdxs(i)) && ...
            ~strcmp(this.conditionName{conditionIdxs(i)}, newName{i})
        this.conditionName{conditionIdxs(i)} = newName{i};
        change = true;
    end
end
newThis = this;
end


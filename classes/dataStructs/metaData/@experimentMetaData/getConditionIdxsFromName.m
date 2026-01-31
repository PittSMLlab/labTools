function conditionIdxs = getConditionIdxsFromName(this, ...
    conditionNames, exactMatchesOnlyFlag, ignoreMissingNamesFlag)
%getConditionIdxsFromName  Returns condition indices from names
%
%   conditionIdxs = getConditionIdxsFromName(this, conditionNames)
%   looks for condition names similar to those given and returns
%   corresponding condition indices. Accepts partial matches.
%
%   conditionIdxs = getConditionIdxsFromName(this, conditionNames,
%   exactMatchesOnlyFlag, ignoreMissingNamesFlag) allows control over
%   matching behavior
%
%   Inputs:
%       this - experimentMetaData object
%       conditionNames - cell array containing strings or nested cell
%                        arrays of strings (e.g., {'Base', 'Adap',
%                        {'Post', 'wash'}})
%       exactMatchesOnlyFlag - if true, only exact matches accepted
%                              (default: false)
%       ignoreMissingNamesFlag - if true, missing names generate
%                                warning instead of error (default:
%                                false)
%
%   Outputs:
%       conditionIdxs - vector of condition indices (NaN for conditions
%                       not found)
%
%   See also: getTrialsInCondition, getConditionsThatMatch

if nargin < 3 || isempty(exactMatchesOnlyFlag)
    % Default behavior accepts partial matches
    exactMatchesOnlyFlag = 0;
end

if nargin < 4 || isempty(ignoreMissingNamesFlag)
    ignoreMissingNamesFlag = 0;
end

if isa(conditionNames, 'char')
    conditionNames = {conditionNames};
end

nConds = length(conditionNames);
conditionIdxs = NaN(nConds, 1);
for i = 1:nConds
    % First: find if there is condition with similar name to the one given
    clear condName;
    if iscell(conditionNames{i})
        for j = 1:length(conditionNames{i})
            condName{j} = lower(conditionNames{i}{j});
        end
    else
        condName{1} = lower(conditionNames{i}); % Lower case
    end
    aux = this.conditionName;
    aux(cellfun(@isempty, aux)) = {''};
    allConds = lower(aux);
    condIdx = [];
    j = 0;
    while isempty(condIdx) && j < length(condName)
        j = j + 1;
        matches = find(strcmpi(allConds, condName{j})); % Exact matches
        if isempty(matches) && exactMatchesOnlyFlag == 0
            warning(['Looking for conditions named ''' condName{j} ...
                ''' but found no exact matches. Looking for partial ' ...
                'matches.']);
            matches = find(~cellfun(@isempty, strfind(allConds, ...
                condName{j})));
        end
        if length(matches) > 1
            warning(['Looking for conditions named ''' condName{j} ...
                ''' but found multiple matches. Using ''' ...
                allConds{matches(1)}]);
            matches = matches(1);
        end
        condIdx = matches;
    end
    if ~isempty(condIdx)
        conditionIdxs(i) = condIdx;
    else
        if ~ignoreMissingNamesFlag
            error(['Looking for conditions named ''' ...
                cell2mat(strcat(condName, ',')) ...
                '''but found no matches, stopping.']);
        else
            warning(['Looking for conditions named ''' ...
                cell2mat(strcat(condName, ',')) ...
                '''but found no matches, ignoring.']);
        end
    end
end
end


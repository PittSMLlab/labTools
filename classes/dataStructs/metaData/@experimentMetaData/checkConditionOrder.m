function conditionOrder = checkConditionOrder(this, ...
    conditionNamesInOrder, silentFlag)
%checkConditionOrder  Checks that conditions appear in order
%
%   conditionOrder = checkConditionOrder(this) checks that all
%   conditions appear in order according to trial numbering
%
%   conditionOrder = checkConditionOrder(this,
%   conditionNamesInOrder, silentFlag) checks specified conditions and
%   optionally displays warnings
%
%   Inputs:
%       this - experimentMetaData object
%       conditionNamesInOrder - cell array of condition names to check
%                               (optional, default: all conditions)
%       silentFlag - if false, displays warnings for out-of-order
%                    conditions (optional, default: true)
%
%   Outputs:
%       conditionOrder - vector indicating order of conditions by first
%                        trial number
%
%   See also: validateTrialsInCondition, sortConditions

% Checks that the given conditions appear in order for the subject,
% according to trial numbering
if nargin < 2 || isempty(conditionNamesInOrder)
    conditionNamesInOrder = this.conditionName;
end

% Doing validation of trials, and getting conditionOrder
conditionOrder = validateTrialsInCondition(this);
conditionIdxsInOrder = ...
    this.getConditionIdxsFromName(conditionNamesInOrder);
% Keeping order of requested conditions only
conditionOrder = conditionOrder(conditionIdxsInOrder);
if nargin > 2 && ~isempty(silentFlag) && ~silentFlag
    if any(diff(conditionOrder) < 1)
        badOrder = find(diff(conditionOrder) < 1);
        for i = 1:length(badOrder)
            display(['Conditions provided are not in order: ' ...
                conditionNamesInOrder{badOrder(i)} ' precedes ' ...
                conditionNamesInOrder{badOrder(i) + 1}]);
        end
    end
end
end


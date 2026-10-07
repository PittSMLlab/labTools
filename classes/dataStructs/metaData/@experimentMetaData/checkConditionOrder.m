function conditionOrder = checkConditionOrder(this, ...
    conditionNamesInOrder, silentFlag)
%CHECKCONDITIONORDER Checks that conditions appear in order.
%
%   conditionOrder = checkConditionOrder(this) checks that all
% conditions appear in order according to trial numbering
%
%   conditionOrder = checkConditionOrder(this,
% conditionNamesInOrder, silentFlag) checks specified conditions and
% optionally displays warnings
%
% Inputs:
%   this                  - experimentMetaData object
%   conditionNamesInOrder - cell array of condition names to check
%                           (optional, default: all conditions)
%   silentFlag            - if false, displays warnings for out-of-order
%                           conditions (optional, default: true)
%
% Outputs:
%   conditionOrder - vector indicating order of conditions by first trial
%                    number
%
% Toolbox Dependencies: None
%
% See also VALIDATETRIALSINCONDITION, SORTCONDITIONS.

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
        for ii = 1:length(badOrder)
            disp(['Conditions provided are not in order: ' ...
                conditionNamesInOrder{badOrder(ii)} ' precedes ' ...
                conditionNamesInOrder{badOrder(ii) + 1}]);
        end
    end
end
end


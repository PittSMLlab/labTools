function newThis = sortConditions(this)
%SORTCONDITIONS Sorts conditions by trial order.
%
%   newThis = sortConditions(this) reorders conditions according to
% their trial numbers, from earliest to latest
%
% Inputs:
%   this - experimentMetaData object
%
% Outputs:
%   newThis - experimentMetaData object with sorted conditions
%
% Toolbox Dependencies: None
%
% See also VALIDATETRIALSINCONDITION, CHECKCONDITIONORDER.

% Get order:
conditionOrder = this.validateTrialsInCondition;
% Sort:
this.conditionName(conditionOrder) = this.conditionName;
this.conditionDescription(conditionOrder) = this.conditionDescription;
this.trialsInCondition(conditionOrder) = this.trialsInCondition;
% Check ordering:
this.checkConditionOrder();
newThis = this;
end


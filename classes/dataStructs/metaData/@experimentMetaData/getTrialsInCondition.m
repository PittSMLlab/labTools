function trialNums = getTrialsInCondition(this, conditionNames)
%getTrialsInCondition  Returns trial numbers in each condition
%
%   trialNums = getTrialsInCondition(this, conditionNames) returns the
%   trial numbers for specified conditions
%
%   Inputs:
%       this - experimentMetaData object
%       conditionNames - cell array containing string(s) specifying
%                        conditions (e.g., {'Base', 'Adap', {'Post',
%                        'wash'}})
%
%   Outputs:
%       trialNums - matrix of trial numbers in the specified conditions
%
%   Example:
%       trialNums = getTrialsInCondition({'Base'})
%       trialNums = [1 2 3]
%
%   See also: getConditionIdxsFromName, getCondLstPerTrial

% Return trial numbers in each condition
%
% Inputs:
% conditionNames -- cell containing string(s)
% E.g. conditionNames = {'Base', 'Adap', {'Post', 'wash'}}
%
% output:
% trialNums -- a matrix of trial numbers in a condition
%
% example:
% trialNums = getTrialsInCondition({'Base'})
% trialNums = [1 2 3]
conditionIdx = this.getConditionIdxsFromName(conditionNames);
trialNums = cell2mat(this.trialsInCondition(conditionIdx));
end


function conditionOrder = validateTrialsInCondition(this)
%validateTrialsInCondition  Validates trial organization
%
%   conditionOrder = validateTrialsInCondition(this) checks that there
%   are no repeated trials and that conditions do not interleave trials
%
%   Inputs:
%       this - experimentMetaData object
%
%   Outputs:
%       conditionOrder - vector indicating proper order of conditions
%                        based on trial numbers
%
%   Note: Throws error if trials are repeated or interleaved between
%         conditions (e.g., condition 'A' has trials 1 and 3, and
%         condition 'B' has trial 2)
%
%   See also: checkConditionOrder, sortConditions

conditionNamesInOrder = this.conditionName;
for i = 1:length(conditionNamesInOrder)
    trialNo{i} = this.getTrialsInCondition(conditionNamesInOrder{i});
end
allTrials = cell2mat(trialNo);
uniqueTrials = unique(allTrials);
if numel(uniqueTrials) ~= numel(allTrials)
    error(['Some trials are repeated, in the same or different ' ...
        'conditions. This is not allowed. Please review.']);
end
mx = cellfun(@(x) min(x), trialNo);
Mx = cellfun(@(x) max(x), trialNo);
% Sorting according to first trial in each condition
[mx1, order1] = sort(mx);
% Sorting according to last trial in each condition
[Mx1, order2] = sort(Mx);
if all(order1 == order2) && all(Mx1(1:end - 1) < mx1(2:end))
    conditionOrder = order1;
else % Condition order cannot be established
    disp(this);
    error(['Trials in conditions appear to be interleaved. This is ' ...
        'not allowed. Please rename conditions.']);
end
end


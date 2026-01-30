function condLst = getCondLstPerTrial(this)
%getCondLstPerTrial  Returns list of condition numbers for each trial
%
%   condLst = getCondLstPerTrial(this) returns a vector with length
%   equal to the number of trials in the experiment and with values
%   equal to the condition number for each trial
%
%   Inputs:
%       this - experimentMetaData object
%
%   Outputs:
%       condLst - vector of condition numbers, one per trial (NaN for
%                 trials not assigned to any condition)
%
%   See also: getTrialsInCondition, getConditionIdxsFromName

% Returns a vector with length equal to the number of trials in the
% experiment and with values equal to the condition number for each trial.
for i = 1:this.Ntrials
    for cond = 1:length(this.trialsInCondition)
        k = find(i == this.trialsInCondition{cond}, 1);
        if ~isempty(k)
            break;
        end
    end
    if isempty(k)
        condLst(i) = NaN;
    else
        condLst(i) = cond;
    end
end
end


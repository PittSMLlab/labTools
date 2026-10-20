function condLst = getCondLstPerTrial(this)
%GETCONDLSTPERTRIAL Returns list of condition numbers for each trial.
%
%   condLst = getCondLstPerTrial(this) returns a vector with length
% equal to the number of trials in the experiment and with values
% equal to the condition number for each trial
%
% Inputs:
%   this - experimentMetaData object
%
% Outputs:
%   condLst - vector of condition numbers, one per trial (NaN for trials not
%             assigned to any condition)
%
% Toolbox Dependencies: None
%
% See also GETTRIALSINCONDITION, GETCONDITIONIDXSFROMNAME.

for tr = 1:this.Ntrials
    for cond = 1:length(this.trialsInCondition)
        k = find(tr == this.trialsInCondition{cond}, 1);
        if ~isempty(k)
            break;
        end
    end
    if isempty(k)
        condLst(tr) = NaN;
    else
        condLst(tr) = cond;
    end
end
end


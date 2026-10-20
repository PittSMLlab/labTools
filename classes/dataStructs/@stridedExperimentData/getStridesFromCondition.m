function strides = getStridesFromCondition(this, condition)
%GETSTRIDESFROMCONDITION Extracts strides from specific condition.
%
%   strides = getStridesFromCondition(this, condition) returns all
% strides from the specified experimental condition
%
% Inputs:
%   this      - stridedExperimentData object
%   condition - condition index number
%
% Outputs:
%   strides - cell array of strideData objects from the condition
%
% Toolbox Dependencies: None
%
% See also EXPERIMENTMETADATA/GETTRIALSINCONDITION.

strides = {};
for trial = this.metaData.trialsInCondition{condition}
    trialData = this.stridedTrials{trial};
    Nsteps    = length(trialData);
    strides(end + 1:end + Nsteps) = trialData;
end
end


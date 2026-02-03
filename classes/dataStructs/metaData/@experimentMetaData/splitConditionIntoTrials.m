function newThis = splitConditionIntoTrials(this, condList)
%splitConditionIntoTrials  Splits conditions into individual trials
%
%   newThis = splitConditionIntoTrials(this, condList) takes specified
%   conditions and splits each into separate conditions, one per trial,
%   with unique names
%
%   Inputs:
%       this - experimentMetaData object
%       condList - cell array of condition names to split
%
%   Outputs:
%       newThis - experimentMetaData object with split conditions
%
%   Example:
%       If condition 'Adaptation' contains trials [5 6 7], this method
%       will create three conditions: 'Adaptation1', 'Adaptation2',
%       'Adaptation3'
%
%   See also: getConditionIdxsFromName, numerateRepeatedConditionNames

newThis = this;
for i = 1:length(condList)
    id = this.getConditionIdxsFromName(condList{i});
    Nt = newThis.trialsInCondition{id};
    newCondNames = mat2cell(strcat(newThis.conditionName{id}, ...
        num2str([1:numel(Nt)]')), ones(size(Nt')), ...
        length(newThis.conditionName{id}) + 1)';
    newDesc = mat2cell(strcat(newThis.conditionDescription{id}, ...
        ', trial #', num2str([1:numel(Nt)]')), ones(size(Nt')), ...
        length(newThis.conditionDescription{id}) + 10)';
    newThis.conditionName = [newThis.conditionName(1:id - 1) ...
        newCondNames newThis.conditionName(id + 1:end)];
    newThis.conditionDescription = ...
        [newThis.conditionDescription(1:id - 1) newDesc ...
        newThis.conditionDescription(id + 1:end)];
    newThis.trialsInCondition = [newThis.trialsInCondition(1:id - 1) ...
        mat2cell(newThis.trialsInCondition{id}, 1, ones(size(Nt))) ...
        newThis.trialsInCondition(id + 1:end)];
end
end


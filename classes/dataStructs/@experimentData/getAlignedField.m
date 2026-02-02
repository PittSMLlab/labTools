function [alignedField, originalTrial, bad] = getAlignedField(this, ...
    field, conditions, events, alignmentLengths)
%getAlignedField  Extracts time-aligned field data
%
%   [alignedField, originalTrial, bad] = getAlignedField(this, field)
%   extracts the specified field time-normalized to standard gait cycle for
%   all trials
%
%   [alignedField, originalTrial, bad] = getAlignedField(this, field,
%   conditions, events, alignmentLengths) extracts for specified
%   conditions, events, and alignment parameters
%
%   Inputs:
%       this - experimentData object
%       field - name of field to extract
%       conditions - condition indices or names (optional, default: all)
%       events - event labels for alignment (optional, default: slowLeg HS)
%       alignmentLengths - vector of sample counts between events
%                          (optional)
%
%   Outputs:
%       alignedField - time-normalized field data
%       originalTrial - vector indicating source trial for each stride
%       bad - logical vector indicating strides with issues
%
%   See also: getStridedField, processedLabData/getAlignedField

if nargin < 4 || isempty(events)
    events = [this.getSlowLeg 'HS'];
end
if nargin < 3 || isempty(conditions)
    trials = cell2mat(this.metaData.trialsInCondition);
else
    % If conditions are given by name, and not by index
    if ~isa(conditions, 'double')
        conditions = getConditionIdxsFromName(this, conditions);
    end
    trials = cell2mat(this.metaData.trialsInCondition(conditions));
end
bad = [];
originalInitTime = [];
originalTrial = [];
originalDurations = [];
for i = trials % Trials in condition
    % [aux, bad1, initTime1] = this.data{i}.(field).splitByEvents(this.data{i}.gaitEvents, events);
    [alignedField1, bad1] = this.data{i}.getAlignedField(field, ...
        events, alignmentLengths);
    if i == trials(1)
        alignedField = alignedField1;
    else
        force = false;
        alignedField = alignedField.cat(alignedField1, [], force);
    end
    bad = [bad; bad1];
    originalTrial = [originalTrial; i * ones(size(bad1))];
    % originalInitTime = [originalInitTime; initTime1];
    % originalDurations = [originalDurations; originalDurations1];
end
end


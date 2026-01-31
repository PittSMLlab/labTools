function [stridedField, bad, originalTrial, originalInitTime, ...
    events] = getStridedField(this, field, conditions, events)
%getStridedField  Extracts strided field data
%
%   [stridedField, bad, originalTrial, originalInitTime, events] =
%   getStridedField(this, field) extracts the specified field
%   organized by stride for all trials
%
%   [stridedField, bad, originalTrial, originalInitTime, events] =
%   getStridedField(this, field, conditions, events) extracts for
%   specified conditions and events
%
%   Inputs:
%       this - experimentData object
%       field - name of field to extract
%       conditions - condition indices or names (optional, default:
%                    all)
%       events - event labels for stride boundaries (optional,
%                default: slowLeg HS)
%
%   Outputs:
%       stridedField - cell array of extracted field data by stride
%       bad - logical vector indicating strides with issues
%       originalTrial - vector indicating source trial for each stride
%       originalInitTime - vector of stride start times
%       events - cell array of event labels used
%
%   See also: getAlignedField, processedLabData/getStridedField

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
stridedField = {};
bad = [];
originalInitTime = [];
originalTrial = [];
for i = trials
    % [aux, bad1, initTime1] = this.data{i}.(field).splitByEvents(this.data{i}.gaitEvents, events);
    [aux, bad1, initTime1, events] = ...
        this.data{i}.getStridedField(field, events);
    stridedField = [stridedField; aux];
    bad = [bad; bad1];
    originalTrial = [originalTrial; i * ones(size(bad1))];
    originalInitTime = [originalInitTime; initTime1];
end
end


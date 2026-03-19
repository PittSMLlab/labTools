function [stridedField, bad, originalTrial, ...
    originalInitTime, gaitEventLabel] = getStridedField( ...
    this, field, conditions, gaitEventLabel)
% getStridedField  Extracts stride-segmented field data across
%   trials and conditions.
%
%   Collects stride-segmented data for a specified field from all trials in
% the given conditions. Strides are defined by the specified gait event
% label. If no event label is provided, the slow-leg heel strike is used as
% the default stride boundary.
%
%   Inputs:
%     this           - experimentData object
%     field          - Name of the data field to extract, as a
%                      string (e.g., 'markerData')
%     conditions     - (optional) Condition indices (double) or condition
%                      names (cell array of strings). Defaults to all
%                      conditions if omitted or empty.
%     gaitEventLabel - (optional) Gait event label defining stride
%                      boundaries (e.g., 'LHS'). Defaults to slow-leg heel
%                      strike if omitted or empty.
%
%   Outputs:
%     stridedField   - Cell array of stride-segmented field data,
%                      one cell per stride across all trials
%     bad            - Logical array flagging rejected strides
%     originalTrial  - Trial index corresponding to each stride
%     originalInitTime - Initial time of each stride within its
%                        original trial
%     gaitEventLabel - Gait event label used for segmentation;
%                      may be refined by the underlying data method
%
%   Toolbox Dependencies:
%     None
%
%   See also: getAlignedField, splitIntoStrides,
%     getConditionIdxsFromName

if nargin < 4 || isempty(gaitEventLabel)
    gaitEventLabel = [this.getSlowLeg() 'HS'];
end
if nargin < 3 || isempty(conditions)
    trials = cell2mat(this.metaData.trialsInCondition);
else
    % If conditions are given by name, not by index
    if ~isa(conditions, 'double')
        conditions = getConditionIdxsFromName(this, conditions);
    end
    trials = cell2mat(this.metaData.trialsInCondition(conditions));
end

stridedField     = {};
bad              = [];
originalInitTime = [];
originalTrial    = [];
for i = trials
    % [aux, bad1, initTime1] = this.data{i}.(field).splitByEvents( ...
    %     this.data{i}.gaitEvents, gaitEventLabel);
    [aux, bad1, initTime1, gaitEventLabel] = ...
        this.data{i}.getStridedField(field, gaitEventLabel);
    stridedField     = [stridedField; aux];
    bad              = [bad; bad1];
    originalTrial    = [originalTrial; i * ones(size(bad1))];
    originalInitTime = [originalInitTime; initTime1];
end

end


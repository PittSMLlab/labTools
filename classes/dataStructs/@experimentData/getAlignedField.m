function [alignedField, originalTrial, bad] = getAlignedField( ...
    this, field, conditions, gaitEventLabel, alignmentLengths)
% getAlignedField  Extracts time-aligned field data across
%   trials and conditions.
%
%   Collects and concatenates time-aligned data for a specified field from
% all trials in the given conditions. Alignment is performed relative to
% the specified gait event label. If no event label is provided, the
% slow-leg heel strike is used as the default alignment event.
%
%   Inputs:
%     this             - experimentData object
%     field            - Name of the data field to extract, as a
%                        string (e.g., 'markerData')
%     conditions       - (optional) Condition indices (double) or condition
%                        names (cell array of strings). Defaults to all
%                        conditions if omitted or empty.
%     gaitEventLabel   - (optional) Gait event label defining the alignment
%                        reference (e.g., 'LHS'). Defaults to slow-leg heel
%                        strike if omitted or empty.
%     alignmentLengths - (optional) Target lengths for time
%                        normalization of each aligned segment
%
%   Outputs:
%     alignedField   - Concatenated time-aligned field data object
%     originalTrial  - Trial index corresponding to each aligned segment
%     bad            - Logical array flagging rejected segments
%
%   Toolbox Dependencies:
%     None
%
%   See also: getStridedField, splitIntoStrides,
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

bad               = [];
originalInitTime  = [];
originalTrial     = [];
originalDurations = [];
for i = trials   % Trials in condition
    % [aux, bad1, initTime1] = this.data{i}.(field).splitByEvents( ...
    %     this.data{i}.gaitEvents, gaitEventLabel);
    [alignedField1, bad1] = this.data{i}.getAlignedField( ...
        field, gaitEventLabel, alignmentLengths);
    if i == trials(1)
        alignedField = alignedField1;
    else
        force        = false;
        alignedField = alignedField.cat(alignedField1, [], force);
    end
    bad           = [bad; bad1];
    originalTrial = [originalTrial; i * ones(size(bad1))];
    % originalInitTime = [originalInitTime; initTime1];
    % originalDurations = [originalDurations; originalDurations1];
end

end


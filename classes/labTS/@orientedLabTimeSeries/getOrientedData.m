function [data, label] = getOrientedData(this, label)
%getOrientedData  Returns data as 3D tensor
%
%   [data, label] = getOrientedData(this) returns all oriented data
%
%   [data, label] = getOrientedData(this, label) returns data for
%   specified marker prefixes
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       label - cell array of marker prefixes (without x/y/z)
%               (optional, default: all)
%
%   Outputs:
%       data - 3D matrix (time x markers x 3) where third dimension
%              contains x, y, z components
%       label - cell array of marker prefixes (same as input)
%
%   Note: If requested labels do not exist AS A PREFIX, NaNs are
%         returned in corresponding matrix components
%
%   See also: getDataAsOTS, getLabelPrefix

T = size(this.Data, 1);
if nargin < 2 || isempty(label)
    label = this.getLabelPrefix;    % retrieve all mrkr labels
elseif isa(label, 'char')
    label = {label};
end

data = nan(T, length(label) * 3);
extendedLabels = this.addLabelSuffix(label);
if ~orientedLabTimeSeries.checkLabelSanity(this.labels)
    error('orientedLabTS:getOrientedData', ...
        'Labels in this object do not pass sanity check.');
end
bool = this.isaLabel(extendedLabels);
data(:, bool) = this.getDataAsVector(extendedLabels(bool));
data = permute(reshape(data, T, 3, round(numel(extendedLabels) / 3)), ...
    [1 3 2]);
end


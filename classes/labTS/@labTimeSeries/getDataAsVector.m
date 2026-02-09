function [data, time, auxLabel] = getDataAsVector(this, label)
%getDataAsVector  Gets data vector for given label(s)
%
%   [data, time, auxLabel] = getDataAsVector(this) returns all data
%   and time vectors
%
%   [data, time, auxLabel] = getDataAsVector(this, label) returns data
%   for specified label(s)
%
%   Inputs:
%       this - labTimeSeries object
%       label - string or cell array of label(s) to extract (optional,
%               default: all labels)
%
%   Outputs:
%       data - matrix of data values for requested label(s)
%       time - time vector
%       auxLabel - cell array of labels for returned data
%
%   Note: If label not found, attempts to match as regular expression
%
%   See also: getDataAsTS, getLabelsThatMatch, isaLabel

if nargin < 2 || isempty(label)
    label = this.labels;
end
if isa(label, 'char')
    auxLabel = {label};
else
    auxLabel = label;
end
time = this.Time;
[boolFlag, labelIdx] = this.isaLabel(auxLabel);
if ~any(boolFlag)
    auxLabel2 = [];
    for i = 1:length(auxLabel)
        auxLabel2 = [auxLabel2 this.getLabelsThatMatch(auxLabel{i})];
    end
    [boolFlag, labelIdx] = this.isaLabel(auxLabel2);
    NN = numel(auxLabel2);
    warning(['None of the provided labels are a parameter in this ' ...
        'timeSeries. Trying to return labels that match the provided ' ...
        'label as a regular expression: found ' num2str(NN) ' matches.']);
else
    for i = 1:length(boolFlag)
        if ~boolFlag(i)
            warning(['Label ' auxLabel{i} ...
                ' is not a labeled dataset in this timeSeries.']);
        end
    end
end

data = this.Data(:, labelIdx(boolFlag));
if nargout > 2
    auxLabel = this.labels(labelIdx(boolFlag));
end
end


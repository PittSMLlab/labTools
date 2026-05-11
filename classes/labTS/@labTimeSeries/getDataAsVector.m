function [data, time, auxLabel] = getDataAsVector(this, label)
%GETDATASVECTOR Extract data vectors for the specified label(s).
%
%   Returns the data matrix and time vector for the requested channel
% labels. If a label is not found by exact match, the function falls back
% to treating the label as a regular expression and returning all matching
% channels.
%
% Inputs:
%   this  - labTimeSeries object
%   label - char or cell array of chars, label(s) to extract (optional;
%           default: all labels)
%
% Outputs:
%   data     - (N×K) double, data for the K matched channels
%   time     - (N×1) double, time vector
%   auxLabel - (1×K) cell of chars, labels for the returned channels
%
% Toolbox Dependencies: None
%
% See also GETDATAASTS, GETLABELSTHATMATCH, ISALABEL.


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


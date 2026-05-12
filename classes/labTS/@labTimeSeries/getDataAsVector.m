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

arguments
    this
    label = []
end

if isempty(label)
    label = this.labels;
end
if ischar(label)
    auxLabel = {label};
else
    auxLabel = label;
end
time = this.Time;

[boolFlag, labelIdx] = this.isaLabel(auxLabel);
if ~any(boolFlag)
    matchedLabels = [];
    for ii = 1:length(auxLabel)
        matchedLabels = [matchedLabels this.getLabelsThatMatch(auxLabel{ii})]; %#ok<AGROW>
    end
    [boolFlag, labelIdx] = this.isaLabel(matchedLabels);
    warning('labTimeSeries:labelNotFound', sprintf( ...
        ['None of the provided labels are in this timeSeries. ' ...
         'Trying regex match: found %d match(es).'], numel(matchedLabels)));
else
    for ii = 1:length(boolFlag)
        if ~boolFlag(ii)
            warning('labTimeSeries:labelNotFound', ...
                'Label ''%s'' is not in this timeSeries.', auxLabel{ii});
        end
    end
end

data = this.Data(:, labelIdx(boolFlag));
if nargout > 2
    auxLabel = this.labels(labelIdx(boolFlag));
end
end

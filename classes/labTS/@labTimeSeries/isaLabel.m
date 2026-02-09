function [boolFlag, labelIdx] = isaLabel(this, label)
%isaLabel  Checks if string is contained in label array
%
%   [boolFlag, labelIdx] = isaLabel(this, label) checks whether
%   specified label(s) exist in the timeseries
%
%   Inputs:
%       this - labTimeSeries object
%       label - string or cell array of label(s) to check
%
%   Outputs:
%       boolFlag - logical vector indicating which labels were found
%       labelIdx - vector of indices for found labels
%
%   See also: getLabelsThatMatch, getDataAsVector

if isa(label, 'char')
    auxLabel{1} = label;
elseif isa(label, 'cell')
    auxLabel = label;
else
    error('labTimeSeries:isaLabel', ['label input argument has to be a '...
        'string or a cell array containing strings.']);
end
auxLabel = auxLabel(:);
N = length(auxLabel);
M = length(this.labels);
% Case in which the list is identical to the label list, save time by
% not calling find() recursively. If this is true, it saves about 50ms
% per call, or 5 secs every 100 calls. If false, it adds a small
% overhead of less than .1ms per call, which is negligible compared to
% the loop that needs to be performed.
if N == M && all(strcmpi(auxLabel, this.labels(:)))
    boolFlag = true(N, 1);
    labelIdx = 1:M;
else
    [boolFlag, labelIdx] = compareListsFast(this.labels, auxLabel);
end
end


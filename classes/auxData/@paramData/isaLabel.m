function [boolFlag, labelIdx] = isaLabel(this, label)
%isaLabel  Checks if label(s) exist in dataset
%
%   [boolFlag, labelIdx] = isaLabel(this, label) checks whether
%   specified label(s) are present in the parameter data (case-
%   insensitive)
%
%   Inputs:
%       this - paramData object
%       label - string or cell array of label(s) to check
%
%   Outputs:
%       boolFlag - logical vector indicating which labels were found
%       labelIdx - vector of indices for found labels (0 for not found)
%
%   Note: Uses case-insensitive comparison
%
%   See also: isaParameter, getParameter

if isa(label, 'char')
    auxLabel{1} = label;
elseif isa(label, 'cell')
    auxLabel = label;
end
N = length(auxLabel);
boolFlag = false(N, 1);
labelIdx = zeros(N, 1);
for j = 1:N
    for i = 1:length(this.labels)
        if strcmpi(auxLabel{j}, this.labels{i})
            boolFlag(j) = true;
            labelIdx(j) = i;
            break;
        end
    end
end
end


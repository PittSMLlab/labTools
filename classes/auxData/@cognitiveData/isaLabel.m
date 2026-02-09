function [boolFlag, labelIdx] = isaLabel(this, label)
%isaLabel  Checks if label(s) exist in dataset
%
%   [boolFlag, labelIdx] = isaLabel(this, label) checks whether
%   specified label(s) are present in the cognitive data
%
%   Inputs:
%       this - cognitiveData object
%       label - string or cell array of label(s) to check
%
%   Outputs:
%       boolFlag - logical vector indicating which labels were found
%       labelIdx - vector of indices for found labels (0 for not
%                  found)
%
%   See also: getScore

if isa(label, 'char')
    auxLabel{1} = label;
elseif isa(label, 'cell')
    auxLabel = label;
else
    error('cognitiveData:isaLabel', ['label input argument has to be ' ...
        'a string or a cell array containing strings.']);
end
N = length(auxLabel);
boolFlag = false(N, 1);
labelIdx = zeros(N, 1);
for j = 1:N
    aux = strcmp(auxLabel{j}, this.labels);
    boolFlag(j) = any(aux);
    labelIdx(j) = find(aux);
end
end


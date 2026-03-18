function [boolFlag, labelIdx] = isaLabelPrefix(this, label)
%isaLabelPrefix  Checks if prefix exists
%
%   [boolFlag, labelIdx] = isaLabelPrefix(this, label) checks if
%   label(s) are valid prefixes
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       label - string or cell array of label prefixes to check
%
%   Outputs:
%       boolFlag - logical vector, true for matches, false if not
%       labelIdx - vector containing indices of matched labels
%
%   See also: getLabelPrefix, isaLabel

if isa(label, 'char')
    auxLabel{1} = label;
elseif isa(label, 'cell')
    auxLabel = label;
else
    error('orientedLabTS:isaLabelPrefix', ...
        ['label input argument has to be a string or a cell array ' ...
        'containing strings.']);
end

N = length(auxLabel);
boolFlag = false(N, 1);
labelIdx = zeros(N, 1);
for j = 1:N
    % Alternative efficient formulation:
    boolFlag(j) = any(strcmp(auxLabel{j}, this.getLabelPrefix));
    if boolFlag(j)
        labelIdx(j) = find(strcmp(auxLabel{j}, this.getLabelPrefix));
    end
end
end


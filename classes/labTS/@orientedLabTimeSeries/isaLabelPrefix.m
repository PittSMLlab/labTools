function [boolFlag, labelIdx] = isaLabelPrefix(this, label)
%ISALABELPREFIX Checks if prefix exists.
%
%   [boolFlag, labelIdx] = isaLabelPrefix(this, label) checks if label(s)
% are valid prefixes
%
% Inputs:
%   this  - orientedLabTimeSeries object
%   label - string or cell array of label prefixes to check
%
% Outputs:
%   boolFlag - logical vector, true for matches, false if not
%   labelIdx - vector containing indices of matched labels
%
% Toolbox Dependencies: None
%
% See also GETLABELPREFIX, ISALABEL.

if isa(label, 'char')
    auxLabel{1} = label;
elseif isa(label, 'cell')
    auxLabel = label;
else
    error('orientedLabTS:isaLabelPrefix', ...
        ['label input argument has to be a string or a cell array ' ...
        'containing strings.']);
end

N        = length(auxLabel);
boolFlag = false(N, 1);
labelIdx = zeros(N, 1);
for jj = 1:N
    % Alternative efficient formulation:
    boolFlag(jj) = any(strcmp(auxLabel{jj}, this.getLabelPrefix));
    if boolFlag(jj)
        labelIdx(jj) = find(strcmp(auxLabel{jj}, this.getLabelPrefix));
    end
end
end


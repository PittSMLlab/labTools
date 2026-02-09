function [boolFlag, labelIdx] = isaParameter(this, label)
%isaParameter  Checks if parameter(s) exist in dataset
%
%   [boolFlag, labelIdx] = isaParameter(this, label) checks whether
%   specified parameter(s) are present and issues warnings for missing
%   parameters
%
%   Inputs:
%       this - paramData object
%       label - string or cell array of parameter name(s) to check
%
%   Outputs:
%       boolFlag - logical vector indicating which parameters were found
%       labelIdx - vector of indices for found parameters (0 for not
%                  found)
%
%   Note: Issues warning if requested parameter does not exist
%
%   See also: isaLabel, getParameter

if isa(label, 'char')
    auxLabel{1} = label;
elseif isa(label, 'cell')
    auxLabel = label;
end
[boolFlag, labelIdx] = isaLabel(this, label);
for i = 1:length(boolFlag)
    if boolFlag(i) == 0
        warning(['Label ' auxLabel{i} ...
            ' is not a parameter in this dataset.']);
    end
end
end


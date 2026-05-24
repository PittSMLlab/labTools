function output = subFileList(input)
%SUBFILELIST Extract parameter file paths from a study input structure.
%
%   Returns a cell array of file path strings by reading the ninth column
% of input.IDs for each subject entry.
%
% Inputs:
%   input - Struct with an IDs field; IDs is an N×9 cell array where the
%           ninth column contains parameter file paths
%
% Outputs:
%   output - 1×N cell array of file path strings
%
% Toolbox Dependencies: None
%
% See also GETSUBSFROMFOLDERS.

subs   = input.IDs(:, 1);
output = cell(1, length(subs));

for ii = 1:length(subs)
    output{ii} = input.IDs{ii, 9};
end

end

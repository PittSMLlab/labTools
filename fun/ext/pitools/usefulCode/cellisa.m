function b = cellisa(cellArr, type)
%CELLISA Check class membership for each element of a cell array.
%
%   Applies isa() to every element of cellArr, returning a logical vector.
%
% Inputs:
%   cellArr - cell array whose elements are to be type-checked
%   type    - class name string (e.g. 'double', 'char')
%
% Outputs:
%   b - logical row vector; b(ii) is true when isa(cellArr{ii}, type)
%
% Toolbox Dependencies: None
%
% See also ISA, CELLFUN.

b = [];
for ii = 1:length(cellArr)
    b(ii) = isa(cellArr{ii}, type);
end

end

function [bool,idxs] = compareLists(list1,list2)
%COMPARELISTS Deprecated wrapper — use COMPARELISTSNESTED instead.
%
%   Passes all arguments through to compareListsNested unchanged.
%   See COMPARELISTSNESTED for full documentation.
%
% Inputs:
%   list1 - cell array of strings or nested cell arrays of strings
%   list2 - cell array of strings to search for
%
% Outputs:
%   bool - logical vector, same size as list2; true where list2{ii} is
%          found in list1
%   idxs - index vector, same size as list2; idxs(ii) is the index into
%          list1 that matched list2{ii} (NaN where bool(ii) is false)
%
% Toolbox Dependencies: None
%
% See also COMPARELISTSNESTED.

warning('Deprecated: use compareListsNested')
[bool,idxs] = compareListsNested(list1,list2);
end


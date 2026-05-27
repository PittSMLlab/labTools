function [bool, idxs] = compareListsNested(list1, list2)
%COMPARELISTSNESTED Search list2 strings against list1 (supports nesting).
%
%   For each element of list2, checks whether it matches any string in
%   list1. list1 may contain plain strings or nested cell arrays of
%   strings (multiple alternative spellings for one entry). If there are
%   multiple matches, idxs points to the LAST match found.
%
% Inputs:
%   list1 - cell array of strings or nested cell arrays of strings,
%           allowing multiple alternative spellings per entry
%   list2 - cell array of strings (or a single char) to search for
%
% Outputs:
%   bool - logical array, same size as list2; true where list2{ii} was
%          found in list1
%   idxs - double array, same size as list2; idxs(ii) is the index into
%          list1 containing list2{ii} (NaN where bool(ii) is false)
%
% Toolbox Dependencies: None
%
% See also COMPARELISTS, STRCMP.

if isa(list2, 'char')
    list2 = {list2};
end
if ~isa(list2, 'cell') || ~all(cellfun(@(x) isa(x, 'char'), list2))
    error('List2 has to be a cell array containing strings.');
end

% Shortcut for when list1 and list2 are both cells of strings:
if all(cellfun(@(x) isa(x, 'char'), list1))
    [bool, idxs] = compareListsFast(list1, list2);
else
    % TODO: make this more efficient by running the fast path for all
    % chars in list1 and only the element-by-element path for non-chars.
    % Currently we use the fast path only when ALL entries are chars.
    idxs = nan(size(list2));
    bool = false(size(list2));
    for ii = 1:length(list1)
        if isa(list1{ii}, 'cell')
            [aux, ~] = compareListsNested(list1{ii}, list2);
        elseif isa(list1{ii}, 'char')
            aux = strcmp(list1{ii}, list2);
        else
            error(['List1 has to be a cell array containing strings ' ...
                'or nested cell-arrays of strings']);
        end
        idxs(aux) = ii;
        bool = bool | aux;
    end
end

end

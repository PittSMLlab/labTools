function [bool,idxs] = compareListsFast(list1,list2)
%Faster version of compareLists. This does not accept list1 being a cell
%array containing cell arrays of strings. Both list1 and list2 have to be
%cell arrays of strings (it will run anyway failing to find matches for cell arrays, so be careful!)
%See also: compareLists

if isa(list2,'char')
    bool = strcmp(list1,list2);
    if nargout > 1
        idxs = find(bool);
    end
else
    N1 = numel(list1);
    N2 = numel(list2);
    bool = false(1,N2);
    idxs = nan(1,N2);
    idxList = 1:N1;
    for jj = 1:N2
        aux = strcmpi(list2{jj},list1);
        if any(aux)
            bool(jj) = true;
            try
                % NOTE: will fail if there are repeated elements in list
                idxs(jj) = idxList(aux);
            catch
                idxs(jj) = find(aux,1,'last');  % return one match
                warning(['Multiple matches found for ' list2{jj}]);
            end
        end
    end
end

end


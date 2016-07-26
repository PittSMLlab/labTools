function [bool,idxs] = compareLists(list1,list2)
%Searches for strings in list2 to match any string in list1.
%List2 has to be a cell array of strings.
%List 1 has to be a cell array containing strings or cell arrays of
%strings, to allow for multiple alternative spellings.
%bool & idxs are of the same size as list2
%bool(i) is true if list2{i} is found in list1
%idxs(i), if bool(i)==true, contains the element of list1 that contains the string list2{i} such that
%any(strcmp(list2{i},list1{idxs(i)}))=true. Note that since list1{idxs(i)}
%may contain a cell array of strings, strcmp(list2{i},list1{idxs(i)}) may
%return a boolean vector
if isa(list2,'char')
    list2={list2};
end
if ~isa(list2,'cell') || ~all(cellfun(@(x) isa(x,'char'),list2))
    error('List2 has to be a cell array containing strings.');
end

bool=false(size(list2));
idxs=nan(size(list2));
for i=1:length(list1)
    if isa(list1{i},'cell')
        [aux,~] = compareLists(list1{i},list2);
    elseif isa(list1{i},'char')
        aux=strcmp(list1{i},list2); %Compares the full list2 to one element of list1
    else
        error('List1 has to be a cell array containing strings or nested cell-arrays of strings');
    end
    idxs(aux)=i;
    bool=bool | aux;
end


end


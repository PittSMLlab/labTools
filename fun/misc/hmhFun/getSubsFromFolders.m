function subs=getSubsFromFolders(path)

if nargin<1
    path='./';
end

things=dir(path);
subs={};

for i=1:length(things)
    if things(i).isdir
        if ~strcmp(things(i).name(1),'.') %not a folder or file if false
            subs{end+1}=things(i).name;
        end                          
    end
end
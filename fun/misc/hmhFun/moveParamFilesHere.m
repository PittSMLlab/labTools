function moveParamFilesHere(path)
% searches for files in all folders in path
% what happens with conflicts? --> semms to just overwrite old file.
% use recursion to look at all levels --> uncomment section.


if nargin<1
    path='./';
end

things=dir(path);

for i=1:length(things)
    if things(i).isdir
        if ~strcmp(things(i).name(1),'.') %not a folder or file if false
            thingsInFolder=dir([path things(i).name]);
            for j=1:length(thingsInFolder)
                if ~strcmp(thingsInFolder(j).name(1),'.')
                    if strcmp(thingsInFolder(j).name(max([1 end-9]):end),'params.mat')
                        copyfile([path things(i).name filesep thingsInFolder(j).name],'./')
%                     elseif thingsInFolder(j).isdir
%                         moveParamFilesHere([path things(i).name filesep])
                    end
                end
            end
        end                          
    end
end

end
function moveParamFilesHere(path)
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

end%MOVEPARAMFILESHERE Copy params.mat files from subfolders to the current
% directory.
%
%   Searches all immediate subdirectories of path for files whose names
% end in 'params.mat' and copies them into the current working directory.
% Conflicts are resolved by overwriting.
%
% Inputs:
%   path - Character vector specifying the folder to search (default:
%          './')
%
% Outputs:
%   None (copies files to current directory)
%
% Toolbox Dependencies: None
%
% See also SUBFILELIST, GETSUBSFROMFOLDERS, COPYFILE.


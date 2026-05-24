function moveParamFilesHere(path)
%MOVEPARAMFILESHERE Copy params.mat files from subfolders to the current
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

if nargin < 1
    path = './';
end

things = dir(path);

for ii = 1:length(things)
    if things(ii).isdir
        if ~strcmp(things(ii).name(1), '.')
            thingsInFolder = dir([path things(ii).name]);
            for jj = 1:length(thingsInFolder)
                if ~strcmp(thingsInFolder(jj).name(1), '.')
                    nameEnd = thingsInFolder(jj).name( ...
                        max([1 end-9]):end);
                    if strcmp(nameEnd, 'params.mat')
                        copyfile([path things(ii).name filesep ...
                            thingsInFolder(jj).name], './')
                    end
                end
            end
        end
    end
end

end

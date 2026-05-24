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
end%GETSUBSFROMFOLDERS List subdirectory names under a given folder.
%
%   Returns a cell array of names of all immediate subdirectories of
% path, excluding entries whose names begin with '.'.
%
% Inputs:
%   path - Character vector specifying the folder to search (default:
%          './')
%
% Outputs:
%   subs - 1×K cell array of subdirectory name strings
%
% Toolbox Dependencies: None
%
% See also DIR, SUBFILELIST.

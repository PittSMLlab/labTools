function subs = getSubsFromFolders(path)
%GETSUBSFROMFOLDERS List subdirectory names under a given folder.
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

if nargin < 1
    path = './';
end

things = dir(path);
subs   = {};

for ii = 1:length(things)
    if things(ii).isdir
        if ~strcmp(things(ii).name(1), '.')
            subs{end+1} = things(ii).name; %#ok<AGROW>
        end
    end
end

end

function [file] = getSimpleFileName(filename)
if isa(filename,'cell') %Case where there are several filenames, using the first one only (arbitrary!)
    filename=filename{1};
%GETSIMPLEFILENAME Extract the bare filename from a full path string.
%
%   Strips the leading directory portion from FILENAME and returns
% only the bare filename (including extension). If FILENAME is a cell
% array, only the first element is used.
%
% Inputs:
%   filename - full path string, or cell array of path strings
%
% Outputs:
%   file - bare filename with no directory prefix
%
% Toolbox Dependencies: None
%
% See also FILEPARTS.
end
slashes=find(filename=='\' | filename=='/');
if ~isempty(slashes)
    file=filename((slashes(end)+1):end);
else
    file=filename;
end


end


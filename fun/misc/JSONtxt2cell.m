function [header, outmat] = JSONtxt2cell(filename)
%JSONTXT2CELL Parse a JSON text file into a header and numeric matrix.
%
%   Opens FILENAME, reads its contents as a single string, and uses
% JSON.parse to decode each top-level bracketed array. The first
% array becomes the header; subsequent arrays are parsed into rows of
% the output matrix.
%
% Inputs:
%   filename - path to the JSON text file
%
% Outputs:
%   header - parsed first JSON array (cell or struct from JSON.parse)
%   outmat - numeric matrix where each row is a subsequent JSON array
%
% Toolbox Dependencies: None
%
% See also JSON.
fid = fopen(filename);
bigstring = fread(fid);
fclose(fid);
bigstring = char(bigstring');

% find opening and closing bracket positions
IB = ismember(bigstring, '[');
IC = ismember(bigstring, ']');

% verify the file has matching bracket pairs
startindex = find(IB);
stopindex  = find(IC);
if length(startindex) ~= length(stopindex)
    disp(['Error in file construction, mismatch of JSON string ' ...
        'terminators "[" and "]"']);
    disp(filename);
    header = '';
    outmat = [];
    return
end
outcell = cell(length(startindex), 1);

% parse the header (first bracketed array)
header = JSON.parse(bigstring(startindex(1):stopindex(1)));

for ii = 2:length(startindex)
    temp = bigstring(startindex(ii):stopindex(ii));
    ID   = ismember(temp, ',');
    commaindex = find(ID);
    g{1} = str2double(temp(2:commaindex(1) - 1));       %#ok<AGROW>
    for jj = 2:length(commaindex)
        g{jj} = str2double( ...                         %#ok<AGROW>
            temp(commaindex(jj-1)+1:commaindex(jj)-1));
    end
    g{end+1} = str2double(temp(commaindex(end)+1:end-1)); %#ok<AGROW>
    outcell{ii-1} = g;
    clear g
end

outcell = outcell(~cellfun('isempty', outcell));
outmat  = zeros(length(outcell), length(outcell{1}));

for ii = 1:length(outcell)
    outmat(ii, :) = cell2mat(outcell{ii});
end
end

function [file] = getSimpleFileName(filename)
if isa(filename,'cell') %Case where there are several filenames, using the first one only (arbitrary!)
    filename=filename{1};
end
slashes=find(filename=='\' | filename=='/');
if ~isempty(slashes)
    file=filename((slashes(end)+1):end);
else
    file=filename;
end


end


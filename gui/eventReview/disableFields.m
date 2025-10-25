function handles = disableFields(handles,varargin)

for ii = 1:length(varargin)
    set(handles.(varargin{ii}),'Enable','off');
end

end


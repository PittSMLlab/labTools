function handles = enableFields(handles,varargin)

for ii = 1:length(varargin)
    set(handles.(varargin{ii}),'Enable','on');
end

end


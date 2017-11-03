function handles = enableFields(handles,varargin)

for i=1:length(varargin)
    set(handles.(varargin{i}),'Enable','on');
end
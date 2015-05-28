function handles = disableFields(handles,varargin)

for i=1:length(varargin)
    set(handles.(varargin{i}),'Enable','off');
end
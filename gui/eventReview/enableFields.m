function handles = enableFields(handles,varargin)

for ii = 1:length(varargin)
    set(handles.(varargin{ii}),'Enable','on');
end

end

%ENABLEFIELDS Enable a list of named GUI controls in a handles struct.
%
%   Sets the 'enable' property to 'on' for each named field in the
% handles structure.
%
% Inputs:
%   handles  - struct with handles and user data (see GUIDATA)
%   varargin - one or more field name strings identifying controls to
%              enable
%
% Outputs:
%   handles - updated handles struct (enable state unchanged in GUIDATA;
%             call guidata after if persistent state is needed)
%
% Toolbox Dependencies:
%   None
%
% See also DISABLEFIELDS.

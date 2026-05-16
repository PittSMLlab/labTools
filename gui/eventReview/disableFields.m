function handles = disableFields(handles, varargin)
%DISABLEFIELDS Disable a list of named GUI controls in a handles struct.
%
%   Sets the 'Enable' property to 'off' for each named field in the
% handles structure.
%
% Inputs:
%   handles  - struct with handles and user data (see GUIDATA)
%   varargin - one or more field name strings identifying controls to
%              disable
%
% Outputs:
%   handles - updated handles struct (enable state unchanged in GUIDATA;
%             call guidata after if persistent state is needed)
%
% Toolbox Dependencies:
%   None
%
% See also ENABLEFIELDS.

for ii = 1:length(varargin)
    set(handles.(varargin{ii}), 'Enable', 'off');
end

end

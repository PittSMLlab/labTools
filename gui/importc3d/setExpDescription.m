function handles = setExpDescription(handles,expDes)
% setExpDescription  Populates GetInfoGUI condition fields from an
%   experiment description struct.
%
%   Reads condition numbers, names, descriptions, trial numbers, and trial
% types from an experiment description struct (loaded from an ExpDetails
% .mat file) and writes each value into the corresponding GUI control in
% GetInfoGUI. Also updates the number-of-conditions field.
%
%   Inputs:
%     handles - handles struct from GetInfoGUI (see GUIDATA)
%     expDes  - experiment description struct, as loaded from an
%               ExpDetails .mat file. Expected fields (all indexed
%               1 to handles.lines):
%                 conditionN   - condition number for row N
%                 condNameN    - condition name for row N
%                 descriptionN - condition description for row N
%                 trialnumN    - trial number string for row N
%                 typeN        - trial type string for row N
%                 numofconds   - (optional) total number of conditions;
%                                counted from populated rows if absent
%                 group        - experiment group/description label
%
%   Outputs:
%     handles - updated handles struct with handles.group set to
%               the experiment group label from expDes
%
%   Toolbox Dependencies:
%     None
%
%   See also: GetInfoGUI, description_edit_Callback,
%             description_edit_CreateFcn

handles.group = expDes.group;

count = 0;
for ii = 1:handles.lines
    % condition numbers
    if isfield(expDes,['condition' num2str(ii)])
        set(handles.(['condition' num2str(ii)]), ...
            'string',num2str(expDes.(['condition' num2str(ii)])));
        count = count + 1;
    end
    % condition names
    if isfield(expDes,['condName' num2str(ii)])
        set(handles.(['condName' num2str(ii)]), ...
            'string',expDes.(['condName' num2str(ii)]));
    end
    % condition descriptions
    if isfield(expDes,['description' num2str(ii)])
        set(handles.(['description' num2str(ii)]), ...
            'string',expDes.(['description' num2str(ii)]));
    end
    % trial numbers for each condition
    if isfield(expDes,['trialnum' num2str(ii)])
        set(handles.(['trialnum' num2str(ii)]), ...
            'string',expDes.(['trialnum' num2str(ii)]));
    end
    % set trial types
    if isfield(expDes,['type' num2str(ii)])
        set(handles.(['type' num2str(ii)]), ...
            'string',expDes.(['type' num2str(ii)]));
    end
end

if isfield(expDes,'numofconds')
    set(handles.numofconds,'string',expDes.numofconds);
else
    set(handles.numofconds,'string',num2str(count));
end

end


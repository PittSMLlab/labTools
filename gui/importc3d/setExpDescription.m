function handles = setExpDescription(handles, expDes)
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

%% Set Experiment Group Label
handles.group = expDes.group;

%% Populate Condition Rows
count = 0;
for ii = 1:handles.lines
    iStr = num2str(ii);
    % Condition numbers
    if isfield(expDes, ['condition' iStr])
        set(handles.(['condition' iStr]), 'string', ...
            num2str(expDes.(['condition' iStr])));
        count = count + 1;
    end
    % Condition names
    if isfield(expDes, ['condName' iStr])
        set(handles.(['condName' iStr]), 'string', ...
            expDes.(['condName' iStr]));
    end
    % Condition descriptions
    if isfield(expDes, ['description' iStr])
        set(handles.(['description' iStr]), 'string', ...
            expDes.(['description' iStr]));
    end
    % Trial numbers for each condition
    if isfield(expDes, ['trialnum' iStr])
        set(handles.(['trialnum' iStr]), 'string', ...
            expDes.(['trialnum' iStr]));
    end
    % Trial types
    if isfield(expDes, ['type' iStr])
        set(handles.(['type' iStr]), 'string', expDes.(['type' iStr]));
    end
end

%% Update Number of Conditions Field
if isfield(expDes, 'numofconds')
    set(handles.numofconds, 'string', expDes.numofconds);
else
    % Fall back to the count of populated condition rows
    set(handles.numofconds, 'string', num2str(count));
end

end


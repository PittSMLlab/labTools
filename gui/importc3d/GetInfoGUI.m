function varargout = GetInfoGUI(varargin)
% GetInfoGUI  GUI for collecting experimental session information.
%
%   Launches a graphical user interface to gather all information
%   regarding a single experiment conducted in the Sensorimotor
%   Learning Laboratory. Fields include participant demographics,
%   experiment metadata, data file locations, trial and condition
%   assignments, and EMG channel labels. Refer to the in-GUI help
%   text (hover over any field) for field-specific guidance.
%
%   Outputs:
%     info - Struct containing all session information entered by
%            the user, or empty ([]) if the GUI was closed without
%            saving.
%
%   Toolbox Dependencies:
%     None
%
%   See also: errorProofInfo, importc3d/ExpDetails

% Last Modified by GUIDE v2.5 18-Mar-2025 13:58:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct( ...
    'gui_Name',       mfilename(),             ...
    'gui_Singleton',  gui_Singleton,           ...
    'gui_OpeningFcn', @GetInfoGUI_OpeningFcn,  ...
    'gui_OutputFcn',  @GetInfoGUI_OutputFcn,   ...
    'gui_LayoutFcn',  [],                      ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    varargout{1:nargout} = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% ============================================================
% --- Executes just before GetInfoGUI is made visible.
function GetInfoGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% GetInfoGUI_OpeningFcn  Initializes the GUI before it becomes visible.
%
%   Inputs:
%     hObject   - handle to figure
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%     varargin  - command line arguments to GetInfoGUI (see VARARGIN)

% Set default command line output
handles.output = hObject;

% Specify number of condition rows displayed in the GUI
handles.lines = 20;

% Update handles structure
guidata(hObject, handles);

% Center GUI on screen  [left, bottom, width, height]
scrsz  = get(0, 'ScreenSize');
set(gcf(), 'Units', 'pixels');
guiPos = get(hObject, 'Position');
set(hObject, 'Position', [ ...
    (scrsz(3) - guiPos(3)) / 2, ...
    (scrsz(4) - guiPos(4)) / 2, ...
    guiPos(3), guiPos(4)]);

% Set tooltip strings displayed when hovering over GUI fields.
% Note: sprintf is used to allow line breaks in tooltip text.

% -- Experiment Info tooltips
set(handles.description_edit, 'TooltipString', sprintf([ ...
    'Describes the experiment that was performed, in general ' ...
    'terms\n', ...
    'Intended to categorize groups of subjects that all ' ...
    'performed the same experiment. When a description is ' ...
    'selected,\n', ...
    'the Condition Info should be automatically populated. ', ...
    'See "Adding an Experiment Description" in the User guide.']));
set(handles.name_edit,    'TooltipString', ...
    'The person(s) who ran the experiment.');
set(handles.month_list,   'TooltipString', ...
    ['Date the experiment was performed ' ...
    '(NOT the date the data was processed)']);
set(handles.day_edit,     'TooltipString', ...
    ['Date the experiment was performed ' ...
    '(NOT the date the data was processed)']);
set(handles.year_edit,    'TooltipString', ...
    ['Date the experiment was performed ' ...
    '(NOT the date the data was processed)']);
set(handles.note_edit,    'TooltipString', sprintf([ ...
    'Notes about the experiment as a whole. If a comment is ' ...
    'specific to a trial,\n', ...
    'do not enter it here (there will be a chance later on to ' ...
    'comment on individual trials).']));
set(handles.schenleyLab,  'TooltipString', ...
    'Was the data collected on Schenley Place?');

% -- Subject Info tooltips
set(handles.subID_edit,    'TooltipString', ...
    ['Coded value used to identify subject. ' ...
    'DO NOT use the subject''s name!']);
set(handles.DOBmonth_list, 'TooltipString', 'Month subject was born');
set(handles.DOBday_edit,   'TooltipString', 'Day subject was born');
set(handles.DOByear_edit,  'TooltipString', 'Year subject was born');
set(handles.gender_list,   'TooltipString', 'Subject''s gender');
set(handles.domleg_list,   'TooltipString', 'Dominant leg of subject');
set(handles.domhand_list,  'TooltipString', ...
    'Dominant hand/arm of subject');
set(handles.fastLeg,       'TooltipString', ...
    'Leg placed on the fast belt');
set(handles.height_edit,   'TooltipString', ...
    'Height of subject as measured in the lab (in cm)');
set(handles.weight_edit,   'TooltipString', ...
    'Weight of subject as measured in the lab (in kg)');

% Wait for user response before returning outputs (see UIRESUME)
uiwait(handles.figure1);

% ============================================================
% --- Outputs from this function are returned to the command line.
function varargout = GetInfoGUI_OutputFcn(hObject, eventdata, handles)
% GetInfoGUI_OutputFcn  Returns GUI outputs to the calling workspace.
%
%   Inputs:
%     hObject   - handle to figure
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%
%   Outputs:
%     varargout{1} - info struct populated by the user, or [] if the
%                    GUI was closed without saving

if ~(isfield(handles, 'noSave') && handles.noSave)
    info = handles.info;

    % Force save immediately so data is preserved if later steps fail
    infoFilePath = [info.save_folder filesep info.ID 'info.mat'];
    if exist(infoFilePath, 'file') > 0
        choice = questdlg( ...
            ['Info file (and possibly others) already exist for ' ...
            info.ID '. Overwrite?'], ...
            'File Name Warning', 'Yes', 'No', 'No');
        if strcmp(choice, 'No')
            info.ID = [info.ID '_' date()];
            h = msgbox(['Saving as ' info.ID], '');
            waitfor(h);
        end
    end
    save([info.save_folder filesep info.ID 'info'], 'info');

    % Prompt user for individual trial observations
    answer = inputdlg( ...
        'Are there any observations for individual trials?(y/n) ', ...
        's');

    % Validate response — must be a single 'y' or 'n'
    while length(answer{1}) > 1 || ...
            (~strcmpi(answer{1}, 'y') && ~strcmpi(answer{1}, 'n'))
        disp('Error: you must enter either "y" or "n"');
        answer = inputdlg( ...
            'Are there any observations for individual trials?(y/n) ', ...
            's');
    end

    % Pre-allocate trial observation cell array if needed
    expTrials = cell2mat(info.trialnums);
    numTrials = length(expTrials);
    if ~isfield(info, 'trialObs') || ...
            length(info.trialObs) < info.numoftrials
        % Subject was not loaded from an existing info file
        info.trialObs{1, info.numoftrials} = '';
    end

    if strcmpi(answer{1}, 'y')
        trialstr = [];
        % Build comma-separated trial string for the eval menu call
        for t = expTrials
            trialstr = [trialstr, ',''Trial ', num2str(t), ''''];
        end
        % Generate dynamic trial selection menu
        eval(['choice = menu(''Choose Trial''', ...
            trialstr, ',''Done'');']);
        while choice ~= numTrials + 1
            % Get observation for trial selected
            obStr = inputdlg( ...
                ['Observations for Trial ' ...
                num2str(expTrials(choice))], ...
                'Enter Observation');
            % Index into cell to store contents as char
            info.trialObs{expTrials(choice)} = obStr{1, 1};
            eval(['choice = menu(''Choose Trial''', ...
                trialstr, ',''Done'');']);
        end
    end

    varargout{1} = info;
    save([info.save_folder filesep info.ID 'info'], 'info');
else
    varargout{1} = [];
end

delete(handles.figure1);

% ============================================================
% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% figure1_CloseRequestFcn  Prompts to save or discard on window close.
%
%   Inputs:
%     hObject   - handle to figure1 (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

choice = questdlg('Do you want to save changes?', ...
    'GetInfoGUI', ...
    'Save', 'Don''t Save', 'Cancel', 'Cancel');
switch choice
    case 'Save'
        % Validate and save whatever was entered
        info = errorProofInfo(handles, true);
        save([info.save_folder filesep info.ID 'info'], 'info');
        handles.noSave = true;
        guidata(hObject, handles);
        uiresume(handles.figure1);
    case 'Don''t Save'
        handles.noSave = true;
        guidata(hObject, handles);
        uiresume(handles.figure1);
    case {'Cancel', ''}
        return;
end

% ============================================================
% ==================== Experiment Info =======================
% ============================================================

function description_edit_Callback(hObject, eventdata, handles)
% description_edit_Callback  Populates condition fields when an
%   experiment description is selected from the dropdown list.
%
%   Inputs:
%     hObject   - handle to description_edit (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

contents = cellstr(get(hObject, 'String'));
expFile  = contents{get(hObject, 'Value')};

% HH 6/16
% eval(expFile);
detailsPath = which('GetInfoGUI');
detailsPath = strrep(detailsPath, 'GetInfoGUI.m', 'ExpDetails');
if exist([detailsPath filesep expFile '.mat'], 'file') > 0
    % First, clear all condition fields
    set(handles.numofconds, 'String', '0');
    for conds = 1:handles.lines
        set(handles.(['condition',   num2str(conds)]), 'string', '');
        set(handles.(['condName',    num2str(conds)]), 'string', '');
        set(handles.(['description', num2str(conds)]), 'string', '');
        set(handles.(['trialnum',    num2str(conds)]), 'string', '');
        set(handles.(['type',        num2str(conds)]), 'string', '');
    end

    % Second, populate fields from the selected experiment description
    a      = load([detailsPath filesep expFile]);
    aux    = fields(a);
    expDes = a.(aux{1});
    handles = setExpDescription(handles, expDes);
    numofconds_Callback(handles.numofconds, eventdata, handles);
end

guidata(hObject, handles);

% These functions execute during object creation, after all
% properties have been set.
% Hint: controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
function description_edit_CreateFcn(hObject, eventdata, handles)
% Populate the experiment description dropdown from ExpDetails directory
detailsPath = which('GetInfoGUI');
detailsPath = strrep(detailsPath, 'GetInfoGUI.m', 'ExpDetails');
W = what(detailsPath);
% experiments=cellstr(W.m);   % HH 6/16
experiments = cellstr(W.mat);
for i = 1:length(experiments)
    fileExt         = find(experiments{i} == '.');
    experiments{i}  = experiments{i}(1:fileExt - 1);
end
set(hObject, 'String', [' '; experiments]);

if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function name_edit_Callback(hObject, eventdata, handles)
% name_edit_Callback  Executes on content change in name_edit.
%
%   Inputs:
%     hObject   - handle to name_edit (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%
% Hints: get(hObject,'String') returns contents as text
%        str2double(get(hObject,'String')) returns contents as double

function name_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

% If Enable == 'on', executes on mouse press in 5-pixel border.
% Otherwise, executes on mouse press in border or over the control.
function name_edit_ButtonDownFcn(hObject, eventdata, handles)
% Toggle the 'Enable' state to On and clear the field
set(hObject, 'Enable', 'On');
set(hObject, 'String', []);
uicontrol(handles.name_edit);

% --- Executes on selection change in month_list.
function month_list_Callback(hObject, eventdata, handles)
% month_list_Callback  Executes on selection change in month_list.
%
%   Inputs:
%     hObject   - handle to month_list (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%
% Hints: contents = cellstr(get(hObject,'String')) returns contents
%        contents{get(hObject,'Value')} returns selected item

function month_list_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function day_edit_Callback(hObject, eventdata, handles)

function day_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function day_edit_ButtonDownFcn(hObject, eventdata, handles)
% Toggle the 'Enable' state to On and clear the field
set(hObject, 'Enable', 'On');
set(hObject, 'String', []);
uicontrol(handles.day_edit);

function year_edit_Callback(hObject, eventdata, handles)

function year_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function year_edit_ButtonDownFcn(hObject, eventdata, handles)
% Toggle the 'Enable' state to On and clear the field
set(hObject, 'Enable', 'On');
set(hObject, 'String', []);
uicontrol(handles.year_edit);

function note_edit_Callback(hObject, eventdata, handles)

function note_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function note_edit_ButtonDownFcn(hObject, eventdata, handles)
% Toggle the 'Enable' state to On and clear the field
set(hObject, 'Enable', 'On');
set(hObject, 'String', []);
uicontrol(handles.note_edit);

% --- Executes on button press in schenleyLab.
function schenleyLab_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of schenleyLab
% set(handles.schenleyLab,'enable','on')
% guidata(hObject,handles);

% --- Executes on button press in schenleyLab.
function schenleyLab_CreateFcn(hObject, eventdata, handles)
% if ispc && isequal(get(hObject,'BackgroundColor'), ...
%         get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end

% --- Executes on key press with focus on schenleyLab.
function schenleyLab_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to schenleyLab (see GCBO)
% eventdata  structure with fields:
%   Key      - name of the key pressed, in lower case
%   Character- character interpretation of the key(s) pressed
%   Modifier - name(s) of any modifier keys pressed
% handles    structure with handles and user data (see GUIDATA)

function perceptualTasks_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of perceptualTasks
% set(handles.schenleyLab,'enable','on')
% guidata(hObject,handles);

% --- Executes on button press in perceptualTasks.
function perceptualTasks_CreateFcn(hObject, eventdata, handles)
% if ispc && isequal(get(hObject,'BackgroundColor'), ...
%         get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end

% --- Executes on key press with focus on perceptualTasks.
function perceptalTasks_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to perceptualTasks (see GCBO)
% eventdata  structure with fields:
%   Key      - name of the key pressed, in lower case
%   Character- character interpretation of the key(s) pressed
%   Modifier - name(s) of any modifier keys pressed
% handles    structure with handles and user data (see GUIDATA)

function backwardCheck_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of backwardCheck
% set(handles.schenleyLab,'enable','on')
% guidata(hObject,handles);

function backwardCheck_CreateFcn(hObject, eventdata, handles)
% if ispc && isequal(get(hObject,'BackgroundColor'), ...
%         get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end

% ============================================================
% ====================== Subject Info ========================
% ============================================================

function subID_edit_Callback(hObject, eventdata, handles)
% subID_edit_Callback  Executes on content change in subID_edit.
%
%   Inputs:
%     hObject   - handle to subID_edit (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%
% Hints: get(hObject,'String') returns contents as text
%        str2double(get(hObject,'String')) returns contents as double

function subID_edit_CreateFcn(hObject, ~, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function subID_edit_ButtonDownFcn(hObject, eventdata, handles)
% Ensure the field is enabled and transfer focus to it
set(hObject, 'Enable', 'On');
uicontrol(handles.subID_edit);

% --- Executes on selection change in DOBmonth_list.
function DOBmonth_list_Callback(hObject, eventdata, handles)
% DOBmonth_list_Callback  Executes on selection change in DOBmonth_list.
%
%   Inputs:
%     hObject   - handle to DOBmonth_list (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%
% Hints: contents = cellstr(get(hObject,'String')) returns contents
%        contents{get(hObject,'Value')} returns selected item

function DOBmonth_list_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function DOBday_edit_Callback(hObject, eventdata, handles)

function DOBday_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function DOBday_edit_ButtonDownFcn(hObject, eventdata, handles)
% Toggle the 'Enable' state to On and clear the field
set(hObject, 'Enable', 'On');
set(hObject, 'String', []);
uicontrol(handles.DOBday_edit);

function DOByear_edit_Callback(hObject, eventdata, handles)

function DOByear_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function DOByear_edit_ButtonDownFcn(hObject, eventdata, handles)
% Toggle the 'Enable' state to On and clear the field
set(hObject, 'Enable', 'On');
set(hObject, 'String', []);
uicontrol(handles.DOByear_edit);

% --- Executes on selection change in gender_list.
function gender_list_Callback(hObject, eventdata, handles)

function gender_list_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

% --- Executes on selection change in fastLeg.
function fastLeg_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of force_check
% set(handles.schenleyLab,'enable','on')
% guidata(hObject,handles);

function fastLeg_CreateFcn(hObject, eventdata, handles)
% if ispc && isequal(get(hObject,'BackgroundColor'), ...
%         get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor','white');
% end

% --- Executes on selection change in domleg_list.
function domleg_list_Callback(hObject, eventdata, handles)

function domleg_list_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

% --- Executes on selection change in domhand_list.
function domhand_list_Callback(hObject, eventdata, handles)

function domhand_list_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

% --- Executes on button press in strokeCheck.
function strokeCheck_Callback(hObject, eventdata, handles)
% strokeCheck_Callback  Toggles visibility of the affected-side popup.
%
%   Inputs:
%     hObject   - handle to strokeCheck (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%
% Hint: get(hObject,'Value') returns toggle state of strokeCheck

if get(hObject, 'Value')
    set(handles.popupAffected, 'Enable', 'On');
    set(handles.text63,        'Enable', 'On');
else
    set(handles.popupAffected, 'Enable', 'Off');
    set(handles.text63,        'Enable', 'Off');
end
guidata(hObject, handles);

% --- Executes on selection change in popupAffected.
function popupAffected_Callback(hObject, eventdata, handles)
% popupAffected_Callback  Executes on selection change in popupAffected.
%
%   Inputs:
%     hObject   - handle to popupAffected (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%
% Hints: contents = cellstr(get(hObject,'String')) returns contents
%        contents{get(hObject,'Value')} returns selected item

function popupAffected_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function height_edit_Callback(hObject, eventdata, handles)

function height_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function weight_edit_Callback(hObject, eventdata, handles)

function weight_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

% ============================================================
% ======================= Data Info ==========================
% ============================================================

% --- Executes on button press in browse.
function browse_Callback(hObject, eventdata, handles)
% browse_Callback  Opens a folder browser for the C3D data location.
%
%   Inputs:
%     hObject   - handle to browse (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

handles.folder_location = uigetdir();
if ~handles.folder_location == 0
    set(handles.c3dlocation, 'string', handles.folder_location);
end
guidata(hObject, handles);

function c3dlocation_Callback(hObject, eventdata, handles)
% c3dlocation_Callback  Executes when C3D location is entered manually.
%
%   Inputs:
%     hObject   - handle to c3dlocation (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

handles.folder_location = get(hObject, 'string');
guidata(hObject, handles);

function c3dlocation_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function basefile_Callback(hObject, eventdata, handles)
% basefile_Callback  Executes on content change in basefile.
%
%   Inputs:
%     hObject   - handle to basefile (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%
% Hints: get(hObject,'String') returns contents as text
%        str2double(get(hObject,'String')) returns contents as double

function basefile_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function numoftrials_Callback(hObject, eventdata, handles)
% numoftrials_Callback  Executes on content change in numoftrials.
%
%   Inputs:
%     hObject   - handle to numoftrials (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%
% Hints: get(hObject,'String') returns contents as text
%        str2double(get(hObject,'String')) returns contents as double

numoftrials = str2double(get(hObject, 'String'));

function numoftrials_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function numofconds_Callback(hObject, eventdata, handles)
% numofconds_Callback  Enables or disables condition rows based on the
%   number of conditions entered.
%
%   Inputs:
%     hObject   - handle to numofconds (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

numofconds = str2double(get(hObject, 'String'));

% First, disable all condition rows
for conds = 1:handles.lines
    set(handles.(['condition',   num2str(conds)]), 'enable', 'off');
    set(handles.(['condName',    num2str(conds)]), 'enable', 'off');
    set(handles.(['description', num2str(conds)]), 'enable', 'off');
    set(handles.(['trialnum',    num2str(conds)]), 'enable', 'off');
    set(handles.(['type',        num2str(conds)]), 'enable', 'off');
end

% Second, validate the entered number
if isnan(numofconds) || numofconds < 0 || numofconds > 20
    h_error = errordlg( ...
        'Please enter a number between 1 and 20', ...
        'Condition Number Error');
    waitfor(h_error);
    uicontrol(hObject);
    return
end

% Third, enable rows up to the number of conditions entered
for conds = 1:numofconds
    set(handles.(['condition',   num2str(conds)]), 'enable', 'on');
    set(handles.(['condName',    num2str(conds)]), 'enable', 'on');
    set(handles.(['description', num2str(conds)]), 'enable', 'on');
    set(handles.(['trialnum',    num2str(conds)]), 'enable', 'on');
    set(handles.(['type',        num2str(conds)]), 'enable', 'on');
end

function numofconds_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

% --- Executes on button press in kinematic_check.
function kinematic_check_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of kinematic_check

% --- Executes on button press in force_check.
function force_check_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of force_check

% --- Executes during object creation, after setting all properties.
function force_check_CreateFcn(hObject, eventdata, handles)
% hObject    handle to force_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on key press with focus on force_check.
function force_check_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to force_check (see GCBO)
% eventdata  structure with fields:
%   Key      - name of the key pressed, in lower case
%   Character- character interpretation of the key(s) pressed
%   Modifier - name(s) of any modifier keys pressed
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in emg_check.
function emg_check_Callback(hObject, eventdata, handles)
% emg_check_Callback  Toggles EMG-related controls based on checkbox state.
%
%   Inputs:
%     hObject   - handle to emg_check (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

state = get(hObject, 'Value');

if state
    set(handles.Nexus,    'enable', 'on');
    set(handles.EMGworks, 'enable', 'on');
    for i = 1:16
        eval(['set(handles.emg1_' num2str(i) ',''enable'',''off'');']);
        eval(['set(handles.emg2_' num2str(i) ',''enable'',''off'');']);
        eval(['set(handles.emg1_' num2str(i) ',''enable'',''on'');']);
        eval(['set(handles.emg2_' num2str(i) ',''enable'',''on'');']);
    end
else
    set(handles.Nexus,          'enable', 'off');
    set(handles.EMGworks,       'enable', 'off');
    set(handles.secfile_browse, 'enable', 'off');
    set(handles.secfileloc,     'enable', 'off');
    for i = 1:16
        eval(['set(handles.emg1_' num2str(i) ',''enable'',''off'');']);
        eval(['set(handles.emg2_' num2str(i) ',''enable'',''off'');']);
    end
end
guidata(hObject, handles);

function Nexus_Callback(hObject, eventdata, handles)
% Nexus_Callback  Toggles secondary file controls for Nexus EMG source.
%
%   Inputs:
%     hObject   - handle to Nexus (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%
% Hint: get(hObject,'Value') returns toggle state of Nexus

state = get(hObject, 'Value');
if state
    set(handles.secfile_browse, 'enable', 'on');
    set(handles.secfileloc,     'enable', 'on');
else
    set(handles.secfile_browse, 'enable', 'off');
    set(handles.secfileloc,     'enable', 'off');
end
guidata(hObject, handles);

% --- Executes on button press in EMGworks.
function EMGworks_Callback(hObject, eventdata, handles)
% EMGworks_Callback  Toggles EMGworks file location controls.
%
%   Inputs:
%     hObject   - handle to EMGworks (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

state = get(hObject, 'Value');
if state
    set(handles.EMGworksFile1_search,  'enable', 'on');
    set(handles.EMGworksLocation,      'enable', 'on');
    set(handles.SecFileSearchEMGworks, 'enable', 'on');
    set(handles.SecondEMGworksLocation,'enable', 'on');
else
    set(handles.EMGworksFile1_search,  'enable', 'off');
    set(handles.EMGworksLocation,      'enable', 'off');
    set(handles.SecFileSearchEMGworks, 'enable', 'on');
    set(handles.SecondEMGworksLocation,'enable', 'on');
end
guidata(hObject, handles);

% --- Executes on button press in secfile_browse.
function secfile_browse_Callback(hObject, eventdata, handles)
% secfile_browse_Callback  Opens folder browser for secondary data location.
%
%   Inputs:
%     hObject   - handle to secfile_browse (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

handles.secfolder_location = uigetdir();
if ~handles.secfolder_location == 0
    set(handles.secfileloc, 'string', handles.secfolder_location);
end
guidata(hObject, handles);

function secfileloc_Callback(hObject, eventdata, handles)
% secfileloc_Callback  Executes when secondary folder is entered manually.
%
%   Inputs:
%     hObject   - handle to secfileloc (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

handles.secfolder_location = get(hObject, 'string');
guidata(hObject, handles);

function secfileloc_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

% ---- EMGworks file location callbacks --------------------------
%%%%%%%%%%%%%% DMMO for EMGworks
% --- Executes on button press in EMGworksFile1_search.
function EMGworksFile1_search_Callback(hObject, eventdata, handles)
handles.EMGworksFile_Loc = uigetdir();
if ~handles.EMGworksFile_Loc == 0
    set(handles.EMGworksLocation, 'string', handles.EMGworksFile_Loc);
end
guidata(hObject, handles);

function EMGworksLocation_Callback(hObject, eventdata, handles)
handles.EMGworksFile_Loc = get(hObject, 'string');
guidata(hObject, handles);

function EMGworksLocation_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function SecFileSearchEMGworks_Callback(hObject, eventdata, handles)
handles.EMGworksFile2Loc = uigetdir();
if ~handles.EMGworksFile2Loc == 0
    set(handles.SecondEMGworksLocation, 'string', ...
        handles.EMGworksFile2Loc);
end
guidata(hObject, handles);

function SecondEMGworksLocation_Callback(hObject, eventdata, handles)
handles.EMGworksFile2Loc = get(hObject, 'string');
guidata(hObject, handles);

function SecondEMGworksLocation_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
%%%%%%%%%%%%%% DMMO for EMGworks
%%%%%%%%%%%%%%

% Hint: get(hObject,'Value') returns toggle state of EMGworks

% ============================================================
% ====================== Condition Info ======================
% ============================================================

function condition1_Callback(hObject, eventdata, handles)
function condName1_Callback(hObject, eventdata, handles)
function description1_Callback(hObject, eventdata, handles)
function trialnum1_Callback(hObject, eventdata, handles)
function type1_Callback(hObject, eventdata, handles)
function condition1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition2_Callback(hObject, eventdata, handles)
function condName2_Callback(hObject, eventdata, handles)
function description2_Callback(hObject, eventdata, handles)
function trialnum2_Callback(hObject, eventdata, handles)
function type2_Callback(hObject, eventdata, handles)
function condition2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition3_Callback(hObject, eventdata, handles)
function condName3_Callback(hObject, eventdata, handles)
function description3_Callback(hObject, eventdata, handles)
function trialnum3_Callback(hObject, eventdata, handles)
function type3_Callback(hObject, eventdata, handles)
function condition3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition4_Callback(hObject, eventdata, handles)
function condName4_Callback(hObject, eventdata, handles)
function description4_Callback(hObject, eventdata, handles)
function trialnum4_Callback(hObject, eventdata, handles)
function type4_Callback(hObject, eventdata, handles)
function condition4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition5_Callback(hObject, eventdata, handles)
function condName5_Callback(hObject, eventdata, handles)
function description5_Callback(hObject, eventdata, handles)
function trialnum5_Callback(hObject, eventdata, handles)
function type5_Callback(hObject, eventdata, handles)
function condition5_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName5_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description5_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum5_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition6_Callback(hObject, eventdata, handles)
function condName6_Callback(hObject, eventdata, handles)
function description6_Callback(hObject, eventdata, handles)
function trialnum6_Callback(hObject, eventdata, handles)
function type6_Callback(hObject, eventdata, handles)
function condition6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition7_Callback(hObject, eventdata, handles)
function condName7_Callback(hObject, eventdata, handles)
function description7_Callback(hObject, eventdata, handles)
function trialnum7_Callback(hObject, eventdata, handles)
function type7_Callback(hObject, eventdata, handles)
function condition7_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName7_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description7_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum7_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition8_Callback(hObject, eventdata, handles)
function condName8_Callback(hObject, eventdata, handles)
function description8_Callback(hObject, eventdata, handles)
function trialnum8_Callback(hObject, eventdata, handles)
function type8_Callback(hObject, eventdata, handles)
function condition8_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName8_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description8_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum8_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition9_Callback(hObject, eventdata, handles)
function condName9_Callback(hObject, eventdata, handles)
function description9_Callback(hObject, eventdata, handles)
function trialnum9_Callback(hObject, eventdata, handles)
function type9_Callback(hObject, eventdata, handles)
function condition9_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName9_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description9_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum9_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition10_Callback(hObject, eventdata, handles)
function condName10_Callback(hObject, eventdata, handles)
function description10_Callback(hObject, eventdata, handles)
function trialnum10_Callback(hObject, eventdata, handles)
function type10_Callback(hObject, eventdata, handles)
function condition10_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName10_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description10_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum10_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition11_Callback(hObject, eventdata, handles)
function condName11_Callback(hObject, eventdata, handles)
function description11_Callback(hObject, eventdata, handles)
function trialnum11_Callback(hObject, eventdata, handles)
function type11_Callback(hObject, eventdata, handles)
function condition11_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName11_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description11_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum11_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition12_Callback(hObject, eventdata, handles)
function condName12_Callback(hObject, eventdata, handles)
function description12_Callback(hObject, eventdata, handles)
function trialnum12_Callback(hObject, eventdata, handles)
function type12_Callback(hObject, eventdata, handles)
function condition12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition13_Callback(hObject, eventdata, handles)
function condName13_Callback(hObject, eventdata, handles)
function description13_Callback(hObject, eventdata, handles)
function trialnum13_Callback(hObject, eventdata, handles)
function type13_Callback(hObject, eventdata, handles)
function condition13_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName13_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description13_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum13_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition14_Callback(hObject, eventdata, handles)
function condName14_Callback(hObject, eventdata, handles)
function description14_Callback(hObject, eventdata, handles)
function trialnum14_Callback(hObject, eventdata, handles)
function type14_Callback(hObject, eventdata, handles)
function condition14_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName14_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description14_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum14_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition15_Callback(hObject, eventdata, handles)
function condName15_Callback(hObject, eventdata, handles)
function description15_Callback(hObject, eventdata, handles)
function trialnum15_Callback(hObject, eventdata, handles)
function type15_Callback(hObject, eventdata, handles)
function condition15_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName15_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description15_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum15_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition16_Callback(hObject, eventdata, handles)
function condName16_Callback(hObject, eventdata, handles)
function description16_Callback(hObject, eventdata, handles)
function trialnum16_Callback(hObject, eventdata, handles)
function type16_Callback(hObject, eventdata, handles)
function condition16_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName16_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description16_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum16_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
% --- Executes during object creation, after setting all properties.
function type16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to type16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition17_Callback(hObject, eventdata, handles)
function condName17_Callback(hObject, eventdata, handles)
function description17_Callback(hObject, eventdata, handles)
function trialnum17_Callback(hObject, eventdata, handles)
function type17_Callback(hObject, eventdata, handles)
function condition17_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName17_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description17_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum17_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
% --- Executes during object creation, after setting all properties.
function type17_CreateFcn(hObject, eventdata, handles)
% hObject    handle to type17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition18_Callback(hObject, eventdata, handles)
function condName18_Callback(hObject, eventdata, handles)
function description18_Callback(hObject, eventdata, handles)
function trialnum18_Callback(hObject, eventdata, handles)
function type18_Callback(hObject, eventdata, handles)
function condition18_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName18_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description18_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum18_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
% --- Executes during object creation, after setting all properties.
function type18_CreateFcn(hObject, eventdata, handles)
% hObject    handle to type18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition19_Callback(hObject, eventdata, handles)
function condName19_Callback(hObject, eventdata, handles)
function description19_Callback(hObject, eventdata, handles)
function trialnum19_Callback(hObject, eventdata, handles)
function type19_Callback(hObject, eventdata, handles)
function condition19_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName19_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description19_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum19_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
% --- Executes during object creation, after setting all properties.
function type19_CreateFcn(hObject, eventdata, handles)
% hObject    handle to type19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

function condition20_Callback(hObject, eventdata, handles)
function condName20_Callback(hObject, eventdata, handles)
function description20_Callback(hObject, eventdata, handles)
function trialnum20_Callback(hObject, eventdata, handles)
function type20_Callback(hObject, eventdata, handles)
function condition20_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function condName20_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function description20_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
function trialnum20_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end
% --- Executes during object creation, after setting all properties.
function type20_CreateFcn(hObject, eventdata, handles)
% hObject    handle to type20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

% ============================================================
% =================== Save As / OK Button ====================
% ============================================================

% ============================================================
% --- Executes on button press in saveExpButton.
function saveExpButton_Callback(hObject, eventdata, handles)
% saveExpButton_Callback  Saves the current condition configuration as
%   a new experiment description file in the ExpDetails directory.
%
%   Inputs:
%     hObject   - handle to saveExpButton (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

% Build the expDes structure from current GUI field values
c = 0;
for i = 1:handles.lines
    % Condition numbers
    condNum = get(handles.(['condition' num2str(i)]), 'string');
    if ~isempty(condNum)
        expDes.(['condition' num2str(i)]) = condNum;
        c = c + 1;
    end
    % Condition names
    condName = get(handles.(['condName' num2str(i)]), 'string');
    if ~isempty(condName)
        expDes.(['condName' num2str(i)]) = condName;
    end
    % Condition descriptions
    condDesc = get(handles.(['description' num2str(i)]), 'string');
    if ~isempty(condDesc)
        expDes.(['description' num2str(i)]) = condDesc;
    end
    % Trial numbers for each condition
    trialNum = get(handles.(['trialnum' num2str(i)]), 'string');
    if ~isempty(trialNum)
        expDes.(['trialnum' num2str(i)]) = trialNum;
    end
    % Trial types
    type = get(handles.(['type' num2str(i)]), 'string');
    if ~isempty(type)
        expDes.(['type' num2str(i)]) = type;
    end
end
expDes.numofconds = c;

answer = inputdlg( ...
    'Enter name of new experiment description: ', ...
    'Experiment Description Name');
if ~isempty(answer)
    answer = char(answer);
    expDes.group = answer;
    % Remove non-alphanumeric characters from the filename
    answer = answer(ismember(answer, ['A':'Z' 'a':'z' '0':'9']));
    detailsPath = which('GetInfoGUI');
    detailsPath = strrep(detailsPath, 'GetInfoGUI.m', 'ExpDetails');
    if exist([detailsPath filesep answer '.mat'], 'file') > 0
        choice = questdlg( ...
            'File name already exists. Overwrite?', ...
            'File Name Warning', 'Yes', 'No', 'No');
        if strcmp(choice, 'No')
            h = msgbox('Experiment description was not saved.', '');
            waitfor(h);
            return;
        end
    end
    save([detailsPath filesep answer], 'expDes');
    description_edit_CreateFcn(handles.description_edit, ...
        eventdata, handles);
    newContents = get(handles.description_edit, 'string');
    ind = find(ismember(newContents, answer));
    set(handles.description_edit, 'Value', ind);
end

% ============================================================
% ------------------- Save Location / OK Button -------------
% ============================================================

function saveloc_edit_Callback(hObject, eventdata, handles)
% saveloc_edit_Callback  Executes when save location is entered manually.
%
%   Inputs:
%     hObject   - handle to saveloc_edit (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

handles.save_folder = get(hObject, 'string');
guidata(hObject, handles);

function saveloc_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

% --- Executes on button press in save_browse.
function save_browse_Callback(hObject, eventdata, handles)
% save_browse_Callback  Opens a folder browser for the save location.
%
%   Inputs:
%     hObject   - handle to save_browse (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

savePath = uigetdir();
if ~savePath == 0
    handles.save_folder = savePath;
    set(handles.saveloc_edit, 'string', handles.save_folder);
end
guidata(hObject, handles);

% --- Executes on button press in ok_button.
function ok_button_Callback(hObject, eventdata, handles)
% ok_button_Callback  Validates GUI inputs and resumes execution.
%
%   Inputs:
%     hObject   - handle to ok_button (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

% Retrieve and validate all information entered in the GUI
handles.info = errorProofInfo(handles);
if handles.info.bad
    return;
else
    handles.info.ok = true;
    guidata(hObject, handles);
    uiresume(handles.figure1);
end

% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles)
% loadButton_Callback  Loads a previously saved info file and populates
%   all GUI fields with the stored session information.
%
%   Inputs:
%     hObject   - handle to loadButton (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

[file, filePath] = uigetfile('*.mat', 'Choose subject handles file');

if file ~= 0
    aux        = load([filePath file]);
    fieldNames = fields(aux);
    subInfo    = aux.(fieldNames{1});
    % TODO: check that file is correct
    if ~isa(subInfo, 'struct')
        h_error = errordlg( ...
            'File selected does not seem to be an info file.', ...
            'Load Error');
        waitfor(h_error);
    else
        % -- Experiment Info
        descriptionContents = ...
            cellstr(get(handles.description_edit, 'string'));
        if isfield(subInfo, 'ExpFile')   % processed after 4/2015
            if ~any(strcmp(descriptionContents, subInfo.ExpFile) == 1)
                set(handles.description_edit, 'String', ...
                    [descriptionContents; subInfo.ExpFile]);
                descriptionContents = cellstr( ...
                    get(handles.description_edit, 'string'));
            end
            set(handles.description_edit, 'Value', ...
                find(strcmp(descriptionContents, subInfo.ExpFile)));
        else
            if ~any(strcmp(descriptionContents, ...
                    subInfo.ExpDescription) == 1)
                set(handles.description_edit, 'String', ...
                    [descriptionContents; subInfo.ExpDescription]);
                descriptionContents = cellstr( ...
                    get(handles.description_edit, 'string'));
            end
            set(handles.description_edit, 'Value', ...
                find(strcmp(descriptionContents, subInfo.ExpDescription)));
        end
        handles.group = subInfo.ExpDescription;

        set(handles.name_edit, 'string', subInfo.experimenter);
        monthContents = cellstr(get(handles.month_list, 'String'));
        set(handles.month_list, 'Value', ...
            find(strcmp(monthContents, subInfo.month)));
        set(handles.day_edit,  'string', subInfo.day);
        set(handles.year_edit, 'string', subInfo.year);
        set(handles.note_edit, 'string', subInfo.exp_obs);

        % -- Subject Info
        set(handles.subID_edit, 'string', subInfo.ID);
        DOBmonthContents = cellstr(get(handles.DOBmonth_list, 'String'));
        set(handles.DOBmonth_list, 'Value', ...
            find(strcmp(DOBmonthContents, subInfo.DOBmonth)));
        set(handles.DOBday_edit,  'string', subInfo.DOBday);
        set(handles.DOByear_edit, 'string', subInfo.DOByear);
        genderContents = cellstr(get(handles.gender_list, 'String'));
        set(handles.gender_list, 'Value', ...
            find(strcmp(genderContents, subInfo.gender)));
        domlegContents = cellstr(get(handles.domleg_list, 'String'));
        set(handles.domleg_list, 'Value', ...
            find(strcmp(domlegContents, subInfo.domleg)));
        domhandContents = cellstr(get(handles.domhand_list, 'String'));
        set(handles.domhand_list, 'Value', ...
            find(strcmp(domhandContents, subInfo.domhand)));
        set(handles.height_edit, 'string', subInfo.height);
        set(handles.weight_edit, 'string', subInfo.weight);

        if isfield(subInfo, 'isStroke')   % for files before 11/2014
            set(handles.strokeCheck, 'Value', subInfo.isStroke);
        else
            set(handles.strokeCheck, 'Value', 0);
        end

        % Fire callback to synchronize 'popupAffected' enable state
        strokeCheck_Callback(handles.strokeCheck, eventdata, handles);
        if get(handles.strokeCheck, 'Value')
            set(handles.popupAffected, 'Value', subInfo.affectedValue);
        end

        if isfield(subInfo, 'fastLeg')
            fastLegContents = cellstr(get(handles.fastLeg, 'String'));
            set(handles.fastLeg, 'Value', ...
                find(strcmp(fastLegContents, subInfo.fastLeg)));
        else
            % For subjects processed before 05/2024: infer fast leg
            if handles.strokeCheck.Value
                % Affected side was set as the slow leg; fast leg is
                % the contralateral limb
                sLeg = subInfo.affectedSide;
                fLeg_value = find( ...
                    ~strcmpi(cellstr(get(handles.fastLeg, 'String')), ...
                    sLeg) & ...
                    ~strcmpi(cellstr(get(handles.fastLeg, 'String')), ''));
                set(handles.fastLeg, 'Value', fLeg_value);
            else
                fLeg = subInfo.domleg;
                fLeg_value = find( ...
                    strcmpi(cellstr(get(handles.fastLeg, 'String')), ...
                    fLeg) & ...
                    ~strcmpi(cellstr(get(handles.fastLeg, 'String')), ''));
                set(handles.fastLeg, 'Value', fLeg_value);
            end
        end

        % -- Data Info
        handles.folder_location = subInfo.dir_location;
        set(handles.c3dlocation,     'string', handles.folder_location);
        set(handles.basefile,        'string', subInfo.basename);
        set(handles.numofconds,      'string', subInfo.numofconds);

        numofconds_Callback(handles.numofconds, eventdata, handles);
        set(handles.kinematic_check, 'Value', subInfo.kinematics);
        set(handles.force_check,     'Value', subInfo.forces);

        % Populate EMG checkbox state and fire callback to synchronize
        % the enable state of all EMG-related controls (Nexus,
        % EMGworks, and individual EMG channel label fields)
        set(handles.emg_check, 'Value', subInfo.EMGs);
        emg_check_Callback(handles.emg_check, eventdata, handles);

        if isfield(subInfo, 'schenleyLab')
            set(handles.schenleyLab, 'Value', subInfo.schenleyLab);
        else
            subInfo.schenleyLab = 0;
            set(handles.schenleyLab, 'Value', subInfo.schenleyLab);
        end

        if isfield(subInfo, 'perceptualTasks')
            set(handles.perceptualTasks, 'Value', subInfo.perceptualTasks);
        else
            subInfo.perceptualTasks = 0;
            set(handles.perceptualTasks, 'Value', subInfo.perceptualTasks);
        end

        if isfield(subInfo, 'backwardCheck')
            set(handles.backwardCheck, 'Value', subInfo.backwardCheck);
        else
            subInfo.backwardCheck = 0;
            set(handles.backwardCheck, 'Value', subInfo.backwardCheck);
        end

        % Populate Nexus checkbox state and fire callback to
        % synchronize secondary C3D file location control enable
        % states; then restore the saved secondary folder path
        if isfield(handles, 'Nexus')
            set(handles.Nexus, 'Value', subInfo.Nexus);
            Nexus_Callback(handles.Nexus, eventdata, handles);
            handles.secfolder_location = subInfo.secdir_location;
            set(handles.secfileloc, 'string', handles.secfolder_location);
        end

        % Populate EMGworks checkbox state and fire callback to
        % synchronize EMGworks file location control enable states;
        % then restore the saved EMGworks folder paths if applicable
        if isfield(handles, 'EMGworks')
            set(handles.EMGworks, 'Value', subInfo.EMGworks);
            EMGworks_Callback(handles.EMGworks, eventdata, handles);
            if subInfo.EMGworks
                handles.EMGworksFile_Loc = subInfo.EMGworksdir_location;
                set(handles.EMGworksLocation, 'string', ...
                    handles.EMGworksFile_Loc);
                handles.EMGworksFile2Loc = subInfo.secEMGworksdir_location;
                set(handles.SecondEMGworksLocation, 'string', ...
                    handles.EMGworksFile2Loc);
            end
        end

        % -- Trial/Condition Info
        for c = 1:subInfo.numofconds
            condNum   = subInfo.cond(c);
            trialnums = subInfo.trialnums{condNum};
            set(handles.(['condition',   num2str(c)]), ...
                'string', num2str(condNum));
            set(handles.(['condName',    num2str(c)]), ...
                'string', subInfo.conditionNames{condNum});
            set(handles.(['description', num2str(c)]), ...
                'string', subInfo.conditionDescriptions{condNum});
            if length(trialnums) > 2 && ~any(diff(trialnums) > 1)
                set(handles.(['trialnum', num2str(c)]), 'string', ...
                    [num2str(trialnums(1)) ':' num2str(trialnums(end))]);
            else
                set(handles.(['trialnum', num2str(c)]), ...
                    'string', num2str(trialnums));
            end
            if isfield(subInfo, 'isOverGround')  % before 7/16/2014
                if subInfo.isOverGround(condNum)
                    set(handles.(['type', num2str(c)]), 'string', 'OG');
                else
                    set(handles.(['type', num2str(c)]), 'string', 'TM');
                end
            else
                set(handles.(['type', num2str(c)]), ...
                    'string', subInfo.type{condNum});
            end
        end

        % -- EMG channel labels (for subjects processed after 7/29/2014)
        if isfield(subInfo, 'EMGList1') && isfield(subInfo, 'EMGList2')
            for i = 1:16
                aux1 = ['emg1_' num2str(i)];
                set(handles.(aux1), 'string', subInfo.EMGList1{i});
                if ~isempty(subInfo.EMGList1{i})
                    set(handles.(aux1), 'enable', 'on');
                end
                aux2 = ['emg2_' num2str(i)];
                set(handles.(aux2), 'string', subInfo.EMGList2{i});
                if ~isempty(subInfo.EMGList2{i})
                    set(handles.(aux2), 'enable', 'on');
                end
            end
        end

        % -- Save location
        handles.save_folder = subInfo.save_folder;
        set(handles.saveloc_edit, 'string', handles.save_folder);

        % -- Trial observations
        if isfield(subInfo, 'trialObs')
            handles.trialObs = subInfo.trialObs;
        end
    end
    guidata(hObject, handles);
end

% ============================================================
% ========================= EMG Callbacks ====================
% ============================================================

function emg1_1_Callback(hObject, eventdata, handles)
function emg1_1_CreateFcn(hObject, eventdata, handles)
function emg1_2_Callback(hObject, eventdata, handles)
function emg1_2_CreateFcn(hObject, eventdata, handles)
function emg1_3_Callback(hObject, eventdata, handles)
function emg1_3_CreateFcn(hObject, eventdata, handles)
function emg1_4_Callback(hObject, eventdata, handles)
function emg1_4_CreateFcn(hObject, eventdata, handles)
function emg1_5_Callback(hObject, eventdata, handles)
function emg1_5_CreateFcn(hObject, eventdata, handles)
function emg1_6_Callback(hObject, eventdata, handles)
function emg1_6_CreateFcn(hObject, eventdata, handles)
function emg1_7_Callback(hObject, eventdata, handles)
function emg1_7_CreateFcn(hObject, eventdata, handles)
function emg1_8_Callback(hObject, eventdata, handles)
function emg1_8_CreateFcn(hObject, eventdata, handles)
function emg1_9_Callback(hObject, eventdata, handles)
function emg1_9_CreateFcn(hObject, eventdata, handles)
function emg1_10_Callback(hObject, eventdata, handles)
function emg1_10_CreateFcn(hObject, eventdata, handles)
function emg1_11_Callback(hObject, eventdata, handles)
function emg1_11_CreateFcn(hObject, eventdata, handles)
function emg1_12_Callback(hObject, eventdata, handles)
function emg1_12_CreateFcn(hObject, eventdata, handles)
function emg1_13_Callback(hObject, eventdata, handles)
function emg1_13_CreateFcn(hObject, eventdata, handles)
function emg1_14_Callback(hObject, eventdata, handles)
function emg1_14_CreateFcn(hObject, eventdata, handles)
function emg1_15_Callback(hObject, eventdata, handles)
function emg1_15_CreateFcn(hObject, eventdata, handles)
function emg1_16_Callback(hObject, eventdata, handles)
function emg1_16_CreateFcn(hObject, eventdata, handles)

function emg2_1_Callback(hObject, eventdata, handles)
function emg2_1_CreateFcn(hObject, eventdata, handles)
function emg2_2_Callback(hObject, eventdata, handles)
function emg2_2_CreateFcn(hObject, eventdata, handles)
function emg2_3_Callback(hObject, eventdata, handles)
function emg2_3_CreateFcn(hObject, eventdata, handles)
function emg2_4_Callback(hObject, eventdata, handles)
function emg2_4_CreateFcn(hObject, eventdata, handles)
function emg2_5_Callback(hObject, eventdata, handles)
function emg2_5_CreateFcn(hObject, eventdata, handles)
function emg2_6_Callback(hObject, eventdata, handles)
function emg2_6_CreateFcn(hObject, eventdata, handles)
function emg2_7_Callback(hObject, eventdata, handles)
function emg2_7_CreateFcn(hObject, eventdata, handles)
function emg2_8_Callback(hObject, eventdata, handles)
function emg2_8_CreateFcn(hObject, eventdata, handles)
function emg2_9_Callback(hObject, eventdata, handles)
function emg2_9_CreateFcn(hObject, eventdata, handles)
function emg2_10_Callback(hObject, eventdata, handles)
function emg2_10_CreateFcn(hObject, eventdata, handles)
function emg2_11_Callback(hObject, eventdata, handles)
function emg2_11_CreateFcn(hObject, eventdata, handles)
function emg2_12_Callback(hObject, eventdata, handles)
function emg2_12_CreateFcn(hObject, eventdata, handles)
function emg2_13_Callback(hObject, eventdata, handles)
function emg2_13_CreateFcn(hObject, eventdata, handles)
function emg2_14_Callback(hObject, eventdata, handles)
function emg2_14_CreateFcn(hObject, eventdata, handles)
function emg2_15_Callback(hObject, eventdata, handles)
function emg2_15_CreateFcn(hObject, eventdata, handles)
function emg2_16_Callback(hObject, eventdata, handles)
function emg2_16_CreateFcn(hObject, eventdata, handles)


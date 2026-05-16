function varargout = uiCreateStudy(varargin)
%UICREATESTUDY GUI for assembling groups of subjects into a study.
%
%   Launches a graphical interface that scans the current working directory
% for subject parameter (.mat) files, lets the user assign them to named
% groups, and saves the resulting studyData object to disk.
%
% Toolbox Dependencies:
%   None
%
% See also: groupAdaptationData

% Last Modified by GUIDE v2.5 22-Jun-2015 10:26:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @uiCreateStudy_OpeningFcn, ...
    'gui_OutputFcn',  @uiCreateStudy_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% ============================================================
% --- Executes just before uiCreateStudy is made visible.
function uiCreateStudy_OpeningFcn(hObject, eventdata, handles, varargin)
% uiCreateStudy_OpeningFcn  Initializes GUI state before it is shown.
%
%   Inputs:
%     hObject   - handle to figure
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%     varargin  - command line arguments to uiCreateStudy (see VARARGIN)

handles.output    = hObject;
handles.studyData = struct;

% Scan the current directory for subject params files
files    = what('./');
fileList = files.mat;
paramFiles = {};

for ii = 1:length(fileList)
    if ~isempty(strfind(lower(fileList{ii}), 'params'))
        paramFiles{end + 1} = fileList{ii};
    end
end

set(handles.allSubList, 'String', paramFiles');
set(handles.allSubList, 'Max',    length(paramFiles));

guidata(hObject, handles);

% UIWAIT makes uiCreateStudy wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% ============================================================
% --- Outputs from this function are returned to the command line.
function varargout = uiCreateStudy_OutputFcn(hObject, eventdata, handles)
% uiCreateStudy_OutputFcn  Returns GUI output to the calling workspace.
%
%   Inputs:
%     hObject   - handle to figure
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%
%   Outputs:
%     varargout{1} - handle to the figure

varargout{1} = handles.output;

% ============================================================
%% Listbox Callbacks

% --- Executes on selection change in allSubList.
function allSubList_Callback(hObject, eventdata, handles)
% allSubList_Callback  Executes on selection change in allSubList.
%
%   Inputs:
%     hObject   - handle to allSubList (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

% --- Executes on selection change in selectSubList.
function selectSubList_Callback(hObject, eventdata, handles)
% selectSubList_Callback  Executes on selection change in selectSubList.
%
%   Inputs:
%     hObject   - handle to selectSubList (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

% --- Executes on selection change in groupList.
function groupList_Callback(hObject, eventdata, handles)
% groupList_Callback  Executes on selection change in groupList.
%
%   Inputs:
%     hObject   - handle to groupList (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

function groupNameEdit_Callback(hObject, eventdata, handles)
% groupNameEdit_Callback  Executes on content change in groupNameEdit.
%
%   Inputs:
%     hObject   - handle to groupNameEdit (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

% ============================================================
%% Add / Remove Subject Buttons

function addButton_Callback(hObject, eventdata, handles)
% addButton_Callback  Moves selected subjects from the all-subjects list
%   to the selected-subjects list.
%
%   Inputs:
%     hObject   - handle to addButton (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

selectSubContents = get(handles.selectSubList, 'String');

contents = get(handles.allSubList, 'String');
inds     = get(handles.allSubList, 'Value');
newSelectSubs = contents(inds);
contents(inds) = [];

newSelectSubList = sort([selectSubContents; newSelectSubs]);

set(handles.selectSubList, 'String', newSelectSubList);
set(handles.allSubList,    'String', contents);
set(handles.allSubList,    'Value',  []);

guidata(hObject, handles);

% --- Executes on button press in removeButton.
function removeButton_Callback(hObject, eventdata, handles)
% removeButton_Callback  Moves selected subjects from the selected list
%   back to the all-subjects list.
%
%   Inputs:
%     hObject   - handle to removeButton (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

allSubContents = get(handles.allSubList, 'String');

contents   = get(handles.selectSubList, 'String');
inds       = get(handles.selectSubList, 'Value');
removeSubs = contents(inds);
contents(inds) = [];

newAllSubList = sort([allSubContents; removeSubs]);

set(handles.allSubList,    'String', newAllSubList);
set(handles.selectSubList, 'String', contents);
set(handles.selectSubList, 'Value',  []);

guidata(hObject, handles);

% --- Executes on button press in addGroupButton.
function addGroupButton_Callback(hObject, eventdata, handles)
% addGroupButton_Callback  Creates a group from the selected subjects and
%   adds it to the study.
%
%   Inputs:
%     hObject   - handle to addGroupButton (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

fileList = get(handles.selectSubList, 'String');
nSubs    = length(fileList);
sub      = struct;

group       = get(handles.groupNameEdit, 'String');
abbrevGroup = group(ismember(group, ['A':'Z' 'a':'z' '1':'9']));
if isempty(abbrevGroup)
    abbrevGroup = 'NoDescription';
end

    %     aux1=strfind(lower(fileList{i}),'params');
    %     subID=fileList{i}(1:(aux1-1));
for ii = 1:nSubs
    load(fileList{ii});
    subID = adaptData.subData.ID;

    sub.IDs(ii)       = {subID};
    sub.adaptData(ii) = {adaptData};
end

handles.studyData.(abbrevGroup) = ...
    groupAdaptationData(sub.IDs, sub.adaptData);

set(handles.selectSubList, 'String', []);

groupContents    = get(handles.groupList, 'String');
newGroupContents = [groupContents; {group}];
set(handles.groupList, 'String', newGroupContents);

guidata(hObject, handles);

% ============================================================
%% Save and CreateFcn Callbacks

function saveButton_Callback(hObject, eventdata, handles)
% saveButton_Callback  Saves the assembled study to a MAT file.
%
%   Inputs:
%     hObject   - handle to saveButton (see GCBO)
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)

[file, path] = uiputfile('*.mat', 'Save Study As');
studyData    = handles.studyData;
save([path file], 'studyData', '-v7.3');

close(handles.figure1);

function allSubList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function groupNameEdit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function groupList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function selectSubList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

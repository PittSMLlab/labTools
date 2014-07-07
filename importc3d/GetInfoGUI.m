function varargout = GetInfoGUI(varargin)
% GETINFOGUI MATLAB code for GetInfoGUI.fig
%      GETINFOGUI, by itself, creates a new GETINFOGUI or raises the existing
%      singleton*.
%
%      H = GETINFOGUI returns the handle to a new GETINFOGUI or the handle to
%      the existing singleton*.
%
%      GETINFOGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GETINFOGUI.M with the given input arguments.
%
%      GETINFOGUI('Property','Value',...) creates a new GETINFOGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GetInfoGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GetInfoGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GetInfoGUI

% Last Modified by GUIDE v2.5 23-Jun-2014 08:52:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @GetInfoGUI_OpeningFcn, ...
    'gui_OutputFcn',  @GetInfoGUI_OutputFcn, ...
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


% --- Executes just before GetInfoGUI is made visible.
function GetInfoGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GetInfoGUI (see VARARGIN)

% Choose default command line output for GetInfoGUI
handles.output = hObject;

% Specify number of condition lines in GUI
handles.lines = 15;

% Update handles structure
guidata(hObject, handles);

%Set GUI position to middle of screen
% left, bottom, width, height
scrsz = get(0,'ScreenSize'); 
set(gcf,'Units','pixels');
guiPos = get(gcf,'Position');
set(gcf, 'Position', [(scrsz(3)-guiPos(3))/2 (scrsz(4)-guiPos(4))/2 guiPos(3) guiPos(4)]);

% UIWAIT makes GetInfoGUI wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GetInfoGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
info=handles.info;
varargout{1}=info;
save([info.save_folder filesep info.ID 'info'],'info')

delete(handles.figure1)


%------------------------Experiment Info---------------------------------%

function description_edit_Callback(hObject, eventdata, handles)
%This was changed to a list!
contents = cellstr(get(hObject,'String'));
expDescrip = contents{get(hObject,'Value')};

%first, clear all feilds
for conds = 1:handles.lines
    eval(['set(handles.condition',num2str(conds),',''string'','''')'])
    eval(['set(handles.condName',num2str(conds),',''string'','''')'])
    eval(['set(handles.description',num2str(conds),',''string'','''')'])
    eval(['set(handles.trialnum',num2str(conds),',''string'','''')'])
    eval(['set(handles.OGcheck',num2str(conds),',''value'',',num2str(0),')'])
end

%second, populate feilds based on experiment description entered.
handles=experimentDetails(expDescrip,handles);
numofconds_Callback(handles.numofconds, eventdata, handles)

guidata(hObject,handles)


function name_edit_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of name_edit as text
%        str2double(get(hObject,'String')) returns contents of name_edit as a double


% --- Executes on selection change in month_list.
function month_list_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns month_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from month_list

function day_edit_Callback(hObject, eventdata, handles)

function year_edit_Callback(hObject, eventdata, handles)

function note_edit_Callback(hObject, eventdata, handles)



%-------------------------Subject Info------------------------------%


function subID_edit_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of subID_edit as text
%        str2double(get(hObject,'String')) returns contents of subID_edit as a double

% --- Executes on selection change in DOBmonth_list.
function DOBmonth_list_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns DOBmonth_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from DOBmonth_list

function DOBday_edit_Callback(hObject, eventdata, handles)

function DOByear_edit_Callback(hObject, eventdata, handles)

% --- Executes on selection change in gender_list.
function gender_list_Callback(hObject, eventdata, handles)

% --- Executes on selection change in domleg_list.
function domleg_list_Callback(hObject, eventdata, handles)

% --- Executes on selection change in domhand_list.
function domhand_list_Callback(hObject, eventdata, handles)

function height_edit_Callback(hObject, eventdata, handles)

height = str2double(get(hObject, 'String'));
guidata(hObject,handles)

function weight_edit_Callback(hObject, eventdata, handles)

weight = str2double(get(hObject, 'String'));
guidata(hObject,handles)


%------------------------Data Info------------------------------%

% --- Executes on button press in browse.
function browse_Callback(hObject, eventdata, handles)
handles.folder_location = uigetdir; %this is how the output_fcn knows where the folder is
if ~handles.folder_location==0
    set(handles.c3dlocation,'string',handles.folder_location)
end
guidata(hObject,handles);

function c3dlocation_Callback(hObject, eventdata, handles)
handles.folder_location = get(hObject,'string');
guidata(hObject,handles)

function basefile_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of basefile as text
%        str2double(get(hObject,'String')) returns contents of basefile as a double

function numoftrials_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of numoftrials as text
%        str2double(get(hObject,'String')) returns contents of numoftrials as a double
numoftrials = str2double(get(hObject,'String'));

function numofconds_Callback(hObject, eventdata, handles)
numofconds = str2double(get(hObject,'String'));

%first, disable ALL
for conds = 1:handles.lines
    eval(['set(handles.condition',num2str(conds),',''enable'',''off'')'])
    eval(['set(handles.condName',num2str(conds),',''enable'',''off'')'])
    eval(['set(handles.description',num2str(conds),',''enable'',''off'')'])
    eval(['set(handles.trialnum',num2str(conds),',''enable'',''off'')'])
    eval(['set(handles.OGcheck',num2str(conds),',''enable'',''off'')'])
end
%second, check number eneterd is valid
if isnan(numofconds) || numofconds<0 || numofconds>15
    h_error=errordlg('Please enter a number between 1 and 15','Condition Number Error');
    set(h_error,'color',[0.8 0.8 0.8])
    waitfor(h_error)
    uicontrol(hObject)
    return
end

%third, enable based on number of conditions entered
for conds = 1:numofconds
    eval(['set(handles.condition',num2str(conds),',''enable'',''on'')'])
    eval(['set(handles.condName',num2str(conds),',''enable'',''on'')'])
    eval(['set(handles.description',num2str(conds),',''enable'',''on'')'])
    eval(['set(handles.trialnum',num2str(conds),',''enable'',''on'')'])
    eval(['set(handles.OGcheck',num2str(conds),',''enable'',''on'')'])
end

% --- Executes on button press in kinematic_check.
function kinematic_check_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of kinematic_check

% --- Executes on button press in force_check.
function force_check_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of force_check

% --- Executes on button press in emg_check.
function emg_check_Callback(hObject, eventdata, handles)

state = get(hObject,'Value');

if state
    set(handles.secfile_browse,'enable','on')
    set(handles.secfileloc,'enable','on')
else
    set(handles.secfile_browse,'enable','off')
    set(handles.secfileloc,'enable','off')
end

% --- Executes on button press in secfile_browse.
function secfile_browse_Callback(hObject, eventdata, handles)
handles.secfolder_location = uigetdir; %this is how the output_fcn knows where the folder is
if ~handles.secfolder_location==0
    set(handles.secfileloc,'string',handles.secfolder_location)
end
guidata(hObject,handles);

function secfileloc_Callback(hObject, eventdata, handles) %runs if folder is input manually by subject
handles.secfolder_location = get(hObject,'string');
guidata(hObject,handles)

%---------------------------Trial Info--------------------------------%

function condition1_Callback(hObject, eventdata, handles)
function condName1_Callback(hObject, eventdata, handles)
function description1_Callback(hObject, eventdata, handles)
function trialnum1_Callback(hObject, eventdata, handles)
% --- Executes on button press in OGcheck1.
function OGcheck1_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of OGcheck1



function condition2_Callback(hObject, eventdata, handles)
function condName2_Callback(hObject, eventdata, handles)
function description2_Callback(hObject, eventdata, handles)
function trialnum2_Callback(hObject, eventdata, handles)
function OGcheck2_Callback(hObject, eventdata, handles)



function condition3_Callback(hObject, eventdata, handles)
function condName3_Callback(hObject, eventdata, handles)
function description3_Callback(hObject, eventdata, handles)
function trialnum3_Callback(hObject, eventdata, handles)
function OGcheck3_Callback(hObject, eventdata, handles)


function condition4_Callback(hObject, eventdata, handles)
function condName4_Callback(hObject, eventdata, handles)
function description4_Callback(hObject, eventdata, handles)
function trialnum4_Callback(hObject, eventdata, handles)
function OGcheck4_Callback(hObject, eventdata, handles)


function condition5_Callback(hObject, eventdata, handles)
function condName5_Callback(hObject, eventdata, handles)
function description5_Callback(hObject, eventdata, handles)
function trialnum5_Callback(hObject, eventdata, handles)
function OGcheck5_Callback(hObject, eventdata, handles)


function condition6_Callback(hObject, eventdata, handles)
function condName6_Callback(hObject, eventdata, handles)
function description6_Callback(hObject, eventdata, handles)
function trialnum6_Callback(hObject, eventdata, handles)
function OGcheck6_Callback(hObject, eventdata, handles)


function condition7_Callback(hObject, eventdata, handles)
function condName7_Callback(hObject, eventdata, handles)
function description7_Callback(hObject, eventdata, handles)
function trialnum7_Callback(hObject, eventdata, handles)
function OGcheck7_Callback(hObject, eventdata, handles)


function condition8_Callback(hObject, eventdata, handles)
function condName8_Callback(hObject, eventdata, handles)
function description8_Callback(hObject, eventdata, handles)
function trialnum8_Callback(hObject, eventdata, handles)
function OGcheck8_Callback(hObject, eventdata, handles)


function condition9_Callback(hObject, eventdata, handles)
function condName9_Callback(hObject, eventdata, handles)
function description9_Callback(hObject, eventdata, handles)
function trialnum9_Callback(hObject, eventdata, handles)
function OGcheck9_Callback(hObject, eventdata, handles)


function condition10_Callback(hObject, eventdata, handles)
function condName10_Callback(hObject, eventdata, handles)
function description10_Callback(hObject, eventdata, handles)
function trialnum10_Callback(hObject, eventdata, handles)
function OGcheck10_Callback(hObject, eventdata, handles)


function condition11_Callback(hObject, eventdata, handles)
function condName11_Callback(hObject, eventdata, handles)
function description11_Callback(hObject, eventdata, handles)
function trialnum11_Callback(hObject, eventdata, handles)
function OGcheck11_Callback(hObject, eventdata, handles)



function condition12_Callback(hObject, eventdata, handles)
function condName12_Callback(hObject, eventdata, handles)
function description12_Callback(hObject, eventdata, handles)
function trialnum12_Callback(hObject, eventdata, handles)
function OGcheck12_Callback(hObject, eventdata, handles)



function condition13_Callback(hObject, eventdata, handles)
function condName13_Callback(hObject, eventdata, handles)
function description13_Callback(hObject, eventdata, handles)
function trialnum13_Callback(hObject, eventdata, handles)
function OGcheck13_Callback(hObject, eventdata, handles)


function condition14_Callback(hObject, eventdata, handles)
function condName14_Callback(hObject, eventdata, handles)
function description14_Callback(hObject, eventdata, handles)
function trialnum14_Callback(hObject, eventdata, handles)
function OGcheck14_Callback(hObject, eventdata, handles)


function condition15_Callback(hObject, eventdata, handles)
function condName15_Callback(hObject, eventdata, handles)
function description15_Callback(hObject, eventdata, handles)
function trialnum15_Callback(hObject, eventdata, handles)
function OGcheck15_Callback(hObject, eventdata, handles)

%---------------------Save as / Okay Button--------------------------%

function saveloc_edit_Callback(hObject, eventdata, handles)
handles.save_folder = get(hObject,'string');
guidata(hObject,handles)


% --- Executes on button press in save_browse.
function save_browse_Callback(hObject, eventdata, handles)
handles.save_folder = uigetdir;
if ~handles.save_folder==0
    set(handles.saveloc_edit,'string',handles.save_folder);
end
guidata(hObject,handles)

% --- Executes on button press in ok_button.
function ok_button_Callback(hObject, eventdata, handles)

handles.info=errorProofInfo(handles);
if handles.info.bad
    return
else
    guidata(hObject,handles)
    uiresume(handles.figure1);
end

% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles)
    
[file,path]=uigetfile('*.mat','Choose subject handles file');

if file==0
    %do nothing
else    
    eval(['aux=load('''  path file ''');'])
    fieldNames=fields(aux);
    eval(['subInfo=aux.' fieldNames{1} ';']);
    %TO DO: check that file is correct
    
    out.bad=0;

% -- Experiment Info
descriptionContents=cellstr(get(handles.description_edit,'string'));
set(handles.description_edit,'Value',find(strcmp(descriptionContents,subInfo.ExpDescription)));
set(handles.name_edit,'string',subInfo.experimenter);
monthContents = cellstr(get(handles.month_list,'String'));
set(handles.month_list,'Value',find(strcmp(monthContents,subInfo.month)));
set(handles.day_edit,'string',subInfo.day);
set(handles.year_edit,'string',subInfo.year);
set(handles.note_edit,'string',subInfo.exp_obs);
% -- Subject Info
set(handles.subID_edit,'string',subInfo.ID);
DOBmonthContents = cellstr(get(handles.DOBmonth_list,'String'));
set(handles.DOBmonth_list,'Value',find(strcmp(DOBmonthContents,subInfo.DOBmonth)));
set(handles.DOBday_edit,'string',subInfo.DOBday);
set(handles.DOByear_edit,'string',subInfo.DOByear);
genderContents = cellstr(get(handles.gender_list,'String'));
set(handles.gender_list,'Value',find(strcmp(genderContents,subInfo.gender)));
domlegContents = cellstr(get(handles.domleg_list,'String'));
set(handles.domleg_list,'Value',find(strcmp(domlegContents,subInfo.domleg)));
domhandContents = cellstr(get(handles.domhand_list,'String'));
set(handles.domhand_list,'Value',find(strcmp(domhandContents,subInfo.domhand)));
set(handles.height_edit,'string',subInfo.height);
set(handles.weight_edit,'string',subInfo.weight);
% -- Data Info
handles.folder_location=subInfo.dir_location;
set(handles.basefile,'string',subInfo.basename);
set(handles.numofconds,'string',subInfo.numofconds);
numofconds_Callback(handles.numofconds,eventdata,handles)
set(handles.kinematic_check,'Value',subInfo.kinematics);
set(handles.force_check,'Value',subInfo.forces);
set(handles.emg_check,'Value',subInfo.EMGs);
handles.secfolder_location=subInfo.secdir_location;
% -- Trial Info
for c = 1:subInfo.numofconds
    condNum=subInfo.cond(c);
    eval(['set(handles.condition',num2str(c),',''string'',',num2str(condNum),')']);
    eval(['set(handles.condName',num2str(c),',''string'',subInfo.conditionNames{',num2str(condNum),'})']);
    eval(['set(handles.description',num2str(c),',''string'',subInfo.conditionDescriptions{',num2str(condNum),'})']);
    trialnums=subInfo.trialnums{condNum};
    if length(trialnums)>2 && ~any(diff(trialnums)>1)
        eval(['set(handles.trialnum',num2str(c),',''string'',''',num2str(trialnums(1)),':',num2str(trialnums(end)),''')']);
    else
        eval(['set(handles.trialnum',num2str(c),',''string'',''',num2str(trialnums),''')']);
    end    
    eval(['set(handles.OGcheck',num2str(c),',''Value'',subInfo.isOverGround(',num2str(condNum),'))']);
end
% --  save location
handles.save_folder=subInfo.save_folder;

    
guidata(hObject,handles)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --------------------------- CreateFcns -------------------------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- These fcns execute during object creation, after setting all properties.

% Hint: controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
function description_edit_CreateFcn(hObject, eventdata, handles)

set(hObject,'String',{'','Old Abrupt','Old Abrupt Second Visit','Old Abrupt No Catch','Old Abrupt Self Selected','Old Gradual','Old Gradual No Catch','Young Abrupt','Young Abrupt Second Visit','Young Gradual','Young Gradual No Catch','Young Abrupt Self Selected','Young Gradual Self Selected', '0002: Distraction', '0002: Old'})

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function name_edit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function month_list_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function day_edit_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function year_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function subID_edit_CreateFcn(hObject, ~, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function DOBmonth_list_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function DOBday_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function DOByear_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function gender_list_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function domleg_list_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function domhand_list_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function height_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function weight_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition5_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName5_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description5_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum5_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition7_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName7_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description7_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum7_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition8_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName8_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description8_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum8_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition9_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName9_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description9_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum9_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition10_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName10_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description10_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum10_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition11_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName11_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description11_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum11_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum12_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition13_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName13_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description13_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum13_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition14_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName14_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description14_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum14_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function condition15_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function condName15_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function description15_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function trialnum15_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function c3dlocation_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function numoftrials_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function numofconds_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function note_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function saveloc_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function basefile_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function secfileloc_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%----------------------------ButtonDownFcns-----------------------------%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over description_edit.

function day_edit_ButtonDownFcn(hObject, eventdata, handles)
% Toggel the "Enable" state to ON and clear letters
set(hObject, 'Enable', 'On');
set(hObject,'String',[])
% Create UI control
uicontrol(handles.day_edit);

function name_edit_ButtonDownFcn(hObject, eventdata, handles)
% Toggel the "Enable" state to ON and clear letters
set(hObject, 'Enable', 'On');
set(hObject,'String',[])
% Create UI control
uicontrol(handles.name_edit);

function year_edit_ButtonDownFcn(hObject, eventdata, handles)
% Toggel the "Enable" state to ON and clear letters
set(hObject, 'Enable', 'On');
set(hObject,'String',[])
% Create UI control
uicontrol(handles.year_edit);

function note_edit_ButtonDownFcn(hObject, eventdata, handles)
% Toggel the "Enable" state to ON and clear letters
set(hObject, 'Enable', 'On');
set(hObject,'String',[])
% Create UI control
uicontrol(handles.note_edit);

function subID_edit_ButtonDownFcn(hObject, eventdata, handles)
% Toggel the "Enable" state to ON and clear letters
set(hObject, 'Enable', 'On');
set(hObject,'String',[])
% Create UI control
uicontrol(handles.subID_edit);

function DOBday_edit_ButtonDownFcn(hObject, eventdata, handles)
% Toggel the "Enable" state to ON and clear letters
set(hObject, 'Enable', 'On');
set(hObject,'String',[])
% Create UI control
uicontrol(handles.DOBday_edit);

function DOByear_edit_ButtonDownFcn(hObject, eventdata, handles)
% Toggel the "Enable" state to ON and clear letters
set(hObject, 'Enable', 'On');
set(hObject,'String',[])
% Create UI control
uicontrol(handles.DOByear_edit);

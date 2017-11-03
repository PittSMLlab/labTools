function varargout = uiCreateStudy(varargin)
% UICREATESTUDY comments go here
%
% See also: 

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


% --- Executes just before uiCreateStudy is made visible.
function uiCreateStudy_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to uiCreateStudy (see VARARGIN)

% Choose default command line output for uiCreateStudy
handles.output = hObject;
handles.studyData=struct;

%find all files in pwd
files=what('./'); 
fileList=files.mat;
paramFiles={};

for i=1:length(fileList)
    %find files in pwd that are (Subject)param.mat files
    aux1=strfind(lower(fileList{i}),'params');
    if ~isempty(aux1)
        paramFiles{end+1}=fileList{i};
    end    
end

set(handles.allSubList,'string',paramFiles')
set(handles.allSubList,'max',length(paramFiles))

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes uiCreateStudy wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = uiCreateStudy_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in allSubList.
function allSubList_Callback(hObject, eventdata, handles)
% hObject    handle to allSubList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns allSubList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from allSubList


% --- Executes on selection change in selectSubList.
function selectSubList_Callback(hObject, eventdata, handles)
% hObject    handle to selectSubList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns selectSubList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from selectSubList

% --- Executes on selection change in groupList.
function groupList_Callback(hObject, eventdata, handles)
% hObject    handle to groupList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns groupList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from groupList


function groupNameEdit_Callback(hObject, eventdata, handles)
% hObject    handle to groupNameEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of groupNameEdit as text
%        str2double(get(hObject,'String')) returns contents of groupNameEdit as a double



% -------------------- Add/Remove Subject Buttons ----------------------- % 

function addButton_Callback(hObject, eventdata, handles)
% hObject    handle to addButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get current state of selected sub list
selectSubContents = get(handles.selectSubList,'string');

%get new subjects to add to list
contents=get(handles.allSubList,'String');
inds=get(handles.allSubList,'value');
newSelectSubs=contents(inds);
contents(inds)=[]; %remove subjects from all sub list

newSelectSubList=sort([selectSubContents; newSelectSubs]);

set(handles.selectSubList,'String',newSelectSubList)
set(handles.allSubList,'String',contents)
set(handles.allSubList,'Value',[])

guidata(hObject, handles);

% --- Executes on button press in removeButton.
function removeButton_Callback(hObject, eventdata, handles)

%get current state of all sub list
allSubContents = get(handles.allSubList,'string');

%get subjects to remove from selected list
contents=get(handles.selectSubList,'String');
inds=get(handles.selectSubList,'Value');
removeSubs=contents(inds);
contents(inds)=[]; %remove subjects from select sub list

newAllSubList=sort([allSubContents; removeSubs]);

set(handles.allSubList,'String',newAllSubList)
set(handles.selectSubList,'String',contents)
set(handles.selectSubList,'Value',[])

guidata(hObject, handles);



% --- Executes on button press in addGroupButton.
function addGroupButton_Callback(hObject, eventdata, handles)

fileList=get(handles.selectSubList,'String');
nSubs=length(fileList);
sub=struct;
%get group
group=get(handles.groupNameEdit,'string');
abbrevGroup=group(ismember(group,['A':'Z' 'a':'z' '1':'9'])); %remove non-alphanumeric characters
if isempty(abbrevGroup)
    abbrevGroup='NoDescription';
end

for i=1:nSubs   
%     aux1=strfind(lower(fileList{i}),'params');
%     subID=fileList{i}(1:(aux1-1));
    load(fileList{i}); 
    subID=adaptData.subData.ID; %I think this is more appropriate.-Pablo

    sub.IDs(i)= {subID};
    sub.adaptData(i)={adaptData};    
end

handles.studyData.(abbrevGroup)=groupAdaptationData(sub.IDs,sub.adaptData);

set(handles.selectSubList,'String',[])

groupContents=get(handles.groupList,'String');
newGroupContents=[groupContents; {group}];
set(handles.groupList,'String',newGroupContents)

guidata(hObject, handles);


function saveButton_Callback(hObject, eventdata, handles)

[file,path] = uiputfile('*.mat','Save Study As');
studyData=handles.studyData;
save([path file],'studyData','-v7.3')

close(handles.figure1)







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

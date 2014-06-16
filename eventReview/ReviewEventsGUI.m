function varargout = ReviewEventsGUI(varargin)
% revieweventsgui MATLAB code for ReviewEventsGUI.fig
%      ReviewEVENTSGUI, by itself, creates a new ReviewEVENTSGUI or raises the existing
%      singleton*.
%
%      H = revieweventsgui returns the handle to a new revieweventsgui or the handle to
%      the existing singleton*.
%
%      revieweventsgui('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in revieweventsgui.M with the given input arguments.
%
%      revieweventsgui('Property','Value',...) creates a new revieweventsgui or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ReviewEventsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ReviewEventsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ReviewEventsGUI

% Last Modified by GUIDE v2.5 05-Apr-2014 16:36:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @ReviewEventsGUI_OpeningFcn, ...
    'gui_OutputFcn',  @ReviewEventsGUI_OutputFcn, ...
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
end

% --- Executes just before ReviewEventsGUI is made visible.
function ReviewEventsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ReviewEventsGUI (see VARARGIN)

% Choose default command line output for ReviewEventsGUI
handles.output = hObject;
handles.changed=false;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ReviewEventsGUI wait for user response (see UIRESUME)
% uiwait(handles.GUI_window);
end

% --- Outputs from this function are returned to the command line.
function varargout = ReviewEventsGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end


%----------------------------------------------------------------
%First step: set directory name to load files from. By default it is the
%current dir: './'

function directory_Callback(hObject, eventdata, handles)
% hObject    handle to directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of directory as text
%        str2double(get(hObject,'String')) returns contents of directory as a double
handles.Dir = get(hObject, 'String');

%checks if Sub is a file
if exist(handles.Dir,'dir')
    set(handles.subject,'Enable','on');
else
    set(handles.directory,'String', 'Try Again:')
    % Give the edit text box focus so user can correct the error
    uicontrol(hObject)
end
guidata(hObject, handles);
end


% --- Executes during object creation, after setting all properties.
function directory_CreateFcn(hObject, eventdata, handles)
% hObject    handle to directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
    set(hObject,'String','./');
end
end
%-------------------------------------------------------------------

%Second, the subject filename needs to be entered.

% --- Executes during object creation, after setting all properties.
function subject_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function subject_Callback(hObject, eventdata, handles)
% hObject    handle to subject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Disable everything
set(handles.plot_button,'Enable','off');
set(handles.next_button,'Enable','off');
set(handles.back_button,'Enable','off');
set(handles.delete_button,'Enable','off');
set(handles.save_button,'Enable','off');
set(handles.add_button,'Enable','off');
set(handles.BPdataType,'Enable','off');
set(handles.BPfield,'Enable','off');
set(handles.TPdataType,'Enable','off');
set(handles.TPfield,'Enable','off');
set(handles.condMenu, 'Enable','off');
set(handles.trialMenu,'Enable','off');
drawnow

global expData
handles.filename = [get(hObject, 'String'),'.mat'];
%checks if Sub is a file
if exist([handles.Dir handles.filename],'file')
    eval(['aux=load('''  handles.Dir handles.filename ''');']) %.mat file can only contain 1 variable, of the experimentData type
    fieldNames=fields(aux);
    handles.varName=fieldNames{1};
    
    eval(['expData=aux.' fieldNames{1} ';']);
    if isa(expData,'experimentData') && expData.isProcessed %if not processed, there will be no events to review
        set(handles.subject_text,'String', 'Filename')
        %Enable and init all menus
        set(handles.plot_button,'Enable','on');
        set(handles.next_button,'Enable','on');
        set(handles.back_button,'Enable','on');
        set(handles.delete_button,'Enable','on');
        set(handles.save_button,'Enable','on');
        set(handles.add_button,'Enable','on');
        set(handles.BPdataType,'Enable','on');
        set(handles.BPfield,'Enable','on');
        set(handles.TPdataType,'Enable','on');
        set(handles.TPfield,'Enable','on');
        
        
        %Enable and initialize condition menu:
        set(handles.condMenu, 'Enable','on');
        set(handles.condMenu, 'String',expData.metaData.conditionsDescription);
        set(handles.condMenu, 'Value',1);
        set(handles.trialMenu,'Value',1);
        guidata(hObject, handles);
        condMenu_Callback(hObject, [], handles);
        
    else
        set(handles.subject_text,'String', 'Try Again:')
        % Give the edit text box focus so user can correct the error
        uicontrol(hObject)
        guidata(hObject, handles)
    end
else
    set(handles.subject_text,'String', 'Try Again:')
    set(handles.condMenu,'Enable','off')
    % Give the edit text box focus so user can correct the error
    uicontrol(hObject)
    guidata(hObject, handles)
end

end
%---------------------------------------------------------------------
%Then: select condition:

% --- Executes on selection change in condMenu.
function condMenu_Callback(hObject, eventdata, handles)
% hObject    handle to condMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global expData
handles.Condition = get(handles.condMenu,'Value');
set(handles.trialMenu, 'Enable','on');
s={};
for i=1:length(expData.metaData.trialsInCondition{handles.Condition})
    s{i}=num2str(expData.metaData.trialsInCondition{handles.Condition}(i));
end
set(handles.trialMenu, 'String',s);
if get(handles.trialMenu,'Value')>length(get(handles.trialMenu,'String'))
    set(handles.trialMenu, 'Value',1);
end
guidata(hObject, handles)
trialMenu_Callback(handles.trialMenu, eventdata, handles);
end

% Hints: contents = cellstr(get(hObject,'String')) returns condMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from condMenu


% --- Executes during object creation, after setting all properties.
function condMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to condMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

%---------------------------------------------------------------------
%Then: select specific trial:
% --- Executes on selection change in trialMenu.
function trialMenu_Callback(hObject, eventdata, handles)
% hObject    handle to trialMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns trialMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from trialMenu
global expData
handles.Trial= expData.metaData.trialsInCondition{handles.Condition}(get(handles.trialMenu,'Value'));
handles.TSlist={};
handles.trialEvents=expData.data{handles.Trial}.gaitEvents;
set(handles.write,'Enable','off')
fieldList=fields(expData.data{handles.Trial});
for i=1:length(fieldList)
    eval(['curField=expData.data{handles.Trial}.' fieldList{i} ';']);
    if isa(curField,'labTimeSeries')
        handles.TSlist{end+1}=fieldList{i};
    end
end
clear curField fieldList
set(handles.BPdataType,'String',handles.TSlist);
set(handles.TPdataType,'String',handles.TSlist);
if get(handles.BPdataType,'Value')>length(get(handles.BPdataType,'String'))
    set(handles.BPdataType,'Value',1);
end
if get(handles.TPdataType,'Value')>length(get(handles.TPdataType,'String'))
    set(handles.TPdataType,'Value',1);
end
guidata(hObject, handles)
BPdataType_Callback(handles.BPdataType, eventdata, handles);
TPdataType_Callback(handles.TPdataType, eventdata, handles);
guidata(hObject, handles)
end

% --- Executes during object creation, after setting all properties.
function trialMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trialMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

%--------------------------------------------------------------------

% --- Executes on selection change in TPfield.
function TPfield_Callback(hObject, eventdata, handles)
% hObject    handle to TPfield (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns TPfield contents as cell array
%        contents{get(hObject,'Value')} returns selected item from TPfield
guidata(hObject, handles)
plot_button_Callback(handles.plot_button,eventdata,handles)
end


% --- Executes during object creation, after setting all properties.
function TPfield_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TPfield (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on selection change in TPdataType.
function TPdataType_Callback(hObject, eventdata, handles)
% hObject    handle to TPdataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns TPdataType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from TPdataType
global expData
eval(['curTS=expData.data{handles.Trial}.' handles.TSlist{get(handles.TPdataType,'Value')} ';']);
set(handles.TPfield,'String',curTS.labels);
if get(handles.TPfield,'Value')>length(get(handles.TPfield,'String'))
    set(handles.TPfield,'Value',1);
end
clear curTS
handles.test=1;
guidata(hObject, handles)
TPfield_Callback(handles.TPfield, eventdata, handles)
end


% --- Executes during object creation, after setting all properties.
function TPdataType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TPdataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on selection change in BPdataType.
function BPdataType_Callback(hObject, eventdata, handles)
% hObject    handle to BPdataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns BPdataType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from BPdataType
global expData
eval(['curTS=expData.data{handles.Trial}.' handles.TSlist{get(handles.BPdataType,'Value')} ';']);
set(handles.BPfield,'String',curTS.labels);
if get(handles.BPfield,'Value')>length(get(handles.BPfield,'String'))
    set(handles.BPfield,'Value',min([4,length(curTS.labels)]));
end
clear curTS
guidata(hObject, handles)
BPfield_Callback(handles.BPfield, eventdata, handles)
end

% --- Executes during object creation, after setting all properties.
function BPdataType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BPdataType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on selection change in BPfield.
function BPfield_Callback(hObject, eventdata, handles)
% hObject    handle to BPfield (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns BPfield contents as cell array
%        contents{get(hObject,'Value')} returns selected item from BPfield
guidata(hObject, handles)
plot_button_Callback(handles.plot_button,eventdata,handles)
end


% --- Executes during object creation, after setting all properties.
function BPfield_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BPfield (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


%BUTTONS:-----------------------------------------------------------

% --- Executes on button press in plot_button.
function plot_button_Callback(hObject, eventdata, handles)
% hObject    handle to plot_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
linkaxes([handles.axes1,handles.axes2],'x')
%Events to plot:
global expData
events=handles.trialEvents;
for i=1:length(events.labels)
    data=events.getDataAsVector(events.labels{i});
    eval([events.labels{i} 'times=events.Time(data==1);']) 
end

%Top plot:
%Get data to plot
TPvalue=get(handles.TPfield,'Value');
eval(['TPlabel=expData.data{handles.Trial}.' handles.TSlist{get(handles.TPdataType,'Value')} '.labels{TPvalue};']);
eval(['LdataTS=expData.data{handles.Trial}.' handles.TSlist{get(handles.TPdataType,'Value')} '.getDataAsTS(''L' TPlabel(2:end) ''');' ]);
eval(['RdataTS=expData.data{handles.Trial}.' handles.TSlist{get(handles.TPdataType,'Value')} '.getDataAsTS(''R' TPlabel(2:end) ''');' ]);
eval(['time=expData.data{handles.Trial}.' handles.TSlist{get(handles.TPdataType,'Value')} '.Time;' ]);

%Do plot
%Get subplot
set(handles.axes1,'nextplot','replace')
plot(handles.axes1,time,LdataTS.Data,'b');
set(handles.axes1,'nextplot','add')
plot(handles.axes1,time,RdataTS.Data,'r');
%Overlay events
plot(handles.axes1,LHStimes,LdataTS.getSample(LHStimes),'kx','LineWidth',2)
plot(handles.axes1,RHStimes,RdataTS.getSample(RHStimes),'ks','LineWidth',2)
plot(handles.axes1,RTOtimes,RdataTS.getSample(RTOtimes),'ko','LineWidth',2)
plot(handles.axes1,LTOtimes,LdataTS.getSample(LTOtimes),'k*','LineWidth',2)

%Bottom plot:
%Get data to plot
BPvalue=get(handles.BPfield,'Value');
eval(['BPlabel=expData.data{handles.Trial}.' handles.TSlist{get(handles.BPdataType,'Value')} '.labels{BPvalue};']);
eval(['LdataTS=expData.data{handles.Trial}.' handles.TSlist{get(handles.BPdataType,'Value')} '.getDataAsTS(''L' BPlabel(2:end) ''');' ]);
eval(['RdataTS=expData.data{handles.Trial}.' handles.TSlist{get(handles.BPdataType,'Value')} '.getDataAsTS(''R' BPlabel(2:end) ''');' ]);
eval(['time=expData.data{handles.Trial}.' handles.TSlist{get(handles.BPdataType,'Value')} '.Time;' ]);
%Do plot
set(handles.axes2,'nextplot','replace')
plot(handles.axes2,time,LdataTS.Data,'b');
set(handles.axes2,'nextplot','add')
plot(handles.axes2,time,RdataTS.Data,'r');
%Overlay events
plot(handles.axes2,LHStimes,LdataTS.getSample(LHStimes),'kx','LineWidth',2)
plot(handles.axes2,RHStimes,RdataTS.getSample(RHStimes),'ks','LineWidth',2)
plot(handles.axes2,RTOtimes,RdataTS.getSample(RTOtimes),'ko','LineWidth',2)
plot(handles.axes2,LTOtimes,LdataTS.getSample(LTOtimes),'k*','LineWidth',2)
legend('Left','Right','LHS','RHS','RTO','LTO')
%Clear vars:
clear RHS* LHS* LTO* RTO* events time
drawnow
guidata(hObject, handles)
end


% --- Executes on button press in delete_button.
function delete_button_Callback(hObject, eventdata, handles)
% hObject    handle to delete_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Select event
axes(handles.axes1)
[x,~]=ginput(1);

%Find closest event
allEventsIndexes=find(sum(handles.trialEvents.Data,2)>0);
deltaT=handles.trialEvents.Time(allEventsIndexes)-x;
[~,selectedEventTimeIndex]=min(deltaT.^2);
selectedEventIndex=allEventsIndexes(selectedEventTimeIndex);

%Eliminate it from handles.trialEvents
handles.trialEvents.Data(selectedEventIndex,:)=false;

%Re-plot
guidata(hObject, handles)
plot_button_Callback(handles.plot_button, eventdata, handles)

end

% --- Executes on button press in add_button.
function add_button_Callback(hObject, eventdata, handles)
% hObject    handle to add_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Ask subject to select event type: RHS, LHS, LTO, RTO
set(handles.eventType,'String',handles.trialEvents.getLabels)
set(handles.eventType,'Enable','on')

%Now the subject should select an event Type, so the function continues on
%eventType_callback
guidata(hObject, handles)

end

% --- Executes on selection change in eventType.
function eventType_Callback(hObject, eventdata, handles)
% hObject    handle to eventType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns eventType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from eventType

%Select location
[x,~]=ginput(1);

%create new event in handles.trialEvents
[~,closestTimeIdx]=min((handles.trialEvents.Time-x).^2);
handles.trialEvents.Data(closestTimeIdx,get(handles.eventType,'Value'))=true;

%Re-plot
guidata(hObject, handles)
plot_button_Callback(handles.plot_button, eventdata, handles)

%Disable this
set(handles.eventType,'Enable','off');
guidata(hObject, handles)
end


% --- Executes during object creation, after setting all properties.
function eventType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to eventType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global expData
expData.data{handles.Trial}.gaitEvents=handles.trialEvents;
handles.changed=true;
set(handles.write,'Enable','on');
guidata(hObject, handles)
end



% --- Executes on button press in next_button.
function next_button_Callback(hObject, eventdata, handles)
% hObject    handle to next_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if length(get(handles.trialMenu,'String'))>get(handles.trialMenu,'Value')
    set(handles.trialMenu,'Value',get(handles.trialMenu,'Value')+1); %Add one to current trial, does this update what the GUI shows?
    guidata(hObject, handles)
    trialMenu_Callback(handles.trialMenu, eventdata, handles)
elseif get(handles.condMenu,'Value')<length(get(handles.condMenu,'String'))
    set(handles.condMenu,'Value',get(handles.condMenu,'Value')+1);
    set(handles.trialMenu,'Value',1);
    guidata(hObject, handles)
    condMenu_Callback(handles.condMenu, eventdata, handles)
end
end


% --- Executes on button press in back_button.
function back_button_Callback(hObject, eventdata, handles)
% hObject    handle to back_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.trialMenu,'Value')>1
    set(handles.trialMenu,'Value',get(handles.trialMenu,'Value')-1); %Add one to current trial, does this update what the GUI shows?
    guidata(hObject, handles)
    trialMenu_Callback(handles.trialMenu, eventdata, handles)
elseif get(handles.condMenu,'Value')>1
    set(handles.condMenu,'Value',get(handles.condMenu,'Value')-1);
    set(handles.trialMenu,'Value',length(get(handles.trialMenu,'String')));
    guidata(hObject, handles)
    condMenu_Callback(handles.condMenu, eventdata, handles)
end
end


%------------------CLOSING---------------------------------
% --- Executes when user attempts to close GUI_window.
function GUI_window_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to GUI_window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global expData
%Disable everything
set(handles.plot_button,'Enable','off');
set(handles.next_button,'Enable','off');
set(handles.back_button,'Enable','off');
set(handles.delete_button,'Enable','off');
set(handles.save_button,'Enable','off');
set(handles.add_button,'Enable','off');
set(handles.BPdataType,'Enable','off');
set(handles.BPfield,'Enable','off');
set(handles.TPdataType,'Enable','off');
set(handles.TPfield,'Enable','off');
set(handles.condMenu, 'Enable','off');
set(handles.directory,'Enable','off');
set(handles.subject,'Enable','off');
set(handles.write,'Enable','off');
set(handles.write,'String', 'Writing...');
drawnow
if handles.changed
    eval([handles.varName '=expData;']); %Assigning same var name
    eval(['save ' handles.Dir handles.filename ' ' handles.varName]); %Saving with same var name
    handles.changed=false;
end
guidata(hObject, handles);
% Hint: delete(hObject) closes the figure
delete(handles.output);
end





% --- Executes on button press in write.
function write_Callback(hObject, eventdata, handles)
global expData
% hObject    handle to write (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Disable everything
set(handles.plot_button,'Enable','off');
set(handles.next_button,'Enable','off');
set(handles.back_button,'Enable','off');
set(handles.delete_button,'Enable','off');
set(handles.save_button,'Enable','off');
set(handles.add_button,'Enable','off');
set(handles.BPdataType,'Enable','off');
set(handles.BPfield,'Enable','off');
set(handles.TPdataType,'Enable','off');
set(handles.TPfield,'Enable','off');
set(handles.condMenu, 'Enable','off');
set(handles.directory,'Enable','off');
set(handles.subject,'Enable','off');
set(handles.write,'Enable','off');
set(handles.write,'String', 'Writing...');
set(handles.trialMenu,'Enable','off');
drawnow
        

        
%Write to disk
eval([handles.varName '=expData;']); %Assigning same var name
eval(['save ' handles.Dir handles.filename ' ' handles.varName]); %Saving with same var name


%Enable everything
set(handles.plot_button,'Enable','on');
set(handles.next_button,'Enable','on');
set(handles.back_button,'Enable','on');
set(handles.delete_button,'Enable','on');
set(handles.save_button,'Enable','on');
set(handles.add_button,'Enable','on');
set(handles.BPdataType,'Enable','on');
set(handles.BPfield,'Enable','on');
set(handles.TPdataType,'Enable','on');
set(handles.TPfield,'Enable','on');
set(handles.condMenu, 'Enable','on');
set(handles.directory,'Enable','on');
set(handles.subject,'Enable','on');
set(handles.write,'String', 'Write to disk');
set(handles.trialMenu,'Enable','on');
guidata(hObject, handles);

end

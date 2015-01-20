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

% Last Modified by GUIDE v2.5 04-Aug-2014 14:26:14

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

% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes just before ReviewEventsGUI is made visible.
function ReviewEventsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% varargin   command line arguments to ReviewEventsGUI (see VARARGIN)

handles.output=hObject;
handles.changed=false;
handles.backButtonFlag=false;

%Initialize with subject options if there are .mat files in current
%directory
files=what;
subFileList={};
if isempty(files.mat)
    %do nothing
else
    for i=1:length(files.mat)
        subFileList{end+1}=files.mat{i}(1:end-4);
    end
    set(handles.subject,'enable','on')
    set(handles.subject,'string',subFileList)
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ReviewEventsGUI wait for user response (see UIRESUME)
% uiwait(handles.GUI_window);
end

% --- Outputs from this function are returned to the command line.
function varargout = ReviewEventsGUI_OutputFcn(hObject, eventdata, handles)

%Set GUI position to middle of screen (not sure what happens if screen is
%smaller than GUI, also not sure why this code only works within this
%function...)
% left, bottom, width, height
scrsz = get(0,'ScreenSize'); 
set(gcf,'Units','pixels');
guiPos = get(gcf,'Position');
set(gcf, 'Position', [(scrsz(3)-guiPos(3))/2 (scrsz(4)-guiPos(4))/2 guiPos(3) guiPos(4)]);

% Get default command line output from handles structure
varargout{1} = handles.output;
end

%% ----------------------------------------------------------------
%First step: set directory name to load files from. By default it is the
%current dir: './'

% --- Executes on button press in browseButton.
function browseButton_Callback(hObject, eventdata, handles)
direct = uigetdir; %pulls up a broswer window so a folder can be selected
set(handles.directory,'string',[direct,filesep])
guidata(hObject,handles)
directory_Callback(handles.directory,eventdata,handles)
end

function directory_Callback(hObject, eventdata, handles)
% hObject    handle to directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of directory as text
%        str2double(get(hObject,'String')) returns contents of directory as a double

direct = get(hObject, 'String');

%checks if Sub is a file
if exist(direct,'dir')    
    files=what(direct);
    subFileList={};
    if isempty(files.mat)
        errordlg('Directory entered does not contain any .mat files','Directory Error');
        set(handles.subject,'Enable','off');
        % Give the edit text box focus so user can correct the error
        uicontrol(hObject)
    else
        set(handles.subject,'Enable','on');
        for i=1:length(files.mat)
            subFileList{end+1}=files.mat{i}(1:end-4);
        end
        set(handles.subject,'string',subFileList)
    end    
else
    errordlg('Path entered is not a directory.','Directory Error');    
    set(handles.subject,'Enable','off');
    % Give the edit text box focus so user can correct the error
    uicontrol(hObject)
end
guidata(hObject, handles);
end

%% -------------------------------------------------------------------
%Second, the subject filename needs to be entered.

function subject_Callback(hObject, eventdata, handles)
% hObject    handle to subject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.Dir=get(handles.directory,'string');

%Disable everything
set(handles.plot_button,'Enable','off');
set(handles.next_button,'Enable','off');
set(handles.back_button,'Enable','off');
set(handles.delete_button,'Enable','off');
set(handles.deleteNbutton,'Enable','off');
set(handles.save_button,'Enable','off');
set(handles.add_button,'Enable','off');
set(handles.BPdataType,'Enable','off');
set(handles.BPfield,'Enable','off');
set(handles.TPdataType,'Enable','off');
set(handles.TPfield,'Enable','off');
set(handles.condMenu, 'Enable','off');
set(handles.trialMenu,'Enable','off');
set(handles.timeSlider,'Enable','off');
set(handles.maxCheck,'Enable','off');
drawnow

global expData
options=cellstr(get(hObject,'String'));
handles.filename = [options{get(hObject,'Value')},'.mat'];

eval(['aux=load('''  handles.Dir handles.filename ''');']) %.mat file can only contain 1 variable, of the experimentData type
fieldNames=fields(aux);
handles.varName=fieldNames{1};

eval(['expData=aux.' fieldNames{1} ';']);
if isa(expData,'experimentData') && expData.isProcessed %if not processed, there will be no events to review
    set(handles.subject_text,'String', 'Filename') 
    
    %Enable and init all menus
    set(handles.plot_button,'Enable','on');
    set(handles.next_button,'Enable','on');
    %set(handles.back_button,'Enable','on');
    set(handles.delete_button,'Enable','on');
    set(handles.deleteNbutton,'Enable','on');
    set(handles.save_button,'Enable','on');
    set(handles.add_button,'Enable','on');
    set(handles.BPdataType,'Enable','on');
    set(handles.BPfield,'Enable','on');
    set(handles.TPdataType,'Enable','on');
    set(handles.TPfield,'Enable','on');
    set(handles.timeSlider,'Enable','on');
    set(handles.maxCheck,'Enable','on');
    
    %Enable and initialize condition menu:
    set(handles.condMenu, 'Enable','on');
    condDes = expData.metaData.conditionName;
    set(handles.condMenu, 'String',condDes(~cellfun('isempty',condDes))); %this is for the case when a condition number was skipped
    set(handles.condMenu, 'Value',1);
    set(handles.trialMenu,'Value',1);
    guidata(hObject, handles);
    condMenu_Callback(handles.condMenu, [], handles);
else
    h_error=errordlg('Subject file must be of the class ''processedTrialData''','Subject Error');
    set(h_error,'color',[0.8 0.8 0.8])
    waitfor(h_error)
    % Give the edit text box focus so user can correct the error
    uicontrol(hObject)
    guidata(hObject, handles)
end


end
%% ---------------------------------------------------------------------
%Then: select condition:

% --- Executes on selection change in condMenu.
function condMenu_Callback(hObject, eventdata, handles)

% check back button ability
if get(hObject,'value')>1
    set(handles.back_button,'enable','on')
else
    set(handles.back_button,'enable','off')
end

global expData
condOptions=get(hObject,'string');
condStr=condOptions(get(hObject,'Value'));
handles.Condition=find(strcmp(expData.metaData.conditionName,condStr));

s={};
for i=1:length(expData.metaData.trialsInCondition{handles.Condition})
    s{i}=num2str(expData.metaData.trialsInCondition{handles.Condition}(i));
end
if isempty(s)
    cla(handles.axes1)
    cla(handles.axes2)
    %Disable everything
    set(handles.plot_button,'Enable','off');
    set(handles.next_button,'Enable','off');
    set(handles.back_button,'Enable','off');
    set(handles.delete_button,'Enable','off');
    set(handles.deleteNbutton,'Enable','off');
    set(handles.save_button,'Enable','off');
    set(handles.add_button,'Enable','off');
    set(handles.BPdataType,'Enable','off');
    set(handles.BPfield,'Enable','off');
    set(handles.TPdataType,'Enable','off');
    set(handles.TPfield,'Enable','off');
    set(handles.trialMenu,'Enable','off');
    set(handles.timeSlider,'Enable','off');
    set(handles.maxCheck,'Enable','off');
    
else
    
    %enable everything
    set(handles.plot_button,'Enable','on');
    set(handles.next_button,'Enable','on');    
    set(handles.delete_button,'Enable','on');
    set(handles.deleteNbutton,'Enable','on');
    set(handles.save_button,'Enable','on');
    set(handles.add_button,'Enable','on');
    set(handles.BPdataType,'Enable','on');
    set(handles.BPfield,'Enable','on');
    set(handles.TPdataType,'Enable','on');
    set(handles.TPfield,'Enable','on');
    set(handles.trialMenu,'Enable','on');
    set(handles.timeSlider,'Enable','on');
    set(handles.maxCheck,'Enable','on');
    
    set(handles.trialMenu, 'Enable','on');
    set(handles.trialMenu, 'String',s);
    if handles.backButtonFlag
        set(handles.trialMenu, 'Value',length(s));
    else
        set(handles.trialMenu, 'Value',1);
    end
    handles.backButtonFlag=false;
    guidata(hObject, handles)
    trialMenu_Callback(handles.trialMenu, eventdata, handles);
end

end




%% ---------------------------------------------------------------------
%Then: select specific trial:

function trialMenu_Callback(hObject, eventdata, handles)

% check back button ability
if get(handles.condMenu,'value')==1 && get(hObject,'value')==1
    set(handles.back_button,'enable','off')
else
    set(handles.back_button,'enable','on')
end

global expData
handles.idx=expData.metaData.trialsInCondition{handles.Condition}(get(hObject,'Value'));
handles.TSlist={};
handles.trialEvents=expData.data{handles.idx}.gaitEvents;
%determine reference leg
if expData.data{handles.idx}.metaData.refLeg == 'R'
    handles.slow = 'R';
    handles.fast = 'L';
else
    handles.slow = 'L';
    handles.fast = 'R';
end
% get condition description and any observations
set(handles.condDescripText,'string',expData.data{handles.idx}.metaData.description)
set(handles.observationText,'string',['Observations: ' expData.data{handles.idx}.metaData.observations])
set(handles.write,'Enable','off')
fieldList=fields(expData.data{handles.idx});
for i=1:length(fieldList)
    eval(['curField=expData.data{handles.idx}.' fieldList{i} ';']);
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
%initialize start/stop times to plot
set(handles.minText,'string','1')
maxTime=ceil(expData.data{handles.idx}.gaitEvents.Time(end));
TW=round(get(handles.timeSlider,'Value'));
if TW>maxTime || get(handles.maxCheck,'value')
    handles.timeWindow=maxTime;
    handles.tstop=maxTime;
    set(handles.timeSlider,'Value',maxTime);
else
    handles.timeWindow=TW;
    handles.tstop=TW;
end
set(handles.maxText,'string',num2str(maxTime));
set(handles.timeSlider,'max',maxTime);
set(handles.timeSlider,'SliderStep',[1/(maxTime-1) 1/(maxTime-1)]) %1 is the lower limit
handles.tstart=0;
set(handles.timeWindowText,'String',handles.timeWindow);
TPdataType_Callback(handles.TPdataType,eventdata,handles);
end

%% -------------------------Data Selection -------------------------------

function TPdataType_Callback(hObject, eventdata, handles)

handles.TPfieldlist = makeFieldList(hObject,handles,handles.TPfield);

handles.test=1;
% guidata(hObject, handles)
TPfield_Callback(handles.TPfield, eventdata, handles)
end

function TPfield_Callback(hObject, eventdata, handles)
handles.last=plotData(handles,handles.TPfield,handles.TPdataType,handles.TPfieldlist,handles.axes1);
BPdataType_Callback(handles.BPdataType,eventdata,handles);
end


function BPdataType_Callback(hObject, eventdata, handles)

handles.BPfieldlist = makeFieldList(hObject,handles,handles.BPfield);

BPfield_Callback(handles.BPfield, eventdata, handles)
end

function BPfield_Callback(hObject, eventdata, handles)
handles.last=plotData(handles,handles.BPfield,handles.BPdataType,handles.BPfieldlist,handles.axes2);
guidata(hObject, handles)
end

function [plotFields] = makeFieldList(hObject,handles,fieldListHandle)

global expData

curTS=expData.data{handles.idx}.(handles.TSlist{get(hObject,'Value')});
fields={};
plotFields={};
set(fieldListHandle,'enable','on')

%The following code removes redundant options in the feild list by
%combinging 'R' and 'L' data as well as 'Fast' and 'Slow' adaptation
%parameters.
%note that two cells need to be created: one with the list of options for
%the drop-down list(feilds) and another that matches each option with the data to
%plot (plotFields)

for i=1:length(curTS.labels)
    if strcmp(curTS.labels{i}(1),handles.fast) %'L' or 'R'
        if any(strcmp(curTS.labels,[handles.slow,curTS.labels{i}(2:end)])) %check there is a corresponding slow label
            if length(curTS.labels)==2 %case where there is only two labels (matlab doesn't like dropdown menus with only one option)
                set(fieldListHandle,'enable','off')
                set(fieldListHandle,'Value',1)
                fields = {'',''};
                plotFields{end+1} = {curTS.labels{i},[handles.slow,curTS.labels{i}(2:end)]};
            elseif length(curTS.labels{i}) == 1 % just 'R' or 'L' (beltspeedreadData for ex)
                fields=handles.TSlist{get(hObject,'Value')};
                plotFields{end+1} = {handles.fast,handles.slow};
            else
                fields{end+1}=curTS.labels{i}(2:end);
                plotFields{end+1} = {curTS.labels{i},[handles.slow,curTS.labels{i}(2:end)]};
            end
        else
            %slow label is missing 
            fields{end+1}=strrep(curTS.labels{i},handles.fast,'F');
            plotFields{end+1} = curTS.labels{i};
        end
    elseif strcmp(curTS.labels{i}(1),handles.slow)
        if ~any(strcmp(curTS.labels,[handles.fast,curTS.labels{i}(2:end)]))
            %fast label is missing 
            fields{end+1}=strrep(curTS.labels{i},handles.slow,'S');
            plotFields{end+1}=curTS.labels{i};
        else
            % already have a slow label so do nothing
        end            
    elseif strcmpi(curTS.labels{i}(max([end-3 1]):end),'Fast')
        fields{end+1}=curTS.labels{i}(1:end-4);
        plotFields{end+1} = {curTS.labels{i},[curTS.labels{i}(1:end-4),'Slow']};
    elseif strcmpi(curTS.labels{i}(max([end-3 1]):end),'Slow')
        %assume we also have a fast label and do nothing
    else
        fields{end+1}=curTS.labels{i};
        plotFields{end+1} = curTS.labels{i};
    end
end

set(fieldListHandle,'String',fields);
if get(fieldListHandle,'Value')>length(get(fieldListHandle,'String'))
    set(fieldListHandle,'Value',1);
end
clear curTS
guidata(hObject, handles)
end



%% -----------------------------BUTTONS:----------------------------------

% --- Executes on slider movement.
function timeSlider_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.timeWindow=round(get(hObject,'Value'));

% % % %to make zooming in start in middle of previous time window: % % % %
% timeToAdd=handles.timeWindow-(handles.tstop-handles.tstart);
% time1=max([handles.tstart-floor(timeToAdd/2) 0]);
% handles.tstop=handles.tstop+ceil(timeToAdd-(handles.tstart-time1));
% handles.tstart=time1;

% to make zooming in start at the beginning of the trial:
handles.tstop=handles.timeWindow;
handles.tstart=0;
set(handles.timeWindowText,'string',handles.timeWindow);
guidata(hObject, handles)
plot_button_Callback(handles.plot_button,eventdata,handles)
end

% --- Executes on button press in maxCheck.
function maxCheck_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of maxCheck
global expData
maxTime=ceil(expData.data{handles.idx}.gaitEvents.Time(end));
if get(handles.maxCheck,'value')
    handles.timeWindow=maxTime;
    handles.tstop=maxTime;
    set(handles.timeSlider,'Value',maxTime);
    set(handles.timeWindowText,'String',handles.timeWindow);
end
plot_button_Callback(handles.plot_button,eventdata,handles)
end

% --- Executes on button press in plot_button.
function plot_button_Callback(hObject, eventdata, handles)

%Top plot:
handles.last=plotData(handles,handles.TPfield,handles.TPdataType,handles.TPfieldlist,handles.axes1);

%Bottom plot:
handles.last=plotData(handles,handles.BPfield,handles.BPdataType,handles.BPfieldlist,handles.axes2);

drawnow
guidata(hObject, handles)
end

function last=plotData(handles,fieldHandle,dataTypeHandle,fieldList,axesHandle)

linkaxes([handles.axes1,handles.axes2],'x')

global expData

value=get(fieldHandle,'Value');
dataType=handles.TSlist{get(dataTypeHandle,'Value')};

TSdata=expData.data{handles.idx}.(dataType);
if isa(TSdata,'parameterSeries')
    times=TSdata.hiddenTime;
else
    times=TSdata.Time;
end

if times(end)<handles.tstop || get(handles.maxCheck,'value')
    endSamp=length(times);
    startSamp=max([1 endSamp-find(times<=handles.timeWindow,1,'last')]);
    last=1;    
else
    startSamp=max([1 find(times>=handles.tstart,1,'first')]);
    endSamp=max([startSamp find(times<=handles.tstop,1,'last')]);
    last=0;
end

%Events to plot:
events=handles.trialEvents;
%event correction factor:
ECF = events.sampFreq/TSdata.sampFreq;
for i=1:length(events.labels)
    data=events.getDataAsVector(events.labels{i});
    eval([events.labels{i} 'times=times(startSamp)+events.Time(data(ceil(startSamp.*ECF):floor(endSamp.*ECF))==1);'])
end

time=times(startSamp:endSamp); %should be same as time=handles.tstart:TSdata.sampPeriod:handles.tstop
set(axesHandle,'nextplot','replace')
if length(fieldList{value})==2
    %get data to plot
    FdataTS=TSdata.getDataAsTS(fieldList{value}{1});
    SdataTS=TSdata.getDataAsTS(fieldList{value}{2});
    if strcmp(dataType,'adaptParams')
        label=fieldList{value}{1}(1:end-4);
        %plot data
    plot(axesHandle,time,FdataTS.Data(startSamp:endSamp),'r.','MarkerSize',20);
    set(axesHandle,'nextplot','add')
    plot(axesHandle,time,SdataTS.Data(startSamp:endSamp),'b.','MarkerSize',20);
    legendEntries = {'Fast','Slow'};
        % do not overlay events
    else
        label=fieldList{value}{1}(2:end);
        %plot data
        plot(axesHandle,time,FdataTS.Data(startSamp:endSamp),'r','MarkerSize',20);
        set(axesHandle,'nextplot','add')
        plot(axesHandle,time,SdataTS.Data(startSamp:endSamp),'b','MarkerSize',20);
        legendEntries = {'Fast','Slow'};
        %Overlay events (only those in the time window...otherwise there
        %will be warnings for the extra legend entries
        if eval(['~isempty(',handles.fast,'HStimes)'])
            eval(['plot(axesHandle,',handles.fast,'HStimes,FdataTS.getSample(',handles.fast,'HStimes),''kx'',''LineWidth'',2);'])
            legendEntries{end+1}='FHS';
        end
        if eval(['~isempty(',handles.fast,'TOtimes)'])
            eval(['plot(axesHandle,',handles.fast,'TOtimes,FdataTS.getSample(',handles.fast,'TOtimes),''ks'',''LineWidth'',2);'])
            legendEntries{end+1}='FTO';
        end
        if eval(['~isempty(',handles.slow,'HStimes)'])
            eval(['plot(axesHandle,',handles.slow,'HStimes,SdataTS.getSample(',handles.slow,'HStimes),''ko'',''LineWidth'',2);'])
            legendEntries{end+1}='SHS';
        end
        if eval(['~isempty(',handles.slow,'TOtimes)'])
            eval(['plot(axesHandle,',handles.slow,'TOtimes,SdataTS.getSample(',handles.slow,'TOtimes),''k*'',''LineWidth'',2);'])
            legendEntries{end+1}='STO';
        end        
    end
else
    %get data to plot
    label=fieldList{value};
    dataTS=TSdata.getDataAsTS(fieldList{value});
    %plot data
    if strcmp(dataType,'adaptParams')
        plot(axesHandle,time,dataTS.Data(startSamp:endSamp),'b.','MarkerSize',20);
    else
        plot(axesHandle,time,dataTS.Data(startSamp:endSamp),'b');
    end
    set(axesHandle,'nextplot','add')
    legendEntries = {'data'};
end

h_legend = legend(axesHandle,legendEntries);
set(h_legend,'FontSize',6)

title(axesHandle,[label,' ',dataType,' Trial ',num2str(handles.idx)])

%Clear vars:
clear RHS* LHS* LTO* RTO* events time
end

% --- Executes on button press in next_button.
function next_button_Callback(hObject, eventdata, handles)

set(handles.back_button,'Enable','on')
if handles.last
    if length(get(handles.trialMenu,'String'))>get(handles.trialMenu,'Value')
        set(handles.trialMenu,'Value',get(handles.trialMenu,'Value')+1); %Add one to current trial, does this update what the GUI shows?
        trialMenu_Callback(handles.trialMenu, eventdata, handles)
    elseif get(handles.condMenu,'Value')<length(get(handles.condMenu,'String'))
        set(handles.condMenu,'Value',get(handles.condMenu,'Value')+1);
        set(handles.trialMenu,'Value',1);
        condMenu_Callback(handles.condMenu, eventdata, handles)
    else
        set(hObject,'Enable','off')
        guidata(hObject, handles)
    end
else
    handles.tstart=handles.tstart+handles.timeWindow;
    handles.tstop=handles.tstop+handles.timeWindow;
    plot_button_Callback(handles.plot_button, eventdata, handles)
end

end


% --- Executes on button press in back_button.
function back_button_Callback(hObject, eventdata, handles)

set(handles.next_button,'Enable','on')
if handles.tstart>0
    handles.tstart=handles.tstart-handles.timeWindow;
    handles.tstop=handles.tstop-handles.timeWindow;
    plot_button_Callback(handles.plot_button, eventdata, handles)
elseif get(handles.trialMenu,'Value')>1
    set(handles.trialMenu,'Value',get(handles.trialMenu,'Value')-1); %Add one to current trial, does this update what the GUI shows?
    trialMenu_Callback(handles.trialMenu, eventdata, handles)
elseif get(handles.condMenu,'Value')>1
    set(handles.condMenu,'Value',get(handles.condMenu,'Value')-1);
    handles.backButtonFlag=true;
    condMenu_Callback(handles.condMenu, eventdata, handles)
else
    set(hObject,'Enable','off')
    guidata(hObject, handles)
end

end

% --- Executes on button press in delete_button.
function delete_button_Callback(hObject, eventdata, handles)

global expData

%Select event
axes(handles.axes1)
[x,~]=ginput;

%Find closest event(s)
allEventsIndexes=find(sum(handles.trialEvents.Data,2)>0);
for i=1:length(x);
    deltaT=handles.trialEvents.Time(allEventsIndexes)-x(i);
    [~,selectedEventTimeIndex]=min(deltaT.^2);
    selectedEventIndex=allEventsIndexes(selectedEventTimeIndex);
    
    %Eliminate it from handles.trialEvents
    handles.trialEvents.Data(selectedEventIndex,:)=false;
end

expData.data{handles.idx}.gaitEvents=handles.trialEvents;
expData.data{handles.idx}.adaptParams=calcParameters(expData.data{handles.idx});

%Re-plot
guidata(hObject, handles)
plot_button_Callback(handles.plot_button, eventdata, handles)

end

% --- Executes on button press in deleteNbutton.
function deleteNbutton_Callback(hObject, eventdata, handles)

global expData

[x,~]=ginput(2);

%Find two closest events
allEventsIndexes=find(sum(handles.trialEvents.Data,2)>0);

deltaTstart=handles.trialEvents.Time(allEventsIndexes)-x(1);
[~,selectedEventTimeIndexStart]=min(deltaTstart.^2);
selectedEventIndexStart=allEventsIndexes(selectedEventTimeIndexStart);

deltaTend=handles.trialEvents.Time(allEventsIndexes)-x(2);
[~,selectedEventTimeIndexEnd]=min(deltaTend.^2);
selectedEventIndexEnd=allEventsIndexes(selectedEventTimeIndexEnd);
    
%Eliminate all events between two indexes from handles.trialEvents
handles.trialEvents.Data(selectedEventIndexStart:selectedEventIndexEnd,:)=false;

expData.data{handles.idx}.gaitEvents=handles.trialEvents;
expData.data{handles.idx}.adaptParams=calcParameters(expData.data{handles.idx});

%Re-plot
guidata(hObject, handles)
plot_button_Callback(handles.plot_button, eventdata, handles)
end

% --- Executes on button press in add_button.
function add_button_Callback(hObject, eventdata, handles)

%Ask subject to select event type: SHS, FHS, STO, FTO
events=handles.trialEvents.getLabels;
events=strrep(events,handles.fast,'F'); %replace 'R' or 'L' with 'F' or 'S'
events=strrep(events,handles.slow,'S');
set(handles.eventType,'String',events)
set(handles.eventType,'Enable','on')

%Now the subject should select an event Type, so the function continues on
%eventType_callback
guidata(hObject, handles)

end

% --- Executes on selection change in eventType.
function eventType_Callback(hObject, eventdata, handles)

% Hints: contents = cellstr(get(hObject,'String')) returns eventType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from eventType
global expData

%Select location
[x,~]=ginput(1);

%create new event in handles.trialEvents
[~,closestTimeIdx]=min((handles.trialEvents.Time-x).^2);
handles.trialEvents.Data(closestTimeIdx,get(handles.eventType,'Value'))=true;

expData.data{handles.idx}.gaitEvents=handles.trialEvents;
expData.data{handles.idx}.adaptParams=calcParameters(expData.data{handles.idx});

%Disable this
set(hObject,'Enable','off');
guidata(hObject, handles)

%Re-plot
plot_button_Callback(handles.plot_button, eventdata, handles)
end



% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)

global expData
expData.data{handles.idx}.gaitEvents=handles.trialEvents;
expData.data{handles.idx}.adaptParams=calcParameters(expData.data{handles.idx});
handles.changed=true;
set(handles.write,'Enable','on');
guidata(hObject, handles)
end

% --- Executes on button press in write.
function write_Callback(hObject, eventdata, handles)
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
set(handles.timeSlider,'Enable','off');
set(handles.maxCheck,'Enable','off');
set(handles.write,'String', 'Writing...');
set(handles.trialMenu,'Enable','off');
drawnow

%Write to disk
eval([handles.varName '=expData;']); %Assigning same var name
eval(['save(''' handles.Dir handles.filename ''',''' handles.varName ''');']); %Saving with same var name
handles.changed=false;

%re-create adaptation parameters object
expData=expData.recomputeParameters;
adaptData=expData.makeDataObj;
eval(['save(''' handles.Dir handles.filename(1:end-4) 'params' ''',''adaptData'');']); %Saving with same var name

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
set(handles.timeSlider,'Enable','on');
set(handles.maxCheck,'Enable','on');
set(handles.write,'String', 'Write to disk');
set(handles.trialMenu,'Enable','on');
guidata(hObject, handles);

end


%% ---------------------------CLOSING---------------------------------

% --- Executes when user attempts to close GUI_window.
function GUI_window_CloseRequestFcn(hObject, eventdata, handles)

global expData
%Disable everything
set(handles.plot_button,'Enable','off');
set(handles.next_button,'Enable','off');
set(handles.back_button,'Enable','off');
set(handles.delete_button,'Enable','off');
set(handles.deleteNbutton,'Enable','off');          
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
set(handles.timeSlider,'Enable','off');
set(handles.maxCheck,'Enable','off');
set(handles.write,'String', 'Writing...');

drawnow
if handles.changed
    %write to disk
    eval([handles.varName '=expData;']); %Assigning same var name
    eval(['save(''' handles.Dir handles.filename ''',''' handles.varName ''');']); %Saving with same var name
    %re-create adaptation parameters object
    adaptData=expData.makeDataObj;
    eval(['save(''' handles.Dir handles.filename(1:end-4) 'params' ''',''adaptData'');']); %Saving with same var name
    handles.changed=false;
end
guidata(hObject, handles);
% Hint: delete(hObject) closes the figure
delete(handles.output);
end

%------------------------ Create Functions -----------------------------%
% --- Executes during object creation, after setting all properties. ---%

% hObject    handle to eventType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

function directory_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
    set(hObject,'String','./');
end
end

function subject_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function condMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function trialMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function TPfield_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function TPdataType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function BPdataType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function BPfield_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function eventType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function timeSlider_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end

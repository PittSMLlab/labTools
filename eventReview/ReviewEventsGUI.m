function varargout = ReviewEventsGUI(varargin)
% ReviewEventsGUI  Plots data in experimentData object and allows you to
%                  add or remove events (HS, TO), and label strides as good
%                  or bad.%      
%
% See also: experimentData

%In all functions:
% hObject    handle to object calling function (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Last Modified by GUIDE v2.5 15-May-2015 15:52:21

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


%% --- Executes just before ReviewEventsGUI is made visible.
function ReviewEventsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% varargin   command line arguments to ReviewEventsGUI (see VARARGIN)

%initialize values
handles.output=hObject;
handles.changed=false;
handles.saved=false;
handles.backButtonFlag=false;
handles.type='';

% Update handles structure
guidata(hObject, handles);

%Set text that pops up when fields of GUI are hovered over. Note: sprintf
%used to allow line breaks in tool tip string.
set(handles.delete_button,'TooltipString',sprintf(['Use crosshair to select the event(s) that need deleted. \n'...
'Press the return (enter) key after clicking on the event(s) to delete them.']));
set(handles.deleteNbutton,'TooltipString',sprintf(['Use crosshair to select the start and end of a range of events to be deleted.\n'...
'ALL events in this range are removed.']));

% UIWAIT makes ReviewEventsGUI wait for user response (see UIRESUME)
% uiwait(handles.GUI_window);
end

% --- Outputs from this function are returned to the command line.
function varargout = ReviewEventsGUI_OutputFcn(hObject, eventdata, handles)

%Set GUI position to middle of screen (not sure why this code only works 
%within this function...)
% left, bottom, width, height
scrsz = get(0,'ScreenSize'); 
set(gcf,'Units','pixels');
guiPos = get(gcf,'Position');
width=min([guiPos(3) scrsz(3)]);
height=min([guiPos(4) scrsz(4)]);
set(gcf, 'Position', [(scrsz(3)-width)/2 (scrsz(4)-height)/2 width height]);

% Get default command line output from handles structure
varargout{1} = handles.output;
end


%% -------------------------Open subject file--------------------------

function uiOpenFile_ClickedCallback(hObject, eventdata, handles)

%If a subject's file is currently open, ask to save.
if isfield(handles,'filename') && ~handles.changed && ~handles.saved
    choice = questdlg(['Do you want to save changes made to ',handles.filename,'?'], ...
    'ReviewEventsGUI', ...
    'Save','Don''t Save','Cancel','Save');
    switch choice
        case 'Save'
            handles.changed=true;
        case 'Don''t Save'
            handles.changed=false;
        case {'Cancel',''}
            return
    end
end

if handles.changed
    write_Callback(handles.write,eventdata,handles)
end

[handles.filename,handles.Dir]=uigetfile('*.mat','Choose subject file'); %opens browse window

if handles.filename~=0
    global expData
    
    %Disable everything
    handles=disableFields(handles,'plot_button','next_button','back_button',...
        'delete_button','deleteNbutton','save_button','add_button',...
        'BPdataType','BPfield','TPdataType','TPfield','condMenu','trialMenu',...
        'timeSlider','maxCheck','defaultRadio','kinematicRadio','forceRadio',...
        'labelBadButton','labelGoodButton','showBadCheck');
    drawnow
    
    aux=load([handles.Dir handles.filename]); %.mat file can only contain 1 variable, of the experimentData type
    fieldNames=fields(aux);
    handles.varName=fieldNames{1};
    
    expData=aux.(fieldNames{1});
    if isa(expData,'experimentData') && expData.isProcessed %if not processed, there will be no events to review
                
        %Enable things
        handles=enableFields(handles,'plot_button','next_button','delete_button',...
            'deleteNbutton','save_button','add_button','BPdataType','BPfield',...
            'TPdataType','TPfield','timeSlider','maxCheck','defaultRadio',...
            'showBadCheck','condMenu','labelBadButton','labelGoodButton');
        if length(expData.data{end}.gaitEvents.labels)==12
            set(handles.kinematicRadio,'Enable','on');
            set(handles.forceRadio,'Enable','on');
        end        
        
        %initialize condition menu:
        condDes = expData.metaData.conditionName;
        set(handles.condMenu, 'String',condDes(~cellfun('isempty',condDes))); %this is for the case when a condition number was skipped
        set(handles.condMenu, 'Value',1);
        set(handles.trialMenu,'Value',1);
        guidata(hObject, handles);
        condMenu_Callback(handles.condMenu, [], handles);
    else
        h_error=errordlg('Subject file must contain a processed object of the class ''experimentData''','Subject Error');
        waitfor(h_error)       
    end    
end
end



%% ---------------------------Select condition----------------------------

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
    %Disable everything (besides condMenu)
     handles=disableFields(handles,'plot_button','next_button','back_button',...
        'delete_button','deleteNbutton','save_button','add_button',...
        'BPdataType','BPfield','TPdataType','TPfield','trialMenu',...
        'timeSlider','maxCheck','defaultRadio','kinematicRadio','forceRadio',...
        'labelBadButton','labelGoodButton','showBadCheck');
    drawnow
else
    %enable everything
    handles=enableFields(handles,'plot_button','next_button','delete_button',...
        'deleteNbutton','save_button','add_button','BPdataType','BPfield',...
        'TPdataType','TPfield','trialMenu','timeSlider','maxCheck','trialMenu',...
        'defaultRadio','showBadCheck','labelBadButton','labelGoodButton');   
    if length(expData.data{end}.gaitEvents.labels)==12
        set(handles.kinematicRadio,'Enable','on');
        set(handles.forceRadio,'Enable','on');
    end
    %set other values
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
%Select specific trial:

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



%% -----------------------------PLOTTING:----------------------------------

% --- Executes on slider movement.
function timeSlider_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.timeWindow=round(get(hObject,'Value'));

% % % %to make zoomed-in time window start in middle of previous time window: % % % %
% timeToAdd=handles.timeWindow-(handles.tstop-handles.tstart);
% time1=max([handles.tstart-floor(timeToAdd/2) 0]);
% handles.tstop=handles.tstop+ceil(timeToAdd-(handles.tstart-time1));
% handles.tstart=time1;

% % % to make zoomed-in time window start at the beginning of the trial: % % % % %
% handles.tstop=handles.timeWindow;
% handles.tstart=0;

% % % %to make zoomed-in time window start at beginning of previous time window: % % % %
handles.tstop=handles.tstart+handles.timeWindow;

set(handles.timeWindowText,'string',handles.timeWindow);
guidata(hObject, handles)
plot_button_Callback(handles.plot_button,eventdata,handles)
end

% --- Executes on button press in maxCheck.
function maxCheck_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of maxCheck
global expData
maxTime=ceil(expData.data{handles.idx}.gaitEvents.Time(end));
set(handles.timeSlider,'enable','on');
if get(handles.maxCheck,'value')
    handles.timeWindow=maxTime;
    handles.tstop=maxTime;
    set(handles.timeSlider,'Value',maxTime);
    set(handles.timeWindowText,'String',handles.timeWindow);
    set(handles.timeSlider,'enable','off');
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

time=times(startSamp:endSamp); %should be same as time=handles.tstart:TSdata.sampPeriod:handles.tstop
set(axesHandle,'nextplot','replace')
if length(fieldList{value})==2
    %get data to plot    
    FdataTS=TSdata.getDataAsTS(fieldList{value}{1});
    SdataTS=TSdata.getDataAsTS(fieldList{value}{2});
    if strcmp(dataType,'adaptParams')        
        label=fieldList{value}{1}(1:end-4);
        %plot data
        bad=TSdata.bad(startSamp:endSamp);
        badStrides=find(bad);
        goodStrides=find(~bad);
        plot(axesHandle,time(goodStrides),FdataTS.Data(goodStrides),'r.','MarkerSize',20);
        set(axesHandle,'nextplot','add')
        plot(axesHandle,time(goodStrides),SdataTS.Data(goodStrides),'b.','MarkerSize',20);
        legendEntries = {'Fast','Slow'};
        if get(handles.showBadCheck,'Value')
             plot(axesHandle,time(badStrides),FdataTS.Data(badStrides),'ro','MarkerSize',6);
             plot(axesHandle,time(badStrides),SdataTS.Data(badStrides),'bo','MarkerSize',6);
             legendEntries ={'Fast','Slow','Bad Fast','Bad Slow'};
        end
        % do not overlay events
    else
        label=fieldList{value}{1}(2:end);
        %plot data
        plot(axesHandle,time,FdataTS.Data(startSamp:endSamp),'r');
        set(axesHandle,'nextplot','add')
        plot(axesHandle,time,SdataTS.Data(startSamp:endSamp),'b');
        legendEntries = {'Fast','Slow'};
        %Events to plot:
        events=handles.trialEvents;
        %event correction factor:
        % TO DO: use a method to make sampling frequencies equivalent instead of using ECF.
        ECF = events.sampFreq/TSdata.sampFreq; 
        for i=1:length(events.labels)
            data=events.getDataAsVector(events.labels{i});
            eval([events.labels{i} 'times=times(startSamp)+events.Time(data(ceil((startSamp-1).*ECF+1):floor((endSamp-1).*ECF+1))==1);'])
        end
        %Overlay events (only those in the time window...otherwise there
        %will be warnings for the extra legend entries
        type=handles.type;
        if eval(['~isempty(',handles.fast,'HStimes)'])
            eval(['plot(axesHandle,',type,handles.fast,'HStimes,FdataTS.getSample(',type,handles.fast,'HStimes),''kx'',''LineWidth'',2);'])
            legendEntries{end+1}='FHS';
        end
        if eval(['~isempty(',handles.fast,'TOtimes)'])
            eval(['plot(axesHandle,',type,handles.fast,'TOtimes,FdataTS.getSample(',type,handles.fast,'TOtimes),''ks'',''LineWidth'',2);'])
            legendEntries{end+1}='FTO';
        end
        if eval(['~isempty(',handles.slow,'HStimes)'])
            eval(['plot(axesHandle,',type,handles.slow,'HStimes,SdataTS.getSample(',type,handles.slow,'HStimes),''ko'',''LineWidth'',2);'])
            legendEntries{end+1}='SHS';
        end
        if eval(['~isempty(',handles.slow,'TOtimes)'])
            eval(['plot(axesHandle,',type,handles.slow,'TOtimes,SdataTS.getSample(',type,handles.slow,'TOtimes),''k*'',''LineWidth'',2);'])
            legendEntries{end+1}='STO';
        end        
    end
else
    %get data to plot
    label=fieldList{value};
    dataTS=TSdata.getDataAsTS(fieldList{value});
    legendEntries = {'data'};
    %plot data
    if strcmp(dataType,'adaptParams')             
        %plot data
        bad=TSdata.bad(startSamp:endSamp);
        badStrides=find(bad);
        goodStrides=find(~bad);        
        plot(axesHandle,time(goodStrides),dataTS.Data(goodStrides),'b.','MarkerSize',20);  
        set(axesHandle,'nextplot','add')
        if get(handles.showBadCheck,'Value')
             plot(axesHandle,time(badStrides),dataTS.Data(badStrides),'bo','MarkerSize',6);
             legendEntries ={'data','bad data'};
        end
    else
        plot(axesHandle,time,dataTS.Data(startSamp:endSamp),'b'); 
        set(axesHandle,'nextplot','add')
    end   
end
set(axesHandle,'Xlim',[handles.tstart handles.tstop]);
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

%% --------------------------Event Editing:----------------------------------

% --- Executes when selected object is changed in event selection button group.
function eventButton_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in eventButton 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
switch get(eventdata.NewValue,'Tag')
    case 'defaultRadio'
        handles.type='';
    case 'kinematicRadio'
        handles.type='kin';
    case 'forceRadio'
        handles.type='force';        
end
plot_button_Callback(handles.plot_button, eventdata, handles)
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
    minDeltaT=min(abs(deltaT));
    if minDeltaT<1 %s
        %pad min value to delete events in same region from alt calcualtion
        selectedEventTimeIndex=find(abs(deltaT)<minDeltaT+0.05);    
        selectedEventIndex=allEventsIndexes(selectedEventTimeIndex);
        
        %Eliminate it from handles.trialEvents
        handles.trialEvents.Data(selectedEventIndex,:)=false;
    end
end

%update events
expData.data{handles.idx}.gaitEvents=handles.trialEvents;
%update parameters (NOTE: this undoes any stride edits)
expData.data{handles.idx}.adaptParams=calcParameters(expData.data{handles.idx},expData.subData);

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
expData.data{handles.idx}.adaptParams=calcParameters(expData.data{handles.idx},expData.subData,handles.type);

%Re-plot
guidata(hObject, handles)
plot_button_Callback(handles.plot_button, eventdata, handles)
end

% --- Executes on button press in add_button.
function add_button_Callback(hObject, eventdata, handles)
%Should this add a TO/HS for all event classes?

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
[~,closestTimeIdx]=min(abs((handles.trialEvents.Time-x)));
handles.trialEvents.Data(closestTimeIdx,get(handles.eventType,'Value'))=true;

expData.data{handles.idx}.gaitEvents=handles.trialEvents;
expData.data{handles.idx}.adaptParams=calcParameters(expData.data{handles.idx},expData.subData,handles.type);

%Disable this
set(hObject,'Enable','off');
guidata(hObject, handles)

%Re-plot
plot_button_Callback(handles.plot_button, eventdata, handles)
end

%% ---------------------------Stride Editing:-----------------------------

% --- Executes on button press in labelBadButton.
function labelBadButton_Callback(hObject, eventdata, handles)

global expData

%Select stride
axes(handles.axes1)
[x,~]=ginput;
[boolFlag,idxs]=expData.data{handles.idx}.adaptParams.isaLabel({'bad','good'});

for i=1:length(x);
    deltaT=expData.data{handles.idx}.adaptParams.hiddenTime-x(i);
    [~,loc]=min(abs(deltaT));
    %update 'bad' and 'good'  
    if all(boolFlag)
        expData.data{handles.idx}.adaptParams.Data(loc,idxs)=[true, false]; 
    else
        expData.data{handles.idx}.adaptParams.Data(loc,idxs)=[true, false]; 
    end
end
%Re-plot
guidata(hObject, handles)
plot_button_Callback(handles.plot_button, eventdata, handles)
end

% --- Executes on button press in labelGoodButton.
function labelGoodButton_Callback(hObject, eventdata, handles)

global expData

%Select stride
axes(handles.axes1)
[x,~]=ginput;
[~,idxs]=expData.data{handles.idx}.adaptParams.isaLabel({'bad','good'});

for i=1:length(x);
    deltaT=expData.data{handles.idx}.adaptParams.hiddenTime-x(i);
    [~,loc]=min(abs(deltaT));
    %update 'bad' and 'good'     
    expData.data{handles.idx}.adaptParams.Data(loc,idxs)=[false, true];   
end
%Re-plot
guidata(hObject, handles)
plot_button_Callback(handles.plot_button, eventdata, handles)
end

% --- Executes on button press in showBadCheck.
function showBadCheck_Callback(hObject, eventdata, handles)
plot_button_Callback(handles.plot_button,eventdata,handles)
end

%% ---------------------------Saving:-----------------------------

% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)

global expData 
% Possibly in the future we could force user to hit save if he/she wants changes to be saved.

% HH: I think the next two lines are unneccesary since any changes to events would have already been saved to expData.
% expData.data{handles.idx}.gaitEvents=handles.trialEvents;
% expData.data{handles.idx}.adaptParams=calcParameters(expData.data{handles.idx});
handles.changed=true; %% HH: this forces the changes to be saved, even if GUI is closed.
set(handles.write,'Enable','on');
guidata(hObject, handles)
end

function uiSaveButton_ClickedCallback(hObject, eventdata, handles)
write_Callback(handles.write,eventdata,handles)
end

% --- Executes on button press in write.
function write_Callback(hObject, eventdata, handles)
global expData

%Disable everything
 handles=disableFields(handles,'plot_button','next_button','back_button',...
     'delete_button','deleteNbutton','save_button','add_button','BPdataType',...
     'BPfield','TPdataType','TPfield','condMenu','trialMenu','timeSlider',...
     'maxCheck','defaultRadio','kinematicRadio','forceRadio','write',...
     'labelBadButton','labelGoodButton','showBadCheck');

set(handles.write,'String', 'Writing...');

drawnow

%Write to disk
eval([handles.varName '=expData;']); %Assigning same var name
%eval(['save(''' handles.Dir handles.filename ''',''' handles.varName
%''');']); %PI: replaced this with the line below on 28/4/2015
save([handles.Dir handles.filename],handles.varName,'-v7.3');%Saving with same var name
handles.changed=false;
handles.saved=true;

%re-create adaptation parameters object
%expData=expData.recomputeParameters; %% HH: I don't think this is necessary, should have already been re-computed earlier. 
adaptData=expData.makeDataObj([handles.Dir handles.filename(1:end-4)]);
% eval(['save(''' handles.Dir handles.filename(1:end-4) 'params' ''',''adaptData'');']); %Saving with same var name --> No longer needed, makeDataObj method automatically saves file.

%Enable everything
handles=enableFields(handles,'plot_button','next_button','back_button',...
    'delete_button','deleteNbutton','save_button','add_button','BPdataType',...
    'BPfield','TPdataType','TPfield','condMenu','timeSlider','maxCheck',...
    'trialMenu','defaultRadio','labelBadButton','labelGoodButton');
if length(expData.data{end}.gaitEvents.labels)==12
    set(handles.kinematicRadio,'Enable','on');
    set(handles.forceRadio,'Enable','on');
end
set(handles.write,'String', 'Write to disk');
guidata(hObject, handles);

end


%% ---------------------------CLOSING---------------------------------

% --- Executes when user attempts to close GUI_window.
function GUI_window_CloseRequestFcn(hObject, eventdata, handles)

%See if subject file should be saved before closing
if ~handles.changed && isfield(handles,'filename') && ~handles.saved
    choice = questdlg(['Do you want to save changes made to ',handles.filename,'?'], ...
	'ReviewEventsGUI', ...
	'Save','Don''t Save','Cancel','Save');
    switch choice
        case 'Save'
            handles.changed=true;
        case 'Don''t Save'
            handles.changed=false;
        case {'Cancel',''}
            return
    end
end

if handles.changed 
    write_Callback(handles.write,eventdata,handles)
end

guidata(hObject, handles);
% Hint: delete(hObject) closes the figure
delete(handles.output);
end

%% ------------------------ Create Functions -----------------------------%
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


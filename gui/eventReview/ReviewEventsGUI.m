function varargout = ReviewEventsGUI(varargin)
%REVIEWEVENTSGUI Plot and edit gait events in an experimentData object.
%
%   Loads a saved experimentData MAT file and provides an interactive
% interface to review force-plate and kinematic gait events (HS, TO),
% add or delete individual events, label strides as good or bad, and
% save the updated experimentData back to disk.
%
% Toolbox Dependencies:
%   None
%
% See also: experimentData, calcParameters, labTimeSeries

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
%REVIEWEVENTSGUI_OPENINGFCN  Initializes GUI state before it is shown.
%
%   Inputs:
%     hObject   - handle to figure
%     eventdata - reserved for future MATLAB versions
%     handles   - struct with handles and user data (see GUIDATA)
%     varargin  - command line arguments to ReviewEventsGUI (see VARARGIN)
%
% Toolbox Dependencies:
%   None

%initialize values
% Update handles structure
handles.output          = hObject;
handles.changed         = false;
handles.saved           = false;
handles.backButtonFlag  = false;
handles.type            = '';

guidata(hObject, handles);

% Set tooltips displayed when hovering over GUI fields.
% Note: sprintf is used to allow line breaks in tooltip text.
set(handles.delete_button, 'TooltipString', sprintf([ ...
    'Use crosshair to select the event(s) that need deleted.\n' ...
    'Press the return (enter) key after clicking on the event(s) ' ...
    'to delete them.']));
set(handles.deleteNbutton, 'TooltipString', sprintf([ ...
    'Use crosshair to select the start and end of a range of events ' ...
    'to be deleted.\nALL events in this range are removed.']));

% UIWAIT makes ReviewEventsGUI wait for user response (see UIRESUME)
% uiwait(handles.GUI_window);
end

% --- Outputs from this function are returned to the command line.
function varargout = ReviewEventsGUI_OutputFcn(hObject, eventdata, handles)

% Center GUI on screen (must run here, not in OpeningFcn)
% left, bottom, width, height
% Get default command line output from handles structure
scrsz  = get(0, 'ScreenSize');
set(gcf(), 'Units', 'pixels');
guiPos = get(gcf(), 'Position');
width  = min([guiPos(3) scrsz(3)]);
height = min([guiPos(4) scrsz(4)]);
set(gcf(), 'Position', [ ...
    (scrsz(3) - width) / 2, (scrsz(4) - height) / 2, width, height]);

varargout{1} = handles.output;
end


%% -------------------------Open subject file--------------------------

function uiOpenFile_ClickedCallback(hObject, eventdata, handles)

% If a subject file is already open, ask to save before switching.
if isfield(handles, 'filename') && ~handles.changed && ~handles.saved
    choice = questdlg( ...
        ['Do you want to save changes made to ', handles.filename, '?'], ...
        'ReviewEventsGUI', 'Save', 'Don''t Save', 'Cancel', 'Save');
    switch choice
        case 'Save'
            handles.changed = true;
        case 'Don''t Save'
            handles.changed = false;
        case {'Cancel', ''}
            return
    end
end

if handles.changed
    write_Callback(handles.write, eventdata, handles)
end

[handles.filename, handles.Dir] = uigetfile('*.mat', 'Choose subject file');

if handles.filename ~= 0
    global expData

    %Disable everything
    handles = disableFields(handles, 'plot_button', 'next_button', ...
        'back_button', 'delete_button', 'deleteNbutton', 'save_button', ...
        'add_button', 'BPdataType', 'BPfield', 'TPdataType', 'TPfield', ...
        'condMenu', 'trialMenu', 'timeSlider', 'maxCheck', 'defaultRadio', ...
        'kinematicRadio', 'forceRadio', 'labelBadButton', 'labelGoodButton', ...
        'showBadCheck');
    drawnow

    aux=load([handles.Dir handles.filename]); %.mat file can only contain 1 variable, of the experimentData type
    if isa(expData,'experimentData') && expData.isProcessed %if not processed, there will be no events to review
        %Enable things
    fieldNames = fieldnames(loaded);
    handles.varName = fieldNames{1};

    expData = loaded.(fieldNames{1});

        handles = enableFields(handles, 'plot_button', 'next_button', ...
            'delete_button', 'deleteNbutton', 'save_button', 'add_button', ...
            'BPdataType', 'BPfield', 'TPdataType', 'TPfield', 'timeSlider', ...
            'maxCheck', 'defaultRadio', 'showBadCheck', 'condMenu', ...
            'labelBadButton', 'labelGoodButton');
        if length(expData.data{end}.gaitEvents.labels) == 12
            set(handles.kinematicRadio, 'Enable', 'On');
            set(handles.forceRadio,     'Enable', 'On');
        end

        %initialize condition menu:
        condDes = expData.metaData.conditionName;
        set(handles.condMenu, 'String',condDes(~cellfun('isempty',condDes))); %this is for the case when a condition number was skipped
        set(handles.condMenu,  'Value', 1);
        set(handles.trialMenu, 'Value', 1);
        guidata(hObject, handles);
        condMenu_Callback(handles.condMenu, [], handles);
    else
        errHandle = errordlg( ...
            ['Subject file must contain a processed object of the ' ...
            'class ''experimentData'''], 'Subject Error');
        waitfor(errHandle)
    end
end
end


%% ---------------------------Select condition----------------------------

% --- Executes on selection change in condMenu.
function condMenu_Callback(hObject, eventdata, handles)

% check back button ability
if get(hObject, 'Value') > 1
    set(handles.back_button, 'Enable', 'On')
else
    set(handles.back_button, 'Enable', 'Off')
end

global expData
condOptions    = get(hObject, 'String');
condStr        = condOptions(get(hObject, 'Value'));
handles.Condition = find(strcmp(expData.metaData.conditionName, condStr));

trialNums = expData.metaData.trialsInCondition{handles.Condition};
trialStr  = {};
for ii = 1:length(trialNums)
    trialStr{ii} = num2str(trialNums(ii));
end

if isempty(trialStr)
    cla(handles.axes1)
    cla(handles.axes2)
    %Disable everything (besides condMenu)
    handles = disableFields(handles, 'plot_button', 'next_button', ...
        'back_button', 'delete_button', 'deleteNbutton', 'save_button', ...
        'add_button', 'BPdataType', 'BPfield', 'TPdataType', 'TPfield', ...
        'trialMenu', 'timeSlider', 'maxCheck', 'defaultRadio', ...
        'kinematicRadio', 'forceRadio', 'labelBadButton', 'labelGoodButton', ...
        'showBadCheck');
    drawnow
else
    %enable everything
    handles = enableFields(handles, 'plot_button', 'next_button', ...
        'delete_button', 'deleteNbutton', 'save_button', 'add_button', ...
        'BPdataType', 'BPfield', 'TPdataType', 'TPfield', 'trialMenu', ...
        'timeSlider', 'maxCheck', 'defaultRadio', 'showBadCheck', ...
        'labelBadButton', 'labelGoodButton');
    if length(expData.data{end}.gaitEvents.labels) == 12
        set(handles.kinematicRadio, 'Enable', 'On');
        set(handles.forceRadio,     'Enable', 'On');
    end
    set(handles.trialMenu, 'String', trialStr);
    if handles.backButtonFlag
        set(handles.trialMenu, 'Value', length(trialStr));
    else
        set(handles.trialMenu, 'Value', 1);
    end
    handles.backButtonFlag = false;

    guidata(hObject, handles)
    trialMenu_Callback(handles.trialMenu, eventdata, handles);
end

end


%% ---------------------------------------------------------------------
%Select specific trial:

function trialMenu_Callback(hObject, eventdata, handles)

% check back button ability
if get(handles.condMenu, 'Value') == 1 && get(hObject, 'Value') == 1
    set(handles.back_button, 'Enable', 'Off')
else
    set(handles.back_button, 'Enable', 'On')
end

global expData
%determine reference leg
handles.idx = expData.metaData.trialsInCondition{handles.Condition}( ...
    get(hObject, 'Value'));
handles.TSlist      = {};
handles.trialEvents = expData.data{handles.idx}.gaitEvents;

if expData.data{handles.idx}.metaData.refLeg == 'R'
    handles.slow = 'R';
    handles.fast = 'L';
else
    handles.slow = 'L';
    handles.fast = 'R';
end
% get condition description and any observations

set(handles.condDescripText, 'String', ...
    expData.data{handles.idx}.metaData.description)
set(handles.observationText, 'String', ...
    ['Observations: ' expData.data{handles.idx}.metaData.observations])
set(handles.write, 'Enable', 'Off')

fieldList = fieldnames(expData.data{handles.idx});
for ii = 1:length(fieldList)
    curField = expData.data{handles.idx}.(fieldList{ii});
    if isa(curField, 'labTimeSeries')
        handles.TSlist{end + 1} = fieldList{ii};
    end
end
clear curField fieldList
%initialize start/stop times to plot

set(handles.BPdataType, 'String', handles.TSlist);
set(handles.TPdataType, 'String', handles.TSlist);
if get(handles.BPdataType, 'Value') > length(get(handles.BPdataType, 'String'))
    set(handles.BPdataType, 'Value', 1);
end
if get(handles.TPdataType, 'Value') > length(get(handles.TPdataType, 'String'))
    set(handles.TPdataType, 'Value', 1);
end

set(handles.minText, 'String', '1')
maxTime = ceil(expData.data{handles.idx}.gaitEvents.Time(end));
TW      = round(get(handles.timeSlider, 'Value'));
if TW > maxTime || get(handles.maxCheck, 'Value')
    handles.timeWindow = maxTime;
    handles.tstop      = maxTime;
    set(handles.timeSlider, 'Value', maxTime);
else
    handles.timeWindow = TW;
    handles.tstop      = TW;
end
set(handles.timeSlider,'SliderStep',[1/(maxTime-1) 1/(maxTime-1)]) %1 is the lower limit
set(handles.maxText,        'String', num2str(maxTime));
set(handles.timeSlider,     'Max',    maxTime);
handles.tstart = 0;
set(handles.timeWindowText, 'String', handles.timeWindow);
TPdataType_Callback(handles.TPdataType, eventdata, handles);
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

function plotFields = makeFieldList(hObject, handles, fieldListHandle)

global expData

curTS        = expData.data{handles.idx}.(handles.TSlist{get(hObject, 'Value')});
fieldOptions = {};
plotFields   = {};
set(fieldListHandle, 'Enable', 'On')

% Remove redundant entries by combining 'R'/'L' pairs and 'Fast'/'Slow'
% pairs into single drop-down options. Two parallel cells are built:
% fieldOptions (display labels) and plotFields (data labels to plot).
for ii = 1:length(curTS.labels)
    if strcmp(curTS.labels{ii}(1), handles.fast)   % fast-leg prefix ('L' or 'R')
        slowLabel = [handles.slow, curTS.labels{ii}(2:end)];
        if any(strcmp(curTS.labels, slowLabel))     % matching slow label exists
            if length(curTS.labels) == 2
                % Only two labels: MATLAB disallows a single-item dropdown
                set(fieldListHandle, 'Enable', 'Off')
                set(fieldListHandle, 'Value', 1)
                fieldOptions         = {'', ''};
                plotFields{end + 1}  = {curTS.labels{ii}, slowLabel};
            elseif length(curTS.labels{ii}) == 1   % bare 'R' or 'L' (belt speed)
                fieldOptions         = handles.TSlist{get(hObject, 'Value')};
                plotFields{end + 1}  = {handles.fast, handles.slow};
            else
                fieldOptions{end + 1} = curTS.labels{ii}(2:end);
                plotFields{end + 1}   = {curTS.labels{ii}, slowLabel};
            end
        else
            % Slow label is missing — flag with 'F' prefix
            fieldOptions{end + 1} = strrep(curTS.labels{ii}, handles.fast, 'F');
            plotFields{end + 1}   = curTS.labels{ii};
        end
    elseif strcmp(curTS.labels{ii}(1), handles.slow)
        if ~any(strcmp(curTS.labels, [handles.fast, curTS.labels{ii}(2:end)]))
            % Fast label is missing — flag with 'S' prefix
            fieldOptions{end + 1} = strrep(curTS.labels{ii}, handles.slow, 'S');
            plotFields{end + 1}   = curTS.labels{ii};
        end
        % else: fast counterpart already added — skip
    elseif strcmpi(curTS.labels{ii}(max([end - 3, 1]):end), 'Fast')
        fieldOptions{end + 1} = curTS.labels{ii}(1:end - 4);
        plotFields{end + 1}   = {curTS.labels{ii}, ...
            [curTS.labels{ii}(1:end - 4), 'Slow']};
    elseif strcmpi(curTS.labels{ii}(max([end - 3, 1]):end), 'Slow')
        % Assume a 'Fast' counterpart already handled — skip
    else
        fieldOptions{end + 1} = curTS.labels{ii};
        plotFields{end + 1}   = curTS.labels{ii};
    end
end

set(fieldListHandle, 'String', fieldOptions);
if get(fieldListHandle, 'Value') > length(get(fieldListHandle, 'String'))
    set(fieldListHandle, 'Value', 1);
end
clear curTS
guidata(hObject, handles)
end


%% -----------------------------PLOTTING:----------------------------------

% --- Executes on slider movement.
function timeSlider_Callback(hObject, eventdata, handles)
handles.timeWindow = round(get(hObject, 'Value'));

% % % %to make zoomed-in time window start in middle of previous time window: % % % %
% timeToAdd=handles.timeWindow-(handles.tstop-handles.tstart);
% time1=max([handles.tstart-floor(timeToAdd/2) 0]);
% handles.tstop=handles.tstop+ceil(timeToAdd-(handles.tstart-time1));
% handles.tstart=time1;

% % % to make zoomed-in time window start at the beginning of the trial: % % % % %
% handles.tstop=handles.timeWindow;
% handles.tstart=0;
% Time window starts at the beginning of the previous window
handles.tstop = handles.tstart + handles.timeWindow;

set(handles.timeWindowText, 'String', handles.timeWindow);
guidata(hObject, handles)
plot_button_Callback(handles.plot_button, eventdata, handles)
end

% --- Executes on button press in maxCheck.
function maxCheck_Callback(hObject, eventdata, handles)
global expData
maxTime = ceil(expData.data{handles.idx}.gaitEvents.Time(end));
set(handles.timeSlider, 'Enable', 'On');
if get(handles.maxCheck, 'Value')
    handles.timeWindow = maxTime;
    handles.tstop      = maxTime;
    set(handles.timeSlider,     'Value',  maxTime);
    set(handles.timeWindowText, 'String', handles.timeWindow);
    set(handles.timeSlider,     'Enable', 'Off');
end
plot_button_Callback(handles.plot_button, eventdata, handles)
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

function last = plotData(handles, fieldHandle, dataTypeHandle, fieldList, axesHandle)

linkaxes([handles.axes1, handles.axes2], 'x')

global expData

fieldIdx = get(fieldHandle, 'Value');
dataType = handles.TSlist{get(dataTypeHandle, 'Value')};

TSdata = expData.data{handles.idx}.(dataType);
if isa(TSdata, 'parameterSeries')
    times = TSdata.hiddenTime;
else
    times = TSdata.Time;
end

if times(end) < handles.tstop || get(handles.maxCheck, 'Value')
    endSamp   = length(times);
    startSamp = max([1, endSamp - find(times <= handles.timeWindow, 1, 'last')]);
    last      = 1;
else
time=times(startSamp:endSamp); %should be same as time=handles.tstart:TSdata.sampPeriod:handles.tstop
    %get data to plot
        %plot data
        %found error 3/30/2016 this is plotting the same values regardless
        %of time scale, fixed
        %         plot(axesHandle,time(goodStrides),FdataTS.Data(goodStrides),'r.','MarkerSize',20);
        %         plot(axesHandle,time(goodStrides),SdataTS.Data(goodStrides),'b.','MarkerSize',20);
    startSamp = max([1, find(times >= handles.tstart, 1, 'first')]);
    endSamp   = max([startSamp, find(times <= handles.tstop, 1, 'last')]);
    last      = 0;
end

set(axesHandle, 'NextPlot', 'Replace')

if length(fieldList{fieldIdx}) == 2
    FdataTS = TSdata.getDataAsTS(fieldList{fieldIdx}{1});
    SdataTS = TSdata.getDataAsTS(fieldList{fieldIdx}{2});

    if strcmp(dataType, 'adaptParams')
        label      = fieldList{fieldIdx}{1}(1:end - 4);
        bad        = TSdata.bad(startSamp:endSamp);
        badStrides  = find(bad);
        goodStrides = find(~bad);
        plot(axesHandle, time(goodStrides), ...
            FdataTS.Data(startSamp + goodStrides), 'r.', 'MarkerSize', 20);
        set(axesHandle, 'NextPlot', 'Add')
        plot(axesHandle, time(goodStrides), ...
            SdataTS.Data(startSamp + goodStrides), 'b.', 'MarkerSize', 20);
        legendEntries = {'Fast', 'Slow'};
        if get(handles.showBadCheck, 'Value')
            plot(axesHandle, time(badStrides), ...
                FdataTS.Data(badStrides), 'ro', 'MarkerSize', 6);
            plot(axesHandle, time(badStrides), ...
                SdataTS.Data(badStrides), 'bo', 'MarkerSize', 6);
            legendEntries = {'Fast', 'Slow', 'Bad Fast', 'Bad Slow'};
        end
        % Events are not overlaid on adaptParams plots
    else
        label = fieldList{fieldIdx}{1}(2:end);
        plot(axesHandle, time, FdataTS.Data(startSamp:endSamp), 'r');
        set(axesHandle, 'NextPlot', 'Add')
        plot(axesHandle, time, SdataTS.Data(startSamp:endSamp), 'b');
        legendEntries = {'Fast', 'Slow'};

        % Build a struct of event times for the visible window.
        % ECF corrects for sampling frequency mismatch between events and data.
        % TODO: replace ECF with a resampling method on events.
        events     = handles.trialEvents;
        ECF        = events.sampFreq / TSdata.sampFreq;
        eventTimes = struct();
        for ii = 1:length(events.labels)
            evData = events.getDataAsVector(events.labels{ii});
            eventTimes.(events.labels{ii}) = times(startSamp) + ...
                events.Time(evData( ...
                    ceil((startSamp - 1) .* ECF + 1) : ...
                    floor((endSamp - 1) .* ECF + 1)) == 1);
        end
        if eval(['~isempty(',handles.fast,'HStimes)'])
            eval(['plot(axesHandle,',type,handles.fast,'HStimes,FdataTS.getSample(',type,handles.fast,'HStimes),''kx'',''LineWidth'',2);'])

        % Overlay events; only events in the time window are plotted to
        % avoid spurious legend entries from empty marker calls.
        type = handles.type;
        fastHStimes = eventTimes.([type handles.fast 'HS']);
        fastTOtimes = eventTimes.([type handles.fast 'TO']);
        slowHStimes = eventTimes.([type handles.slow 'HS']);
        slowTOtimes = eventTimes.([type handles.slow 'TO']);
            legendEntries{end + 1} = 'FHS';
        end
            eval(['plot(axesHandle,',type,handles.fast,'TOtimes,FdataTS.getSample(',type,handles.fast,'TOtimes),''ks'',''LineWidth'',2);'])
        if ~isempty(fastTOtimes)
            legendEntries{end + 1} = 'FTO';
        end
            eval(['plot(axesHandle,',type,handles.slow,'HStimes,SdataTS.getSample(',type,handles.slow,'HStimes),''ko'',''LineWidth'',2);'])
        if ~isempty(slowHStimes)
            legendEntries{end + 1} = 'SHS';
        end
        if eval(['~isempty(',handles.slow,'TOtimes)'])
            eval(['plot(axesHandle,',type,handles.slow,'TOtimes,SdataTS.getSample(',type,handles.slow,'TOtimes),''k*'',''LineWidth'',2);'])
            legendEntries{end + 1} = 'STO';
        end
    end
else
    label  = fieldList{fieldIdx};
    dataTS = TSdata.getDataAsTS(fieldList{fieldIdx});
    legendEntries = {'data'};

    if strcmp(dataType, 'adaptParams')
        bad        = TSdata.bad(startSamp:endSamp);
        badStrides  = find(bad);
        goodStrides = find(~bad);
        plot(axesHandle, time(goodStrides), ...
            dataTS.Data(startSamp + goodStrides), 'b.', 'MarkerSize', 20);
        set(axesHandle, 'NextPlot', 'Add')
        if get(handles.showBadCheck, 'Value')
            plot(axesHandle, time(badStrides), ...
                dataTS.Data(startSamp + badStrides), 'bo', 'MarkerSize', 6);
            legendEntries = {'data', 'bad data'};
        end
    else
        plot(axesHandle, time, dataTS.Data(startSamp:endSamp), 'b');
        set(axesHandle, 'NextPlot', 'Add')
    end
end

set(axesHandle, 'XLim', [handles.tstart handles.tstop]);
legendHandle = legend(axesHandle, legendEntries);
set(legendHandle, 'FontSize', 6)

clear RHS* LHS* LTO* RTO* events time
title(axesHandle, [label, ' ', dataType, ' Trial ', num2str(handles.idx)])
end

% --- Executes on button press in next_button.
function next_button_Callback(hObject, eventdata, handles)

set(handles.back_button, 'Enable', 'On')
if handles.last
        set(handles.trialMenu,'Value',get(handles.trialMenu,'Value')+1); %Add one to current trial, does this update what the GUI shows?
    if length(get(handles.trialMenu, 'String')) > get(handles.trialMenu, 'Value')
        trialMenu_Callback(handles.trialMenu, eventdata, handles)
    elseif get(handles.condMenu, 'Value') < length(get(handles.condMenu, 'String'))
        set(handles.condMenu,  'Value', get(handles.condMenu, 'Value') + 1);
        set(handles.trialMenu, 'Value', 1);
        condMenu_Callback(handles.condMenu, eventdata, handles)
    else
        set(hObject, 'Enable', 'Off')
        guidata(hObject, handles)
    end
else
    handles.tstart = handles.tstart + handles.timeWindow;
    handles.tstop  = handles.tstop  + handles.timeWindow;
    plot_button_Callback(handles.plot_button, eventdata, handles)
end

end

% --- Executes on button press in back_button.
function back_button_Callback(hObject, eventdata, handles)

set(handles.next_button, 'Enable', 'On')
if handles.tstart > 0
    handles.tstart = handles.tstart - handles.timeWindow;
    handles.tstop  = handles.tstop  - handles.timeWindow;
    plot_button_Callback(handles.plot_button, eventdata, handles)
    set(handles.trialMenu,'Value',get(handles.trialMenu,'Value')-1); %Add one to current trial, does this update what the GUI shows?
elseif get(handles.trialMenu, 'Value') > 1
    trialMenu_Callback(handles.trialMenu, eventdata, handles)
elseif get(handles.condMenu, 'Value') > 1
    set(handles.condMenu, 'Value', get(handles.condMenu, 'Value') - 1);
    handles.backButtonFlag = true;
    condMenu_Callback(handles.condMenu, eventdata, handles)
else
    set(hObject, 'Enable', 'Off')
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
switch get(eventdata.NewValue, 'Tag')
    case 'defaultRadio'
        handles.type = '';
    case 'kinematicRadio'
        handles.type = 'kin';
    case 'forceRadio'
        handles.type = 'force';
end
plot_button_Callback(handles.plot_button, eventdata, handles)
end

% --- Executes on button press in delete_button.
function delete_button_Callback(hObject, eventdata, handles)

global expData

%Select event
axes(handles.axes1)
[x, ~] = ginput;

%Find closest event(s)
allEventsIndexes = find(sum(handles.trialEvents.Data, 2) > 0);
minDeltaTThresh  = 1;     % events within 1 s of click are candidates (s)
paddingT         = 0.05;  % pad to also catch simultaneous alt-class event (s)
for ii = 1:length(x)
        %pad min value to delete events in same region from alt calcualtion
        %Eliminate it from handles.trialEvents
    deltaT    = handles.trialEvents.Time(allEventsIndexes) - x(ii);
    minDeltaT = min(abs(deltaT));
    if minDeltaT < minDeltaTThresh
        selectedEventTimeIndex = find(abs(deltaT) < minDeltaT + paddingT);
        selectedEventIndex     = allEventsIndexes(selectedEventTimeIndex);
        handles.trialEvents.Data(selectedEventIndex, :) = false;
    end
end

expData.data{handles.idx}.gaitEvents  = handles.trialEvents;
% NOTE: recalculating parameters here undoes any manual stride label edits
expData.data{handles.idx}.adaptParams = calcParameters( ...
    expData.data{handles.idx}, expData.subData);

guidata(hObject, handles)
plot_button_Callback(handles.plot_button, eventdata, handles)

end

% --- Executes on button press in deleteNbutton.
function deleteNbutton_Callback(hObject, eventdata, handles)

global expData

[x, ~] = ginput(2);

%Find two closest events
allEventsIndexes = find(sum(handles.trialEvents.Data, 2) > 0);

deltaTstart = handles.trialEvents.Time(allEventsIndexes) - x(1);
[~, selectedEventTimeIndexStart] = min(deltaTstart .^ 2);
selectedEventIndexStart = allEventsIndexes(selectedEventTimeIndexStart);

deltaTend = handles.trialEvents.Time(allEventsIndexes) - x(2);
[~, selectedEventTimeIndexEnd] = min(deltaTend .^ 2);
selectedEventIndexEnd = allEventsIndexes(selectedEventTimeIndexEnd);

%Eliminate all events between two indexes from handles.trialEvents
handles.trialEvents.Data(selectedEventIndexStart:selectedEventIndexEnd, :) = false;

expData.data{handles.idx}.gaitEvents  = handles.trialEvents;
expData.data{handles.idx}.adaptParams = calcParameters( ...
    expData.data{handles.idx}, expData.subData, handles.type);

guidata(hObject, handles)
plot_button_Callback(handles.plot_button, eventdata, handles)
end

% --- Executes on button press in add_button.
function add_button_Callback(hObject, eventdata, handles)
%Should this add a TO/HS for all event classes?

%Ask subject to select event type: SHS, FHS, STO, FTO
% Replace leg-specific prefixes ('R'/'L') with 'F'/'S' in event labels
events = handles.trialEvents.getLabels();
events = strrep(events, handles.fast, 'F');
events = strrep(events, handles.slow, 'S');
set(handles.eventType, 'String', events)
set(handles.eventType, 'Enable', 'On')

%Now the subject should select an event Type, so the function continues on
%eventType_callback
guidata(hObject, handles)

end

% --- Executes on selection change in eventType.
function eventType_Callback(hObject, eventdata, handles)
global expData

%Select location
[x, ~] = ginput(1);

%create new event in handles.trialEvents
[~, closestTimeIdx] = min(abs(handles.trialEvents.Time - x));
handles.trialEvents.Data(closestTimeIdx, get(handles.eventType, 'Value')) = true;

expData.data{handles.idx}.gaitEvents  = handles.trialEvents;
expData.data{handles.idx}.adaptParams = calcParameters( ...
    expData.data{handles.idx}, expData.subData, handles.type);

%Disable this
set(hObject, 'Enable', 'Off');
guidata(hObject, handles)

plot_button_Callback(handles.plot_button, eventdata, handles)
end

%% ---------------------------Stride Editing:-----------------------------

% --- Executes on button press in labelBadButton.
function labelBadButton_Callback(hObject, eventdata, handles)

global expData

%Select stride
axes(handles.axes1)
[boolFlag,idxs]=expData.data{handles.idx}.adaptParams.isaLabel({'bad','good'});
[x, ~] = ginput;

for ii = 1:length(x)
    %update 'bad' and 'good'
    if all(boolFlag)
        expData.data{handles.idx}.adaptParams.Data(loc,idxs)=[true, false];
    else
        expData.data{handles.idx}.adaptParams.Data(loc,idxs)=[true, false];
    end
    deltaT    = expData.data{handles.idx}.adaptParams.hiddenTime - x(ii);
    [~, loc]  = min(abs(deltaT));
end

guidata(hObject, handles)
plot_button_Callback(handles.plot_button, eventdata, handles)
end

% --- Executes on button press in labelGoodButton.
function labelGoodButton_Callback(hObject, eventdata, handles)

global expData

%Select stride
axes(handles.axes1)
[x, ~] = ginput;
[~, idxs] = expData.data{handles.idx}.adaptParams.isaLabel({'bad', 'good'});

for ii = 1:length(x)
    %update 'bad' and 'good'
    deltaT   = expData.data{handles.idx}.adaptParams.hiddenTime - x(ii);
    [~, loc] = min(abs(deltaT));
    expData.data{handles.idx}.adaptParams.Data(loc, idxs) = [false, true];
end

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
set(handles.write, 'Enable', 'On');
guidata(hObject, handles)
end

function uiSaveButton_ClickedCallback(hObject, eventdata, handles)
write_Callback(handles.write, eventdata, handles)
end

% --- Executes on button press in write.
function write_Callback(hObject, eventdata, handles)
global expData

%Disable everything
handles = disableFields(handles, 'plot_button', 'next_button', 'back_button', ...
    'delete_button', 'deleteNbutton', 'save_button', 'add_button', 'BPdataType', ...
    'BPfield', 'TPdataType', 'TPfield', 'condMenu', 'trialMenu', 'timeSlider', ...
    'maxCheck', 'defaultRadio', 'kinematicRadio', 'forceRadio', 'write', ...
    'labelBadButton', 'labelGoodButton', 'showBadCheck');

set(handles.write, 'String', 'Writing...');
drawnow

%eval(['save(''' handles.Dir handles.filename ''',''' handles.varName
%''');']); %PI: replaced this with the line below on 28/4/2015
%expData=expData.recomputeParameters; %% HH: I don't think this is necessary, should have already been re-computed earlier.
% eval(['save(''' handles.Dir handles.filename(1:end-4) 'params' ''',''adaptData'');']); %Saving with same var name --> No longer needed, makeDataObj method automatically saves file.
%Enable everything
% Save expData under its original workspace variable name
saveData.(handles.varName) = expData;
save([handles.Dir handles.filename], '-struct', 'saveData', '-v7.3');
handles.changed = false;
handles.saved   = true;

% Regenerate the *params.mat adaptationData file
adaptData = expData.makeDataObj([handles.Dir handles.filename(1:end - 4)]); %#ok<NASGU>

handles = enableFields(handles, 'plot_button', 'next_button', 'back_button', ...
    'delete_button', 'deleteNbutton', 'save_button', 'add_button', 'BPdataType', ...
    'BPfield', 'TPdataType', 'TPfield', 'condMenu', 'timeSlider', 'maxCheck', ...
    'trialMenu', 'defaultRadio', 'labelBadButton', 'labelGoodButton');
if length(expData.data{end}.gaitEvents.labels) == 12
    set(handles.kinematicRadio, 'Enable', 'On');
    set(handles.forceRadio,     'Enable', 'On');
end
set(handles.write, 'String', 'Write to disk');
guidata(hObject, handles);

end

%% ---------------------------CLOSING---------------------------------

% --- Executes when user attempts to close GUI_window.
function GUI_window_CloseRequestFcn(hObject, eventdata, handles)

%See if subject file should be saved before closing
if ~handles.changed && isfield(handles, 'filename') && ~handles.saved
    choice = questdlg( ...
        ['Do you want to save changes made to ', handles.filename, '?'], ...
        'ReviewEventsGUI', 'Save', 'Don''t Save', 'Cancel', 'Save');
    switch choice
        case 'Save'
            handles.changed = true;
        case 'Don''t Save'
            handles.changed = false;
        case {'Cancel', ''}
            return
    end
end

if handles.changed
    write_Callback(handles.write, eventdata, handles)
end

guidata(hObject, handles);
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
if ispc && isequal(get(hObject, 'BackgroundColor'), ...
        get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'White');
    set(hObject, 'String', './');
end
end

function subject_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','White');
end
end

function condMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','White');
end
end

function trialMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','White');
end
end

function TPfield_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','White');
end
end

function TPdataType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','White');
end
end

function BPdataType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','White');
end
end

function BPfield_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','White');
end
end

function eventType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','White');
end
end

function timeSlider_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', [0.9 0.9 0.9]);
end
end


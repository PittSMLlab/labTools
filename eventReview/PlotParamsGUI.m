function varargout = PlotParamsGUI(varargin)
% PLOTPARAMSGUI comments go here
%
% See also: 

% Last Modified by GUIDE v2.5 29-May-2015 15:32:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PlotParamsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @PlotParamsGUI_OutputFcn, ...
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

% --- Executes just before PlotParamsGUI is made visible.
function PlotParamsGUI_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for PlotParamsGUI
handles.output = hObject;

handles.SMatrix=makeSMatrix;
handles.groups=fields(handles.SMatrix);
g=handles.groups;

%Populate subject list
subs={};
handles.subjects={};
for i=1:length(g)
    auxSubs=handles.SMatrix.(g{i}).IDs(:,1);
    handles.subjects=[handles.subjects; auxSubs];
    if mod(i,2)==1
        for s=1:length(auxSubs)
           auxSubs{s}= ['<html><b>' auxSubs{s} '</b></html>'];
        end
    end
    subs=[subs; auxSubs];
end
set(handles.subjectList,'String',subs)

%populate parameter list (Just load one subject for now)
load(handles.SMatrix.(g{1}).IDs{1,9})
set(handles.parameterList,'String',adaptData.getParameterList)

%populate group list
for i=1:2:length(g)
g{i}=['<html><b>' g{i} '</b></html>'];
end
set(handles.groupList,'String',g);

% Update handles structure
guidata(hObject, handles);
% UIWAIT makes PlotParamsGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = PlotParamsGUI_OutputFcn(hObject, eventdata, handles) 

%Set GUI position to bottom of screen (not sure why this code only works 
%within this function...)
% left, bottom, width, height
scrsz = get(0,'ScreenSize'); 
set(gcf,'Units','pixels');
guiPos = get(gcf,'Position');
width=min([guiPos(3) scrsz(3)]);
height=min([guiPos(4) scrsz(4)]);
set(gcf, 'Position', [(scrsz(3)-width)/2 45 width height]);
% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --------------------------------------------------------------------
function saveTool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to saveTool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


function groupList_Callback(hObject, eventdata, handles)

%reset condition values
set(handles.conditionList,'Value',[])
set(handles.conditionSubList,'Value',[])
set(handles.conditionSubList,'String','')

if ~isempty(get(hObject,'Value'))    
    
    % contents=cellstr(get(hObject,'String'));
    contents=fields(handles.SMatrix);
    groups=contents(get(hObject,'Value'));

    % %populate condition listbox (All possible conditions)
    % conditions={};
    % for g=1:length(groups)
    % conditions=[conditions handles.SMatrix.(groups{g}).conditions];
    % end
    % conds=unique(conditions,'stable');
    % set(handles.conditionList,'string',conds')

    %populate condition listbox only with conditions all groups contatin
    conditions=handles.SMatrix.(groups{1}).conditions;
    for i=2:length(groups)
        auxCond=handles.SMatrix.(groups{i}).conditions;
        condPresent=false(1,length(conditions));
        for c=1:length(auxCond)
            condPresent=condPresent+ismember(conditions,auxCond(c));
        end
        if any(~condPresent)
            conditions(~condPresent)=[];
        end     
    end
    set(handles.conditionList,'string',conditions')
end


end

% --- Executes on selection change in subjectList.
function subjectList_Callback(hObject, eventdata, handles)

if ~isempty(get(hObject,'Value'))    
    
    selectedSubs=handles.subjects(get(hObject,'Value'));
    groups=fields(handles.SMatrix);
%     groups={};
%     for i=1:length(selectedSubs)
%         load([selectedSubs{i} 'params.mat'])
%         groups{end+1}=adaptData.metaData.ID;
%     end
%     groups=unique(groups);
    boolFlag=false(1,length(groups));
    for g=1:length(groups)
       for s=1:length(selectedSubs)
          if ismember(selectedSubs{s},handles.SMatrix.(groups{g}).IDs(:,1))
              boolFlag(g)=true;
          end
       end
    end
    groups=groups(boolFlag);

    conditions=handles.SMatrix.(groups{1}).conditions;
        for i=2:length(groups)
            auxCond=handles.SMatrix.(groups{i}).conditions;
            condPresent=false(1,length(conditions));
            for c=1:length(auxCond)
                condPresent=condPresent+ismember(conditions,auxCond(c));
            end
            if any(~condPresent)
                conditions(~condPresent)=[];
            end     
        end
        set(handles.conditionList,'string',conditions')
end

end


% --- Executes on selection change in parameterList.
function parameterList_Callback(hObject, eventdata, handles)
% hObject    handle to parameterList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns parameterList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from parameterList
end

% --- Executes on selection change in conditionList.
function conditionList_Callback(hObject, eventdata, handles)
contents = cellstr(get(hObject,'String'));
set(handles.conditionSubList,'string',contents(get(hObject,'Value')))
end

% --------------------------------------------------------------------
function openTool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to openTool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

function plotButton_Callback(hObject, eventdata, handles)

% ah = findall(handles.plotPanel,'type','axes');
% if ~isempty(ah)
%    delete(ah)
% end

% groupContents=cellstr(get(handles.groupList,'String'));
groupContents=fields(handles.SMatrix);
adaptDataList={};
indivSubList={{}};
if ~isempty(get(handles.groupList,'Value'))
    groups=groupContents(get(handles.groupList,'Value'));
    for g=1:length(groups)
        adaptDataList{g}=subFileList(handles.SMatrix.(groups{g}));
    end
    if ~isempty(get(handles.subjectList,'Value'))
        %need to segregate individual subjects by group
        indivSubs=handles.subjects(get(handles.subjectList,'Value'));
        for g=1:length(groups)
            for s=1:length(indivSubs)
                if ismember(indivSubs{s},handles.SMatrix.(groups{g}).IDs(:,1))
                    [~,locb]=ismember(indivSubs{s},handles.SMatrix.(groups{g}).IDs(:,1));
                    indivSubList{g}{end+1}=handles.SMatrix.(groups{g}).IDs{locb,9};
                    %indivSubList{g}{end+1}=[indivSubs{s} 'params.mat'];
                end
            end
        end
    end
else
    if ~isempty(get(handles.subjectList,'Value'))    
        indivSubs=handles.subjects(get(handles.subjectList,'Value'));
        for s=1:length(indivSubs)
            %adaptDataList{end+1}={[indivSubs{s} 'params.mat']};
            groups=fields(handles.SMatrix);
            for g=1:numel(groups)
                [~,locb]=ismember(indivSubs{s},handles.SMatrix.(groups{g}).IDs(:,1));
                if ~isempty(locb)
                    adaptDataList{end+1}={handles.SMatrix.(groups{g}).IDs{locb,9}};
                end
            end
        end
    end
end

paramContents=cellstr(get(handles.parameterList,'String'));
params=paramContents(get(handles.parameterList,'Value'))';
if get(handles.samePlotCheck,'Value')
    params=params';
end
condContents=cellstr(get(handles.conditionList,'String'));
conds=condContents(get(handles.conditionList,'Value'));

trialMarkerFlag=ismember(conds,conds(get(handles.conditionSubList,'Value')));

binwidth=str2double(get(handles.binEdit,'string'));
adaptationData.plotAvgTimeCourse(adaptDataList,params,conds,binwidth,trialMarkerFlag',get(handles.indivSubs,'Value'),indivSubList);
end


function binEdit_Callback(hObject, eventdata, handles)
% hObject    handle to binEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of binEdit as text
%        str2double(get(hObject,'String')) returns contents of binEdit as a double
end


% --- Executes on button press in indivSubs.
function indivSubs_Callback(hObject, eventdata, handles)
% hObject    handle to indivSubs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of indivSubs
end

% --- Executes on button press in samePlotCheck.
function samePlotCheck_Callback(hObject, eventdata, handles)
% hObject    handle to samePlotCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of samePlotCheck
end


% --- Executes on selection change in conditionSubList.
function conditionSubList_Callback(hObject, eventdata, handles)
% hObject    handle to conditionSubList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns conditionSubList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from conditionSubList
end


%%%%%%%%%%%%%%%%%%%%%%%  CREATE FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%
function conditionList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function parameterList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function groupList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function binEdit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function subjectList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function conditionSubList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

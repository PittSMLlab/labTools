function varargout = PlotParamsGUI(varargin)
% PLOTPARAMSGUI comments go here
%
% See also:

% Last Modified by GUIDE v2.5 11-Jun-2015 11:12:24

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

%% --- Executes just before PlotParamsGUI is made visible.
function varargout = PlotParamsGUI_OutputFcn(hObject, eventdata, handles)
%Outputs from this function are returned to the command line.

%Set GUI position to bottom of screen (not sure why this code only works within this function...)
% scrsz = get(0,'ScreenSize');
% set(gcf,'Units','pixels');
% guiPos = get(gcf,'Position');
% width=min([guiPos(3) scrsz(3)]);
% height=min([guiPos(4) scrsz(4)]);
% % left, bottom, width, height
% set(gcf, 'Position', [(scrsz(3)-width)/2 45 width height]);

% Get default command line output from handles structure
varargout{1} = handles.output;
end

function PlotParamsGUI_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for PlotParamsGUI
handles.output = hObject;

scrsz = get(0,'ScreenSize');
set(gcf,'Units','pixels');
guiPos = get(gcf,'Position');
width=min([guiPos(3) scrsz(3)]);
height=min([guiPos(4) scrsz(4)]);
% left, bottom, width, height
set(hObject, 'Position', [(scrsz(3)-width)/2 45 width height]);

handles.paramVals=[];
handles.SMatrix=makeSMatrix;
handles.results=getResults(handles.SMatrix,{'good'});
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

%set color strings
for i=1:17
    clr=get(handles.(['color' num2str(i)]),'BackgroundColor');
    set(handles.(['color' num2str(i)]),'ForeGroundColor',contrastColor(clr));
    set(handles.(['color' num2str(i)]),'string',['[' num2str(clr.*255) ']']);
end

%initialize drop down list with different color orders
path=which('PlotParamsGUI');
path=strrep(path,'PlotParamsGUI.m','Plotting Colors');
W=what(path);
colorOrders=cellstr(W.mat);
for i=1:length(colorOrders)
    fileExt=find(colorOrders{i}=='.');
    colorOrders{i}=colorOrders{i}(1:fileExt-1);
end
set(handles.colorMenu,'String',[' ';colorOrders])

% Update handles structure
guidata(hObject, handles);
% UIWAIT makes PlotParamsGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

%% --------------------------Selecting Plot Type:----------------------------------

% --- Executes when selected object is changed in plotTypePanel.
function plotTypePanel_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in plotTypePanel
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

%first, disable everything
handles = disableFields(handles,'groupList','subjectList','parameterList',...
    'conditionList','plotButton','binEdit','conditionSubList','indivSubs',...
    'samePlotCheck','regExpBox','maxPerturbCheck','earlyNumPts','lateNumPts',...
    'exptLastNumPts','removeBiasCheck','printCodeCheck','colorMenu','saveColorsButton');

for i=1:17
    set(handles.(['color' num2str(i)]),'Enable','off');
end

%Then, enable things based on plot type
switch get(eventdata.NewValue,'Tag')
    case 'timeCourseButton'
        handles.plotType=1;
        handles = enableFields(handles,'groupList','subjectList','parameterList',...
            'regExpBox','samePlotCheck','conditionList','conditionSubList',...
            'indivSubs','binEdit','printCodeCheck','colorMenu','saveColorsButton');
        for i=1:17
            set(handles.(['color' num2str(i)]),'Enable','on');
        end
        set(handles.parameterList,'max',10)
        set(handles.conditionText,'String','Conditions')
    case 'earlyLateBarButton'
        handles.plotType=2;
        handles = enableFields(handles,'groupList','subjectList','parameterList',...
            'regExpBox','conditionList','indivSubs','earlyNumPts','lateNumPts',...
            'exptLastNumPts','removeBiasCheck','printCodeCheck');
        set(handles.parameterList,'max',10)
        set(handles.conditionText,'String','Conditions')
    case 'scatterButton'
        handles.plotType=3;
        handles = enableFields(handles,'groupList','subjectList','parameterList',...
            'regExpBox','conditionList','binEdit');
    case 'epochBarButton'
        handles.plotType=4;
        handles = enableFields(handles,'groupList','parameterList','regExpBox',...
            'conditionList','maxPerturbCheck','indivSubs');
        set(handles.parameterList,'max',10)
        set(handles.conditionText,'String','Epochs')
        set(handles.conditionList,'String',fields(handles.results));
end
set(handles.plotButton,'enable','on')
guidata(hObject, handles);
end

function groupList_Callback(hObject, eventdata, handles)

if strcmpi(get(handles.conditionText,'string'),'conditions') %only if conditionList is filled with conditions
    
    conditionContents=get(handles.conditionList,'String');
    selectedConds=conditionContents(get(handles.conditionList,'Value'));
    conditionSubContents=get(handles.conditionSubList,'String');
    selectedSubConds=conditionSubContents(get(handles.conditionSubList,'Value'));
    %     %reset condition values
    %     set(handles.conditionList,'Value',[])
    %     set(handles.conditionSubList,'Value',[])
    %     set(handles.conditionSubList,'String','')
    
    if ~isempty(get(hObject,'Value'))
        
        % contents=cellstr(get(hObject,'String'));
        contents=fields(handles.SMatrix);
        groups=contents(get(hObject,'Value'));
        
        % %populate condition listbox (All possible conditions)
        %     conditions={};
        %     for g=1:length(groups)
        %     conditions=[conditions handles.SMatrix.(groups{g}).conditions];
        %     end
        %     conds=unique(conditions,'stable');
        %     set(handles.conditionList,'string',conds')
        
        %populate condition listbox only with conditions all groups contain
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
        
        %re-select conditions previously selected
        inds=find(ismember(conditions,selectedConds));
        set(handles.conditionList,'Value',inds)        
        subConds=conditions(inds);
        set(handles.conditionSubList,'String',subConds)
        subInds=find(ismember(subConds,selectedSubConds));
        set(handles.conditionSubList,'Value',subInds);
        
    end
end

end

% --- Executes on selection change in subjectList.
function subjectList_Callback(hObject, eventdata, handles)

if ~isempty(get(hObject,'Value')) && isempty(get(handles.groupList,'Value'))
    
    conditionContents=get(handles.conditionList,'String');
    selectedConds=conditionContents(get(handles.conditionList,'Value'));
    conditionSubContents=get(handles.conditionSubList,'String');
    selectedSubConds=conditionSubContents(get(handles.conditionSubList,'Value'));
    
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
            condPresent=condPresent+ismember(lower(conditions),lower(auxCond(c)));
        end
        if any(~condPresent)
            conditions(~condPresent)=[];
        end
    end
    set(handles.conditionList,'string',conditions')
    
    %re-select conditions previously selected
    inds=find(ismember(conditions,selectedConds));
    if ~isempty(inds)
        set(handles.conditionList,'Value',inds)
        subConds=conditions(inds);
        set(handles.conditionSubList,'String',subConds)
        subInds=find(ismember(subConds,selectedSubConds));
        set(handles.conditionSubList,'Value',subInds);
    end
end

end

% --- Executes on selection change in parameterList.
function parameterList_Callback(hObject, eventdata, handles)
% hObject    handle to parameterList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns parameterList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from parameterList

values=get(hObject,'Value');
newVals=values(~ismember(values,handles.paramVals));
handles.paramVals=values(ismember(values,handles.paramVals));
maxNum=get(hObject,'max');
if length(values)>maxNum
    allVals=[handles.paramVals newVals];
    handles.paramVals=allVals(end-(maxNum-1):end);
else
    handles.paramVals=[handles.paramVals newVals];
end
set(hObject,'Value',handles.paramVals)

guidata(hObject, handles);
end

% --- Executes on selection change in conditionList.
function conditionList_Callback(hObject, eventdata, handles)

conditionSubContents=get(handles.conditionSubList,'String');
selectedSubConds=conditionSubContents(get(handles.conditionSubList,'Value'));

set(handles.conditionSubList,'Value',[])
contents = cellstr(get(hObject,'String'));
set(handles.conditionSubList,'string',contents(get(hObject,'Value')))

%re-select conditions previously selected
inds=find(ismember(contents(get(hObject,'Value')),selectedSubConds));
set(handles.conditionSubList,'Value',inds)


end

%% --------------------------------------------------------------------
function saveTool_ClickedCallback(hObject, eventdata, handles)

end

% --------------------------------------------------------------------
function openTool_ClickedCallback(hObject, eventdata, handles)

end

function plotButton_Callback(hObject, eventdata, handles)
% groupContents=cellstr(get(handles.groupList,'String'));

%get color order
colorOrder=zeros(17,3);
for i=1:17
    colorOrder(i,:)=get(handles.(['color' num2str(i)]),'BackgroundColor');
end

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
                if locb~=0
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

indivSubFlag=get(handles.indivSubs,'Value');

switch handles.plotType
    case 1
        trialMarkerFlag=ismember(conds,conds(get(handles.conditionSubList,'Value')));
        binwidth=str2double(get(handles.binEdit,'string'));
        adaptationData.plotAvgTimeCourse(adaptDataList,params,conds,binwidth,trialMarkerFlag',indivSubFlag,indivSubList,colorOrder);
        %to print code previous line to command window:
        if get(handles.printCodeCheck,'value')
            for g=1:length(adaptDataList)
                aux{g}=['{' strjoin(adaptDataList{g},',') '}'];
            end
            for g=1:length(indivSubList)
                aux2{g}=['{' strjoin(indivSubList{g},',') '}'];
            end
            adaptDataStr=['{' strjoin(aux,',') '}'];
            indivSubStr=['{' strjoin(aux2,',') '}'];
            if get(handles.samePlotCheck,'Value')
                paramStr=['{' strjoin(params,';') '}'];
            else
                paramStr=['{' strjoin(params,',') '}'];
            end
            paramStr=['{' strjoin(params,',') '}'];
            disp(['adaptationData.plotAvgTimeCourse(' adaptDataStr ',' paramStr ',' num2str(binwidth) ',[' num2str(trialMarkerFlag') '],' num2str(indivSubFlag) ',' indivSubStr ')'])
        end
    case 2
        removeBiasFlag=1;
        earlyNumber=[];
        lateNumber=[];
        exemptLast=[];
        legendNames=[];
        significanceThreshold=0.01;
        adaptationData.plotGroupedSubjectsBars(adaptDataList,params,removeBiasFlag,indivSubFlag,conds,earlyNumber,lateNumber,exemptLast,legendNames,significanceThreshold)
    case 3
        binSize=str2double(get(handles.binEdit,'string'));
        removeBias=1;
        adaptationData.groupedScatterPlot(adaptDataList,params,conds,binSize,[],[])
    case 4
        results=getResults(handles.SMatrix,params,groups,get(handles.maxPerturbCheck,'value'));
        barGroups(handles.SMatrix,results,groups,params,conds,indivSubFlag);
end
end


function binEdit_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of binEdit as text
%        str2double(get(hObject,'String')) returns contents of binEdit as a double
end


% --- Executes on button press in indivSubs.
function indivSubs_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of indivSubs
end

% --- Executes on button press in samePlotCheck.
function samePlotCheck_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of samePlotCheck
end


% --- Executes on selection change in conditionSubList.
function conditionSubList_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns conditionSubList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from conditionSubList
end

function regExpBox_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of regExpBox as text
%        str2double(get(hObject,'String')) returns contents of regExpBox as a double

expression=get(hObject,'String');
%Get labels that match:
paramList=cellstr(get(handles.parameterList,'String'));
aux=regexp(paramList,expression);
bool=cellfun(@(x) ~isempty(x),aux);
inds=find(bool);
set(handles.parameterList,'Value',inds(1:min([end get(handles.parameterList,'max')])));
end


% --- Executes on button press in maxPerturbCheck.
function maxPerturbCheck_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of maxPerturbCheck
end


function earlyNumPts_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of earlyNumPts as text
%        str2double(get(hObject,'String')) returns contents of earlyNumPts as a double
end

function lateNumPts_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of lateNumPts as text
%        str2double(get(hObject,'String')) returns contents of lateNumPts as a double
end


function exptLastNumPts_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of exptLastNumPts as text
%        str2double(get(hObject,'String')) returns contents of exptLastNumPts as a double
end

% --- Executes on button press in removeBiasCheck.
function removeBiasCheck_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of removeBiasCheck
end

% --- Executes on button press in printCodeCheck.
function printCodeCheck_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of printCodeCheck
end


% --- Executes on selection change in colorMenu.
function colorMenu_Callback(hObject, eventdata, handles)
% hObject    handle to colorMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns colorMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from colorMenu

%initialize drop down list with different color orders
path=which('PlotParamsGUI');
path=strrep(path,'PlotParamsGUI.m','Plotting Colors');
contents=cellstr(get(hObject,'String'));
colorFile=contents{get(hObject,'Value')};

if exist([path filesep colorFile '.mat'],'file')>0
    a=load([path filesep colorFile]);
    aux=fields(a);
    colorOrder=a.(aux{1});

    if size(colorOrder,2)==3 && max(max(colorOrder))<=1 && min(min(colorOrder))>=0
        for i=1:min([17 size(colorOrder,1)])
            clr=colorOrder(i,:);
            set(handles.(['color' num2str(i)]),'String',['[' num2str(round(clr.*255)) ']']);
            set(handles.(['color' num2str(i)]),'BackgroundColor',clr);
            set(handles.(['color' num2str(i)]),'ForeGroundColor',contrastColor(clr));
        end
    end
end

end

% --- Executes on button press in saveColorsButton.
function saveColorsButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveColorsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
colorOrder=nan(17,3);
for i=1:17
   colorOrder(i,:)=get(handles.(['color' num2str(i)]),'backgroundColor'); 
end
answer = inputdlg('Eneter name of new color order: ','File Name Input');
path=which('PlotParamsGUI');
path=strrep(path,'PlotParamsGUI.m','Plotting Colors');
save([path filesep char(answer)],'colorOrder')

W=what(path);
colorOrders=cellstr(W.mat);
for i=1:length(colorOrders)
    fileExt=find(colorOrders{i}=='.');
    colorOrders{i}=colorOrders{i}(1:fileExt-1);
end
set(handles.colorMenu,'String',[' ';colorOrders])
end

%% --------------------- Color Buttons --------------------------------%%

function color1_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color2_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color3_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color4_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color5_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color6_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color7_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color8_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color9_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color10_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color11_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color12_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color13_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color14_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color15_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color16_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function color17_Callback(hObject, eventdata, handles)
handles = colorButtonCallback(hObject,handles);
guidata(hObject, handles);
end

function handles = colorButtonCallback(hObject,handles)
%open up color selection tool
clr=uisetcolor(get(hObject,'BackgroundColor'),'Set Color');
rgb=round(clr.*255);
%change background,foreground, and string of button
set(hObject,'BackgroundColor',clr)
set(hObject,'ForegroundColor',contrastColor(clr))
set(hObject,'String',['[' num2str(rgb) ']']);
%update color order?
end

%% ------------- CREATE FUNCTIONS - DO NOT EDIT ------------------------%%

% hObject    handle to exptLastNumPts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

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

function regExpBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function earlyNumPts_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function lateNumPts_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function exptLastNumPts_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function colorMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over regExpBox.
function regExpBox_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to regExpBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

function varargout = PlotParamsGUI(varargin)
% PLOTPARAMSGUI comments go here
%
% See also:

% Last Modified by GUIDE v2.5 04-May-2016 12:48:39

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

function PlotParamsGUI_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for PlotParamsGUI
handles.output = hObject;

%Position GUI window in the bottom, center of the screen
scrsz = get(0,'ScreenSize');
set(gcf,'Units','pixels');
guiPos = get(gcf,'Position'); % left, bottom, width, height
width=min([guiPos(3) scrsz(3)]);
height=min([guiPos(4) scrsz(4)]);
set(hObject, 'Position', [(scrsz(3)-width)/2 45 width height]);

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

function varargout = PlotParamsGUI_OutputFcn(hObject, eventdata, handles)
%Outputs from this function are returned to the command line.

% Get default command line output from handles structure
varargout{1} = handles.output;
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
    'exptLastNumPts','removeBiasCheck','printCodeCheck','colorMenu','saveColorsButton','biofeedback','AlignEnd2','InitiAlig');

for i=1:17
    set(handles.(['color' num2str(i)]),'Enable','off');
end

%Then, enable things based on plot type
switch get(eventdata.NewValue,'Tag')
    case 'timeCourseButton'
        handles.plotType=1;
        handles = enableFields(handles,'groupList','subjectList','parameterList',...
            'regExpBox','samePlotCheck','conditionList','conditionSubList',...
            'indivSubs','binEdit','printCodeCheck','colorMenu','saveColorsButton','biofeedback','removeBiasCheck','AlignEnd2','InitiAlig');
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
        set(handles.parameterList,'max',3)
    case 'epochBarButton'
        results=getResults(handles.Study,{'good'},handles.groups(1));
        handles.plotType=4;
        handles = enableFields(handles,'groupList','parameterList','regExpBox',...
            'conditionList','maxPerturbCheck','indivSubs','printCodeCheck',...
            'colorMenu','saveColorsButton');
        for i=1:17
            set(handles.(['color' num2str(i)]),'Enable','on');
        end 
        set(handles.parameterList,'max',10)
        set(handles.conditionText,'String','Epochs')
        set(handles.conditionList,'String',fields(results));
    case 'correlationButton'
        results=getResults(handles.Study,{'good'},handles.groups(1));
        handles.plotType=5;
        handles = enableFields(handles,'groupList','parameterList','regExpBox',...
            'conditionList');
        set(handles.parameterList,'max',5)      
        set(handles.conditionText,'String','Epochs')
        set(handles.conditionList,'String',fields(results),'max',2)
    case 'CorrelationParams'
        results=getResults(handles.Study,{'good'},handles.groups(1));
        handles.plotType=6;
        handles = enableFields(handles,'groupList','parameterList','regExpBox',...
            'conditionList');
        set(handles.parameterList,'max',2)
        set(handles.conditionText,'String','Epochs')
        set(handles.conditionList,'String',fields(results),'max',5)
        
end
set(handles.plotButton,'enable','on')
guidata(hObject, handles);
end

%% ---------------- Selecting Groups/Subjects to Plot ----------------- %%

function groupList_Callback(hObject, eventdata, handles)
%when a group is selected, the parameter list and condition lists are
%populated with options based on common conditions/parameters that all subs
%in all groups selected contain


if ~isempty(get(hObject,'Value')) %if at least one group is selected
        
    % contents=cellstr(get(hObject,'String')); <-- this returns groups with html formatting. Not good!
    contents=fields(handles.Study);
    groups=contents(get(hObject,'Value'));
    
    %create groupAdaptationData with all subjects
    allGroups=handles.Study.(groups{1});
    for i=2:length(groups)
        allGroups=cat(allGroups,handles.Study.(groups{i}));
    end

    % %populate condition listbox (All possible conditions)
    %     conditions={};
    %     for g=1:length(groups)
    %     conditions=[conditions handles.Study.(groups{g}).getCommonConditions];
    %     end
    %     conds=unique(conditions,'stable');
    %     set(handles.conditionList,'string',conds')

    
    if strcmpi(get(handles.conditionText,'string'),'conditions') %only if conditionList is filled with conditions (and not epochs)
        %get current state of condition/parameter lists
        conditionContents=get(handles.conditionList,'String');
        selectedConds=conditionContents(get(handles.conditionList,'Value'));
        conditionSubContents=get(handles.conditionSubList,'String');
        selectedSubConds=conditionSubContents(get(handles.conditionSubList,'Value'));
        
        conditions=allGroups.getCommonConditions;
        set(handles.conditionList,'string',conditions')
        
        %re-select conditions/parameters previously selected
        condInds=find(ismember(conditions,selectedConds));
        set(handles.conditionList,'Value',condInds)
        subConds=conditions(condInds);
        set(handles.conditionSubList,'String',subConds)
        subInds=find(ismember(subConds,selectedSubConds));
        set(handles.conditionSubList,'Value',subInds);
    end
    
    parameterContents=get(handles.parameterList,'String');
    selectedParams=parameterContents(get(handles.parameterList,'Value'));
    
    [parameters,handles.descriptions]=allGroups.getCommonParameters;    
    set(handles.parameterList,'string',parameters)
    
    paramInds=find(ismember(parameters,selectedParams));
    set(handles.parameterList,'Value',paramInds);
    
    guidata(hObject, handles);
else        
    if strcmp(get(handles.subjectList,'enable'),'on')
        subjectList_Callback(handles.subjectList,eventdata,handles)
    end
end

end

% --- Executes on selection change in subjectList.
function subjectList_Callback(hObject, eventdata, handles)

if isempty(get(handles.groupList,'Value'))
    if ~isempty(get(hObject,'Value')) %only enter if no groups are selected but at least one subjects is
        
        %get current state of condition lists
        conditionContents=get(handles.conditionList,'String');
        selectedConds=conditionContents(get(handles.conditionList,'Value'));
        conditionSubContents=get(handles.conditionSubList,'String');
        selectedSubConds=conditionSubContents(get(handles.conditionSubList,'Value'));
        parameterContents=get(handles.parameterList,'String');
        selectedParams=parameterContents(get(handles.parameterList,'Value'));
        
        selectedSubs=handles.subjects(get(hObject,'Value'));
        groups=fields(handles.Study);
        
        %determine which groups subjects belong to
        boolFlag=false(1,length(groups));
        for g=1:length(groups)
            for s=1:length(selectedSubs)
                if ismember(selectedSubs{s},handles.Study.(groups{g}).ID)
                    boolFlag(g)=true;
                end
            end
        end
        groups=groups(boolFlag);
        
        allGroups=handles.Study.(groups{1});
        for i=2:length(groups)
            allGroups=cat(allGroups,handles.Study.(groups{i}));
        end
        conditions=allGroups.getCommonConditions(selectedSubs);
        [parameters,handles.descriptions]=allGroups.getCommonParameters(selectedSubs);
        set(handles.conditionList,'string',conditions')
        set(handles.parameterList,'string',parameters)
        
        %re-select conditions previously selected
        condInds=find(ismember(conditions,selectedConds));
        set(handles.conditionList,'Value',condInds)
        subConds=conditions(condInds);
        set(handles.conditionSubList,'String',subConds)
        subInds=find(ismember(subConds,selectedSubConds));
        set(handles.conditionSubList,'Value',subInds);
        paramInds=find(ismember(parameters,selectedParams));
        set(handles.parameterList,'Value',paramInds);
    else
        %reset condition/parameter values
        set(handles.conditionList,'Value',[])
        set(handles.conditionList,'String','')
        set(handles.conditionSubList,'Value',[])
        set(handles.conditionSubList,'String','')
        set(handles.parameterList,'Value',[])
        set(handles.parameterList,'String','')
    end
end

guidata(hObject, handles);
end

%% ------------  Other options for plotting ---------------- %%

% --- Executes on selection change in parameterList.
function parameterList_Callback(hObject, eventdata, handles)


values=get(hObject,'Value');

if strcmp(get(handles.figure1,'SelectionType'),'open')
    description=handles.descriptions{values}; % display window with parameter description
    msgbox(description,'Description');
end

%restrict the number of selected parameters to be less than or equal to
%'max' property of the list
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

%add selected conditions to list for plotting individual trials (only for time course)
if handles.plotType==1 
    conditionSubContents=get(handles.conditionSubList,'String');
    selectedSubConds=conditionSubContents(get(handles.conditionSubList,'Value'));

    set(handles.conditionSubList,'Value',[])
    contents = cellstr(get(hObject,'String'));
    set(handles.conditionSubList,'string',contents(get(hObject,'Value')))

    %re-select conditions previously selected
    inds=find(ismember(contents(get(hObject,'Value')),selectedSubConds));
    set(handles.conditionSubList,'Value',inds)
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

% --- Executes on button press in biofeedback.
function biofeedback_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of biofeedback
end

% --- Executes on button press in printCodeCheck.
function printCodeCheck_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of printCodeCheck
end

function AlignEnd2_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of AlignEnd2 as text
%        str2double(get(hObject,'String')) returns contents of AlignEnd2 as a double
end

function InitiAlig_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of InitiAlig as text
%        str2double(get(hObject,'String')) returns contents of InitiAlig as a double

end

%% ----------------- Open/Save button in toolstrip --------------------- %%
function saveTool_ClickedCallback(hObject, eventdata, handles)

end

function openTool_ClickedCallback(hObject, eventdata, handles)

[handles.filename,handles.dir]=uigetfile('*.mat','Choose study file'); %opens browse window

if handles.filename~=0
    
    h=msgbox('Opening...','');
    child = get(h,'children');
    delete(child(1)); %delete OK button
    drawnow
    aux=load([handles.dir handles.filename]); %.mat file can only contain 1 variable: structure with groupAdaptationData objects
    
    close(h)
    
    fieldNames=fields(aux);
    handles.varName=fieldNames{1};
    handles.Study=aux.(fieldNames{1});     
    %Inititalize handle fields
    handles.paramVals=[];
    handles.groups=fields(handles.Study);   

    %Populate subject list
    g=handles.groups;
    subs={};
    handles.subjects={};
    for i=1:length(g)
        auxSubs=handles.Study.(g{i}).ID;
        handles.subjects=[handles.subjects auxSubs];
        if mod(i,2)==1
            for s=1:length(auxSubs)
                auxSubs{s}= ['<html><b>' auxSubs{s} '</b></html>']; %html tags allow for formating font
            end
        end
        subs=[subs; auxSubs'];
    end
    set(handles.subjectList,'String',subs)


    %populate group list
    for i=1:2:length(g)
        g{i}=['<html><b>' g{i} '</b></html>'];
    end
    set(handles.groupList,'String',g);
end
guidata(hObject, handles);
end

%% -------------------- Do the actual plotting ------------------------%%

function plotButton_Callback(hObject, eventdata, handles)
% groupContents=cellstr(get(handles.groupList,'String'));

%get color order
colorOrder=zeros(17,3);
for i=1:17
    colorOrder(i,:)=get(handles.(['color' num2str(i)]),'BackgroundColor');
end

groupContents=fields(handles.Study);
adaptDataList={};
indivSubList={};%cell(1,length(get(handles.subjectList,'Value')));
indivSubStr='[]';
if handles.plotType==2 %%DULCE
    if ~isempty(get(handles.groupList,'Value'))
        groups=groupContents(get(handles.groupList,'Value'));
        for g=1:length(groups)
            %adaptDataList{g}=subFileList(handles.Study.(groups{g})); %%HH 6/17
            adaptDataList{g}= handles.Study.(groups{g});
        end
    end
else
    if ~isempty(get(handles.groupList,'Value'))    
    groups=groupContents(get(handles.groupList,'Value'));
    for g=1:length(groups)
        %adaptDataList{g}=subFileList(handles.Study.(groups{g})); %%HH 6/17
        adaptDataList{g}= handles.Study.(groups{g}).adaptData;
    end
    adaptDataStr=['{' strjoin(strcat([handles.varName '.'],groups,'.adaptData')',',') '}'];
    if ~isempty(get(handles.subjectList,'Value'))
        indivSubList=cell(1,length(get(handles.groupList,'Value')));
        indivSubStr=adaptDataStr;
        %need to segregate individual subjects by group
        indivSubs=handles.subjects(get(handles.subjectList,'Value'));
        for g=1:length(groups)
            [isAinB,locAinB]=ismember(indivSubs,handles.Study.(groups{g}).ID);
            for s=1:length(indivSubs)                
                if isAinB(s)                    
                    indivSubList{g}{end+1}=handles.Study.(groups{g}).adaptData{locAinB(s)};
                end                
            end
            indivSubStr=strrep(indivSubStr,[groups{g} '.adaptData'],[groups{g} '.adaptData{' num2str(locAinB(isAinB)) '}']);
        end
    end
else    
    if ~isempty(get(handles.subjectList,'Value'))
        indivSubs=handles.subjects(get(handles.subjectList,'Value'));
        for s=1:length(indivSubs)
            %adaptDataList{end+1}={[indivSubs{s} 'params.mat']};
            groups=fields(handles.Study);
            for g=1:numel(groups)
                [isAinB,locAinB]=ismember(indivSubs{s},handles.Study.(groups{g}).ID);
                if isAinB
                    adaptDataList{end+1}=handles.Study.(groups{g}).adaptData(locAinB);
                end
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
if get(handles.samePlotCheck,'Value')
    paramStr=['{' strjoin(strcat('''',params,'''')',';') '}'];
else
    paramStr=['{' strjoin(strcat('''',params,''''),',') '}'];
end

condContents=cellstr(get(handles.conditionList,'String'));
conds=condContents(get(handles.conditionList,'Value'));
condStr=['{' strjoin(strcat('''',conds,'''')',',') '}'];

indivSubFlag=get(handles.indivSubs,'Value');
biofeedbackFlag=get(handles.biofeedback,'Value');
removeBias=get(handles.removeBiasCheck,'Value');

switch handles.plotType
    case 1 %time course
        trialMarkerFlag=ismember(conds,conds(get(handles.conditionSubList,'Value')));
        binwidth=str2double(get(handles.binEdit,'string'));
        alignEndFlag=str2double(get(handles.AlignEnd2,'string'));
        initiAligFlat=str2double(get(handles.InitiAlig,'string'));
        adaptationData.plotAvgTimeCourse(adaptDataList,params,conds,binwidth,trialMarkerFlag',indivSubFlag,indivSubList,colorOrder,biofeedbackFlag,removeBias,groups,[],[],alignEndFlag,initiAligFlat);
        %to print code previous line to command window:
        if get(handles.printCodeCheck,'value')
            disp(['load(''' handles.dir handles.filename ''')'])
            disp(['adaptDataList = ' adaptDataStr ';'])
            disp(['params = ' paramStr ';'])
            disp(['conds = ' condStr ';'])
            disp(['binWidth = ' num2str(binwidth) ';'])
            disp(['trialMarkerFlag = [' num2str(trialMarkerFlag') '];'])
            disp(['indivSubFlag = ' num2str(indivSubFlag) ';'])
            disp(['IndivSubList = ' indivSubStr ';'])   
            disp(['removeBias = ' removeBias ';'])
            disp(['groups = ' groups ';'])
            disp(['adaptationData.plotAvgTimeCourse(adaptDataList,params,conds,binWidth,trialMarkerFlag,indivSubFlag,IndivSubList,' num2str(biofeedbackFlag) ')','removeBias','groups'])
        end
    case 2 % early/late bars
        removeBiasFlag=get(handles.removeBiasCheck,'Value');
        earlyNumber=[str2double(get(handles.earlyNumPts,'string')) str2double(get(handles.lateNumPts,'string'))];
        lateNumber=[];
        exemptLast=str2double(get(handles.exptLastNumPts,'string'));
        legendNames=[];
        significanceThreshold=0.01;
        adaptationData.plotGroupedSubjectsBarsv2(adaptDataList,params,removeBiasFlag,indivSubFlag,conds,earlyNumber,lateNumber,exemptLast,legendNames,significanceThreshold)
    case 3 % scatter plot
        binSize=str2double(get(handles.binEdit,'string'));
%         removeBias=1;
        adaptationData.scatterPlotLab(adaptDataList,params,conds,[],[],binSize,[],removeBias)
        
    case 4 %epoch bars
        results=getResults(handles.Study,params,groups,get(handles.maxPerturbCheck,'value'));
        barGroups(handles.Study,results,groups,params,conds,indivSubFlag,colorOrder);
        if get(handles.printCodeCheck,'value')
            disp(['load(''' handles.dir handles.filename ''')'])
            disp(['groups = {' strjoin(strcat('''',groups,'''')',',') '};'])
            disp(['params = ' paramStr ';'])
            disp(['results = getResults(' handles.varName ',params,groups,' num2str(get(handles.maxPerturbCheck,'value')) ');'])
            disp(['epochs = ' condStr ';'])            
            disp(['indivSubFlag = ' num2str(indivSubFlag) ';'])                 
            disp(['barGroups(' handles.varName ',results,groups,params,epochs,indivSubFlag)'])
        end
        
    case 5 %correlation
        results=getResults(handles.Study,params,groups,get(handles.maxPerturbCheck,'value'));
        adaptationData.Correlations(adaptDataList,results,params,conds,groups,colorOrder,1)
    case 6 %correlation by params 
        results=getResults(handles.Study,params,groups,get(handles.maxPerturbCheck,'value'));
        adaptationData.Correlations(adaptDataList,results,params,conds,groups,colorOrder,2)
       
        
end
end


%% ------------------ Color order selection ---------------------------- %%

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

function AlignEnd2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function InitiAlig_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

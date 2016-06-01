function varargout = GetInfoGUIbeta(varargin)
% GETINFOGUIBETA MATLAB code for GetInfoGUIbeta.fig
%      GETINFOGUIBETA, by itself, creates a new GETINFOGUIBETA or raises the existing
%      singleton*.
%
%      H = GETINFOGUIBETA returns the handle to a new GETINFOGUIBETA or the handle to
%      the existing singleton*.
%
%      GETINFOGUIBETA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GETINFOGUIBETA.M with the given input arguments.
%
%      GETINFOGUIBETA('Property','Value',...) creates a new GETINFOGUIBETA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GetInfoGUIbeta_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GetInfoGUIbeta_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GetInfoGUIbeta

% Last Modified by GUIDE v2.5 24-May-2016 15:00:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GetInfoGUIbeta_OpeningFcn, ...
                   'gui_OutputFcn',  @GetInfoGUIbeta_OutputFcn, ...
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


% --- Executes just before GetInfoGUIbeta is made visible.
function GetInfoGUIbeta_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GetInfoGUIbeta (see VARARGIN)

% Choose default command line output for GetInfoGUIbeta
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%Set GUI position to middle of screen
% left, bottom, width, height
scrsz = get(0,'ScreenSize'); 
set(gcf,'Units','pixels');
guiPos = get(hObject,'Position');
set(hObject, 'Position', [(scrsz(3)-guiPos(3))/2 (scrsz(4)-guiPos(4))/2 guiPos(3) guiPos(4)]);

% UIWAIT makes GetInfoGUIbeta wait for user response (see UIRESUME)
uiwait(handles.figure1);
clc

% --- Outputs from this function are returned to the command line.
function varargout = GetInfoGUIbeta_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~(isfield(handles,'noSave') && handles.noSave)
    info=handles.info;

    %Forcing save before the rest of the things are done (so, if it fails, we
    %don't lose it).
    if exist([info.save_folder filesep info.ID 'info.mat'],'file')>0
        choice=questdlg(['Info file (and possibly others) already exist for ' info.ID '. Overwrite?'],'File Name Warning','Yes','No','No');
        if strcmp(choice,'No')            
            info.ID = [info.ID '_' date];
            h=msgbox(['Saving as ' info.ID],'');
            waitfor(h)          
        end                
    end
    save([info.save_folder filesep info.ID 'info'],'info')

    %ask user if there are observations for individual trials
    answer=inputdlg('Are there any observations for individual trials?(y/n) ','s');

    %make sure the correct response is entered
    while length(answer{1})>1 || (~strcmpi(answer{1},'y') && ~strcmpi(answer{1},'n'))
        disp('Error: you must enter either "y" or "n"')
        answer=inputdlg('Are there any observations for individual trials?(y/n) ','s');
    end

    %create a menu to choose any trial
    expTrials = cell2mat(info.trialnums);
    numTrials = length(expTrials);
    if ~isfield(info,'trialObs') || length(info.trialObs)<info.numoftrials
        %if a subject wasn't loaded
        info.trialObs{1,info.numoftrials} = '';
    end
    if strcmpi(answer{1},'y')    
        trialstr = [];
        %create trial string
        for t = expTrials
            trialstr = [trialstr,',''Trial ',num2str(t),''''];
        end
        %generate menu
        eval(['choice = menu(''Choose Trial''',trialstr,',''Done'');'])
        while choice ~= numTrials+1
            % get observation for trial selected
            obStr = inputdlg(['Observations for Trial ',num2str(expTrials(choice))],'Enter Observation');
            info.trialObs{expTrials(choice)} = obStr{1,1}; % obStr by itself is a cell object, so need to index to make a char
            eval(['choice = menu(''Choose Trial''',trialstr,',''Done'');'])
        end   
    end

    varargout{1}=info;
    save([info.save_folder filesep info.ID 'info'],'info')
else
    varargout{1}=[];
end


delete(handles.figure1)

% --- Executes on selection change in descriptionmenu.
function descriptionmenu_Callback(hObject, eventdata, handles)
% hObject    handle to descriptionmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns descriptionmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from descriptionmenu


% --- Executes during object creation, after setting all properties.
function descriptionmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to descriptionmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function subID_edit_Callback(hObject, eventdata, handles)
% hObject    handle to subID_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of subID_edit as text
%        str2double(get(hObject,'String')) returns contents of subID_edit as a double


% --- Executes during object creation, after setting all properties.
function subID_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subID_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in gender_list.
function gender_list_Callback(hObject, eventdata, handles)
% hObject    handle to gender_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns gender_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from gender_list


% --- Executes during object creation, after setting all properties.
function gender_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gender_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in DOBmonth_list.
function DOBmonth_list_Callback(hObject, eventdata, handles)
% hObject    handle to DOBmonth_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns DOBmonth_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from DOBmonth_list


% --- Executes during object creation, after setting all properties.
function DOBmonth_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DOBmonth_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DOBday_edit_Callback(hObject, eventdata, handles)
% hObject    handle to DOBday_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DOBday_edit as text
%        str2double(get(hObject,'String')) returns contents of DOBday_edit as a double


% --- Executes during object creation, after setting all properties.
function DOBday_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DOBday_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DOByear_edit_Callback(hObject, eventdata, handles)
% hObject    handle to DOByear_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DOByear_edit as text
%        str2double(get(hObject,'String')) returns contents of DOByear_edit as a double


% --- Executes during object creation, after setting all properties.
function DOByear_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DOByear_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in domleg_list.
function domleg_list_Callback(hObject, eventdata, handles)
% hObject    handle to domleg_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns domleg_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from domleg_list


% --- Executes during object creation, after setting all properties.
function domleg_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to domleg_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in domhand_list.
function domhand_list_Callback(hObject, eventdata, handles)
% hObject    handle to domhand_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns domhand_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from domhand_list


% --- Executes during object creation, after setting all properties.
function domhand_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to domhand_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function height_edit_Callback(hObject, eventdata, handles)
% hObject    handle to height_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of height_edit as text
%        str2double(get(hObject,'String')) returns contents of height_edit as a double


% --- Executes during object creation, after setting all properties.
function height_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to height_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function weight_edit_Callback(hObject, eventdata, handles)
% hObject    handle to weight_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of weight_edit as text
%        str2double(get(hObject,'String')) returns contents of weight_edit as a double


% --- Executes during object creation, after setting all properties.
function weight_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to weight_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in strokeCheck.
function strokeCheck_Callback(hObject, eventdata, handles)
% hObject    handle to strokeCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of strokeCheck
if get(hObject,'Value')
    set(handles.popupAffected,'Enable','On')
    set(handles.text63,'Enable','On')
else
    set(handles.popupAffected,'Enable','Off')
    set(handles.text63,'Enable','Off')
end
guidata(hObject,handles)

% --- Executes on selection change in popupAffected.
function popupAffected_Callback(hObject, eventdata, handles)
% hObject    handle to popupAffected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupAffected contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupAffected


% --- Executes during object creation, after setting all properties.
function popupAffected_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupAffected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in description_edit.
function description_edit_Callback(hObject, eventdata, handles)
% hObject    handle to description_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
contents = cellstr(get(hObject,'String'));
expFile = contents{get(hObject,'Value')};

path=which('GetInfoGUIbeta');
path=strrep(path,'GetInfoGUIbeta.m','ExpDetails');

if exist([path filesep expFile '.mat'],'file')==2
    a=load([path filesep expFile]);
    a = a.expDes;
    aux=fields(a);
    numcond = a.numofconds;
    
    data = cell(numcond,5);
    temp = 1;
    for z=1:numcond
        data{z,1} = z;
        data{z,2} = getfield(a,aux{temp+1});
        data{z,4} = getfield(a,aux{temp+2});
        data{z,5} = getfield(a,aux{temp+3});
%         keyboard
        temp = temp+4;
    end

    set(handles.uitable1,'Data',data);
end

guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function description_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to description_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

%initialize drop down list with different experiment types
path=which('GetInfoGUIbeta');
path=strrep(path,'GetInfoGUIbeta.m','ExpDetails');
W=what(path);
experiments=cellstr(W.mat);
for i=1:length(experiments)
    fileExt=find(experiments{i}=='.');
    experiments{i}=experiments{i}(1:fileExt-1);
end
set(hObject,'String',[' ';experiments])

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function name_edit_Callback(hObject, eventdata, handles)
% hObject    handle to name_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of name_edit as text
%        str2double(get(hObject,'String')) returns contents of name_edit as a double


% --- Executes during object creation, after setting all properties.
function name_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to name_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in month_list.
function month_list_Callback(hObject, eventdata, handles)
% hObject    handle to month_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns month_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from month_list


% --- Executes during object creation, after setting all properties.
function month_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to month_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function day_edit_Callback(hObject, eventdata, handles)
% hObject    handle to day_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of day_edit as text
%        str2double(get(hObject,'String')) returns contents of day_edit as a double


% --- Executes during object creation, after setting all properties.
function day_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to day_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function year_edit_Callback(hObject, eventdata, handles)
% hObject    handle to year_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of year_edit as text
%        str2double(get(hObject,'String')) returns contents of year_edit as a double


% --- Executes during object creation, after setting all properties.
function year_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to year_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function note_edit_Callback(hObject, eventdata, handles)
% hObject    handle to note_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of note_edit as text
%        str2double(get(hObject,'String')) returns contents of note_edit as a double


% --- Executes during object creation, after setting all properties.
function note_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to note_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function c3dlocation_Callback(hObject, eventdata, handles)
% hObject    handle to c3dlocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of c3dlocation as text
%        str2double(get(hObject,'String')) returns contents of c3dlocation as a double
handles.folder_location = get(hObject,'string');
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function c3dlocation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to c3dlocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in browse.
function browse_Callback(hObject, eventdata, handles)
% hObject    handle to browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.folder_location = uigetdir; %this is how the output_fcn knows where the folder is
if ~handles.folder_location==0
    set(handles.c3dlocation,'string',handles.folder_location)
end
guidata(hObject,handles);


function basefile_Callback(hObject, eventdata, handles)
% hObject    handle to basefile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of basefile as text
%        str2double(get(hObject,'String')) returns contents of basefile as a double


% --- Executes during object creation, after setting all properties.
function basefile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to basefile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numoftrials_Callback(hObject, eventdata, handles)
% hObject    handle to numoftrials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numoftrials as text
%        str2double(get(hObject,'String')) returns contents of numoftrials as a double


% --- Executes during object creation, after setting all properties.
function numoftrials_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numoftrials (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numofconds_Callback(hObject, eventdata, handles)
% hObject    handle to numofconds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numofconds as text
%        str2double(get(hObject,'String')) returns contents of numofconds as a double
newnum = get(handles.numofconds,'String');
data = get(handles.uitable1,'Data');
[m,~] = size(data);

if str2double(newnum) > m
%     keyboard
    data = [data;cell(str2double(newnum)-m,5)];
    set(handles.uitable1,'Data',data);
    
elseif str2double(newnum) < m
    ends = str2double(newnum);
    data(ends+1:end,:)=[];
    set(handles.uitable1,'Data',data);
end

% --- Executes during object creation, after setting all properties.
function numofconds_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numofconds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in kinematic_check.
function kinematic_check_Callback(hObject, eventdata, handles)
% hObject    handle to kinematic_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of kinematic_check


% --- Executes on button press in force_check.
function force_check_Callback(hObject, eventdata, handles)
% hObject    handle to force_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of force_check


% --- Executes on button press in emg_check.
function emg_check_Callback(hObject, eventdata, handles)
% hObject    handle to emg_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of emg_check
state = get(hObject,'Value');

if state
    set(handles.secfile_browse,'enable','on')
    set(handles.secfileloc,'enable','on')
    for i=1:16
        eval(['set(handles.emg1_' num2str(i) ',''enable'',''off'');']);
        eval(['set(handles.emg2_' num2str(i) ',''enable'',''off'');']);
        eval(['set(handles.emg1_' num2str(i) ',''enable'',''on'');']);
        eval(['set(handles.emg2_' num2str(i) ',''enable'',''on'');']);
    end
else
    set(handles.secfile_browse,'enable','off')
    set(handles.secfileloc,'enable','off')
    for i=1:16
        eval(['set(handles.emg1_' num2str(i) ',''enable'',''off'');']);
        eval(['set(handles.emg2_' num2str(i) ',''enable'',''off'');']);
    end
end
guidata(hObject,handles);


function secfileloc_Callback(hObject, eventdata, handles)
% hObject    handle to secfileloc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of secfileloc as text
%        str2double(get(hObject,'String')) returns contents of secfileloc as a double


% --- Executes during object creation, after setting all properties.
function secfileloc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to secfileloc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in secfile_browse.
function secfile_browse_Callback(hObject, eventdata, handles)
% hObject    handle to secfile_browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.secfolder_location = uigetdir; %this is how the output_fcn knows where the folder is
if ~handles.secfolder_location==0
    set(handles.secfileloc,'string',handles.secfolder_location)
end
guidata(hObject,handles);

% --- Executes on button press in ok_button.
function ok_button_Callback(hObject, eventdata, handles)
% hObject    handle to ok_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% % % GET INFORMATION FROM GUI FIELDS AND ERROR PROOF BEFORE SAVING % % %
handles.info=errorProofInfobeta(handles);
% keyboard
if handles.info.bad
    return
else
    guidata(hObject,handles)
    uiresume(handles.figure1);
end

% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function emg1_1_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_1 as text
%        str2double(get(hObject,'String')) returns contents of emg1_1 as a double


% --- Executes during object creation, after setting all properties.
function emg1_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_2_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_2 as text
%        str2double(get(hObject,'String')) returns contents of emg1_2 as a double


% --- Executes during object creation, after setting all properties.
function emg1_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_3_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_3 as text
%        str2double(get(hObject,'String')) returns contents of emg1_3 as a double


% --- Executes during object creation, after setting all properties.
function emg1_3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_4_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_4 as text
%        str2double(get(hObject,'String')) returns contents of emg1_4 as a double


% --- Executes during object creation, after setting all properties.
function emg1_4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_5_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_5 as text
%        str2double(get(hObject,'String')) returns contents of emg1_5 as a double


% --- Executes during object creation, after setting all properties.
function emg1_5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_6_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_6 as text
%        str2double(get(hObject,'String')) returns contents of emg1_6 as a double


% --- Executes during object creation, after setting all properties.
function emg1_6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_7_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_7 as text
%        str2double(get(hObject,'String')) returns contents of emg1_7 as a double


% --- Executes during object creation, after setting all properties.
function emg1_7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_8_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_8 as text
%        str2double(get(hObject,'String')) returns contents of emg1_8 as a double


% --- Executes during object creation, after setting all properties.
function emg1_8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_9_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_9 as text
%        str2double(get(hObject,'String')) returns contents of emg1_9 as a double


% --- Executes during object creation, after setting all properties.
function emg1_9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_10_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_10 as text
%        str2double(get(hObject,'String')) returns contents of emg1_10 as a double


% --- Executes during object creation, after setting all properties.
function emg1_10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_11_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_11 as text
%        str2double(get(hObject,'String')) returns contents of emg1_11 as a double


% --- Executes during object creation, after setting all properties.
function emg1_11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_12_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_12 as text
%        str2double(get(hObject,'String')) returns contents of emg1_12 as a double


% --- Executes during object creation, after setting all properties.
function emg1_12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_13_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_13 as text
%        str2double(get(hObject,'String')) returns contents of emg1_13 as a double


% --- Executes during object creation, after setting all properties.
function emg1_13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_14_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_14 as text
%        str2double(get(hObject,'String')) returns contents of emg1_14 as a double


% --- Executes during object creation, after setting all properties.
function emg1_14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_15_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_15 as text
%        str2double(get(hObject,'String')) returns contents of emg1_15 as a double


% --- Executes during object creation, after setting all properties.
function emg1_15_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg1_16_Callback(hObject, eventdata, handles)
% hObject    handle to emg1_16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg1_16 as text
%        str2double(get(hObject,'String')) returns contents of emg1_16 as a double


% --- Executes during object creation, after setting all properties.
function emg1_16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg1_16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_1_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_1 as text
%        str2double(get(hObject,'String')) returns contents of emg2_1 as a double


% --- Executes during object creation, after setting all properties.
function emg2_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_2_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_2 as text
%        str2double(get(hObject,'String')) returns contents of emg2_2 as a double


% --- Executes during object creation, after setting all properties.
function emg2_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_3_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_3 as text
%        str2double(get(hObject,'String')) returns contents of emg2_3 as a double


% --- Executes during object creation, after setting all properties.
function emg2_3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_4_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_4 as text
%        str2double(get(hObject,'String')) returns contents of emg2_4 as a double


% --- Executes during object creation, after setting all properties.
function emg2_4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_5_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_5 as text
%        str2double(get(hObject,'String')) returns contents of emg2_5 as a double


% --- Executes during object creation, after setting all properties.
function emg2_5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_6_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_6 as text
%        str2double(get(hObject,'String')) returns contents of emg2_6 as a double


% --- Executes during object creation, after setting all properties.
function emg2_6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_7_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_7 as text
%        str2double(get(hObject,'String')) returns contents of emg2_7 as a double


% --- Executes during object creation, after setting all properties.
function emg2_7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_8_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_8 as text
%        str2double(get(hObject,'String')) returns contents of emg2_8 as a double


% --- Executes during object creation, after setting all properties.
function emg2_8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_9_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_9 as text
%        str2double(get(hObject,'String')) returns contents of emg2_9 as a double


% --- Executes during object creation, after setting all properties.
function emg2_9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_10_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_10 as text
%        str2double(get(hObject,'String')) returns contents of emg2_10 as a double


% --- Executes during object creation, after setting all properties.
function emg2_10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_11_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_11 as text
%        str2double(get(hObject,'String')) returns contents of emg2_11 as a double


% --- Executes during object creation, after setting all properties.
function emg2_11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_12_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_12 as text
%        str2double(get(hObject,'String')) returns contents of emg2_12 as a double


% --- Executes during object creation, after setting all properties.
function emg2_12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_13_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_13 as text
%        str2double(get(hObject,'String')) returns contents of emg2_13 as a double


% --- Executes during object creation, after setting all properties.
function emg2_13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_14_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_14 as text
%        str2double(get(hObject,'String')) returns contents of emg2_14 as a double


% --- Executes during object creation, after setting all properties.
function emg2_14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_15_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_15 as text
%        str2double(get(hObject,'String')) returns contents of emg2_15 as a double


% --- Executes during object creation, after setting all properties.
function emg2_15_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function emg2_16_Callback(hObject, eventdata, handles)
% hObject    handle to emg2_16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of emg2_16 as text
%        str2double(get(hObject,'String')) returns contents of emg2_16 as a double


% --- Executes during object creation, after setting all properties.
function emg2_16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to emg2_16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function saveloc_edit_Callback(hObject, eventdata, handles)
% hObject    handle to saveloc_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of saveloc_edit as text
%        str2double(get(hObject,'String')) returns contents of saveloc_edit as a double


% --- Executes during object creation, after setting all properties.
function saveloc_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to saveloc_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save_browse.
function save_browse_Callback(hObject, eventdata, handles)
% hObject    handle to save_browse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
path = uigetdir;
if ~path==0
    handles.save_folder=path;
    set(handles.saveloc_edit,'string',handles.save_folder);
end
guidata(hObject,handles)

% --- Executes on button press in saveExpButton.
function saveExpButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveExpButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

data = get(handles.uitable1,'Data');
error = 0;
for z=1:length(data)
    if ~isempty(data(z,1))
        expDes.(['condition' num2str(z)]) = num2str(data{z,1});
    else
        disp(['ERROR missing condition number in row: ',num2str(z)]);
        error = 1;
    end
    
    if ~isempty(data(z,2))
        expDes.(['condName' num2str(z)]) = num2str(data{z,2});
    else
        disp(['ERROR missing condition name in row: ',num2str(z)]);
        error = 2;
    end
    
%     if ~isempty(data(z,3))
%         expDes.(['description' num2str(z)]) = data(z,3);
%     else
%         disp(['WARNING missing description in row: ',num2str(z)]);
% %         error = 2;
%     end
    
    if ~isempty(data(z,4))
        expDes.(['trialnum' num2str(z)]) = num2str(data{z,4});
    else
        disp(['ERROR missing trial number in row: ',num2str(z)]);
        error = 4;
    end
    
    if ~isempty(data(z,5))
        expDes.(['type' num2str(z)]) = num2str(data{z,5});
    else
        disp(['ERROR missing trial type in row: ',num2str(z)]);
        error = 5;
    end
    
end
expDes.numofconds=length(data);

if error == 0
    answer = inputdlg('Enter name of new experiment description: ','Experiment Description Name');
    if ~isempty(answer)
        answer = char(answer);
        expDes.group=answer;
        answer=answer(ismember(answer,['A':'Z' 'a':'z' '0':'9'])); %remove non-alphanumeric characters
        path=which('GetInfoGUIbeta');
        path=strrep(path,'GetInfoGUIbeta.m','ExpDetails');
        if exist([path filesep answer '.mat'],'file')>0
            choice=questdlg('File name already exists. Overwrite?','File Name Warning','Yes','No','No');
            if strcmp(choice,'No')
                h=msgbox('Experiment description was not saved.','');
                waitfor(h)
                return
            end
        end
        save([path filesep answer],'expDes')
        description_edit_CreateFcn(handles.description_edit, eventdata, handles)
        newContents=get(handles.description_edit,'String');
        ind=find(ismember(newContents,answer));
        set(handles.description_edit,'Value',ind)

    end
end

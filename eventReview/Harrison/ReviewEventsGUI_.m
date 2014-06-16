function varargout = ReviewEventsGUI(varargin)
% REVEIWEVENTSGUI MATLAB code for ReveiwEventsGUI.fig
%      REVEIWEVENTSGUI, by itself, creates a new REVEIWEVENTSGUI or raises the existing
%      singleton*.
%
%      H = REVEIWEVENTSGUI returns the handle to a new REVEIWEVENTSGUI or the handle to
%      the existing singleton*.
%
%      REVEIWEVENTSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in REVEIWEVENTSGUI.M with the given input arguments.
%
%      REVEIWEVENTSGUI('Property','Value',...) creates a new REVEIWEVENTSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ReveiwEventsGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ReveiwEventsGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ReveiwEventsGUI

% Last Modified by GUIDE v2.5 27-Nov-2013 12:52:11

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


% --- Executes just before ReveiwEventsGUI is made visible.
function ReviewEventsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ReveiwEventsGUI (see VARARGIN)

% Choose default command line output for ReveiwEventsGUI
handles.output = hObject;
handles.deleted = 0;
handles.last = 0;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ReveiwEventsGUI wait for user response (see UIRESUME)
% uiwait(handles.GUI_window);


% --- Outputs from this function are returned to the command line.
function varargout = ReviewEventsGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


%First, the subject file needs to be eneterd.

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

function subject_Callback(hObject, eventdata, handles)
% hObject    handle to subject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%make subject variables global so they can be accessed by other functions
global Trial KinEvents tEvents slowleg OGEvents OGTrial b OGb

handles.Sub = [get(hObject, 'String'),'.mat'];

%checks if Sub is a file
if exist(handles.Sub) == 2
    eval(['load ', handles.Sub])
    set(handles.trial_num,'Enable','on') %allow user to enter trial
    set(handles.subject_text,'String', 'Subject')
    set(handles.data_type, 'Enable','on')
    handles.TMorOG = get(handles.data_type,'Value');
    set(handles.force_radio,'Enable','on','value',1)
    set(handles.ankle_radio,'Enable','on')
    set(handles.hip_radio,'Enable','on')
    handles.radio = 1;
else
    set(handles.subject_text,'String', 'Try Again:')
    set(handles.trial_num,'Enable','off')
    set(handles.data_type,'Enable','off')
    % Give the edit text box focus so user can correct the error
    uicontrol(hObject)
end

guidata(hObject, handles);



%Then the trial can be entered

% --- Executes during object creation, after setting all properties.
function trial_num_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trial_num (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function trial_num_Callback(hObject, eventdata, handles)
% hObject    handle to trial_num (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global Trial OGTrial

handles.i = str2double(get(hObject,'String'));

if handles.TMorOG == 1 %Treadmill
    numOftrials = length(Trial);
elseif handles.TMorOG == 2 %overground
    numOftrials = length(OGTrial);
end

%make sure a valid trial is entered.
if handles.i>numOftrials || handles.i<=0 || isnan(handles.i)
    set(handles.plot_button,'Enable','off')
    set(handles.next_button,'Enable','off')
    set(handles.back_button,'Enable','off')
    set(handles.delete_button,'Enable','off')
    set(handles.save_button,'Enable','off')
    set(handles.add_button,'Enable','off')
    set(handles.force_radio,'Enable','off')
    set(handles.ankle_radio,'Enable','off')
    set(handles.hip_radio,'Enable','off')
    set(handles.trial_text,'String','Try Again:')
    uicontrol(hObject)
else
    set(handles.trial_text,'String','Trial')
    set(handles.plot_button,'Enable','on')
    handles.last = 0;
end

handles.Kinstart = 1;
handles.tstart = 1;

guidata(hObject, handles);


% --- Executes on button press in plot_button.
function plot_button_Callback(hObject, eventdata, handles)
% hObject    handle to plot_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global Trial KinEvents tEvents slowleg OGEvents OGTrial

if handles.TMorOG == 1 %Treadmill
    
    %collect data for trial i
    i = handles.i;
    K_0 = handles.Kinstart;
    t_0 = handles.tstart;
    
    %--See if any data was deleted by the delete_button callback --%
    % note, if this is placed within delete_button callback, the user won't be
    % able to delete data because the cursor range will be whatever it is
    % before the user gets a chance to move it.
    if handles.deleted
        cursorRange = dualcursor(handles.axes1);
        KinEvents(KinEvents(:,1)==i & KinEvents(:,3)>=cursorRange(1) & KinEvents(:,3)<=cursorRange(3),:)=[];
        %             KinEvents(KinEvents(:,1)==i & KinEvents(:,3)>=val2(1) & KinEvents(:,3)<=val2(3),:)=[];
        tEvents(tEvents(:,1)==i & tEvents(:,3)>=(cursorRange(1)/100) & tEvents(:,3)<=(cursorRange(3)/100),:)=[];
        %             tEvents(tEvents(:,1)==i & tEvents(:,3)>=(val2(1)/100) & tEvents(:,3)<=(val2(3)/100),:)=[];
        handles.deleted = 0;
    end
    
    cla(handles.axes1)
    cla(handles.axes2)
    
    handles.RLegAngle = Trial(i).Angle.RLimb;
    handles.LLegAngle = Trial(i).Angle.LLimb;
    
    handles.RForce = Trial(i).Forces.RFz;
    handles.LForce = Trial(i).Forces.LFz;
    
    handles.RAnklePos = Trial(i).RAnklePos.Y;
    handles.LAnklePos = Trial(i).LAnklePos.Y;
    
    handles.RHipPos = Trial(i).RHipPos.Y;
    handles.LHipPos = Trial(i).LHipPos.Y;
   
    if max(KinEvents(:,2))>10000
        handles.N = 10000;
    else
        handles.N = 1000;
    end
    
    handles.REvents = KinEvents(KinEvents(:,1)==i & KinEvents(:,2)<handles.N,3);
    handles.LEvents = KinEvents(KinEvents(:,1)==i & KinEvents(:,2)>handles.N,3);
    handles.RtEvents = round(tEvents(tEvents(:,1)==i & tEvents(:,2)<handles.N,3)*1000);
    handles.LtEvents = round(tEvents(tEvents(:,1)==i & tEvents(:,2)>handles.N,3)*1000);
    
    
    if K_0 < (length(handles.RLegAngle)-2000) %arbitrarily picked RLegAngle (should this be 1500??)
        K_stop = (handles.Kinstart+2000)-1;
        t_stop = (handles.tstart+20000)-1;
    else
        K_stop = length(handles.RLegAngle);
        t_stop = length(handles.RForce);
    end
    
    set(handles.back_button,'Enable','off')
    if handles.Kinstart> 1500;
        set(handles.back_button,'Enable','on')
    end
    
    handles.SubREvents = handles.REvents(handles.REvents >= K_0 & handles.REvents <= K_stop);
    handles.SubLEvents = handles.LEvents(handles.LEvents >= K_0 & handles.LEvents <= K_stop);
    handles.SubtREvents = handles.RtEvents(handles.RtEvents >= t_0 & handles.RtEvents <= t_stop);
    handles.SubtLEvents = handles.LtEvents(handles.LtEvents >= t_0 & handles.LtEvents <= t_stop);
    
    % plot kinematic data
    set(handles.axes1,'nextplot','replace')
    plot(handles.axes1,K_0:K_stop,handles.RLegAngle(K_0:K_stop),'r')
    set(handles.axes1,'nextplot','add')
    plot(handles.axes1,K_0:K_stop,handles.LLegAngle(K_0:K_stop),'b')
    plot(handles.axes1,handles.SubREvents,handles.RLegAngle(handles.SubREvents),'g*')
    plot(handles.axes1,handles.SubLEvents,handles.LLegAngle(handles.SubLEvents),'g*')
    title(handles.axes1,['Angle Data TRIAL ',num2str(i)])
    
    if handles.radio == 1
        %plot force data
        set(handles.axes2,'nextplot','replace')
        plot(handles.axes2,t_0:t_stop,handles.RForce(t_0:t_stop),'r')
        set(handles.axes2,'nextplot','add')
        plot(handles.axes2,t_0:t_stop,handles.LForce(t_0:t_stop),'b')
        plot(handles.axes2,handles.SubtREvents,handles.RForce(handles.SubtREvents),'g*')
        plot(handles.axes2,handles.SubtLEvents,handles.LForce(handles.SubtLEvents),'g*')
        title(handles.axes2,['Force Data TRIAL ',num2str(i)])
        set(handles.axes2, 'YLim', [-1000 200])
        set(handles.axes2,'YDir','reverse');
    elseif handles.radio == 2
        %plot ankle data
        set(handles.axes2,'nextplot','replace')
        plot(handles.axes2,K_0:K_stop,handles.RAnklePos(K_0:K_stop),'r')
        set(handles.axes2,'nextplot','add')
        plot(handles.axes2,K_0:K_stop,handles.LAnklePos(K_0:K_stop),'b')
        plot(handles.axes2,handles.SubREvents,handles.RAnklePos(handles.SubREvents),'g*')
        plot(handles.axes2,handles.SubLEvents,handles.LAnklePos(handles.SubLEvents),'g*')
        title(handles.axes2,['Ankle Pos Data TRIAL ',num2str(i)]) 
        set(handles.axes2,'YDir','reverse');
    elseif handles.radio == 3
        %plot hip data
        %plot ankle data
        set(handles.axes2,'nextplot','replace')
        plot(handles.axes2,K_0:K_stop,handles.RHipPos(K_0:K_stop),'r')
        set(handles.axes2,'nextplot','add')
        plot(handles.axes2,K_0:K_stop,handles.LHipPos(K_0:K_stop),'b')
        plot(handles.axes2,handles.SubREvents,handles.RHipPos(handles.SubREvents),'g*')
        plot(handles.axes2,handles.SubLEvents,handles.LHipPos(handles.SubLEvents),'g*')
        title(handles.axes2,['Hip Pos Data TRIAL ',num2str(i)])
        set(handles.axes2,'YDir','reverse');
    end
    
    
    %------Make slow leg HS the first event-----%
    %Code written based off angle.
    
    if slowleg == 1 %right leg slow, start with right HS
        
        
        while handles.RLegAngle(handles.REvents(1)) < handles.RLegAngle(handles.REvents(2)) %Make HS first event for right foot
            %Kinematic data
            KinEvents(KinEvents(:,1)==i & KinEvents(:,3)==handles.REvents(1),:)=[];
            handles.REvents(1)=[];
            %time data
            tEvents(tEvents(:,1)==i & tEvents(:,3)==handles.RtEvents(1)/1000,:)=[];
            handles.RtEvents(1)=[];
        end
        
        %The following two while loops could probably be collapsed into
        %one... I kept them this way just in case.
        
        %Kinematic data
        while handles.LEvents(1)<handles.REvents(1)
            KinEvents(KinEvents(:,1)==i & KinEvents(:,3)==handles.LEvents(1),:)=[];
            handles.LEvents(1)=[];
        end      
        
        %time data      
        while handles.LtEvents(1)<handles.RtEvents(1)
            tEvents(tEvents(:,1)==i & tEvents(:,3)==handles.LtEvents(1)/1000,:)=[];
            handles.LtEvents(1)=[];
        end
        
    else %left leg is slow, start with left HS
        
       
        while handles.LLegAngle(handles.LEvents(1)) < handles.LLegAngle(handles.LEvents(2)) %Make HS first event for right foot
            %Kinematic Data
            KinEvents(KinEvents(:,1)==i & KinEvents(:,3)==handles.LEvents(1),:)=[];
            handles.LEvents(1)=[];
            %Time data
            tEvents(tEvents(:,1)==i & tEvents(:,3)==handles.LtEvents(1)/1000,:)=[];
            handles.LtEvents(1)=[];
        end
        
        %Kinematic Data
        while handles.REvents(1) < handles.LEvents(1)
            KinEvents(KinEvents(:,1)==i & KinEvents(:,3)==handles.REvents(1),:)=[];
            handles.REvents(1)=[];
        end
        
        %Time data
        while handles.RtEvents(1) < handles.LtEvents(1)
            tEvents(tEvents(:,1)==i & tEvents(:,3)==handles.RtEvents(1)/1000,:)=[];
            handles.RtEvents(1)=[];
        end
    end
    
    %------------ Plot --------------%
    
    % Re-define events.
    
    handles.REvents = KinEvents(KinEvents(:,1)==i & KinEvents(:,2)<handles.N,3);
    handles.LEvents = KinEvents(KinEvents(:,1)==i & KinEvents(:,2)>handles.N,3);
    handles.RtEvents = round(tEvents(tEvents(:,1)==i & tEvents(:,2)<handles.N,3)*1000);
    handles.LtEvents = round(tEvents(tEvents(:,1)==i & tEvents(:,2)>handles.N,3)*1000);
    
    
    handles.SubREvents = handles.REvents(handles.REvents >= K_0 & handles.REvents <= K_stop);
    handles.SubLEvents = handles.LEvents(handles.LEvents >= K_0 & handles.LEvents <= K_stop);
    handles.SubtREvents = handles.RtEvents(handles.RtEvents >= t_0 & handles.RtEvents <= t_stop);
    handles.SubtLEvents = handles.LtEvents(handles.LtEvents >= t_0 & handles.LtEvents <= t_stop);
    
    
    plot(handles.axes1,handles.SubREvents,handles.RLegAngle(handles.SubREvents),'k*')
    plot(handles.axes1,handles.SubLEvents,handles.LLegAngle(handles.SubLEvents),'k*')
    
    if handles.radio == 1
        plot(handles.axes2,handles.SubtREvents,handles.RForce(handles.SubtREvents),'k*')
        plot(handles.axes2,handles.SubtLEvents,handles.LForce(handles.SubtLEvents),'k*')
    elseif handles.radio == 2
        plot(handles.axes2,handles.SubREvents,handles.RAnklePos(handles.SubREvents),'k*')
        plot(handles.axes2,handles.SubLEvents,handles.LAnklePos(handles.SubLEvents),'k*')
    elseif handles.radio == 3
        plot(handles.axes2,handles.SubREvents,handles.RHipPos(handles.SubREvents),'k*')
        plot(handles.axes2,handles.SubLEvents,handles.LHipPos(handles.SubLEvents),'k*')
    end
    
    
elseif handles.TMorOG == 2 %OverGround
    
    i = handles.i;
    K_0 = handles.Kinstart;
    
    if handles.deleted
        cursorRange = dualcursor(handles.axes1);
        OGEvents(OGEvents(:,1)==i & OGEvents(:,3)>=cursorRange(1) & OGEvents(:,3)<=cursorRange(3),:)=[];
        handles.deleted = 0;
    end
    
    cla(handles.axes1)
    cla(handles.axes2)
    
    if max(OGEvents(:,2))>10000
        handles.N = 10000;
    else
        handles.N = 1000;
    end
    
    handles.RLegAngle = OGTrial(i).Angle.RLimb;
    handles.LLegAngle = OGTrial(i).Angle.LLimb;
    
    handles.RAnklePos = OGTrial(i).RAnklePos.Y;
    handles.LAnklePos = OGTrial(i).LAnklePos.Y;
    
    handles.RHipPos = OGTrial(i).RHipPos.Y;
    handles.LHipPos = OGTrial(i).LHipPos.Y;
    
    handles.REvents = OGEvents(OGEvents(:,1)==i & OGEvents(:,2)<handles.N,3);
    handles.LEvents = OGEvents(OGEvents(:,1)==i & OGEvents(:,2)>handles.N,3);
    
    
    if K_0 < (length(handles.RLegAngle)-2000) %arbitrarily picked RLegAngle (should this be 1500??)
        K_stop = (handles.Kinstart+2000)-1;
    else
        K_stop = length(handles.RLegAngle);
    end
    
    set(handles.back_button,'Enable','off')
    if handles.Kinstart> 1500;
        set(handles.back_button,'Enable','on')
    end
    
    handles.SubREvents = handles.REvents(handles.REvents >= K_0 & handles.REvents <= K_stop);
    handles.SubLEvents = handles.LEvents(handles.LEvents >= K_0 & handles.LEvents <= K_stop);
    
    set(handles.axes1,'nextplot','replace')
    plot(handles.axes1,K_0:K_stop,handles.RLegAngle(K_0:K_stop),'r')
    set(handles.axes1,'nextplot','add')
    plot(handles.axes1,K_0:K_stop,handles.LLegAngle(K_0:K_stop),'b')
    plot(handles.axes1,handles.SubREvents,handles.RLegAngle(handles.SubREvents),'g*')
    plot(handles.axes1,handles.SubLEvents,handles.LLegAngle(handles.SubLEvents),'g*')
    title(handles.axes1,['Angle Data TRIAL ',num2str(i)])
    
    if handles.radio == 2
        set(handles.axes2,'nextplot','replace')
        plot(handles.axes2,K_0:K_stop,handles.RAnklePos(K_0:K_stop),'r')
        set(handles.axes2,'nextplot','add')
        plot(handles.axes2,K_0:K_stop,handles.LAnklePos(K_0:K_stop),'b')
        plot(handles.axes2,handles.SubREvents,handles.RAnklePos(handles.SubREvents),'g*')
        plot(handles.axes2,handles.SubLEvents,handles.LAnklePos(handles.SubLEvents),'g*')
        title(handles.axes2,['Ankle Pos Data TRIAL ',num2str(i)])
        set(handles.axes2,'YDir','reverse');
    elseif handles.radio == 3
        set(handles.axes2,'nextplot','replace')
        plot(handles.axes2,K_0:K_stop,handles.RHipPos(K_0:K_stop),'r')
        set(handles.axes2,'nextplot','add')
        plot(handles.axes2,K_0:K_stop,handles.LHipPos(K_0:K_stop),'b')
        plot(handles.axes2,handles.SubREvents,handles.RHipPos(handles.SubREvents),'g*')
        plot(handles.axes2,handles.SubLEvents,handles.LHipPos(handles.SubLEvents),'g*')
        title(handles.axes2,['Hip Pos Data TRIAL ',num2str(i)])
        set(handles.axes2,'YDir','reverse');
    end
        
    
    %------Make slow leg HS the first event-----%
    %Code written based off angle.
    
    if slowleg == 1 %right leg slow, start with right HS
        
        %Make HS first event for right foot
        while handles.RLegAngle(handles.REvents(1)) < handles.RLegAngle(handles.REvents(2))
            OGEvents(OGEvents(:,1)==i & OGEvents(:,3)==handles.REvents(1),:)=[];
            handles.REvents(1)=[];
        end
        
        %make right HS be the first event
        while handles.LEvents(1)<handles.REvents(1)
            OGEvents(OGEvents(:,1)==i & OGEvents(:,3)==handles.LEvents(1),:)=[];
            handles.LEvents(1)=[];
        end
        
    else %left leg is slow, start with left HS
        
        %Make HS first event for left foot
        while handles.LLegAngle(handles.LEvents(1)) < handles.LLegAngle(handles.LEvents(2))
            OGEvents(OGEvents(:,1)==i & OGEvents(:,3)==handles.LEvents(1),:)=[];
            handles.LEvents(1)=[];
        end
        
        %make left HS be the firts event
        while handles.REvents(1) < handles.LEvents(1)
            OGEvents(OGEvents(:,1)==i & OGEvents(:,3)==handles.REvents(1),:)=[];
            handles.REvents(1)=[];
        end
    end
    
    %------------ Plot --------------%
    
    % Re-define events.
    
    handles.REvents = OGEvents(OGEvents(:,1)==i & OGEvents(:,2)<handles.N,3);
    handles.LEvents = OGEvents(OGEvents(:,1)==i & OGEvents(:,2)>handles.N,3);
    
    
    handles.SubREvents = handles.REvents(handles.REvents >= K_0 & handles.REvents <= K_stop);
    handles.SubLEvents = handles.LEvents(handles.LEvents >= K_0 & handles.LEvents <= K_stop);
    
    plot(handles.axes1,handles.SubREvents,handles.RLegAngle(handles.SubREvents),'k*')
    plot(handles.axes1,handles.SubLEvents,handles.LLegAngle(handles.SubLEvents),'k*')
    
    if handles.radio == 2
        plot(handles.axes2,handles.SubREvents,handles.RAnklePos(handles.SubREvents),'k*')
        plot(handles.axes2,handles.SubLEvents,handles.LAnklePos(handles.SubLEvents),'k*')
    elseif handles.radio == 3
        plot(handles.axes2,handles.SubREvents,handles.RHipPos(handles.SubREvents),'k*')
        plot(handles.axes2,handles.SubLEvents,handles.LHipPos(handles.SubLEvents),'k*')
    end
end

if handles.last~=1
    set(handles.next_button,'Enable','on')
end
set(handles.add_button,'Enable', 'on')
set(handles.delete_button,'Enable','on')
set(handles.save_button,'Enable','on')

guidata(hObject, handles);



% --- Executes on button press in delete_button.
function delete_button_Callback(hObject, eventdata, handles)
% hObject    handle to delete_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

plot_button_Callback(handles.plot_button,eventdata,handles)

axes(handles.axes1)
dualcursor([handles.Kinstart handles.Kinstart+10],[.05 1.05; .25 1.05],'gs')

handles.deleted = 1;

guidata(hObject, handles);



% --- Executes on button press in add_button.
function add_button_Callback(hObject, eventdata, handles)
% hObject    handle to add_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
plot_button_Callback(handles.plot_button,eventdata,handles)

handles.deleted = 0; %Not sure why this is here, but I'm keeping it for now.

global KinEvents tEvents OGEvents b OGb

[X,Y,click_type] = ginput;

if handles.TMorOG == 1 %Treadmill
    for j = 1:length(click_type)
        refPoint=round(X(j));           
        if click_type(j) == 1 %left click --> add to LEvents
            
            %Pad the clicked point by 10 samples on either side
            %Check for a max and then a min among angle samples
            %if neither exist, don't add new event
            AngleSample = [handles.LLegAngle(refPoint-10:refPoint+10) (refPoint-10:refPoint+10)'];
            newEvent = AngleSample(AngleSample(:,1)==max(AngleSample(:,1)),2);
            if newEvent == AngleSample(1,2) || newEvent == AngleSample(end,2)
                newEvent = AngleSample(AngleSample(:,1)==min(AngleSample(:,1)),2);
                if newEvent == AngleSample(1,2) || newEvent == AngleSample(end,2)
                    continue;
                end
            end    
            
            insertcode=KinEvents(find(KinEvents(:,1)==handles.i & KinEvents(:,2)>handles.N,1,'last'),2)+1;
            if isempty(insertcode)
                insertcode=handles.N+1;
            end
            
        elseif click_type(j) ==3 %right click --> add to REvents
            
            %same as above, check for max or min within 20 points around
            %click
            AngleSample = [handles.RLegAngle(refPoint-10:refPoint+10) (refPoint-10:refPoint+10)'];
            newEvent = AngleSample(AngleSample(:,1)==max(AngleSample(:,1)),2);
            if newEvent == AngleSample(1,2) || newEvent == AngleSample(end,2)
                newEvent = AngleSample(AngleSample(:,1)==min(AngleSample(:,1)),2);
                if newEvent == AngleSample(1,2) || newEvent == AngleSample(end,2)
                    continue;
                end
            end 
            
            insertcode=KinEvents(find(KinEvents(:,1)==handles.i & KinEvents(:,2)<handles.N,1,'last'),2)+1;
            if isempty(insertcode)
                insertcode=1;
            end
            
        end
        KinEvents = [KinEvents; handles.i insertcode newEvent];
        tEvents = [tEvents; handles.i insertcode newEvent/100];
        KinEvents = orderEvents(KinEvents,b);
        tEvents = orderEvents(tEvents,b);
    end
    
elseif handles.TMorOG == 2 %Over Ground
    
    for j = 1:length(click_type)
        refPoint=round(X(j));
        if click_type(j) == 1 %left click
            
            AngleSample = [handles.LLegAngle(refPoint-10:refPoint+10) (refPoint-10:refPoint+10)'];
            newEvent = AngleSample(AngleSample(:,1)==max(AngleSample(:,1)),2);
            if newEvent == AngleSample(1,2) || newEvent == AngleSample(end,2)
                newEvent = AngleSample(AngleSample(:,1)==min(AngleSample(:,1)),2);
                if newEvent == AngleSample(1,2) || newEvent == AngleSample(end,2)
                    continue;
                end
            end    
            
            insertcode=OGEvents(find(OGEvents(:,1)==handles.i & OGEvents(:,2)>handles.N,1,'last'),2)+1;
            if isempty(insertcode)
                insertcode=1001;
            end
            
        elseif click_type(j) ==3
            
            AngleSample = [handles.RLegAngle(refPoint-10:refPoint+10) (refPoint-10:refPoint+10)'];
            newEvent = AngleSample(AngleSample(:,1)==max(AngleSample(:,1)),2);
            if newEvent == AngleSample(1,2) || newEvent == AngleSample(end,2)
                newEvent = AngleSample(AngleSample(:,1)==min(AngleSample(:,1)),2);
                if newEvent == AngleSample(1,2) || newEvent == AngleSample(end,2)
                    continue;
                end
            end    
            
            insertcode=OGEvents(find(OGEvents(:,1)==handles.i & OGEvents(:,2)<handles.N,1,'last'),2)+1;
            if isempty(insertcode)
                insertcode=1;
            end
        end
        OGEvents = [OGEvents; handles.i insertcode newEvent];  
        OGEvents = orderEvents(OGEvents,OGb);
    end
end

guidata(hObject, handles);

plot_button_Callback(handles.plot_button,eventdata,handles)


% --- Executes on mouse press over axes background.



% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global KinEvents tEvents OGEvents

if handles.TMorOG == 1 %Treadmill
    variables = ' KinEvents tEvents';
elseif handles.TMorOG == 2 %Over Ground
    variables = ' OGEvents';
end
eval(['save ',handles.Sub,variables,' -append']);



% --- Executes on button press in next_button.
function next_button_Callback(hObject, eventdata, handles)
% hObject    handle to next_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global Trial OGTrial

if handles.TMorOG == 1 %Treadmill    
    %get start of subtrial
    K_0 = handles.Kinstart;
    t_0 = handles.tstart;
    
    if K_0 < (length(handles.RLegAngle)-2000) %arbitrarily picked RLegAngle (should this be 1500??)
        
        handles.Kinstart = handles.Kinstart+1500;
        handles.tstart = handles.tstart+15000;
        handles.last = 0;
    else
        
        if handles.i < length(Trial)
            handles.i = handles.i+1;
            set(handles.trial_num,'String',num2str(handles.i))
            handles.Kinstart = 1;
            handles.tstart = 1;
            handles.last = 0;
        else
            save_button_Callback(handles.save_button,eventdata,handles)
            set(handles.next_button,'Enable','off')
            handles.last = 1;
        end
    end
elseif handles.TMorOG == 2 %OverGround
    %get start of subtrial
    K_0 = handles.Kinstart;   
    
    if K_0 < (length(handles.RLegAngle)-2000) %arbitrarily picked RLegAngle (should this be 1500??)
        handles.Kinstart = handles.Kinstart+1500;
        handles.last = 0;
    else        
        if handles.i < length(OGTrial)
            handles.i = handles.i+1;
            set(handles.trial_num,'String',num2str(handles.i))
            handles.Kinstart = 1;   
            handles.last = 0;
        else
            save_button_Callback(handles.save_button,eventdata,handles)
            set(handles.next_button,'Enable','off')
            handles.last = 1;
        end
    end
end

guidata(hObject,handles)
plot_button_Callback(handles.plot_button, eventdata, handles)


% --- Executes on button press in back_button.
function back_button_Callback(hObject, eventdata, handles)
% hObject    handle to back_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Kinstart = handles.Kinstart-1500;
handles.tstart = handles.tstart-15000;
handles.last = 0;

guidata(hObject, handles);

plot_button_Callback(handles.plot_button,eventdata,handles)


% --- Executes on selection change in data_type.
function data_type_Callback(hObject, eventdata, handles)
% hObject    handle to data_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.TMorOG = get(hObject,'Value');

if handles.TMorOG == 1
    set(handles.force_radio,'Enable','on','Value',1)
    set(handles.ankle_radio,'Enable','on')
    set(handles.hip_radio,'Enable','on')
    handles.radio = 1;
elseif handles.TMorOG == 2
    set(handles.force_radio,'Enable','off')
    set(handles.ankle_radio,'Enable','on','Value',1)
    set(handles.hip_radio,'Enable','on')
    handles.radio = 2;
end

guidata(hObject, handles);

% Hints: contents = cellstr(get(hObject,'String')) returns data_type contents as cell array
%        contents{get(hObject,'Value')} returns selected item from data_type


% --- Executes during object creation, after setting all properties.
function data_type_CreateFcn(hObject, eventdata, handles)
% hObject    handle to data_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when selected object is changed in uipanel1.
function uipanel1_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in uipanel1 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

switch get(eventdata.NewValue,'Tag')
    case 'force_radio'
        handles.radio = 1;
    case 'ankle_radio'
        handles.radio = 2;
    case 'hip_radio'
        handles.radio = 3;
end

guidata(hObject, handles);


     
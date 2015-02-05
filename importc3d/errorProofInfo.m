function out = errorProofInfo(handles)

out.bad=false;

% -- Experiment Info
descriptionContents=cellstr(get(handles.description_edit,'string'));
out.ExpDescription=descriptionContents{get(handles.description_edit,'Value')};
if strcmp(out.ExpDescription,' ')
    h_error=errordlg('Please choose an experiment description','Description Error');    
    waitfor(h_error)
    uicontrol(handles.description_edit)
    out.bad=true;
    return
end
out.experimenter = get(handles.name_edit,'string');
if strcmp(out.experimenter,' (Enter name/initials)')
    h_error=errordlg('Please enter the name of the person who ran the experiment','Experimenter Error');    
    waitfor(h_error)
    uicontrol(handles.name_edit)
    out.bad=true;
    return
end
MonthContents = cellstr(get(handles.month_list,'String'));
out.month = MonthContents{get(handles.month_list,'Value')};
out.day = str2double(get(handles.day_edit,'string'));
if isnan(out.day) || out.day<0 || out.day>31
    h_error=errordlg('Please enter a day between 1 and 31','Day Error');    
    waitfor(h_error)
    uicontrol(handles.day_edit)
    out.bad=true;
    return
end
out.year = str2double(get(handles.year_edit,'string'));
if isnan(out.year) || out.year<2010 || out.year>3000
    h_error=errordlg('Please enter the year when the experiment took place','Year Error');
    waitfor(h_error)
    uicontrol(handles.year_edit)
    out.bad=true;
    return
end    
out.exp_obs = get(handles.note_edit,'string');

% -- Subject Info
out.ID = get(handles.subID_edit,'string');
if strcmp(out.ID,'Sub#')
    h_error=errordlg('Please enter the subject ID','ID Error');    
    waitfor(h_error)
    uicontrol(handles.subID_edit)
    out.bad=true;
    return
end
DOBmonthContents = cellstr(get(handles.DOBmonth_list,'String'));
out.DOBmonth = DOBmonthContents{get(handles.DOBmonth_list,'Value')};
out.DOBday = str2double(get(handles.DOBday_edit,'string'));
if isnan(out.DOBday) || out.DOBday<0 || out.DOBday>31
    h_error=errordlg('Please enter a day between 1 and 31','Day Error');    
    waitfor(h_error)    
    uicontrol(handles.DOBday_edit)
    out.bad=true;
    return
end
out.DOByear = str2double(get(handles.DOByear_edit,'string'));
if isnan(out.DOByear) || out.DOByear<1900 || out.year>3000 %seems like an appropriate range...
    h_error=errordlg('Please enter the year when the subject was born','Year Error');    
    waitfor(h_error)    
    uicontrol(handles.DOByear_edit)
    out.bad=true;
    return
end 
genderContents = cellstr(get(handles.gender_list,'String'));
out.gender = genderContents{get(handles.gender_list,'Value')};
domlegContents = cellstr(get(handles.domleg_list,'String'));
out.domleg = domlegContents{get(handles.domleg_list,'Value')};
domhandContents = cellstr(get(handles.domhand_list,'String'));
out.domhand = domhandContents{get(handles.domhand_list,'Value')};
out.height = str2double(get(handles.height_edit,'string'));
if isnan(out.height) || out.height<0 || out.height>230 %seems like an appropriate range...
    h_error=errordlg('Please enter the height of the subject','Height Error');    
    waitfor(h_error)    
    uicontrol(handles.height_edit)
    out.bad=true;
    return
end 
out.weight = str2double(get(handles.weight_edit,'string'));
if isnan(out.weight) || out.weight<0 || out.weight>140 %seems like an appropriate range...
    h_error=errordlg('Please enter the weight of the subject','Weight Error');    
    waitfor(h_error)    
    uicontrol(handles.weight_edit)
    out.bad=true;
    return
end 
out.isStroke = get(handles.strokeCheck,'Value');
if out.isStroke==1
    aux=get(handles.popupAffected,'String');
    out.affectedValue=get(handles.popupAffected,'Value');
    out.affectedSide=aux{out.affectedValue};
end

% -- Data Info
if isfield(handles,'folder_location')
    if exist(handles.folder_location,'dir')
        out.dir_location = handles.folder_location;
    else
        h_error=errordlg('Please enter a folder that exists','Directory Error');    
        waitfor(h_error)    
        uicontrol(handles.c3dlocation)
        out.bad=true;
        return
    end
else
    out.dir_location = pwd;
end
out.basename = get(handles.basefile,'string');
out.numofconds = str2double(get(handles.numofconds,'string'));
out.kinematics = get(handles.kinematic_check,'Value');
out.forces = get(handles.force_check,'Value');
out.EMGs = get(handles.emg_check,'Value');
if isfield(handles,'secfolder_location')    
    if exist(handles.secfolder_location)
        out.secdir_location = handles.secfolder_location;
    else
%         h_error=errordlg('Please enter a folder that exists','Directory Error');    
%         waitfor(h_error)    
%         uicontrol(handles.secfileloc)
%         out.bad=1;
%         return
    out.secdir_location=out.dir_location;
    end
else
    out.secdir_location = pwd;
end

% -- Trial Info
for c = 1:str2double(get(handles.numofconds,'string'))
    condNum = str2double(get(handles.(['condition',num2str(c)]),'string'));
    out.cond(c) = condNum;
    out.conditionNames{condNum}=get(handles.(['condName',num2str(c)]),'string');
    out.conditionDescriptions{condNum}=get(handles.(['description',num2str(c)]),'string');
    trialnums = get(handles.(['trialnum',num2str(c)]),'string');
    out.trialnums{condNum} = eval(['[',trialnums,']']);
    %need to eval for entry of numbers like '1:6' or '7 8 9'
    out.type{condNum} = get(handles.(['type',num2str(c)]),'string');
end

trials=cell2mat(out.trialnums);
out.numoftrials = max(trials);

for t=trials
    if t<10
        filename = [out.dir_location filesep out.basename  '0' num2str(t) '.c3d'];        
    else
        filename = [out.dir_location filesep out.basename num2str(t) '.c3d'];        
    end
    if ~exist(filename,'file')
        h_error=errordlg(['The file ',filename,' does not exist.'],'File Name Error');        
        waitfor(h_error)    
        uicontrol(handles.basefile)
        out.bad=true;
        return
    end
    if out.EMGs
        if t<10            
            filename2 = [out.secdir_location filesep out.basename  '0' num2str(t) '.c3d'];
        else            
            filename2 = [out.secdir_location filesep out.basename num2str(t) '.c3d'];
        end
        if ~exist(filename2,'file')
            h_error=errordlg(['The file ',filename2,' does not exist.'],'File Name Error');            
            waitfor(h_error)    
            uicontrol(handles.basefile)
            out.bad=true;
            return
        end    
    end
end

% -- EMG data
if isfield(handles,'emg1_1')
   for i=1:16
       aux1=['emg1_' num2str(i)];
       out.EMGList1(i)={get(handles.(aux1),'string')};
       aux2=['emg2_' num2str(i)];
       out.EMGList2(i)={get(handles.(aux2),'string')};
   end
   allowedMuscles={'BF','SEMB','SEMT','PER','TA','SOL','MG','LG','GLU','TFL','ILP','ADM','RF','VM','VL'};
   %Check that all muscles are allowed
   
   %Check for sync signals
   
end

% --  save location
if isfield(handles,'save_folder')
    if exist(handles.save_folder,'dir')
        out.save_folder = handles.save_folder;
    else
        h_error=errordlg('Please enter a save folder that exists','Directory Error');            
        waitfor(h_error)    
        uicontrol(handles.saveloc_edit)
        out.bad=true;        
    end
        
else
    out.save_folder = pwd;
end

% -- Trial Observations
if isfield(handles,'trialObs')
    out.trialObs=handles.trialObs;
end

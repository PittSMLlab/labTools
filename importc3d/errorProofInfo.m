function out = errorProofInfo(handles)

out.bad=0;

% -- Experiment Info
descriptionContents=cellstr(get(handles.description_edit,'string'));
out.ExpDescription=descriptionContents{get(handles.description_edit,'Value')};
if strcmp(out.ExpDescription,' ')
    h_error=errordlg('Please choose an experiment description','Description Error');    
    waitfor(h_error)
    uicontrol(handles.description_edit)
    out.bad=1;
    return
end
out.experimenter = get(handles.name_edit,'string');
if strcmp(out.experimenter,' (Enter name/initials)')
    h_error=errordlg('Please enter the name of the person who ran the experiment','Experimenter Error');    
    waitfor(h_error)
    uicontrol(handles.name_edit)
    out.bad=1;
    return
end
MonthContents = cellstr(get(handles.month_list,'String'));
out.month = MonthContents{get(handles.month_list,'Value')};
out.day = str2double(get(handles.day_edit,'string'));
if isnan(out.day) || out.day<0 || out.day>31
    h_error=errordlg('Please enter a day between 1 and 31','Day Error');    
    waitfor(h_error)
    uicontrol(handles.day_edit)
    out.bad=1;
    return
end
out.year = str2double(get(handles.year_edit,'string'));
if isnan(out.year) || out.year<2010 || out.year>3000
    h_error=errordlg('Please enter the year when the experiment took place','Year Error');
    waitfor(h_error)
    uicontrol(handles.year_edit)
    out.bad=1;
    return
end    
out.exp_obs = get(handles.note_edit,'string');

% -- Subject Info
out.ID = get(handles.subID_edit,'string');
if strcmp(out.ID,'Sub#')
    h_error=errordlg('Please enter the subject ID','ID Error');    
    waitfor(h_error)
    uicontrol(handles.subID_edit)
    out.bad=1;
    return
end
DOBmonthContents = cellstr(get(handles.DOBmonth_list,'String'));
out.DOBmonth = DOBmonthContents{get(handles.DOBmonth_list,'Value')};
out.DOBday = str2double(get(handles.DOBday_edit,'string'));
if isnan(out.DOBday) || out.DOBday<0 || out.DOBday>31
    h_error=errordlg('Please enter a day between 1 and 31','Day Error');    
    waitfor(h_error)    
    uicontrol(handles.DOBday_edit)
    out.bad=1;
    return
end
out.DOByear = str2double(get(handles.DOByear_edit,'string'));
if isnan(out.DOByear) || out.DOByear<1900 || out.year>3000 %seems like an appropriate range...
    h_error=errordlg('Please enter the year when the subject was born','Year Error');    
    waitfor(h_error)    
    uicontrol(handles.DOByear_edit)
    out.bad=1;
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
    out.bad=1;
    return
end 
out.weight = str2double(get(handles.weight_edit,'string'));
if isnan(out.weight) || out.weight<0 || out.weight>140 %seems like an appropriate range...
    h_error=errordlg('Please enter the weight of the subject','Weight Error');    
    waitfor(h_error)    
    uicontrol(handles.weight_edit)
    out.bad=1;
    return
end 

% -- Data Info
if isfield(handles,'folder_location')
    out.dir_location = handles.folder_location;
else
    out.dir_location = pwd;
end
out.basename = get(handles.basefile,'string');
out.numofconds = str2double(get(handles.numofconds,'string'));
out.kinematics = get(handles.kinematic_check,'Value');
out.forces = get(handles.force_check,'Value');
out.EMGs = get(handles.emg_check,'Value');
if isfield(handles,'secfolder_location')
    out.secdir_location = handles.secfolder_location;
else
    out.secdir_location = pwd;
end

% -- Trial Info
for c = 1:str2double(get(handles.numofconds,'string'))
    condNum = eval(['str2double(get(handles.condition',num2str(c),',''string''))']);
    out.cond(c) = condNum;
    out.conditionNames{condNum}=eval(['get(handles.condName',num2str(c),',''string'')']);
    out.conditionDescriptions{condNum}=eval(['get(handles.description',num2str(c),',''string'')']);
    trialnums = eval(['get(handles.trialnum',num2str(c),',''string'')']);
    out.trialnums{condNum} = eval(['[',trialnums,']']);
    %need double eval. First is to retrieve string from edit box, second is
    %to accomodate for entry of numbers like '1:6' or '7 8 9'
    out.isOverGround(condNum) = eval(['get(handles.OGcheck',num2str(c),',''Value'')']);
end

trials=cell2mat(out.trialnums);
out.numoftrials = length(trials);

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
        out.bad=1;
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
            out.bad=1;
            return
        end    
    end
end


% --  save location
if isfield(handles,'save_folder')
    out.save_folder = handles.save_folder;
else
    out.save_folder = pwd;
end

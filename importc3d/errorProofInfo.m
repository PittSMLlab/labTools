function out = errorProofInfo(handles,ignoreErrors)
%Checks feilds of GetInfoGUI to ensure entry is valid and reasonable.
%If entry is invalid, issues warning about which field is incorrect.
%
%Input:
% hadles - handle structure from GetInfoGUI
% ignoreErrors - enter true to ignore errors

out.bad=false;

%% Get info from GUI fields

% -- Experiment Info
descriptionContents=cellstr(get(handles.description_edit,'string'));
if ~isempty(get(handles.description_edit,'Value'))
out.ExpFile=descriptionContents{get(handles.description_edit,'Value')};
else
    out.ExpFile=descriptionContents{1}; %Empty string
end
    
if isfield(handles,'group')
    out.ExpDescription=handles.group;
else
    out.ExpDescription=out.ExpFile;
end
out.experimenter = get(handles.name_edit,'string');
MonthContents = cellstr(get(handles.month_list,'String'));
out.month = MonthContents{get(handles.month_list,'Value')};
out.day = str2double(get(handles.day_edit,'string'));
out.year = str2double(get(handles.year_edit,'string'));
out.exp_obs = get(handles.note_edit,'string');

% -- Subject Info
out.ID = get(handles.subID_edit,'string');
DOBmonthContents = cellstr(get(handles.DOBmonth_list,'String'));
out.DOBmonth = DOBmonthContents{get(handles.DOBmonth_list,'Value')};
out.DOBday = str2double(get(handles.DOBday_edit,'string'));
out.DOByear = str2double(get(handles.DOByear_edit,'string'));
genderContents = cellstr(get(handles.gender_list,'String'));
out.gender = genderContents{get(handles.gender_list,'Value')};
domlegContents = cellstr(get(handles.domleg_list,'String'));
out.domleg = domlegContents{get(handles.domleg_list,'Value')};
domhandContents = cellstr(get(handles.domhand_list,'String'));
out.domhand = domhandContents{get(handles.domhand_list,'Value')};
out.height = str2double(get(handles.height_edit,'string'));
out.weight = str2double(get(handles.weight_edit,'string'));
out.isStroke = get(handles.strokeCheck,'Value');

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
    out.secdir_location = out.dir_location;
end

% -- Trial Info
Nconds=str2double(get(handles.numofconds,'string'));
if ~isnan(Nconds) && Nconds>0
    for c = 1:Nconds
        condNum = str2double(get(handles.(['condition',num2str(c)]),'string'));
        out.cond(c) = condNum;
        out.conditionNames{condNum}=get(handles.(['condName',num2str(c)]),'string');
        out.conditionDescriptions{condNum}=get(handles.(['description',num2str(c)]),'string');
        trialnums = get(handles.(['trialnum',num2str(c)]),'string');
        out.trialnums{condNum} = eval(['[',trialnums,']']);
        %need to eval for entry of numbers like '1:6' or '7 8 9'
        out.type{condNum} = get(handles.(['type',num2str(c)]),'string');
    end
else
    out.trialnums={0};
end

trials=cell2mat(out.trialnums);
out.numoftrials = max(trials);

% -- EMG data
if isfield(handles,'emg1_1')
    for i=1:16
        aux1=['emg1_' num2str(i)];
        out.EMGList1(i)={get(handles.(aux1),'string')};
        aux2=['emg2_' num2str(i)];
        out.EMGList2(i)={get(handles.(aux2),'string')};
    end
end

% --  save location
if isfield(handles,'save_folder')
    out.save_folder = handles.save_folder;
else
    out.save_folder = pwd;
end

% -- Trial Observations
if isfield(handles,'trialObs')
    out.trialObs=handles.trialObs;
end

%% Check for errors

if ~(nargin>1 && ignoreErrors)
        
    % -- Experiment Info
%     if strcmp(out.ExpFile,' ')
%         h_error=errordlg('Please choose an experiment description','Description Error');
%         waitfor(h_error)
%         uicontrol(handles.description_edit)
%         out.bad=true; close(h); return
%     end
    if strcmp(out.experimenter,' (Enter name/initials)')
        h_error=errordlg('Please enter the name of the person who ran the experiment','Experimenter Error');
        waitfor(h_error)
        uicontrol(handles.name_edit)
        out.bad=true; return
    end
    if isnan(out.day) || out.day<0 || out.day>31
        h_error=errordlg('Please enter a day between 1 and 31','Day Error');
        waitfor(h_error)
        uicontrol(handles.day_edit)
        out.bad=true; return
    end
    if isnan(out.year) || out.year<2010 || out.year>3000
        h_error=errordlg('Please enter the year when the experiment took place','Year Error');
        waitfor(h_error)
        uicontrol(handles.year_edit)
        out.bad=true; return
    end
    
    % -- Subject Info
    if strcmp(out.ID,'Sub#')
        h_error=errordlg('Please enter the subject ID','ID Error');
        waitfor(h_error)
        uicontrol(handles.subID_edit)
        out.bad=true; return
    end
    if isnan(out.DOBday) || out.DOBday<0 || out.DOBday>31
        h_error=errordlg('Please enter a day between 1 and 31','Day Error');
        waitfor(h_error)
        uicontrol(handles.DOBday_edit)
        out.bad=true; return
    end
    if isnan(out.DOByear) || out.DOByear<1900 || out.year>3000 %seems like an appropriate range...
        h_error=errordlg('Please enter the year when the subject was born','Year Error');
        waitfor(h_error)
        uicontrol(handles.DOByear_edit)
        out.bad=true; return
    end
    if isnan(out.height) || out.height<0 || out.height>230 %seems like an appropriate range...
        h_error=errordlg('Please enter the height of the subject','Height Error');
        waitfor(h_error)
        uicontrol(handles.height_edit)
        out.bad=true; return
    end
    if isnan(out.weight) || out.weight<0 || out.weight>170 %seems like an appropriate range...
        h_error=errordlg('Please enter the weight of the subject','Weight Error');
        waitfor(h_error)
        uicontrol(handles.weight_edit)
        out.bad=true; return
    end
    if strcmp(out.domhand,' ')
        h_error=errordlg('Please select a dominant arm','Dominant Arm Error');
        waitfor(h_error)
        uicontrol(handles.domhand_list)
        out.bad=true; return
    end
    if strcmp(out.domleg,' ')
        h_error=errordlg('Please select a dominant leg','Dominant Leg Error');
        waitfor(h_error)
        uicontrol(handles.domleg_list)
        out.bad=true; return
    end
    if out.isStroke==1
        aux=get(handles.popupAffected,'String');
        out.affectedValue=get(handles.popupAffected,'Value');
        out.affectedSide=aux{out.affectedValue};
    end
    
    % -- Data Info
    if ~exist(out.dir_location,'dir')
        h_error=errordlg('Please enter a folder that exists','Directory Error');
        waitfor(h_error)
        uicontrol(handles.c3dlocation)
        out.bad=true; return
    end
    if ~exist(out.secdir_location,'dir')
        %     h_error=errordlg('Please enter a folder that exists','Directory Error');
        %     waitfor(h_error)
        %     uicontrol(handles.secfileloc)
        %     out.bad=1;
        %     return
        out.secdir_location=out.dir_location;
    end
    
    % -- Trial Info
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
            out.bad=true; return
        end
%         %Check marker labels are good in .c3d files
%         H=btkReadAcquisition(filename);
%         markerLabels=fieldnames(btkGetMarkers(H));
%         mustHaveLabels={'LHIP','RHIP','LANK','RANK','RHEE','LHEE','LTOE','RTOE','RKNE','LKNE'};
%         labelPresent=false(1,length(mustHaveLabels));
%         for i=1:length(markerLabels)
%             label=findLabel(markerLabels{i});
%             labelPresent=labelPresent+ismember(mustHaveLabels,label);
%         end
%         if any(~labelPresent)
%             missingLabels=find(~labelPresent);
%             str='';
%             for j=missingLabels
%                 str=[str ', ' mustHaveLabels{j}];
%             end
%             h_error=errordlg(['Marker data does not contain: ' str(3:end) '. Edit ''findLabel'' code to fix.'],'Marker Data Error');
%             waitfor(h_error)
%             uicontrol(handles.basefile)
%             out.bad=true; return
%         end
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
                out.bad=true; return
            end
        end
   end
%     
%     % -- EMG data
%     if isfield(handles,'emg1_1')
%         allowedMuscles={'BF','SEMB','SEMT','PER','TA','SOL','MG','LG','GLU','TFL','ILP','ADM','RF','VM','VL'};
%         %Check that all muscles are allowed
%         
%         %Check for sync signals
%     end
    
    % --  save location
    if ~exist(out.save_folder,'dir')
        h_error=errordlg('Please enter a save folder that exists','Directory Error');
        waitfor(h_error)
        uicontrol(handles.saveloc_edit)
        out.bad=true; 
    end       
end









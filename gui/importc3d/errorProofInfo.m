function out = errorProofInfo(handles, ignoreErrors)
% errorProofInfo  Validates and extracts all fields from GetInfoGUI.
%
%   Reads all control values from the GetInfoGUI handles structure,
% packages them into an output struct, and optionally validates that all
% entries are valid and complete. If an invalid entry is found, an error
% dialog is shown, focus is returned to the offending field, and out.bad is
% set to true so that the caller can abort.
%
%   Inputs:
%     handles      - handles struct from GetInfoGUI (see GUIDATA)
%     ignoreErrors - (optional) logical; set true to skip field validation
%                    and return the struct regardless of entry validity.
%                    Defaults to false if omitted.
%
%   Outputs:
%     out - struct containing all session information extracted from
%           the GUI fields, with the following fields of note:
%             out.bad - true if a validation error was detected
%             out.ok  - set to true by ok_button_Callback on success
%
%   Toolbox Dependencies:
%     None
%
%   See also: GetInfoGUI, ok_button_Callback, figure1_CloseRequestFcn

arguments
    handles      (1,1) struct
    ignoreErrors (1,1) logical = false
end

out.bad = false;

%% Extract Information from GUI Fields
% -- Experiment Information
descriptionContents = cellstr(get(handles.description_edit, 'string'));
if ~isempty(get(handles.description_edit, 'Value'))
    out.ExpFile = ...
        descriptionContents{get(handles.description_edit, 'Value')};
else
    out.ExpFile = descriptionContents{1};   % set to empty string
end

if isfield(handles, 'group')
    out.ExpDescription = handles.group;
else
    out.ExpDescription = out.ExpFile;
end
out.experimenter = get(handles.name_edit, 'string');
MonthContents    = cellstr(get(handles.month_list, 'String'));
out.month        = MonthContents{get(handles.month_list, 'Value')};
out.day          = str2double(get(handles.day_edit,  'string'));
out.year         = str2double(get(handles.year_edit, 'string'));
out.exp_obs      = get(handles.note_edit, 'string');

% -- Subject Information
out.ID           = get(handles.subID_edit, 'string');
DOBmonthContents = cellstr(get(handles.DOBmonth_list, 'String'));
out.DOBmonth     = DOBmonthContents{get(handles.DOBmonth_list, 'Value')};
out.DOBday       = str2double(get(handles.DOBday_edit,  'string'));
out.DOByear      = str2double(get(handles.DOByear_edit, 'string'));
genderContents   = cellstr(get(handles.gender_list, 'String'));
out.gender       = genderContents{get(handles.gender_list, 'Value')};
fastLegContents  = cellstr(get(handles.fastLeg, 'String'));
out.fastLeg      = fastLegContents{get(handles.fastLeg, 'Value')};
domlegContents   = cellstr(get(handles.domleg_list, 'String'));
out.domleg       = domlegContents{get(handles.domleg_list, 'Value')};
domhandContents  = cellstr(get(handles.domhand_list, 'String'));
out.domhand      = domhandContents{get(handles.domhand_list, 'Value')};
out.height       = str2double(get(handles.height_edit, 'string'));
out.weight       = str2double(get(handles.weight_edit, 'string'));
out.isStroke     = get(handles.strokeCheck, 'Value');

% -- Data Information
if isfield(handles, 'folder_location')
    out.dir_location = handles.folder_location;
else
    out.dir_location = pwd();
end
out.basename        = get(handles.basefile, 'string');
out.numofconds      = str2double(get(handles.numofconds, 'string'));
out.kinematics      = get(handles.kinematic_check, 'Value');
out.forces          = get(handles.force_check, 'Value');
out.EMGs            = get(handles.emg_check, 'Value');
out.Nexus           = get(handles.Nexus, 'Value');
out.EMGworks        = get(handles.EMGworks, 'Value');
out.schenleyLab     = get(handles.schenleyLab, 'Value');
out.perceptualTasks = get(handles.perceptualTasks, 'Value');
out.backwardCheck   = get(handles.backwardCheck, 'Value');

if isfield(handles, 'secfolder_location') && out.Nexus == 1
    out.secdir_location = handles.secfolder_location;
else
    % Pablo I. modified (07/16/2015): previously this was populated
    % with the same directory as the primary files, which made no
    % sense (probably was just done to avoid errors downstream).
    out.secdir_location = '';
end

if isfield(handles, 'EMGworksFile_Loc')
    out.EMGworksdir_location = handles.EMGworksFile_Loc;
else
    % Pablo I. modified (07/16/2015): previously this was populated
    % with the same directory as the primary files, which made no
    % sense (probably was just done to avoid errors downstream).
    out.EMGworksdir_location = '';
end

if isfield(handles, 'EMGworksFile2Loc')
    out.secEMGworksdir_location = handles.EMGworksFile2Loc;
else
    % Pablo I. modified (07/16/2015): previously this was populated
    % with the same directory as the primary files, which made no
    % sense (probably was just done to avoid errors downstream).
    out.secEMGworksdir_location = '';
end

% -- Trial Information
Nconds = str2double(get(handles.numofconds, 'string'));
if ~isnan(Nconds) && Nconds > 0
    for c = 1:Nconds                        % for each condition, ...
        condNum = str2double( ...
            get(handles.(['condition', num2str(c)]), 'string'));
        out.cond(c) = condNum;
        out.conditionNames{condNum} = strtrim( ...
            get(handles.(['condName', num2str(c)]), 'string'));
        out.conditionDescriptions{condNum} = ...
            get(handles.(['description', num2str(c)]), 'string');
        trialnums = get(handles.(['trialnum', num2str(c)]), 'string');
        % str2num handles range notation (e.g. '1:6') and
        % space-separated lists (e.g. '7 8 9') without eval
        out.trialnums{condNum} = str2num(trialnums); %#ok<ST2NM>
        out.type{condNum} = get(handles.(['type', num2str(c)]), 'string');
    end
else
    out.trialnums = {0};
end

trials          = cell2mat(out.trialnums);
out.numoftrials = max(trials);

% -- EMG Data
if isfield(handles, 'emg1_1')
    for ii = 1:16
        aux1 = ['emg1_' num2str(ii)];
        out.EMGList1(ii) = {get(handles.(aux1), 'string')};
        aux2 = ['emg2_' num2str(ii)];
        out.EMGList2(ii) = {get(handles.(aux2), 'string')};
    end
end

% -- Save Location
if isfield(handles, 'save_folder')
    out.save_folder = handles.save_folder;
else
    out.save_folder = pwd();
end

% -- Trial Observations
if isfield(handles, 'trialObs')
    out.trialObs = handles.trialObs;
end

%% Validate GUI Field Entries
% This section is skipped when ignoreErrors is true (e.g., when called
% from figure1_CloseRequestFcn for a lenient close-time save).

if ~ignoreErrors
    % -- Experiment Info
    % if strcmp(out.ExpFile,' ')
    %     h_error = errordlg( ...
    %         'Please choose an experiment description', ...
    %         'Description Error');
    %     waitfor(h_error);
    %     uicontrol(handles.description_edit);
    %     out.bad = true;
    %     close(h);
    %     return;
    % end
    if strcmp(out.experimenter, ' (Enter name/initials)')
        h_error = errordlg( ...
            ['Please enter the name or initials of the person who ' ...
            'ran the experiment.'], 'Experimenter Error');
        waitfor(h_error);
        uicontrol(handles.name_edit);
        out.bad = true;
        return;
    end
    if isnan(out.day) || out.day < 1 || out.day > 31
        h_error = errordlg( ...
            'Please enter the day of the experiment (1-31).', ...
            'Experiment Day Error');
        waitfor(h_error);
        uicontrol(handles.day_edit);
        out.bad = true;
        return;
    end
    if isnan(out.year) || out.year < 2010 || out.year > 3000
        h_error = errordlg( ...
            ['Please enter the year the experiment took place ' ...
            '(2010 or later).'], 'Experiment Year Error');
        waitfor(h_error);
        uicontrol(handles.year_edit);
        out.bad = true;
        return;
    end

    % -- Subject Info
    if strcmp(out.ID, 'Sub#')
        h_error = errordlg( ...
            ['Please enter the coded subject ID (do not use the ' ...
            'subject''s name).'], 'Subject ID Error');
        waitfor(h_error);
        uicontrol(handles.subID_edit);
        out.bad = true;
        return;
    end
    if isnan(out.DOBday) || out.DOBday < 1 || out.DOBday > 31
        h_error = errordlg( ...
            'Please enter the subject''s birth day (1-31).', ...
            'Birth Day Error');
        waitfor(h_error);
        uicontrol(handles.DOBday_edit);
        out.bad = true;
        return;
    end
    if isnan(out.DOByear) || out.DOByear < 1900 || out.DOByear > 3000
        h_error = errordlg( ...
            'Please enter the subject''s birth year (1900 or later).', ...
            'Birth Year Error');
        waitfor(h_error);
        uicontrol(handles.DOByear_edit);
        out.bad = true;
        return;
    end
    if isnan(out.height) || out.height <= 0 || out.height > 230
        h_error = errordlg( ...
            ['Please enter the subject''s height in cm ' ...
            '(valid range: 1-230 cm).'], 'Height Error');
        waitfor(h_error);
        uicontrol(handles.height_edit);
        out.bad = true;
        return;
    end
    if isnan(out.weight) || out.weight <= 0 || out.weight > 170
        h_error = errordlg( ...
            ['Please enter the subject''s weight in kg ' ...
            '(valid range: 1-170 kg).'], 'Weight Error');
        waitfor(h_error);
        uicontrol(handles.weight_edit);
        out.bad = true;
        return;
    end
    if strcmp(out.domhand, ' ')
        h_error = errordlg( ...
            'Please select the subject''s dominant arm.', ...
            'Dominant Arm Error');
        waitfor(h_error);
        uicontrol(handles.domhand_list);
        out.bad = true;
        return;
    end
    if strcmp(out.domleg, ' ')
        h_error = errordlg( ...
            'Please select the subject''s dominant leg.', ...
            'Dominant Leg Error');
        waitfor(h_error);
        uicontrol(handles.domleg_list);
        out.bad = true;
        return;
    end
    if out.isStroke == 1
        aux               = get(handles.popupAffected, 'String');
        out.affectedValue = get(handles.popupAffected, 'Value');
        out.affectedSide  = aux{out.affectedValue};
    end

    % -- Data Info
    if ~isfolder(out.dir_location)
        h_error = errordlg( ...
            ['The primary C3D data folder does not exist. ' ...
            'Please enter a valid folder path.'], ...
            'C3D Data Folder Error');
        waitfor(h_error);
        uicontrol(handles.c3dlocation);
        out.bad = true;
        return;
    end
    if ~isempty(out.secdir_location) && ~isfolder(out.secdir_location)
        h_error = errordlg( ...
            ['The secondary C3D data folder does not exist. ' ...
            'Please enter a valid folder path.'], ...
            'Secondary C3D Folder Error');
        waitfor(h_error);
        uicontrol(handles.secfileloc);
        out.bad = true;
        return;
    end

    if ~isempty(out.EMGworksdir_location) && ...
            ~isfolder(out.EMGworksdir_location)
        h_error = errordlg( ...
            ['The primary EMGworks data folder does not exist. ' ...
            'Please enter a valid folder path.'], ...
            'EMGworks Folder Error');
        waitfor(h_error);
        uicontrol(handles.EMGworksLocation);
        out.bad = true;
        return;
    end
    if ~isempty(out.secEMGworksdir_location) && ...
            ~isfolder(out.secEMGworksdir_location)
        h_error = errordlg( ...
            ['The secondary EMGworks data folder does not exist. ' ...
            'Please enter a valid folder path.'], ...
            'Secondary EMGworks Folder Error');
        waitfor(h_error);
        uicontrol(handles.SecondEMGworksLocation);
        out.bad = true;
        return;
    end

    % -- Trial Info
    for t = trials
        filename = fullfile(out.dir_location, ...
            [out.basename sprintf('%02d', t) '.c3d']);
        if ~isfile(filename)
            h_error = errordlg( ...
                ['The file ', filename, ' does not exist. ' ...
                'Check the C3D data folder and base file name.'], ...
                'C3D File Not Found');
            waitfor(h_error);
            uicontrol(handles.basefile);
            out.bad = true;
            return;
        end
        % Check marker labels are valid in C3D files
        % H = btkReadAcquisition(filename);
        % markerLabels = fieldnames(btkGetMarkers(H));
        % mustHaveLabels = {'LHIP', 'RHIP', 'LANK', 'RANK', ...
        %     'RHEE', 'LHEE', 'LTOE', 'RTOE', 'RKNE', 'LKNE'};
        % labelPresent = false(1, length(mustHaveLabels));
        % for i = 1:length(markerLabels)
        %     label = findLabel(markerLabels{i});
        %     labelPresent = labelPresent + ismember(mustHaveLabels,label);
        % end
        % if any(~labelPresent)
        %     missingLabels = find(~labelPresent);
        %     str = '';
        %     for j = missingLabels
        %         str = [str ', ' mustHaveLabels{j}];
        %     end
        %     h_error = errordlg( ...
        %         ['Marker data does not contain: ' ...
        %         str(3:end) '. Edit ''findLabel'' to fix.'], ...
        %         'Marker Data Error');
        %     waitfor(h_error)
        %     uicontrol(handles.basefile)
        %     out.bad = true;
        %     return;
        % end
        if ~isempty(out.secdir_location)
            filename2 = fullfile(out.secdir_location, ...
                [out.basename sprintf('%02d', t) '.c3d']);
            if ~isfile(filename2)
                h_error = errordlg( ...
                    ['The secondary C3D file ', filename2, ' does not ' ...
                    'exist. Check the secondary C3D folder and base ' ...
                    'file name.'], 'Secondary C3D File Not Found');
                waitfor(h_error);
                uicontrol(handles.basefile);
                out.bad = true;
                return;
            end
        end
    end

    % ---- EMGworks file checks (DMMO) ---------------------------------
    % Note: t retains the value of the last trial from the loop above.
    if ~isempty(out.EMGworksdir_location)
        filename3 = fullfile(out.EMGworksdir_location, ...
            [out.basename sprintf('%02d', t) '.mat']);
        if ~isfile(filename3)
            h_error = errordlg( ...
                ['The EMGworks file ', filename3, ' does not exist. ' ...
                'Check the EMGworks folder and base file name.'], ...
                'EMGworks File Not Found');
            waitfor(h_error);
            uicontrol(handles.basefile);
            out.bad = true;
            return;
        end
    end
    if ~isempty(out.secEMGworksdir_location)
        filename4 = fullfile(out.secEMGworksdir_location, ...
            [out.basename sprintf('%02d', t) '.mat']);
        if ~isfile(filename4)
            h_error = errordlg( ...
                ['The secondary EMGworks file ', filename4, ' does not '...
                'exist. Check the secondary EMGworks folder and base ' ...
                'file name.'], 'Secondary EMGworks File Not Found');
            waitfor(h_error);
            uicontrol(handles.basefile);
            out.bad = true;
            return;
        end
    end

end

% -- EMG data
% if isfield(handles, 'emg1_1')
%     allowedMuscles = {'BF', 'SEMB', 'SEMT', 'PER', 'TA', 'SOL', 'MG', ...
%         'LG', 'GLU', 'TFL', 'ILP', 'ADM', 'RF', 'VM', 'VL'};
%     % Check that all muscles are allowed
%     % Check for sync signals
% end

% -- Save Location
% Note: this check always runs regardless of ignoreErrors, since a valid
% save path is required even for lenient close-time saves.
if ~isfolder(out.save_folder)
    h_error = errordlg(['The save folder does not exist. ' ...
        'Please enter a valid folder path.'], 'Save Folder Error');
    waitfor(h_error);
    uicontrol(handles.saveloc_edit);
    out.bad = true;
end

end


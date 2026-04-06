function [expData, rawExpData, adaptData] = loadSubject(info, eventClass)
% loadSubject  Load, organize, process, and save experimental session
%   data from C3D files into labTools data objects.
%
%   Reads raw trial data from the .c3d files specified by info, constructs
% labTools data objects (experimentData, subjectData), detects gait events,
% computes adaptation parameters, and saves the results to disk. If datlog
% files are present for all trials, data logs are synchronized prior to
% processing.
%
%   Inputs:
%     info       - Struct of session information returned by GetInfoGUI,
%                  containing participant demographics, file paths, trial
%                  and condition assignments, and EMG channel labels
%     eventClass - (optional) String specifying the gait event detection
%                  method. Defaults to '' if omitted or empty:
%                    ''      - default (forces for TM, kinematics for OG)
%                    'kin'   - strictly from kinematics (OG trials)
%                    'force' - strictly from forces (TM trials)
%
%   Outputs:
%     expData    - Processed experimentData object
%     rawExpData - Unprocessed experimentData object
%     adaptData  - adaptationData object with computed adaptation params
%
%   Toolbox Dependencies:
%     None
%
%   See also: GetInfoGUI, c3d2mat, getTrialMetaData, loadTrials,
%     experimentData, experimentData.process, SyncDatalog, determineRefLeg

arguments
    info       (1,1) struct
    eventClass (1,:) char   = ''
end

%% Initialize Diary to Save All Information Displayed during Loading
% onCleanup guarantees diary is closed even if an error is thrown
diaryFileName = fullfile(info.save_folder, [info.ID 'loading.log']);
diary(diaryFileName);
cleanupDiary  = onCleanup(@() diary('off'));

%% Ask user for EMG normalization condition if EMG data is present
if ~isempty(info.EMGList1) || ~isempty(info.EMGList2)
    %EMG is present, ask user what normalization condition they want to
    %use. If none provided will use OGBase first is available
    %Then TMBase, Then NIM base, if none is present will do trial1
    %
     [indx,tf] = listdlg('PromptString',{'EMG data is present.',...
         'Select a condition to normalize the EMG data (all data will be strecthed %',...
         'where 0% = min and 100% = max of this condition'},...
        'SelectionMode','single','ListString',info.conditionNames,...
        'ListSize',[400,250],'InitialValue',1);
     if tf == 0 %no selection was made
         warning(['EMG data present but no normalization reference condition was provided to compute EMG norms',...
             'Will use default (look inforder for OGBase, TMBase, NimBase, TRBase, TSBase and use the first one found.',...
             'When still cannot find, will normalize use any conditions containing base matching type of the 1st condition'])
         normalizationRefCond = '';
     else
         normalizationRefCond = info.conditionNames{indx};
         fprintf('EMG data present, will normalize to reference condition using %s based on users choice.\n',normalizationRefCond)
     end

    %next ask the user to choose how they want to bias the data.
    opts.Interpreter = 'tex';
    % Include the desired Default answer
    opts.Default = 'Default';
    answer = questdlg(['After normalization, we will also compute bias removed norms.',...
        'Do you want to default bias removal (remove based on trial type, this is default behavior) ',...
        'or do you want to force bias removal to use the same condition throughout?'],...
         '||EMG|| bias removal condition',...
                  'Default','Select my own',opts);
    if strcmp(answer,'Default')
        biasRemovalCond = '';
        fprintf('Will compute unbiased EMG norm using default bias removal where trial type specific bias will be removed\n');
    else
        
        [indx,tf] = listdlg('PromptString',{'Force bias removal to use the same condition for all trials.',...
                'Select a condition to unbias the EMG data'},...
                'SelectionMode','single','ListString',info.conditionNames,...
                'ListSize',[400,250],'InitialValue',1);
         if tf == 0 %no selection was made
             warning(['User wanted to choose their own bias removal conditions to remove bias when computing unbiased EMG norms, ',...
                 'but no selection was made. Will revert to use default (remove condition type specific bias)'])
             biasRemovalCond = '';
         else
             biasRemovalCond = info.conditionNames{indx};
             fprintf('When computing EMG norm will unbias the data for all trials using %s based on users choice',biasRemovalCond)
         end
    end
end

%% Determine Experiment Date
% 'labDate' is a 'labTools' repository class
expDate = labDate(info.day, info.month, info.year);

%% Experiment Information
% Creates 'experimentMetaData' object, which houses information about
% the number of trials, their descriptions, notes, and trial numbers.
% expMD = experimentMetaData(info.ExpDescription, expDate, ...
%     info.experimenter, info.exp_obs, strtrim(info.conditionNames), ...
%     info.conditionDescriptions, info.trialnums, info.numoftrials, ...
%     info.schenleyLab, info.perceptualTasks);
% Constructor(ID, date, experimenter, obs, conds, desc, trialLst, Ntrials);

%% Participant Information
% Resolve reference leg and fast leg fields, then build subjectData
info    = determineRefLeg(info);
DOB     = labDate(info.DOBday, info.DOBmonth, info.DOByear);
% Compute age at time of experimental session to nearest month
% TODO: why not compute age to the nearest day? privacy concern?
ageInMonths = round(expDate.timeSince(DOB));
age         = ageInMonths / 12;

if ~isfield(info, 'isStroke') || info.isStroke == 0     % if no stroke, ...
    subData = subjectData(DOB, info.gender, info.domleg, info.domhand, ...
        info.height, info.weight, age, info.ID, info.fastLeg);
else                                                    % otherwise, ...
    % TODO: add date of stroke to participant data object
    subData = strokeSubjectData(DOB, info.gender, info.domleg, ...
        info.domhand, info.height, info.weight, age, info.ID, ...
        info.fastLeg, info.affectedSide);
end

%% Process Trial Data
% Generate meta data for each trial in the experimental session
[trialMD, fileList, secFileList, datlogExist] = getTrialMetaData(info);
rawTrialData = loadTrials(trialMD, fileList, secFileList, info);

% The below code block is most likely redundant, but keep for now;
% the code will always have datlog = true when perceptual task = 1.
if datlogExist || info.perceptualTasks == 1
    datlog = {{}};
    for trial = 1:length(rawTrialData)      % for each trial, ...
        if ~isempty(rawTrialData{trial})    % if trial data available, ...
            % Extract trial data logs from trial meta data
            datlog{trial} = rawTrialData{trial}.metaData.datlog;
        else                                % otherwise, ...
            datlog{trial} = {};             % set as empty cell
        end
    end
    % Creates 'experimentMetaData' object, which contains information about
    % the number of trials, their descriptions, notes, and trial numbers.
    expMD = experimentMetaData(info.ExpDescription, expDate, ...
        info.experimenter, info.exp_obs, strtrim(info.conditionNames), ...
        info.conditionDescriptions, info.trialnums, info.numoftrials, ...
        info.schenleyLab, info.perceptualTasks, datlog);
else
    expMD = experimentMetaData(info.ExpDescription, expDate, ...
        info.experimenter, info.exp_obs, strtrim(info.conditionNames), ...
        info.conditionDescriptions, info.trialnums, info.numoftrials, ...
        info.schenleyLab, info.perceptualTasks);
    % Constructor(ID,date,experimenter,obs,conds,desc,trialLst,Ntrials);
end
rawExpData = experimentData(expMD, subData, rawTrialData);

% FIXME: close all figures and remove intermediate variables to free
% up some memory in MATLAB.
% There seems to be a memory issue since summer 2025. During c3d2mat,
% the PC will run out of memory, shown as OutOfMemory, OutOfHeapSpace,
% or png file failed to write errors. A better solution is needed to
% identify why we are running out of memory or if there is a memory
% leak. Since the cause is not yet known, closing figures and removing
% variables is a temporary workaround to allow the code to run.
close('all');
clc();
clearvars -except info eventClass rawExpData datlogExist normalizationRefCond biasRemovalCond;

% Synchronize data logs if datlog files exist for all trials and the
% forces exist within those files.
if datlogExist                          % if there are data log files, ...
    rawExpData = SyncDatalog(rawExpData, ...
        [fullfile(info.save_folder, 'DatlogSyncRes') filesep]);
end
save(fullfile(info.save_folder, [info.ID 'RAW.mat']), ...
    'rawExpData', '-v7.3');

%% Process Data
expData   = rawExpData.process(eventClass);
adaptData = expData.makeDataObj([]); %make one without saving it.

%if EMG is present, now also compute EMG norm parameters and populate the
%norm back to expData
if ~isempty(info.EMGList1) || ~isempty(info.EMGList2)
    try
        muscleLabels = [info.EMGList1, info.EMGList2];
        muscleLabels = muscleLabels(~(cellfun(@isempty,muscleLabels) | startsWith(muscleLabels,'sync')));
        muscleLabels = unique(cellfun(@(x) x(2:end),muscleLabels,'UniformOutput',false));
        adaptData = appendEMGNormParameters(adaptData, muscleLabels, normalizationRefCond, biasRemovalCond);
        expData = populateNewParamBackToExpData(expData,adaptData);
    catch ME
        %if the adapt creation or the appending new data fails, save the
        %expData anyway to have some intermediate data to work with.
        % Save processed data object
        warning('EMG data present but norm calculation failed. Saving the data without EMG norm.\n')
        fprintf(2, '%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'))
    end
end

% Save processed data object
save(fullfile(info.save_folder, [info.ID '.mat']), 'expData', '-v7.3');

% Make a new 'adaptationData' object and save in the 'params' file. This
% ensures parameter order is consistent with what we expect (where
% fakeparams) is the last parameter
adaptData = expData.makeDataObj(fullfile(info.save_folder, info.ID));

%% Handle Experiments Requiring Special Trial Splitting from Data Logs
if contains(erase(info.ExpDescription, ' '), 'SpinalAdaptation')
    if ~isempty(info.EMGList1) || ~isempty(info.EMGList2)
        [expData, adaptData] = SepCondsInExpByAudioCue(expData, ...
            info.save_folder, info.ID, eventClass, info.ExpDescription,...
            muscleLabels, normalizationRefCond, biasRemovalCond);
    else
        [expData, adaptData] = SepCondsInExpByAudioCue(expData, ...
            info.save_folder, info.ID, eventClass, info.ExpDescription);
    end
end

end

% ============================================================
% ==================== Local Functions =======================
% ============================================================

function info = determineRefLeg(info)
% determineRefLeg  Resolves info.refLeg and info.fastLeg from the
%   available session information.
%
%   Determines the reference leg (slow-belt leg) using the first
% available source of information in the following priority order:
%   1) info.fastLeg, if already specified
%   2) info.affectedSide, if the participant is a stroke patient
%   3) info.domleg, as a fallback (dominant leg assumed to be the
%      fast-belt leg)
%
%   Inputs:
%     info - Session info struct from GetInfoGUI. Must contain at least
%            one of: info.fastLeg, info.affectedSide (with
%            info.isStroke == 1), or info.domleg
%
%   Outputs:
%     info - Session info struct with info.refLeg ('L' or 'R') and, if not
%            already present, info.fastLeg ('Left' or 'Right') populated
%
%   See also: loadSubject

if isfield(info, 'fastLeg')                 % if fast leg specified, ...
    if strcmpi(info.fastLeg, 'right')
        info.refLeg = 'L';
    elseif strcmpi(info.fastLeg, 'left')
        info.refLeg = 'R';
    else
        warning(['Reference leg could not be determined from ' ...
            'information given. Make sure info.fastLeg is either ' ...
            '''Left'' or ''Right''.']);
    end
elseif isfield(info, 'isStroke') && info.isStroke == 1  % if stroke, ...
    % Reference leg is the affected side when belt speed is not given.
    % TODO: add condition in case fast leg field does not exist
    if strcmpi(info.affectedSide, 'right')
        info.refLeg  = 'R';
        info.fastLeg = 'Left';
    elseif strcmpi(info.affectedSide, 'left')
        info.refLeg  = 'L';
        info.fastLeg = 'Right';
    else
        warning(['Reference leg could not be determined from ' ...
            'information given. Make sure info.affectedSide is ' ...
            'either ''Left'' or ''Right''.']);
    end
else                                                    % otherwise, ...
    % Assume reference leg is non-dominant when information not given
    if strcmpi(info.domleg, 'right')
        info.refLeg  = 'L';
        info.fastLeg = 'Right';
    elseif strcmpi(info.domleg, 'left')
        info.refLeg  = 'R';
        info.fastLeg = 'Left';
    else
        warning(['Reference leg could not be determined from ' ...
            'information given. Make sure info.domleg is either ' ...
            '''Left'' or ''Right''.']);
    end
end

end


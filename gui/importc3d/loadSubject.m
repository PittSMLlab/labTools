function [expData,rawExpData,adaptData] = loadSubject(info,eventClass)
%loadSubject  Load, organize, process, and save data from .c3d files as a
%             subject's .mat file
%
%INPUTS:
%'info' is the structured array output from 'GetInfoGUI'
%'eventClass' can be a string value: '' or 'kin' or 'force'   it
%specifies the method to determine gait events. When in doubt, use ''.
%
%OUTPUTS:
%expData: a processed instance of the 'experimentData' class
%rawExpData: an unprocessed instance of the 'experimentData' class
%
%See also: getTrialMetaData, experimentData, experimentData.process

if nargin < 2 || isempty(eventClass)    % if no gait event method input,...
    % use default method (choose 'force' - TM trials, 'kin' - OG trials)
    eventClass = '';
end

%% Initialize Diary to Save All Information Displayed during Loading
diaryFileName = [info.save_folder filesep info.ID 'loading.log'];
diary(diaryFileName);

%% Determine Experiment Date
% 'labDate' is a 'labTools' repository class
expDate = labDate(info.day,info.month,info.year);

%% Experiment Information
% creates 'experimentMetaData' object, which houses information about the
% number of trials, their descriptions, notes, and trial #'s
% expMD = experimentMetaData(info.ExpDescription,expDate, ...
%     info.experimenter,info.exp_obs,strtrim(info.conditionNames), ...
%     info.conditionDescriptions,info.trialnums,info.numoftrials, ...
%     info.schenleyLab,info.perceptualTasks);
% Constructor(ID,date,experimenter,obs,conds,desc,trialLst,Ntrials);

%% Participant Information
% determine the reference leg, which assumes that:
%   1) the leg on the fast belt is the dominant leg
%   2) 'info.domleg' is either 'left' or 'right'
%   3) the reference leg is the leg on the slow belt
if isfield(info,'fastLeg')                  % if fast leg specified, ...
    if strcmpi(info.fastLeg,'right')
        info.refLeg = 'L';
    elseif strcmpi(info.fastLeg,'left')
        info.refLeg = 'R';
    else
        warning(['Reference leg could not be determined from ' ...
            'information given. Make sure info.fastLeg is either '''...
            '''Left'' or ''Right''.']);
    end
elseif isfield(info,'isStroke') && info.isStroke == 1   % if stroke, ...
    % reference leg is affected side when leg / belt speed is not provided
    % TODO: add condition in case fast leg field does not exist
    if strcmpi(info.affectedSide,'right')
        info.refLeg = 'R';
        info.fastLeg = 'Left';
    elseif strcmpi(info.affectedSide,'left')
        info.refLeg = 'L';
        info.fastLeg = 'Right';
    else
        warning(['Reference leg could not be determined from ' ...
            'information given. Make sure info.affectedSide is either ' ...
            '''Left'' or ''Right''.']);
    end
else                                                    % otherwise, ...
    % assume reference leg is non-dominant leg when information not given
    if strcmpi(info.domleg,'right')
        info.refLeg = 'L';
        info.fastLeg = 'Right';
    elseif strcmpi(info.domleg,'left')
        info.refLeg = 'R';
        info.fastLeg = 'Left';
    else
        warning(['Reference leg could not be determined from ' ...
            'information given. Make sure info.domleg is either ' ...
            '''Left'' or ''Right''.']);
    end
end

DOB = labDate(info.DOBday,info.DOBmonth,info.DOByear);
% compute age at time of experimental session to nearest month
% TODO: why not compute age to the nearest day?
ageInMonths = round(expDate.timeSince(DOB));    % round to closest month
age = ageInMonths / 12;

if ~isfield(info,'isStroke') || info.isStroke == 0  % if no stroke, ...
    subData = subjectData(DOB,info.gender,info.domleg, ...
        info.domhand,info.height,info.weight,age,info.ID,info.fastLeg);
else                                                % otherwise, stroke
    % TODO: add date of stroke to participant data object
    subData = strokeSubjectData(DOB,info.gender,info.domleg, ...
        info.domhand,info.height,info.weight,age,info.ID,info.fastLeg, ...
        info.affectedSide);
end

%% Process Trial Data
% generate meta data for each trial in experimental session
[trialMD,fileList,secFileList,datlogExist] = getTrialMetaData(info);
rawTrialData = loadTrials(trialMD,fileList,secFileList,info);

% the below code block is most likely redundant, but keep for now
% the code will always have datlog = true when perceptual task = 1
if datlogExist || info.perceptualTasks == 1
    datlog = {{}};
    for trial = 1:length(rawTrialData)      % for each trial, ...
        if ~isempty(rawTrialData{trial})    % if trial data available, ...
            % extract trial data logs from meta data
            datlog{trial} = rawTrialData{trial}.metaData.datlog;
        else                                % otherwise, ...
            datlog{trial} = {};             % set as empty cell
        end
    end
    % creates 'experimentMetaData' object, which contains information about
    % the number of trials, their descriptions, notes, and trial #'s
    expMD = experimentMetaData(info.ExpDescription,expDate, ...
        info.experimenter,info.exp_obs,strtrim(info.conditionNames), ...
        info.conditionDescriptions,info.trialnums,info.numoftrials, ...
        info.schenleyLab,info.perceptualTasks,datlog);
else
    expMD = experimentMetaData(info.ExpDescription,expDate, ...
        info.experimenter,info.exp_obs,strtrim(info.conditionNames), ...
        info.conditionDescriptions,info.trialnums,info.numoftrials, ...
        info.schenleyLab,info.perceptualTasks);
    % Constructor(ID,date,experimenter,obs,conds,desc,trialLst,Ntrials);
end
rawExpData = experimentData(expMD,subData,rawTrialData);

% FIXME: close all figures and remove intermediate variables to free up
% some memory in matlab.
% There seems to be a memory issue since summer 2025. During c3d2mat, the
% PC will run out of memory which is shown as OutOfMemory, OutOfHeapSpace,
% or png file failed to write errors. A better solution is needed to
% identify why we are running out of memory or do we have a memory leak.
% Since we do not know the cause now, will try close the figures and
% remove variables to make the code run for now.
close all; clc;
clearvars -except info eventClass rawExpData datlogExist;

% synch data logs if the 'datlog' files exist for all trials and the forces
% exist within those files
if datlogExist          % if there are data log files, ...
    rawExpData = SyncDatalog(rawExpData, ...
        [info.save_folder filesep 'DatlogSyncRes' filesep]);
end
save([info.save_folder filesep info.ID 'RAW.mat'],'rawExpData','-v7.3');

%% Process Data
expData = rawExpData.process(eventClass);
% save processed data object
save([info.save_folder filesep info.ID '.mat'],'expData','-v7.3');
% create 'adaptationData' object, and save 'params' file
adaptData = expData.makeDataObj([info.save_folder filesep info.ID]);

%% Handle Experiments that Require Special Trial Splitting from Data Logs
if contains(erase(info.ExpDescription,' '),'SpinalAdaptation')
    [expData,adaptData] = SepCondsInExpByAudioCue(expData, ...
        info.save_folder,info.ID,eventClass,info.ExpDescription);
end

diary off;

end


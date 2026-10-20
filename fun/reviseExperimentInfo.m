function  [expData,rawExpData,adaptData] = reviseExperimentInfo()
%REVISEEXPERIMENTINFO Re-enter session information and rebuild the files.
%
%   Asks for the experimental session information through GetInfoGUI,
% reloads the saved raw and processed data of that session, rebuilds the
% experiment and participant metadata and the trial metadata from the new
% information, and wraps the existing trial data in new objects. Events
% and parameters are not recomputed; the files are saved and the params
% file is regenerated.
%
% Side effects: shows GetInfoGUI; loads <ID>RAW.mat and <ID>.mat from
%   info.save_folder and overwrites both (-v7.3), then writes the params
%   file through makeDataObj.
%
% Inputs:
%   none
%
% Outputs:
%   expData    - processed experimentData with the revised information
%   rawExpData - raw experimentData with the revised information
%   adaptData  - adaptationData built from expData
%
% Toolbox Dependencies: None
%
% See also GETINFOGUI, EXPERIMENTDATA.PROCESS, EXPERIMENTDATA.MAKEDATAOBJ.

info = GetInfoGUI();            % retrieve experimental session information
% load previous raw and processed experimental session data for comparison
load(fullfile(info.save_folder, [info.ID 'RAW.mat']));
load(fullfile(info.save_folder, [info.ID '.mat']));
expDate = labDate(info.day,info.month,info.year);

%% Experiment Information
expMD = experimentMetaData(info.ExpDescription,expDate, ...
    info.experimenter,info.exp_obs,info.conditionNames, ...
    info.conditionDescriptions,expData.metaData.trialsInCondition, ...
    expData.metaData.Ntrials);
% constructor(ID,date,experimenter,obs,conds,desc,trialLst,Ntrials);

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
            'information given. Make sure info.fastLeg is either ' ...
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
age         = ageInMonths / 12;

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

% Generate meta data for each trial
for cond = sort(info.cond)
    for t = expData.metaData.trialsInCondition{cond}
        if ~isfield(info,'trialObs')
            info.trialObs = cell(info.numoftrials,1);
        end
        % constructor: (name,desc,obs,refLeg,cond,filename,type)
        trialMD{t} = trialMetaData(info.conditionNames{cond}, ...
            info.conditionDescriptions{cond},...
            info.trialObs{t},info.refLeg,cond, ...
            expData.data{t}.metaData.rawDataFilename,info.type{cond});
    end
end

% Load trials
for t = cell2mat(expData.metaData.trialsInCondition)
    GRFData    = rawExpData.data{t}.GRFData;
    EMGData    = rawExpData.data{t}.EMGData;
    accData    = rawExpData.data{t}.accData;
    markerData = rawExpData.data{t}.markerData;
    %rawTrialData(metaData,markerData,EMGData,GRFData,beltSpeedSetData, ...
    %    beltSpeedReadData,accData,EEGData,footSwitches)
    trials{t} = rawTrialData(trialMD{t},markerData,EMGData,GRFData,[], ...
        [],accData,[],[]);
end
% NOTE: the below line overwrites any previous file of the same name!
rawExpData = experimentData(expMD,subData,trials);
% save updated raw 'rawExperimentalData' object
save(fullfile(info.save_folder, [info.ID 'RAW.mat']),'rawExpData','-v7.3')

%% "Process" data
for t = 1:length(rawExpData.data)
    if ~isempty(rawExpData.data{t})
        procEMGData = expData.data{t}.procEMGData;
        filteredEMGData = expData.data{t}.EMGData;
        angleData = expData.data{t}.angleData;
        events = expData.data{t}.gaitEvents;
        beltSpeedReadData = expData.data{t}.beltSpeedReadData;
        jointMomentsData = expData.data{t}.jointMomentsData;
        COPData = expData.data{t}.COPData;
        COMData = expData.data{t}.COMData;

        % Generate processedTrial object
        processedData{t} = processedTrialData(trialMD{t}, ...
            expData.data{t}.markerData,...
            filteredEMGData,expData.data{t}.GRFData, ...
            expData.data{t}.beltSpeedSetData,beltSpeedReadData,...
            expData.data{t}.accData,expData.data{t}.EEGData, ...
            expData.data{t}.footSwitchData,events,procEMGData,angleData, ...
            COPData,COMData,jointMomentsData);
        processedData{t}.adaptParams = expData.data{t}.adaptParams;
    else
        processedData{t} = [];
    end
end
% NOTE: the below line overwrites any previous file of the same name!
expData = experimentData(expMD,subData,processedData);
% save updated processed 'experimentalData' object
save(fullfile(info.save_folder, [info.ID '.mat']),'expData','-v7.3');
% update and save 'adaptationData' object
adaptData = expData.makeDataObj(fullfile(info.save_folder, info.ID));

end


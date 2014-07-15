%c3d2mat: The main function for turing .c3d files into a subject .mat file
%This script collects information regarding the experiment conducted,
%trnasforms the raw data from .c3d files into easy to use matlab objects,
%and then processes that data to give HS and TO events, limb angles,
%adaptation parameters, and processed EMG data (if EMG data are present)

% Get info!
info = GetInfoGUI;
expDate = labDate(info.day,info.month,info.year);

%% Experiment info

expMD=experimentMetaData(info.ExpDescription,expDate,info.experimenter,...
    info.exp_obs,info.conditionNames,info.conditionDescriptions,info.trialnums,info.numoftrials);
%Constructor(ID,date,experimenter,obs,conds,desc,trialLst,Ntrials)

%% Subject info

% find reference leg
%This assumes
%   1) that the leg on the fast belt is the dominant leg
%   2) that info.domleg is either 'left' or 'right'
%   3) that the reference leg is the leg on the slow belt

if strcmpi(info.domleg,'right')
    info.refLeg = 'L';
elseif strcmpi(info.domleg,'left')
    info.refLeg = 'R';
else
    warning('reference leg could not be determined from information given. Make sure info.domleg is either ''Left'' or ''Right''.')
end

DOB = labDate(info.DOBday,info.DOBmonth,info.DOByear);

%age calc 
age = expDate.year - DOB.year;
if expDate.month < DOB.month
    age = age-1;
elseif expDate.month == DOB.month
    if expDate.day < DOB.day
        age = age-1;
    end
end

subData=subjectData(DOB,info.gender,info.domleg,info.domhand,info.height,...
    info.weight,age,info.ID);

%% Trial Data

% Generate meta data for each trial
[trialMD,fileList,secFileList]=getTrialMetaData(info);

% Load trials
rawTrialData=loadTrials(trialMD,fileList,secFileList,info);

rawExpData=experimentData(expMD,subData,rawTrialData);

%% Process data
data={};
for trial=cell2mat(info.trialnums)
    trialData=rawTrialData{trial};
    data{trial}=trialData.process;    
end
%% Save data
expData=experimentData(expMD,subData,data);

save([info.save_folder '/' info.ID 'RAW.mat'],'rawExpData')
save([info.save_folder '/' info.ID '.mat'],'expData')
clearvars -except expMD subData data
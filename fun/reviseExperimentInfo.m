function reviseExperimentInfo

%reviseSubjectInfo

% Get info!
info = GetInfoGUI;


%%
%Compare to old subject file
load([info.save_folder filesep info.ID 'RAW.mat'])
load([info.save_folder filesep info.ID '.mat'])

expDate = labDate(info.day,info.month,info.year);
%% Experiment info

expMD=experimentMetaData(info.ExpDescription,expDate,info.experimenter,...
    info.exp_obs,info.conditionNames,info.conditionDescriptions,expData.metaData.trialsInCondition,expData.metaData.Ntrials);
%Constructor(ID,date,experimenter,obs,conds,desc,trialLst,Ntrials)

%% Subject info

% find reference leg
%This assumes
%   1) that the leg on the fast belt is the dominant leg
%   2) that info.domleg is either 'left' or 'right'
%   3) that the reference leg is the leg on the slow belt

if isfield(info,'isStroke') && info.isStroke==1 %For stroke patients, reference leg is equal to affected side
    if strcmpi(info.affectedSide,'right')
        info.refLeg='R';
    elseif strcmpi(info.affectedSide,'left')
        info.refLeg = 'L';
    else
        warning('Reference leg could not be determined from information given. Make sure info.affectedSide is either ''Left'' or ''Right''.')
    end
else %For non-stroke patients, we are assuming that the reference leg is their non-dominant leg
    if strcmpi(info.domleg,'right')
        info.refLeg = 'L';
    elseif strcmpi(info.domleg,'left')
        info.refLeg = 'R';
    else
        warning('Reference leg could not be determined from information given. Make sure info.domleg is either ''Left'' or ''Right''.')
    end
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

if ~isfield(info,'isStroke') || info.isStroke==0
    subData=subjectData(DOB,info.gender,info.domleg,info.domhand,info.height,...
    info.weight,age,info.ID);
else
    subData=strokeSubjectData(DOB,info.gender,info.domleg,info.domhand,info.height,...
    info.weight,age,info.ID,info.affectedSide); %TO DO: add stroke date
end

%% Trial Data

% Generate meta data for each trial
for cond = sort(info.cond) 
    for t = expData.metaData.trialsInCondition{cond}               
        if ~isfield(info,'trialObs')
            info.trialObs=cell(info.numoftrials,1);
        end
        % constructor: (name,desc,obs,refLeg,cond,filename,type)
        trialMD{t}=trialMetaData(info.conditionNames{cond},info.conditionDescriptions{cond},...
            info.trialObs{t},info.refLeg,cond,expData.data{t}.metaData.rawDataFilename,info.type{cond});        
    end    
end

% Load trials
for t=cell2mat(expData.metaData.trialsInCondition)     
    GRFData=rawExpData.data{t}.GRFData;
    EMGData=rawExpData.data{t}.EMGData;
    accData=rawExpData.data{t}.accData;
    markerData=rawExpData.data{t}.markerData;    
    %rawTrialData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches)
    trials{t}=rawTrialData(trialMD{t},markerData,EMGData,GRFData,[],[],accData,[],[]);
end    
    
rawExpData=experimentData(expMD,subData,trials); %Overwrites old!

%save raw
save([info.save_folder filesep info.ID 'RAW.mat'],'rawExpData','-v7.3')

%% "Process" data
for t=1:length(rawExpData.data)    
    if ~isempty(rawExpData.data{t})        
            procEMGData=expData.data{t}.procEMGData;
            filteredEMGData=expData.data{t}.EMGData;
            angleData=expData.data{t}.angleData;
            events = expData.data{t}.gaitEvents;            
            beltSpeedReadData = expData.data{t}.beltSpeedReadData; 
            jointMomentsData = expData.data{t}.jointMomentsData;
            COPData = expData.data{t}.COPData;
            COMData = expData.data{t}.COMData; 
            
            % Generate processedTrial object
            processedData{t}=processedTrialData(trialMD{t},expData.data{t}.markerData,...
                filteredEMGData,expData.data{t}.GRFData,expData.data{t}.beltSpeedSetData,beltSpeedReadData,...
                expData.data{t}.accData,expData.data{t}.EEGData,expData.data{t}.footSwitchData,events,procEMGData,angleData,COPData,COMData,jointMomentsData);
            processedData{t}.adaptParams=expData.data{t}.adaptParams;     
    else
        processedData{t}=[];
    end
end
expData=experimentData(expMD,subData,processedData); %Overwrites old!

%Save processed
save([info.save_folder filesep info.ID '.mat'],'expData','-v7.3')

%create adaptationData object
adaptData=expData.makeDataObj([info.save_folder filesep info.ID]);

end

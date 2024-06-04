function [expData, adaptData] = SepCondsInExpByAudioCue(expData, resSavePath, subjectID, eventClass, studyName)
% Separate 1 condition into multiple in expData using timing information from audioCue.
% The function saves the new expData and adaptData in [resSavePath
% subjectID] and copies the old files into [resSavePath subjectID originalCondName]
% Always separate on sTO to presever sHS in new conditions as much as possible. 
% This is specific for the SpinalAdaptation study (uses prior knowledge of what's
% in the audioCue to separate the trials). 
% ***NOTE**** Logic in here can be generalized for other studies who want to 
% split trials, search and fill in the blank for sections with "study
% specific logic"
%
% OUTPUTARGS: -expData: experimentData object with conditions
%                   separated. 
%             -adaptData: adaptationData object with conitions separated.
% INPUTARGS: 
%           - expData: rawExperimentData object with datlog loaded.
%           - resSavePath: string, the directory to save the exp and adapt
%                   data with conditions separated.
%           - subjectID: string, subject ID.
%           - eventClass: string, allowed values: 'force',
%                  'kin',''(default), this usually comes from the info file
%                   in c3d2mat
%           - studyName: string, name of the study (use this to add in
%                   study specific logic when separating trials).
% Examples: See: loadSubject.m

% $Author: Shuqi Liu $	$Date: 2024/05/22 13:24:55 $	$Revision: 0.1 $
% Copyright: Sensorimotor Learning Laboratory 2024

%% Create a new raw Exp Data object
%set up trigger event, copied from calcParameters
refLeg = expData.getRefLeg;
if refLeg == 'R'
    s = 'R';    f = 'L'; %TODO: substitute with getOtherLeg()
elseif refLeg == 'L'
    s = 'L';    f = 'R'; %TODO: substitute with getOtherLeg()
else
    ME=MException('MakeParameters:refLegError','the refLeg/initEventSide property of metaData must be either ''L'' or ''R''.');
    throw(ME);
end

%Define the events that will be used for all further computations
eventTypes={[s,'HS'],[f,'TO'],[f,'HS'],[s,'TO']};
eventTypes=strcat(eventClass,eventTypes);
triggerEvent=eventTypes{4}; %in calc parameter trial starts with sHS, so separate on the event immediately before to preserve as much strides as possible.

newExpData = expData;
trialData = expData.data;

if strcmpi(studyName, 'SpinalAdaptation')
    condsToUpdate = contains(expData.metaData.conditionName,'Split Train') | contains(expData.metaData.conditionName,'Practice');
    if sum(condsToUpdate) ~= 9
        condsToUpdate = find(condsToUpdate)
        error('Conds to split missing, expected 9 condsToUpdate. Got %d, Check condition name.',sum(condsToUpdate))
    end
else %default to all false (no update), add other study specific logic here.
    condsToUpdate = false(size(expData.metaData.trialsInCondition)); 
end
origTrials = cell2mat(expData.metaData.trialsInCondition(condsToUpdate));

%% Separate conditions using info from the audioCue timing in the datlog.
tic
for origTrialIdx = origTrials
    fprintf('Processing orig trial %d\n', origTrialIdx)
    
    %use original index to get data log, original condition name 
    origCondName = expData.data{origTrialIdx}.metaData.name;
    datlog = expData.metaData.datlog{origTrialIdx};
    
    %find the new trial index using the old name and the new name list
    %(newRawData is being updated in each for loop inside). This is needed
    %bc old trialIdx won't be valid anymore (trialIdx updated in the for loop), but we also want to avoid
    %looping through newly added conditions. 
    [~, loc] = ismember(origCondName, newExpData.metaData.conditionName);
    trialsInCond = cell2mat(newExpData.metaData.trialsInCondition(loc));
    newTrialIdx = trialsInCond(1); %initialize to the 1st trial index, this will then be incremented for each new cond added.
    
    msg = datlog.audioCues.audio_instruction_message;
    msgTime = datlog.audioCues.startInRelativeTime + datlog.dataLogTimeOffsetBest;
    %filter out relevant messages only (study specific decisions)
    if strcmpi(studyName, 'SpinalAdaptation')
        if contains(origCondName,'Practice')
            relMsg = contains(msg, 'DccRamp2Split') | contains(msg, 'Split');
        elseif contains(origCondName,'Split Train')
            relMsg = (contains(msg, 'Mid') | contains(msg, 'DccRamp2Split') | contains(msg, 'Split') | contains(msg, 'Rest')) & (~strcmpi(msg, 'Rest4')); %all rest except for rest 4 (last one, no data in there)
            if strcmpi(origCondName,'TM Split Train Post 1') %post 1 no 1st ramp, so Mid1 is the first condition but the 1st separating point is DccRamp2Split1
                relMsg = relMsg & (~strcmpi(msg, 'Mid1')); %ignore Mid1 in Post train 1 (no ramp to start, one condition short)
            end
            %Improvements: this can be done with reg exp
            relMsg(1) = false; %ignore the 1st rest (from rest to mid, only had 1 condition = ramp to start walking, 2nd condition is mid = tied walking)
        end
    else %default to all false, add other study specific logic here.
        relMsg = false(size(msg)); 
    end
    msg = msg(relMsg);
    msgTime = msgTime(relMsg);
    
    for trialIdx = trialsInCond %usually only have 1.
        curTrl = trialData{trialIdx};
        for msgIdx = 1:numel(msg) 
            if strcmpi(studyName, 'SpinalAdaptation')
                %StudySpecific logic: create new trial from event time and after, update curTrl to only keep 1 to eventtime -1 , and update trial meta data
                if startsWith(msg{msgIdx},'Rest') %change to ramp2Tied
                    newName = [origCondName ' Ramp2Tied' msg{msgIdx}(end)];
                else
                    newName = [origCondName ' ' msg{msgIdx}];
                end
            else %default value, add other study specific logic here.
                newName = [origCondName ' Default'];
            end
            newDescription = newName; %keep it the same for now.
            %create a new trial separing on closet sHS to the msg
            triggerEventTime = curTrl.gaitEvents.Data(:,strcmp(curTrl.gaitEvents.labels,triggerEvent));
            triggerEventTime = curTrl.gaitEvents.Time(triggerEventTime);
            [closestTime,closestIdx] = min(abs(msgTime(msgIdx) - triggerEventTime));
            closestTime = triggerEventTime(closestIdx);
            %Option2. use msg time directly, performs about the same as uing sTO
            % closestTime = msgTime(msgIdx); 
            %Improvements: this can be improved to split all
            %trials follwoing the msgTime once, then add all new trials
            %once isntead of the looping methods.
            [nextTrial, curTrl] = createNextTrialAuto(curTrl, closestTime, newName);

            %update cell array list of trial data
            trialData = [trialData(1:newTrialIdx-1),{curTrl,nextTrial},trialData(newTrialIdx+1:end)];
            %nextTrial now belongs to a new conditions. Increment the condition 
            % for each element after the curTrl by 1. Also update the
            % rawDataFileName bc the last 2 digits of that is used later on
            % to populate TrialIdx in the adaptationData.Data.
            for jj = newTrialIdx+1:length(trialData)
                if ~isempty(trialData{jj})
                    trialData{jj}.metaData.condition = trialData{jj}.metaData.condition+1;
                    if contains(trialData{jj}.metaData.rawDataFilename,'_SpltNewIdx') %already been renamed in prev ite, replace it.
                        trialData{jj}.metaData.rawDataFilename(end-1:end) = sprintf('%02d',jj);
                    else %1st time being renamed, append
                        trialData{jj}.metaData.rawDataFilename = [trialData{jj}.metaData.rawDataFilename '_SpltNewIdx' sprintf('%02d',jj)];
                        %the correct trialIdx should be the index of this trial in the list of trialData.
                    end
                end
            end
            nextTrial = trialData{newTrialIdx+1}; %index out the updated curtrl with new cond & file name
            newExpData.data = trialData;
                        
            %now update expData.metadata
            curCondIdx = curTrl.metaData.condition; %give index of the condition this trial belongs to.
            newTrialsInConds = {newTrialIdx+1};
            %for the ones following, increment by 1
            for i = curCondIdx+1:length(newExpData.metaData.conditionName)
                newTrialsInConds{i-curCondIdx+1} = newExpData.metaData.trialsInCondition{i}+1;
            end
            newExpData.metaData.trialsInCondition = [newExpData.metaData.trialsInCondition{1:curCondIdx}, newTrialsInConds];
            newExpData.metaData.conditionName = [newExpData.metaData.conditionName{1:curCondIdx}, {newName}, newExpData.metaData.conditionName{curCondIdx+1:end}];
            newExpData.metaData.conditionDescription = [newExpData.metaData.conditionDescription{1:curCondIdx}, {newDescription}, newExpData.metaData.conditionDescription{curCondIdx+1:end}];
            newExpData.metaData.Ntrials = newExpData.metaData.Ntrials + 1; %add 1 trial
            
            newTrialIdx = newTrialIdx + 1;
            curTrl = nextTrial; 
        end
    end
end

%rename the trials for readability (study specific naming convention)
if strcmpi(studyName, 'SpinalAdaptation')
    newName = regexprep(newExpData.metaData.conditionName,...
        {'^TM Split Train Pre 1$','^TM Split Train Pre 2$','^TM Split Train Post 1$','^TM Split Train Post 2$'},...
        {'TM Split Train Pre 1 Ramp2Tied1','TM Split Train Pre 2 Ramp2Tied1','TM Split Train Post 1 Mid1','TM Split Train Post 2 Ramp2Tied1'});
    pracNames = regexp(newExpData.metaData.conditionName,'^Practice [1-5]$');
    pracNames = find(~cellfun(@isempty,pracNames))
    for i = pracNames
        newName{i} = [newName{i} 'Tied']; %practice block do it with no space
    end
    newName = regexprep(newName,...
        {' DccRamp2Split0',' Split0','DccRamp2Split'},...
        {'RampToSplit','Split','RampToSplit'}); %Pre/PostTrain1 Keep the space.
    newName'
    newExpData.metaData.conditionName = newName;
    
    %update the trial meta data to also match the
    %expData.metaData.conditionName
    for i = 1:numel(newExpData.metaData.trialsInCondition)
        trialsToUpdate = cell2mat(newExpData.metaData.trialsInCondition(i));
        for j = trialsToUpdate
            newExpData.data{j}.metaData.name = newExpData.metaData.conditionName{i};
        end
    end
else
    %add other study specific logic naming convention/style here.
end
toc

%% special handling for the 1st ramp2start in SAS01Session2 to get rid of some rest to help get good strides out when computing params.
if strcmpi(studyName, 'SpinalAdaptation') & strcmp(subjectID,'SAS01V02') %hard coded for now
    newExpDataBackup = newExpData;
    newExpData = newExpDataBackup;
    figure(); plot(newExpData.data{1,9}.GRFData.Time,newExpData.data{1,9}.GRFData.Data(:,3))
    temp = newExpData.data{9}.split(180); %from 180s to end (180 is taken from looking at the fig)
    figure(); plot(temp.GRFData.Time,temp.GRFData.Data(:,3))
    newExpData.data{9} = temp;
end

%% inspect results (should expect force traces to roughly match how long the trial is, contains non-periodic traces at beginning or end of the original trial).
inspectResPlot = true;

if inspectResPlot
    figure('units','normalized','outerposition',[0 0 1 1]); spIdx = 1; %ax = [];
    for i = 1:length(newExpData.metaData.conditionName)
        for j = cell2mat(newExpData.metaData.trialsInCondition(i))
            ax(spIdx) = subplot(10,1,spIdx); 
            plot(newExpData.data{1, j}.GRFData.Time,newExpData.data{1, j}.GRFData.Data(:,3)); title(['Trial ' num2str(j) ' ' newExpData.metaData.conditionName{i}])
            spIdx = spIdx + 1;
        end
        if spIdx == 10 %max per figure reached (fig full, start the next one)
            figure('units','normalized','outerposition',[0 0 1 1]); hold on; %restart a figure
            spIdx = 1;
        end           
    end
end

%% Save this new exp data and recompute exp and params
tic

%save an intermediate file with the sep conditions
% save([resSavePath subjectID 'Separated.mat'],'newExpData','-v7.3') 

%save a copy of the exp and adapt data if exists, then replace it.
if exist([resSavePath filesep subjectID '.mat'],'file')
   eval(['copyfile ' resSavePath filesep subjectID '.mat ' resSavePath filesep subjectID 'OriginalCondName.mat'])
end
if exist([resSavePath filesep subjectID 'params.mat'])
   eval(['copyfile ' resSavePath filesep subjectID 'params.mat ' resSavePath filesep subjectID 'OriginalCondNameparams.mat'])
end

%recompute and overwrite/replace the expData
expData = newExpData.flushAndRecomputeParameters(eventClass);
save([resSavePath filesep subjectID '.mat'],'expData','-v7.3') 

%create adaptationData object
adaptData=expData.makeDataObj([resSavePath filesep subjectID]);

toc

f = adaptData.plotAvgTimeCourse(adaptData,{'singleStanceSpeedFastAbsANK','singleStanceSpeedSlowAbsANK'});
saveas(f,[resSavePath filesep subjectID 'SeparatedSpeeds'])
saveas(f,[resSavePath filesep subjectID 'SeparatedSpeeds.png'])

end
function [expData, adaptData] = SepCondsInExpByAudioCue(expData, ...
    resSavePath, subjectID, eventClass, studyName, muscleLabels, ...
    normalizationRefCond, biasRemovalCond)
%SEPCONDSINEXPBYAUDIOCUE Split conditions of a session at audio-cue times.
%
%   Separates conditions of a SpinalAdaptation session into multiple
% conditions using the audio-cue timing in the datlog (study specific: it
% uses prior knowledge of what is in the audio cues; add other studies in
% the "study specific logic" branches). New trials are split at the sTO
% event closest to each cue (s = reference leg) so that sHS strides are
% preserved in the new conditions as much as possible. The parameters are
% then recomputed (flushAndRecomputeParameters), an adaptationData object
% is built, and the average speed time courses are plotted. For subject
% 'SAS01V02' in a SpinalAdaptation study, trial 9 is additionally cut at
% 180 s (hard coded).
%
%   Side effects: saves <ID>Separated.mat (no file separator is inserted
% between resSavePath and subjectID, so resSavePath must end with one);
% copies <ID>.mat and <ID>params.mat, when present, to
% <ID>OriginalCondName.mat and <ID>OriginalCondNameparams.mat; saves the
% new <ID>.mat, <ID>params.mat, and <ID>SeparatedSpeeds (.fig and .png)
% in resSavePath, silently overwriting existing files of the same names
% (see DATA_OUTPUTS.md); opens GRF inspection figures; and displays some
% intermediate values in the command window.
%
% Inputs:
%   expData              - rawExperimentData object with datlog loaded
%   resSavePath          - char, directory to save the exp and adapt data
%                          with conditions separated
%   subjectID            - char, subject ID
%   eventClass           - char, 'force', 'kin', or '' (default); usually
%                          comes from the info file in c3d2mat
%   studyName            - char, name of the study (selects the study
%                          specific logic when separating trials)
%   muscleLabels         - cell array of char, unique muscle names (e.g.,
%                          {'BF', 'GLU', 'LG', 'MG', 'PER', 'SEMT',
%                          'SOL', 'TA', 'VL', 'VM'}). Optional: EMG norm
%                          parameters are computed only when all eight
%                          arguments are given and this is nonempty; if
%                          the norm calculation fails, a warning is issued
%                          and the parameters are computed without it
%   normalizationRefCond - char, name of the condition used to normalize
%                          the EMG: all EMG is stretched relative to the
%                          last 40 strides (excluding the last 5) of this
%                          condition so that 100% = its max and 0 = its
%                          min
%   biasRemovalCond      - char, optional, name of the condition used to
%                          compute bias-removed EMG norms for all trial
%                          types (e.g., 'OGBase'); if omitted, trial-type
%                          specific baselines are used (see REMOVEBIASV4)
%
% Outputs:
%   expData   - experimentData object with conditions separated
%   adaptData - adaptationData object with conditions separated
%
% Examples:
%   see loadSubject.m
%
% Toolbox Dependencies:
%   None
%
% See also LOADSUBJECT, SYNCDATALOG, APPENDEMGNORMPARAMETERS.


% $Author: Shuqi Liu $	$Date: 2024/05/22 13:24:55 $	$Revision: 0.1 $
% Copyright: Sensorimotor Learning Laboratory 2024

%% Create a new raw Exp Data object
%set up trigger event, copied from calcParameters
refLeg = expData.getRefLeg();
if refLeg == 'R'
    s = 'R';    f = 'L'; %TODO: substitute with getOtherLeg()
elseif refLeg == 'L'
    s = 'L';    f = 'R'; %TODO: substitute with getOtherLeg()
else
    ME = MException('MakeParameters:refLegError', ['the refLeg/' ...
        'initEventSide property of metaData must be either ''L'' or ' ...
        '''R''.']);
    throw(ME);
end

%Define the events that will be used for all further computations
eventTypes = {[s, 'HS'], [f, 'TO'], [f, 'HS'], [s, 'TO']};
eventTypes = strcat(eventClass, eventTypes);
% in calc parameter trial starts with sHS, so separate on the event
% immediately before to preserve as much strides as possible.
triggerEvent = eventTypes{4};

newExpData = expData;
trialData = expData.data;

if contains(erase(studyName, ' '), 'SpinalAdaptation')
    condsToUpdate = contains(expData.metaData.conditionName, ...
        'Split Train') | contains(expData.metaData.conditionName, ...
        'Practice');
    if sum(condsToUpdate) ~= 9
        condsToUpdate = find(condsToUpdate)
        error(['Conds to split missing, expected 9 condsToUpdate. ' ...
            'Got %d, Check condition name.'], sum(condsToUpdate))
    end
elseif contains(erase(studyName, ' '), 'SpinalAdaptBout')
    condsToUpdate = contains(expData.metaData.conditionName, 'Train');
else %default to all false (no update), add other study specific logic here.
    condsToUpdate = false(size(expData.metaData.trialsInCondition));
end
origTrials = cell2mat(expData.metaData.trialsInCondition(condsToUpdate));

%% Separate conditions using info from the audioCue timing in the datlog.
tic
for origTrialIdx = origTrials
% for origTrialIdx = 3
    fprintf('Processing orig trial %d\n', origTrialIdx)

    %use original index to get data log, original condition name
    origCondName = expData.data{origTrialIdx}.metaData.name;
    datlog = expData.metaData.datlog{origTrialIdx};

    %find the new trial index using the old name and the new name list
    %(newRawData is being updated in each for loop inside). This is needed
    %bc old trialIdx won't be valid anymore (trialIdx updated in the for
    %loop), but we also want to avoid looping through newly added
    %conditions.
    [~, loc] = ismember(origCondName, newExpData.metaData.conditionName);
    trialsInCond = cell2mat(newExpData.metaData.trialsInCondition(loc));
    % initialize to the 1st trial index, this will then be incremented for
    % each new cond added.
    newTrialIdx = trialsInCond(1);

    msg = datlog.audioCues.audio_instruction_message;
    msgTime = datlog.audioCues.startInRelativeTime ...
        + datlog.dataLogTimeOffsetBest;
    %filter out relevant messages only (study specific decisions)
    if contains(erase(studyName, ' '), 'SpinalAdaptation')
        if contains(origCondName, 'Practice')
            relMsg = contains(msg, 'DccRamp2Split') ...
                | contains(msg, 'Split');
        elseif contains(origCondName, 'Split Train')
            % all rest except for rest 4 (last one, no data in there)
            relMsg = (contains(msg, 'Mid') ...
                | contains(msg, 'DccRamp2Split') ...
                | contains(msg, 'Split') | contains(msg, 'Rest')) ...
                & (~strcmpi(msg, 'Rest4'));
            % post 1 no 1st ramp, so Mid1 is the first condition but the
            % 1st separating point is DccRamp2Split1
            if strcmpi(origCondName, 'TM Split Train Post 1')
                % ignore Mid1 in Post train 1 (no ramp to start, one
                % condition short)
                relMsg = relMsg & (~strcmpi(msg, 'Mid1'));
            end
            %Improvements: this can be done with reg exp
            % ignore the 1st rest (from rest to mid, only had 1 condition
            % = ramp to start walking, 2nd condition is mid = tied walking)
            relMsg(1) = false;
        end
    elseif contains(erase(studyName, ' '), 'SpinalAdaptBoutStudy')
        if contains(origCondName, 'Control')
            relMsg = ~ismember(msg, 'AccRamp1') ...
                & ~contains(msg, 'TMStopAudioCountDown_Train') ...
                & ~contains(msg, 'Rest') & ~contains(msg, 'Trial_End');
        elseif contains(origCondName, 'Split Train')
            relMsg = ~ismember(msg, 'AccRamp1') ...
                & ~contains(msg, 'TMStopAudioCountDown_Train') ...
                & ~startsWith(msg, 'Split') & ~contains(msg, 'Rest') ...
                & ~contains(msg, 'Mid5') & ~contains(msg, 'Trial_End');
        end
    else %default to all false, add other study specific logic here.
        relMsg = false(size(msg));
    end
    msg = msg(relMsg);
    msgTime = msgTime(relMsg);

    for trialIdx = trialsInCond %usually only have 1.
        curTrl = trialData{trialIdx};
        for msgIdx = 1:numel(msg)
            if contains(erase(studyName, ' '), 'SpinalAdaptation')
                %StudySpecific logic: create new trial from event time and
                %after, update curTrl to only keep 1 to eventtime -1, and
                %update trial meta data
                if startsWith(msg{msgIdx}, 'Rest') %change to ramp2Tied
                    newName = [origCondName ' Ramp2Tied' msg{msgIdx}(end)];
                else
                    newName = [origCondName ' ' msg{msgIdx}];
                end
            elseif contains(erase(studyName, ' '), 'SpinalAdaptBoutStudy')
                %StudySpecific logic: create new trial from event time and
                %after, update curTrl to only keep 1 to eventtime -1, and
                %update trial meta data
                newName = [origCondName ' ' msg{msgIdx}];
            else %default value, add other study specific logic here.
                newName = [origCondName ' Default'];
            end
            newDescription = newName; %keep it the same for now.
            %create a new trial separing on closet sHS to the msg
            triggerEventTime = curTrl.gaitEvents.Data(:, ...
                strcmp(curTrl.gaitEvents.labels, triggerEvent));
            triggerEventTime = curTrl.gaitEvents.Time(triggerEventTime);
            [closestTime, closestIdx] = min( ...
                abs(msgTime(msgIdx) - triggerEventTime));
            closestTime = triggerEventTime(closestIdx);
            %Option2. use msg time directly, performs about the same as
            %uing sTO
            % closestTime = msgTime(msgIdx);
            %Improvements: this can be improved to split all
            %trials follwoing the msgTime once, then add all new trials
            %once isntead of the looping methods.
            [nextTrial, curTrl] = createNextTrialAuto( ...
                curTrl, closestTime, newName);

            %update cell array list of trial data
            trialData = [trialData(1:newTrialIdx-1), ...
                {curTrl, nextTrial}, trialData(newTrialIdx+1:end)];
            %nextTrial now belongs to a new conditions. Increment the
            % condition for each element after the curTrl by 1. Also
            % update the rawDataFileName bc the last 2 digits of that is
            % used later on to populate TrialIdx in the
            % adaptationData.Data.
            for jj = newTrialIdx+1:length(trialData)
                if ~isempty(trialData{jj})
                    trialData{jj}.metaData.condition = ...
                        trialData{jj}.metaData.condition + 1;
                    % already been renamed in prev ite, replace it.
                    if contains(trialData{jj}.metaData.rawDataFilename, ...
                            '_SpltNewIdx')
                        %TODO: this line needs to support 3 digits in the
                        %two lines below.
                        trialData{jj}.metaData.rawDataFilename( ...
                            end-2:end) = sprintf('%03d', jj);
                    else %1st time being renamed, append
                        trialData{jj}.metaData.rawDataFilename = [ ...
                            trialData{jj}.metaData.rawDataFilename ...
                            '_SpltNewIdx' sprintf('%03d', jj)];
                        %the correct trialIdx should be the index of this
                        %trial in the list of trialData.
                    end
                end
            end
            %index out the updated curtrl with new cond & file name
            nextTrial = trialData{newTrialIdx+1};
            newExpData.data = trialData;

            %now update expData.metadata
            %give index of the condition this trial belongs to.
            curCondIdx = curTrl.metaData.condition;
            newTrialsInConds = {newTrialIdx+1};
            %for the ones following, increment by 1
            for ii = curCondIdx+1:length(newExpData.metaData.conditionName)
                newTrialsInConds{ii-curCondIdx+1} = ...
                    newExpData.metaData.trialsInCondition{ii} + 1;
            end
            newExpData.metaData.trialsInCondition = [ ...
                newExpData.metaData.trialsInCondition{1:curCondIdx}, ...
                newTrialsInConds];
            newExpData.metaData.conditionName = [ ...
                newExpData.metaData.conditionName{1:curCondIdx}, ...
                {newName}, ...
                newExpData.metaData.conditionName{curCondIdx+1:end}];
            newExpData.metaData.conditionDescription = [ ...
                newExpData.metaData.conditionDescription{1:curCondIdx}, ...
                {newDescription}, ...
                newExpData.metaData.conditionDescription{curCondIdx+1:end}];
            %add 1 trial
            newExpData.metaData.Ntrials = newExpData.metaData.Ntrials + 1;

            newTrialIdx = newTrialIdx + 1;
            curTrl = nextTrial;
        end
    end
end

%rename the trials for readability (study specific naming convention)
if contains(erase(studyName, ' '), 'SpinalAdaptation')
    newName = regexprep(newExpData.metaData.conditionName, ...
        {'^TM Split Train Pre 1$', '^TM Split Train Pre 2$', ...
        '^TM Split Train Post 1$', '^TM Split Train Post 2$'}, ...
        {'TM Split Train Pre 1 Ramp2Tied1', ...
        'TM Split Train Pre 2 Ramp2Tied1', ...
        'TM Split Train Post 1 Mid1', ...
        'TM Split Train Post 2 Ramp2Tied1'});
    pracNames = regexp(newExpData.metaData.conditionName, ...
        '^Practice [1-5]$');
    pracNames = find(~cellfun(@isempty, pracNames))
    for ii = pracNames
        %practice block do it with no space
        newName{ii} = [newName{ii} 'Tied'];
    end
    %Pre/PostTrain1 Keep the space.
    newName = regexprep(newName, ...
        {' DccRamp2Split0', ' Split0', 'DccRamp2Split'}, ...
        {'RampToSplit', 'Split', 'RampToSplit'});
    newName'
    newExpData.metaData.conditionName = newName;

    %update the trial meta data to also match the
    %expData.metaData.conditionName
    for ii = 1:numel(newExpData.metaData.trialsInCondition)
        trialsToUpdate = cell2mat( ...
            newExpData.metaData.trialsInCondition(ii));
        for jj = trialsToUpdate
            newExpData.data{jj}.metaData.name = ...
                newExpData.metaData.conditionName{ii};
        end
    end
else
    %add other study specific logic naming convention/style here.
end
toc

%% special handling for the 1st ramp2start in SAS01Session2
% get rid of some rest to help get good strides out when computing params.
if contains(erase(studyName, ' '), 'SpinalAdaptation') ...
        && strcmp(subjectID, 'SAS01V02') %hard coded for now
    newExpDataBackup = newExpData;
    newExpData = newExpDataBackup;
    figure(); plot(newExpData.data{1,9}.GRFData.Time, ...
        newExpData.data{1,9}.GRFData.Data(:,3))
    %from 180s to end (180 is taken from looking at the fig)
    temp = newExpData.data{9}.split(180);
    figure(); plot(temp.GRFData.Time, temp.GRFData.Data(:,3))
    newExpData.data{9} = temp;
end

%% inspect results
% (should expect force traces to roughly match how long the trial is,
% contains non-periodic traces at beginning or end of the original trial).
inspectResPlot = true;

if inspectResPlot
    figure('units', 'normalized', 'outerposition', [0 0 1 1]);
    spIdx = 1; %ax = [];
    for ii = 1:length(newExpData.metaData.conditionName)
        for jj = cell2mat(newExpData.metaData.trialsInCondition(ii))
            ax(spIdx) = subplot(10, 1, spIdx);
            plot(newExpData.data{1, jj}.GRFData.Time, ...
                newExpData.data{1, jj}.GRFData.Data(:,3));
            title(['Trial ' num2str(jj) ' ' ...
                newExpData.metaData.conditionName{ii}])
            spIdx = spIdx + 1;
        end
        %max per figure reached (fig full, start the next one)
        if spIdx == 10
            figure('units', 'normalized', 'outerposition', [0 0 1 1]);
            hold on; %restart a figure
            spIdx = 1;
        end
    end
end

%% Save this new exp data and recompute exp and params
tic

%save an intermediate file with the sep conditions
% NOTE: no file separator between resSavePath and subjectID here, unlike
% the saves below; resSavePath must end with a separator.
save([resSavePath subjectID 'Separated.mat'], 'newExpData', '-v7.3')

%save a copy of the exp and adapt data if exists, then replace it.
if exist(fullfile(resSavePath, [subjectID '.mat']), 'file')
    copyfile(fullfile(resSavePath, [subjectID '.mat']), ...
        fullfile(resSavePath, [subjectID 'OriginalCondName.mat']))
end
if exist(fullfile(resSavePath, [subjectID 'params.mat']))
    copyfile(fullfile(resSavePath, [subjectID 'params.mat']), ...
        fullfile(resSavePath, [subjectID 'OriginalCondNameparams.mat']))
end

%recompute and overwrite/replace the expData
if nargin == 8 && ~isempty(muscleLabels)
    try
        expData = newExpData.flushAndRecomputeParameters(eventClass, [], ...
            true, muscleLabels, ...
            normalizationRefCond, biasRemovalCond);
    catch
        %if the adapt creation or the appending new data fails, save the
        %expData anyway to have some intermediate data to work with.
        % Save processed data object
        warning(['muscleLabels provided but norm calculation failed. ' ...
            'Compute parameters without EMG norm.\n'])
        expData = newExpData.flushAndRecomputeParameters(eventClass);
    end
else
    expData = newExpData.flushAndRecomputeParameters(eventClass);
end

save(fullfile(resSavePath, [subjectID '.mat']), 'expData', '-v7.3')
%create and save adaptationData object
adaptData = expData.makeDataObj(fullfile(resSavePath, subjectID));

toc

f = adaptData.plotAvgTimeCourse(adaptData, ...
    {'singleStanceSpeedFastAbsANK', 'singleStanceSpeedSlowAbsANK'});
saveas(f, fullfile(resSavePath, [subjectID 'SeparatedSpeeds']))
saveas(f, fullfile(resSavePath, [subjectID 'SeparatedSpeeds.png']))

end

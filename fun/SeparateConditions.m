function adaptDataToSep = SeparateConditions(adaptDataToSep, ...
    oldConditionName, newConditionName, Tied2Split, speedDiff, ...
    newDecription, plotSpeed, containsPercTask)
%SEPARATECONDITIONS Split one condition into two using belt speed.
%
%   Separates the condition oldConditionName into {oldConditionName,
% newConditionName} at the stride where the belt speed difference changes
% between tied and split walking. The new condition must occur after the
% old one in time; the reverse is not handled. Trial numbers after the
% separated trial shift by one. If newConditionName already exists, the
% strides of oldConditionName are assigned a new trial number and merged
% into it, which only works when it directly follows oldConditionName.
% A speed change must hold for 4 consecutive strides to count as a
% transition rather than speed noise. Currently used for the first block
% of the pre-intervention trials.
%
% Side effects: when plotSpeed is true, plots the belt speed before and
%   after separating.
%
% Inputs:
%   adaptDataToSep   - adaptationData containing the condition to split
%   oldConditionName - name of the condition to split
%   newConditionName - name of the condition split off
%   Tied2Split       - (optional) true if the transition is from tied to
%                      split, false if from split to tied (default: true)
%   speedDiff        - (optional) belt speed difference cutoff (mm/s);
%                      differences above it count as split. Use the upper
%                      bound of the noise in the tied condition
%                      (default: 75)
%   newDecription    - (optional) description of the new condition
%                      (default: 'Separated <oldConditionName>')
%   plotSpeed        - (optional) logical, plot the speeds (default:
%                      false)
%   containsPercTask - (optional) logical, a perceptual task is present
%                      (default: false)
%
% Outputs:
%   adaptDataToSep - adaptationData with the separated conditions
%
% Example:
%   adaptData = SeparateConditions(adaptData, 'TMMidThenAdapt', ...
%       'Adaptation', true, speedDiff, [], plotSpeed);
%   splits TMMidThenAdapt into {TMMidThenAdapt, Adaptation} and moves the
%   second half into the existing Adaptation condition.
%
% Toolbox Dependencies: None
%
% NOTE: adapted from DulceMariscal/Generalization_Regressions/
%   AddingConditions.m (GitHub).
%
% Copyright: Sensorimotor Learning Laboratory 2024

if nargin < 4 || isempty(Tied2Split)
    Tied2Split = true; %default separate tied - split transition
end

if nargin < 5 || isempty(speedDiff)
    %default 75, tied belt speed difference usually is not perfectly 0,
    %has some noise, 75mm/s (0.075m/s) is a somewhat ok estimation of the
    %noise.
    speedDiff = 75;
end

if nargin < 6 || isempty(newDecription)
    newDecription = ['Separated ' oldConditionName];
end

if nargin < 7 || isempty(plotSpeed)
    plotSpeed = false;
end

if nargin < 8 || isempty(containsPercTask)
    containsPercTask = false;
end

%% Validate inputs
[condExist, loc] = ismember({oldConditionName, newConditionName}, ...
    adaptDataToSep.metaData.conditionName);
if ~condExist(1) %oldCondition doesn't exist, error
    error('oldConditionName does not exist. Check your input.')
    %newCondition already exists, but it happens before oldCondition, this
    %is an undefined and unreasonable situation
elseif condExist(2) && (loc(2)-loc(1) ~= 1)
    error(['newConditionName need to happen right after ' ...
        'oldConditionName. Check your input.'])
end
newCondExist = condExist(2);
newCondLoc   = loc(2);

if plotSpeed
    adaptDataToSep.plotAvgTimeCourse(adaptDataToSep, ...
        {'singleStanceSpeedFastAbsANK','singleStanceSpeedSlowAbsANK'})
    title('Before Changing Conditions');
end

%% Locate the speed signal
idxfast = compareListsNested({'singleStanceSpeedFastAbsANK'}, ...
    adaptDataToSep.data.labels) == 1;
idxslow = compareListsNested({'singleStanceSpeedSlowAbsANK'}, ...
    adaptDataToSep.data.labels) == 1;

trialNum = ...
    adaptDataToSep.metaData.trialsInCondition{ ...
    strcmp(adaptDataToSep.metaData.conditionName,oldConditionName)};
columnIdxForTrialNum = ...
    find(compareListsNested({'Trial'},adaptDataToSep.data.labels));

fast       = adaptDataToSep.data.Data(:,idxfast);
slow       = adaptDataToSep.data.Data(:,idxslow);
difference = fast-slow;

%% Find the speed change
% current condition of interes
%find all cases where diff in speed > speedDiff
diffMask         = (abs(difference) > speedDiff & ...
    adaptDataToSep.data.Data(:,columnIdxForTrialNum) == trialNum)';
%if happens continuously for 4 strides: speed did change instead of
%noise in speed
thresholdStrides = 4;

%perceptual task, index out non-percep, then find idx with speed change,
%then find out
%original idx of the speed change
if containsPercTask
    percepCol        = ismember(adaptDataToSep.data.labels,'percTask');
    nonpercepStrides = ...
        find(~logical(adaptDataToSep.data.Data(:,percepCol)));
    diffMask         = diffMask(nonpercepStrides);
end

if Tied2Split
    %get the 1st stride that have [0 1 1 1 1 ..] pattern where speed
    %difference is <speedDiffThreshold, then continuously >
    %speedDiffThreshold for n strides. (went from tied to split)
    %build a mask to find out continuous steps with speed difference
    %matching the threshold.
    thresholdFramesMask = [0, ones(1, thresholdStrides)];
    %TODO: this can be more robust probably by checking continuos strides at
    %speeddiff= 0 then continuous stride at diff > speeddiff
    %TODO: i don't think the 0 padding in diffmask is needed because speed
    %change shouldn't happen at the first or last stride of the
    %condition, that will separate a new condition that includes only 1
    %strides which doesn't make sense.

    %get the first stride that speeds changed
    idxSplit = strfind([0,diffMask],[thresholdFramesMask]);
    % strfind is a pattern matching algorithm. pad 0 to diffMask in case
    % started difference at frame 1, the 2nd argument is the pattern
    % to match, find the index where the previous frame didn't have speed
    % diff > speedDiff and the
    % next 150 frames have speed diff > speedDiff
else
    %get the 1st stride that have [1 1 1 1 .. 0 ] pattern where speed
    %difference continuously > speedDiffThreshold for n strides, then
    %< diffThreshold (went from split to tied)
    thresholdFramesMask = [ones(1, thresholdStrides),0];
    %get the first stride where 4 stride later speed changed
    idxSplit = strfind([diffMask,0],[thresholdFramesMask]);
    %shift to the first stride where speed is tied now.
    idxSplit = idxSplit + thresholdStrides;
end

%% Map the split back to all strides
%indices included the perceptual trials)
if containsPercTask
    idxSplit = nonpercepStrides(idxSplit);
end

% trialNum = ...
%    adaptDataToSep.metaData.trialsInCondition{ ...
%    strcmp(adaptDataToSep.metaData.conditionName,oldConditionName)};


%% Update the condition metadata
if newCondExist
    %if the new condition name given already exist, add this separated
    %new trial into the existing trials in the existing newCondition,
    %and shift all the trial numbers after this separated trial by 1.
    %TODO: both approaches seem convoluted, the for loop can be
    %improved for readability.
    newTrialsInConds = adaptDataToSep.metaData.trialsInCondition;
    %shift original trialNumbers by 1 and add the new separated trial
    newTrialsInConds{newCondLoc} = [trialNum+1 ...
        newTrialsInConds{newCondLoc}+1];
    newTrialsInConds(newCondLoc+1:end) = ...
        cellfun(@(x) x+1,newTrialsInConds(newCondLoc+1:end), ...
        'UniformOutput',false);
    adaptDataToSep.metaData.trialsInCondition = newTrialsInConds;
else
    %a new condition name is given, shift all trials after the current old
    %condition name by 1,
    %increase the total # of conditions
    [condExist, oldCondLoc] = ismember(oldConditionName, ...
        adaptDataToSep.metaData.conditionName);

    %keep the trials till oldConditionName
    newTrialsInConds = ...
        adaptDataToSep.metaData.trialsInCondition(1:oldCondLoc);
    %insert the new trial as its own condition
    newTrialsInConds = [newTrialsInConds, {[trialNum+1]}];
    newTrialsInConds = [newTrialsInConds, ...
        cellfun(@(x) x+1, ...
        adaptDataToSep.metaData.trialsInCondition(oldCondLoc+1:end), ...
        'UniformOutput',false)];
    %shift everything after by 1

    adaptDataToSep.metaData.trialsInCondition = newTrialsInConds;
    adaptDataToSep.metaData.conditionName = ...
        [adaptDataToSep.metaData.conditionName{1:oldCondLoc}, ...
        {newConditionName}, ...
        adaptDataToSep.metaData.conditionName{oldCondLoc+1:end}];
    adaptDataToSep.metaData.conditionDescription = ...
        [adaptDataToSep.metaData.conditionDescription{1:oldCondLoc}, ...
        {newDecription}, ...
        adaptDataToSep.metaData.conditionDescription{oldCondLoc+1:end}];

    %Alt approach, just use a branch new trial number of the splitted
    %trials, this should also work just that the trial numbers won't be
    %sorted.
    %         adaptDataToSep.metaData.conditionName{ ...
    %    currConditionLength+1}=newConditions;
    %         adaptDataToSep.metaData.trialsInCondition{ ...
    %    currConditionLength+1}=currMaxTrial+1;
    %         adaptDataToSep.metaData.conditionDescription{ ...
    %    currConditionLength+1}= newDecription;
    %         adaptDataToSep.data.trialTypes{ ...
    %    currConditionLength+1}=newTrialType;
    %         adaptDataToSep.data.Data(idxSplit, ...
    %    columnIdxForTrialNum)=currMaxTrial+1;
end
%now update the data
%increment Ntrials by 1
adaptDataToSep.metaData.Ntrials = adaptDataToSep.metaData.Ntrials+1;
adaptDataToSep.data = ...
    adaptDataToSep.data.setTrialTypes( ...
    {adaptDataToSep.data.trialTypes{1:trialNum} ...
    adaptDataToSep.data.trialTypes{ ...
    trialNum} adaptDataToSep.data.trialTypes{trialNum+1:end}});
%shift all trial numbers after the idx to split by 1
adaptDataToSep.data.Data(idxSplit:end,columnIdxForTrialNum) = ...
    adaptDataToSep.data.Data(idxSplit:end,columnIdxForTrialNum) +1;

if plotSpeed
    adaptDataToSep.plotAvgTimeCourse(adaptDataToSep, ...
        {'singleStanceSpeedFastAbsANK','singleStanceSpeedSlowAbsANK'})
    title('After Adding Conditions')
end
end

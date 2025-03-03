%Chagingparams, create new conditions in 1 trial, currently only need to
%use it fors the first block for preintervention trials.
function adaptDataToSep = SeparateConditions(adaptDataToSep, oldConditionName, newConditionName, Tied2Split, speedDiff, newDecription, plotSpeed, containsPercTask)
% Separate 1 condition given by oldConditionName into 2: {oldConditionName, newConditionName}
% the newConditionName needs to happen after the oldConditionName
% chronologically, otherwise it doesn't make sense and the code is not handling that right now.
% The trial numbers after the current trial being separated will be shifted by 1. 
% 
% [input]
%   - adaptDataToSep: an adaptationData object that contains conditiosn to be separated. 
%   - oldConditionName: string of the name of the condition that will be separated into 2
%   - newConditionName: string of the condition name of the new trial that was
%           separated out. If newConditionName already exists, will assign the strides in the
%           oldConditionName a new trial number and put them into part of the
%           newConditionName, but this basically only works if the
%           newConditionName is immediately after the oldConditionName
%   - speedDiff: integer representing the speed difference in mm/s that we
%           should use as a cutoff to separate conditions. Should be the upper bound of 
%           the speed difference measured with noise in the tied condition
%           so that anything above this uppder bound of tied will be
%           considered split. A good starting value is 75
%   - Tied2SplitOrSplit2Tied: true if the conditions split is from tied to
%           split. False if it's from split to tied walking. OPTIONAL,
%           default true (from split to tied)
%   - newDecription: string description of the new condition that will be
%           added after the split. OPTIONAL, default "Separated
%           oldConditionName"
%   - plotSpeed: OPTIONAL. boolean indicating if before and after condition
%           separating speed figures should be plotted. Default false.
%   - containsPercTask: OPTIONAL. boolean indicating if perceptual task is
%           present, default to false.
%
% [output]
%   - adaptDataToSep: an adaptationData object that contains the new conditions that have been separated. 
% Examples: 
%adaptData = AddingConditionsNirs(adaptData, 'TMMidThenAdapt', 'Adaptation', speedDiff, true, [], plotSpeed);
% The above example will separate TMMidThenAdapt in to {TMMidThenAdapt, 'Adaptation'} and group the
% 2nd half of TMMidThenAdapt in split into Adaptation condition that
% already exists:      
% 
% See also: Github: DulceMariscal/Generalization_Regressions/AddingConditions.m
%
% $Author: Shuqi Liu $	$Date: 2024/11/26 14:58:55 $	$Revision: 0.1 $
% Copyright: Sensorimotor Learning Laboratory 2024

    if nargin < 4 || isempty(Tied2Split)
        Tied2Split = true; %default separate tied - split transition
    end
    
    if nargin < 5 || isempty(speedDiff)
        speedDiff = 75; %default 75, tied belt speed difference usually is not perfectly 0, has some noise, 75mm/s (0.075m/s) is a somewhat ok estimation of the noise.
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
  
    %check if input is valid
    [condExist, loc] = ismember({oldConditionName, newConditionName}, adaptDataToSep.metaData.conditionName);
    if ~condExist(1) %oldCondition doesn't exist, error
        error('oldConditionName does not exist. Check your input.')
    elseif condExist(2) && (loc(2)-loc(1)~=1) %newCondition already exists, but it happens before oldCondition, this is an undefined and unreasonable situation
        error('newConditionName need to happen right after oldConditionName. Check your input.')
    end
    newCondExist = condExist(2);
    newCondLoc = loc(2);
    
    if plotSpeed
        adaptDataToSep.plotAvgTimeCourse(adaptDataToSep,{'singleStanceSpeedFastAbsANK','singleStanceSpeedSlowAbsANK'})
        title('Before Changing Conditions');  
    end
    
    % find the index for the label singleStanceSpeedFastAbsANK
    idxfast=compareListsNested({'singleStanceSpeedFastAbsANK'},adaptDataToSep.data.labels)==1;
    idxslow=compareListsNested({'singleStanceSpeedSlowAbsANK'},adaptDataToSep.data.labels)==1;
    
    trialNum = adaptDataToSep.metaData.trialsInCondition{strcmp(adaptDataToSep.metaData.conditionName,oldConditionName)};
    columnIdxForTrialNum=find(compareListsNested({'Trial'},adaptDataToSep.data.labels));

    fast=adaptDataToSep.data.Data(:,idxfast);
    slow=adaptDataToSep.data.Data(:,idxslow);
    difference=fast-slow;

    % find the index with speed difference or speed at 1 but also within the
    % current condition of interes
    diffMask = (abs(difference)>speedDiff & adaptDataToSep.data.Data(:,columnIdxForTrialNum) == trialNum)'; %find all cases where diff in speed > speedDiff
    thresholdStrides = 4; %if happens continuously for 4 strides: speed did change instead of noise in speed
    
    %perceptual task, index out non-percep, then find idx with speed change, then find out
    %original idx of the speed change
    if containsPercTask
        percepCol = ismember(adaptDataToSep.data.labels,'percTask');
        nonpercepStrides = find(~logical(adaptDataToSep.data.Data(:,percepCol)));
        diffMask = diffMask(nonpercepStrides);
    end
    
    if Tied2Split
        %get the 1st stride that have [0 1 1 1 1 ..] pattern where speed
        %difference is <speedDiffThreshold, then continuously >
        %speedDiffThreshold for n strides. (went from tied to split)
        thresholdFramesMask = [zeros(1,thresholdStrides), ones(1, thresholdStrides)]; %build a mask to find out continuous steps with speed difference matching the threshold.
        %TODO: this can be more robust probably by checking continuos strides at speeddiff= 0 then continuous stride at diff > speeddiff
        %TODO: i don't think the 0 padding in diffmask is needed because speed change shouldn't happen at the first or last stride of the
        %condition, that will separate a new condition that includes only 1 strides which doesn't make sense.
        
        idxSplit = strfind([zeros(1,thresholdStrides),diffMask],[thresholdFramesMask]); %get the first stride that speeds changed
        % strfind is a pattern matching algorithm. pad 0 to diffMask in case started difference at frame 1, the 2nd argument is the pattern
        % to match, find the index where the previous frame didn't have speed diff > speedDiff and the 
        % next 150 frames have speed diff > speedDiff
    else
        %get the 1st stride that have [1 1 1 1 .. 0 0 0 0 ] pattern where speed
        %difference continuously > speedDiffThreshold for n strides, then
        %< diffThreshold continuously for n strides (went from split to
        %tied), both need to be continuously for n strides to avoid
        %separating condition at a noisy speed stride. Need to consistently
        %be above then below threshold to count as real-split
        thresholdFramesMask = [ones(1, thresholdStrides),zeros(1,thresholdStrides)]; 
        idxSplit = strfind([diffMask,zeros(1,thresholdStrides)],[thresholdFramesMask]); %get the first stride where 4 stride later speed changed
        idxSplit = idxSplit + thresholdStrides; %shift to the first stride where speed is tied now. 
    end
    
    %perceptual task, return the idxSplit in the original data frame (where
    %indices included the perceptual trials)
    if containsPercTask
        idxSplit = nonpercepStrides(idxSplit);
    end
    
    if newCondExist
        %if the new condition name given already exist, add this separated
        %new trial into the existing trials in the existing newCondition,
        %and shift all the trial numbers after this separated trial by 1.
        %TODO: both approaches seem convoluted, the for loop can be
        %improved for readability. 
        newTrialsInConds = adaptDataToSep.metaData.trialsInCondition;
        newTrialsInConds{newCondLoc} = [trialNum+1 newTrialsInConds{newCondLoc}+1]; %shift original trialNumbers by 1 and add the new separated trial
        newTrialsInConds(newCondLoc+1:end) = cellfun(@(x) x+1,newTrialsInConds(newCondLoc+1:end),'UniformOutput',false);
        adaptDataToSep.metaData.trialsInCondition = newTrialsInConds;
    else
        %a new condition name is given, shift all trials after the current old condition name by 1,
        %increase the total # of conditions
        [condExist, oldCondLoc] = ismember(oldConditionName, adaptDataToSep.metaData.conditionName);
        
        newTrialsInConds = adaptDataToSep.metaData.trialsInCondition(1:oldCondLoc); %keep the trials till oldConditionName
        newTrialsInConds = [newTrialsInConds, {[trialNum+1]}]; %insert the new trial as its own condition
        newTrialsInConds = [newTrialsInConds, cellfun(@(x) x+1,adaptDataToSep.metaData.trialsInCondition(oldCondLoc+1:end),'UniformOutput',false)];
        %shift everything after by 1
        
        adaptDataToSep.metaData.trialsInCondition = newTrialsInConds;
        adaptDataToSep.metaData.conditionName = [adaptDataToSep.metaData.conditionName{1:oldCondLoc}, {newConditionName}, adaptDataToSep.metaData.conditionName{oldCondLoc+1:end}];
        adaptDataToSep.metaData.conditionDescription = [adaptDataToSep.metaData.conditionDescription{1:oldCondLoc}, {newDecription}, adaptDataToSep.metaData.conditionDescription{oldCondLoc+1:end}];
        
        %Alt approach, just use a branch new trial number of the splitted
        %trials, this should also work just that the trial numbers won't be
        %sorted.
%         adaptDataToSep.metaData.conditionName{currConditionLength+1}=newConditions;
%         adaptDataToSep.metaData.trialsInCondition{currConditionLength+1}=currMaxTrial+1;
%         adaptDataToSep.metaData.conditionDescription{currConditionLength+1}= newDecription;
%         adaptDataToSep.data.trialTypes{currConditionLength+1}=newTrialType;
%         adaptDataToSep.data.Data(idxSplit,columnIdxForTrialNum)=currMaxTrial+1;
    end
    %now update the data
    adaptDataToSep.metaData.Ntrials = adaptDataToSep.metaData.Ntrials+1; %increment Ntrials by 1
    adaptDataToSep.data = adaptDataToSep.data.setTrialTypes({adaptDataToSep.data.trialTypes{1:trialNum} adaptDataToSep.data.trialTypes{trialNum} adaptDataToSep.data.trialTypes{trialNum+1:end}});
    adaptDataToSep.data.Data(idxSplit:end,columnIdxForTrialNum) = adaptDataToSep.data.Data(idxSplit:end,columnIdxForTrialNum) +1; %shift all trial numbers after the idx to split by 1
        
    if plotSpeed
        adaptDataToSep.plotAvgTimeCourse(adaptDataToSep,{'singleStanceSpeedFastAbsANK','singleStanceSpeedSlowAbsANK'})
        title('After Adding Conditions')
    end
end 

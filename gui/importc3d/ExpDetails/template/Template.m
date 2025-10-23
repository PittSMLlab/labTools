%EDIT THIS COMMENT: INCLUDE A BREIF DESCRIPTION OF THE STUDY
% Example: OG study: older participants adapted abruptly

% The different fields of the condition info are defined here.
% Save this code to a different name, and then run it once
% Finish editing for changes to appear in 'GetInfoGUI'

% define name of group
expDes.group = 'New Group';

% define maximum number of conditions
maxConds = 10;                          % EDIT FOR YOUR EXPERIMENT

% define total number of conditions
expDes.numofconds = num2str(maxConds);  % matches defined maximum

% define condition numbers
for cond = 1:maxConds                   % for each condition, ...
    expDes.(['condition' num2str(cond)]) = num2str(cond);   % set numbers
end

% define trial types
%   Trial types descibe the general condition of the trial (e.g, walking
% overground or on an incline).
% NOTE: types should only be defined for general conditions that require a
% separate baseline for bias removal (e.g., even though there may be a
% slow, fast, and medium baseline treadmill trial, if only the medium
% baseline is used for bias removal from other treadmill trials, then these
% can all be grouped into a general treadmill trial type)
for t = [1 9]                               % for OG trial indices, ...
    expDes.(['type' num2str(t)]) = 'OG';    % overground walking trials
end
for t = [2:8 10]                            % for TM trial indices, ...
    expDes.(['type' num2str(t)]) = 'TM';    % treadmill walking trials
end
% NOTE: 'IN' is typically used for inclined treadmill trial types

% define condition names, which should be short but descriptive and should
% follow lab conventions, if possible. IMPORTANT: The condition that will
% be used to remove a bias from all other trials of the same type MUST
% be named such that one of the type strings and the string �base� are
% both included in the name of the condition.
expDes.condName1 = 'OG base';   % will be used for 'OG' trial bias removal
expDes.condName2 = 'slow base';
expDes.condName3 = 'short split';
expDes.condName4 = 'fast base';
expDes.condName5 = 'TM base';   % will be used for 'TM' trial bias removal
expDes.condName6 = 'adaptation';
expDes.condName7 = 'catch';
expDes.condName8 = 're-adaptation';
expDes.condName9 = 'OG post';
expDes.condName10 = 'TM post';

% define condition descriptions. Be as descriptive as possible. Include
% whatever information seems important to someone who is unfamiliar with
% the experimental protocol, such as the number of strides and possibly the
% speeds at which the treadmill belts were set.
expDes.description1 = '8m walkway for 6 min';
expDes.description2 = '150 strides at 0.5 m/s';
expDes.description3 = '10 strides 2:1, 1 m/s and 0.5 m/s';
expDes.description4 = '150 strides at 1 m/s';
expDes.description5 = '150 strides at 0.75 m/s';
expDes.description6 = '600 strides 2:1, 1 m/s and 0.5 m/s';
expDes.description7 = '10 strides at 0.75 m/s';
expDes.description8 = '300 strides 2:1, 1 m/s and 0.5 m/s';
expDes.description9 = '8 m walkway for 6 min';
expDes.description10 = '450 strides at 0.75 m/s';

% define (expected) trial numbers for each condition where multiple trials
% per condition can be specified as '1:5', '1,2,3', or '4 5', but not
% '1-5'). These default values may need to be edited for each experimental
% session. NOTE that the numbers correspond to names of the Vicon Nexus
% files generated during experiment.
expDes.trialnum1 = '1:6';
expDes.trialnum2 = '7';
expDes.trialnum3 = '8';
expDes.trialnum4 = '9';
expDes.trialnum5 = '10';
expDes.trialnum6 = '11:14';
expDes.trialnum7 = '15';
expDes.trialnum8 = '16 17';
expDes.trialnum9 = '18:23';
expDes.trialnum10 = '24:26';

% --------------------- DO NOT EDIT BELOW THIS LINE --------------------- %
groupName = expDes.group;
groupName = groupName(ismember(groupName,['A':'Z' 'a':'z']));
path = which('GetInfoGUI');
path = strrep(path,'GetInfoGUI.m','ExpDetails');
save([path filesep groupName],'expDes');


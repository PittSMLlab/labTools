% expDesTemplate  Template script for generating an experiment description.
%
%   Defines an experiment description structure (expDes) and saves it as a
% MAT file in the ExpDetails folder, where it becomes available as a
% selectable option in the GetInfoGUI experiment description dropdown.
%
%   How to use this template:
%     1. Save a copy of this file under a new, descriptive name that
%        reflects your experiment (e.g., 'myStudyOlderAdults.m'). The
%        saved MAT file will share this name.
%     2. Edit all fields in Sections 1-6 to match your experimental design.
%        Follow the inline guidance for each field.
%     3. Run the script once. The expDes struct will be saved automatically
%        to the ExpDetails folder and will appear in GetInfoGUI.
%     4. Re-run the script any time you need to update the description.
%        The existing MAT file will be overwritten.
%
%   Toolbox Dependencies:
%     None
%
%   See also: GetInfoGUI, errorProofInfo, setExpDescription

% EDIT THIS COMMENT: INCLUDE A BRIEF DESCRIPTION OF THE STUDY
% EXAMPLE: OG Study: older participants adapted abruptly

% ============================================================
% ===================== 1. Group Name ========================
% ============================================================

% Define the display name for this experiment group. This is the label
% that will appear in the GetInfoGUI experiment description dropdown, and
% is stored in info.ExpDescription for all sessions using this template.
% The MAT file will be saved using only the alphabetic characters of this
% string (see the save step at the bottom of this script).
expDes.group = 'New Group';             % EDIT: descriptive group name

% ============================================================
% ================ 2. Number of Conditions ===================
% ============================================================

% Define the total number of experimental conditions. All subsequent
% sections (trial types, names, descriptions, and trial numbers) must
% define exactly this many entries.
maxConds          = 10;                 % EDIT: total number of conditions
expDes.numofconds = num2str(maxConds);  % stored as string for GUI

% ============================================================
% =================== 3. Condition Numbers ===================
% ============================================================

% Condition numbers are assigned sequentially and should not need editing.
% They are used internally to index into condition-specific fields.
for cond = 1:maxConds
    expDes.(['condition' num2str(cond)]) = num2str(cond);
end

% ============================================================
% ==================== 4. Trial Types ========================
% ============================================================

% Trial types describe the general locomotion context of each condition.
% They are used to group conditions that share the same baseline for bias
% removal during data processing. Common types are:
%   'OG' - overground walking
%   'TM' - treadmill walking
%   'IN' - inclined treadmill walking
%
% IMPORTANT: Only distinguish types if they require a separate baseline for
% bias removal. For example, if slow, medium, and fast treadmill conditions
% all use the same baseline, they should all be assigned 'TM' even though
% they differ in speed.
%
% EDIT: replace the index vectors below with the condition indices for each
% type in your experiment.

for t = [1 9]                               % EDIT: OG condition indices
    expDes.(['type' num2str(t)]) = 'OG';    % overground walking
end
for t = [2:8 10]                            % EDIT: TM condition indices
    expDes.(['type' num2str(t)]) = 'TM';    % treadmill walking
end

% ============================================================
% ================== 5. Condition Names ======================
% ============================================================

% define condition names, which should be short but descriptive and should
% follow lab conventions, if possible. IMPORTANT: The condition that will
% be used to remove a bias from all other trials of the same type MUST
% be named such that one of the type strings and the string ‘base’ are
% both included in the name of the condition.
expDes.condName1  = 'OG base';   % used for 'OG' trial bias removal
expDes.condName2  = 'slow base';
expDes.condName3  = 'short split';
expDes.condName4  = 'fast base';
expDes.condName5  = 'TM base';   % used for 'TM' trial bias removal
expDes.condName6  = 'adaptation';
expDes.condName7  = 'catch';
expDes.condName8  = 're-adaptation';
expDes.condName9  = 'OG post';
expDes.condName10 = 'TM post';

% ============================================================
% ================ 6. Condition Descriptions =================
% ============================================================

% define condition descriptions. Be as descriptive as possible. Include
% whatever information seems important to someone who is unfamiliar with
% the experimental protocol, such as the number of strides and possibly the
% speeds at which the treadmill belts were set.
expDes.description1  = '8 m walkway for 6 min';
expDes.description2  = '150 strides at 0.5 m/s';
expDes.description3  = '10 strides 2:1, 1 m/s and 0.5 m/s';
expDes.description4  = '150 strides at 1 m/s';
expDes.description5  = '150 strides at 0.75 m/s';
expDes.description6  = '600 strides 2:1, 1 m/s and 0.5 m/s';
expDes.description7  = '10 strides at 0.75 m/s';
expDes.description8  = '300 strides 2:1, 1 m/s and 0.5 m/s';
expDes.description9  = '8 m walkway for 6 min';
expDes.description10 = '450 strides at 0.75 m/s';

% ============================================================
% ================== 7. Trial Numbers ========================
% ============================================================

% define (expected) trial numbers for each condition where multiple trials
% per condition can be specified as '1:5', '1,2,3', or '4 5', but not
% '1-5'). These default values may need to be edited for each experimental
% session. NOTE that the numbers correspond to names of the Vicon Nexus
% files generated during experiment.
expDes.trialnum1  = '1:6';
expDes.trialnum2  = '7';
expDes.trialnum3  = '8';
expDes.trialnum4  = '9';
expDes.trialnum5  = '10';
expDes.trialnum6  = '11:14';
expDes.trialnum7  = '15';
expDes.trialnum8  = '16 17';
expDes.trialnum9  = '18:23';
expDes.trialnum10 = '24:26';

% ============================================================
% ==================== Save expDes File ======================
% ============================================================
% --------------- DO NOT EDIT BELOW THIS LINE ----------------
groupName    = expDes.group;
groupName    = groupName(ismember(groupName, ['A':'Z' 'a':'z']));
detailsPath  = which('GetInfoGUI');
detailsPath  = strrep(detailsPath, 'GetInfoGUI.m', 'ExpDetails');
save(fullfile(detailsPath, groupName), 'expDes');
fprintf('Experiment description saved: %s\n', ...
    fullfile(detailsPath, [groupName '.mat']));


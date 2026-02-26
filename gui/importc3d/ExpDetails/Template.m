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
expDes.numofconds = maxConds;           % stored as double

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

% Condition names should be short but descriptive and follow lab naming
% conventions where possible.
%
% IMPORTANT: The condition used as the bias-removal baseline for all other
% conditions of the same type MUST have a name that includes both the type
% string (e.g., 'OG' or 'TM') and the string 'base'. For example, a
% treadmill baseline condition could be named 'TM base'.
%
% EDIT: update the cell array entries below to match your conditions. Add
% or remove entries as needed — the total must equal maxConds.

condNames = { ...
    'OG base',       ...    % condition 1  — OG bias removal baseline
    'slow base',     ...    % condition 2
    'short split',   ...    % condition 3
    'fast base',     ...    % condition 4
    'TM base',       ...    % condition 5  — TM bias removal baseline
    'adaptation',    ...    % condition 6
    'catch',         ...    % condition 7
    're-adaptation', ...    % condition 8
    'OG post',       ...    % condition 9
    'TM post'};             % condition 10

% ============================================================
% ================ 6. Condition Descriptions =================
% ============================================================

% Descriptions should provide enough detail for someone unfamiliar with
% the protocol to understand what occurred in each condition. Include the
% number of strides (or duration) and any relevant speed or belt ratio
% information. Format: '<N> strides at <speed(s)>', '<duration> on <N>m
% walkway', or similar as appropriate.
%
% EDIT: update the cell array entries below to match your conditions.

condDescriptions = { ...
    '8 m walkway for 6 min',                ...    % condition 1
    '150 strides at 0.5 m/s',               ...    % condition 2
    '10 strides 2:1, 1 m/s and 0.5 m/s',    ...    % condition 3
    '150 strides at 1 m/s',                 ...    % condition 4
    '150 strides at 0.75 m/s',              ...    % condition 5
    '600 strides 2:1, 1 m/s and 0.5 m/s',   ...    % condition 6
    '10 strides at 0.75 m/s',               ...    % condition 7
    '300 strides 2:1, 1 m/s and 0.5 m/s',   ...    % condition 8
    '8 m walkway for 6 min',                ...    % condition 9
    '450 strides at 0.75 m/s'};                    % condition 10

% ============================================================
% ================== 7. Trial Numbers ========================
% ============================================================

% Trial numbers correspond to the numeric suffixes of the Vicon Nexus
% C3D files recorded during the session (e.g., 'basename07.c3d').
%
% Multiple trials per condition can be specified as:
%   '1:5'   - trials 1 through 5 (contiguous range)
%   '1 2 3' - trials 1, 2, and 3 (space-separated list)
%   '1,2,3' - trials 1, 2, and 3 (comma-separated list)
% NOTE: '1-5' is NOT a supported format.
%
% These are default values that may be adjusted for each individual session
% in GetInfoGUI after the experiment description is loaded.
%
% EDIT: update the cell array entries below to match your expected trial
% numbering.

trialNums = { ...
    '1:6',   ...    % condition 1
    '7',     ...    % condition 2
    '8',     ...    % condition 3
    '9',     ...    % condition 4
    '10',    ...    % condition 5
    '11:14', ...    % condition 6
    '15',    ...    % condition 7
    '16 17', ...    % condition 8
    '18:23', ...    % condition 9
    '24:26'};       % condition 10

% ============================================================
% ==================== Save expDes File ======================
% ============================================================
% --------------- DO NOT EDIT BELOW THIS LINE ----------------

% Validate that each cell array contains exactly maxConds entries before
% populating the struct and saving.
if length(condNames) ~= maxConds
    error(['expDesTemplate: %d condName entries defined, but ' ...
        'maxConds = %d. Add or remove entries to match.'], ...
        length(condNames), maxConds);
end
if length(condDescriptions) ~= maxConds
    error(['expDesTemplate: %d description entries defined, but ' ...
        'maxConds = %d. Add or remove entries to match.'], ...
        length(condDescriptions), maxConds);
end
if length(trialNums) ~= maxConds
    error(['expDesTemplate: %d trialnum entries defined, but ' ...
        'maxConds = %d. Add or remove entries to match.'], ...
        length(trialNums), maxConds);
end

% Populate expDes struct fields from validated cell arrays
for cond = 1:maxConds
    expDes.(['condName'     num2str(cond)]) = condNames{cond};
    expDes.(['description'  num2str(cond)]) = condDescriptions{cond};
    expDes.(['trialnum'     num2str(cond)]) = trialNums{cond};
end

% Derive the MAT filename from the group name (alphabetic characters only)
% and save to the ExpDetails folder alongside GetInfoGUI.
groupName   = expDes.group;
groupName   = groupName(ismember(groupName, ['A':'Z' 'a':'z']));
detailsPath = which('GetInfoGUI');
detailsPath = strrep(detailsPath, 'GetInfoGUI.m', 'ExpDetails');
save(fullfile(detailsPath, groupName), 'expDes');
fprintf('Experiment description saved: %s\n', ...
    fullfile(detailsPath, [groupName '.mat']));


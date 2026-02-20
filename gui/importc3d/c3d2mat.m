% c3d2mat  Main script for parsing C3D session files into a MAT file.
%
% This script collects information regarding the experiment conducted and
% transforms data from the C3D format into 'labTools' objects. It then
% processes that data to compute heel strike and toe off events, limb
% angles, adaptation parameters, and processed EMG data (if present).
%
% Toolbox Dependencies:
%   None
%
% See also: GetInfoGUI, loadSubject

%% Collect Experimental Session Information

% Launch the GetInfoGUI to collect participant data, experiment metadata,
% notes, and trial conditions from the user.
info = GetInfoGUI();

%% Process Experimental Data

if ~isempty(info)   % if experimental information was provided, proceed
    % Available methods for determining gait events:
    %   ''      - default (forces for TM trials, kinematics otherwise)
    %   'kin'   - strictly from kinematics (overground trials with
    %             limited or no force plate data)
    %   'force' - strictly from forces (treadmill trials with
    %             consistent, reliable force plate data)
    eventClass = {'', 'kin', 'force'};

    answer = menu('Which events should be used to compute parameters?', ...
        'default (use forces for TM trials, kinematics otherwise)', ...
        'strictly from kinematics', ...
        'strictly from forces');

    if answer == 0      % if the menu window was closed with 'X', ...
        answer = 1;     % default to the standard event detection method
    end

    % Main processing call for the participant's experimental data
    [expData, rawExpData, adaptData] = ...
        loadSubject(info, eventClass{answer});

    clear answer eventClass;
else    % if no experimental information was provided, abort
    return;
end


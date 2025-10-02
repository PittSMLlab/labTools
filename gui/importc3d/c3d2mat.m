%c3d2mat -- The main script for parsing C3D session files into a MAT file.
%
% This script collects information regarding the experiment conducted and
% transforms the data from the .c3d format into 'labTools' objects and then
% processes that data to give heel strike and toe off events, limb angles,
% adaptation parameters, and processed EMG data (if EMG data are present).
%
% See also: GetInfoGUI, loadSubject

% Begin by running the GetInfoGUI, which collects participant data,
% experiment data, and notes, as well as trial conditions.
info = GetInfoGUI;

% Ask which event class to use
%   (either default, kinematics only, or forces only)
if ~isempty(info)               % if experimental information provided, ...
    % available methods to determine gait events:
    %   '' is default option (force for TM trials, kinematics otherwise)
    %   'kin' for overground trials (limited/no force plate data)
    %   'force' for treadmill trials (consistent/reliable force plate data)
    eventClass = {'','kin','force'};
    answer = menu('Which events should be used to compute parameters?', ...
        'default (use force for TM trials, kinematics otherwise)', ...
        'strictly from kinematics','strictly from forces');
    if answer == 0  % if GUI menu window exited ('X'), ...
        answer = 1; % set to 'default'
    end

    % main processing call for participant's experimental data
    [expData,rawExpData,adaptData] = loadSubject(info,eventClass{answer});

    clear answer eventClass;    % clear workspace variables
else                            % otherwise, ...
    return;
end


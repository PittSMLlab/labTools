%c3d2mat -- The main script for parsing .c3d files into a subject .mat file.
%
%This script collects information regarding the experiment conducted,
%transforms the data from .c3d format into labTools objects,
%and then processes that data to give HS and TO events, limb angles,
%adaptation parameters, and processed EMG data (if EMG data are present)
%
%See also: GetInfoGUI, loadSubject

% Begin by running the GetInfoGUI, this will collect subject data,
% experiment data and notes, as well as trial conditions.
% info = GetInfoGUI;
info = GetInfoGUIbeta;

%Ask which event class to use
eventClass={'','kin','force'};%possible methods to determine gait events, 'kin' for over ground, 'force' for treadmill. '' is use trial type or default
answer=menu('Which events should be used to compute parameters?','default (use kinematics for TM trials, forces otherwise)','strictly from kinematics','strictly from forces');
if answer==0
    answer=1;
end

%Do the actual loading
if ~isempty(info)
    [expData,rawExpData,adaptData]=loadSubject(info,eventClass{answer});
end

clear answer eventClass
%c3d2mat    The main function for turning .c3d files into a subject .mat file.
%
%This script collects information regarding the experiment conducted,
%trnasforms the raw data from .c3d files into matlab objects,
%and then processes that data to give HS and TO events, limb angles,
%adaptation parameters, and processed EMG data (if EMG data are present)
%
%See also: GetInfoGUI, loadSubject

% Get info!
info = GetInfoGUI;

%Ask which event class to use
eventClass={'','kin','force'};
answer=menu('Which events should be used to compute parameters?','default (use kinematics for TM trials, forces otherwise)','strictly from kinematics','strictly from forces');
if answer==0
    answer=1;
end

%Do the actual loading
if ~isempty(info)
    [expData,rawExpData,adaptData]=loadSubject(info,eventClass{answer});
end

clear answer eventClass
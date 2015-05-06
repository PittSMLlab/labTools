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

%Do the actual loading
if ~isempty(info)
    [expData,rawExpData,adaptData]=loadSubject(info);
end
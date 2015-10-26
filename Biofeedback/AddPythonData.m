%Script to process a python biofeedback data file and add the columns of
%data onto the end of the subject's adaptData instance
%  No inputs required, inputs are asked for during the execution. However,
%  it is required that Nexus processing has already been done prior to
%  calling this function. otherwise it will not be able to find the
%  labtools objects to update.
%
%  No output is returned, however a message is displayed which indicated
%  success or failure
%
%This function is intended to be universaly usefull, in other words it
%will be useful for any study collecting biofeedback in conjunction with a
%nexus gait trial. This is not designed for biofeedback trials outside of
%gait (it doesn't make sense to be doing this if there is no gait).
%
%written 10/26/2015 WDA

%select processed subject data to add biofeedback info to:
[notname,LTpathname]=uigetfile('*.mat*','Select Subject File:');%you can pick any of the matlab files SUB.RAW or sub.info or sub.params etc.
cd(LTpathname);
%enter the subject code
LTfilename = inputdlg('Please enter the subject code:','',1,{notname(1:6)});%notname is a guess, make sure to check or this will crash
LTfilename = LTfilename{1};
%load subject files
WB = waitbar(0,'Loading RAW file');
load([LTfilename 'RAW.mat']);
waitbar(0.33,WB,'Loading main file');
load([LTfilename '.mat']);
waitbar(0.66,WB,'Loading params file');
load([LTfilename 'params.mat']);
waitbar(1,WB,'Loading complete');
pause(0.25)
close(WB)






%select python file(s) to process
% [filenames,~] = uigetfiles('*.*','Select filenames');
% 
% if iscell(filenames)
%     
%     
% else
%     
% end
% 
% end
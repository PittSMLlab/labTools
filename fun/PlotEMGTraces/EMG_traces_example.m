%%Traces from example subject to show how data is summarized

%You can update this script to your data set 
%Important is to load a ID.mat file
%Choose the conditions that you want to plot 
%Hoe many strides you want to plot 
%IF you want to plot the early or the late part of the conditions 
% IF you want to ignore stides at the early part of the conditon

%% 1: Load Data

if ~exist('expData','var')    % if data file has not been loaded, ...
    load([strSess '.mat']);   % load the data file
else                    % otherwise, ...
    % currently do nothing because adaptData & strSess exist
    strSess = 'C3S12_S1';
end

%% Set muscle to plot
muscle={'TFL','GLU','HIP','SEMB','SEMT','BF','VM','VL','RF','SOL','LG','MG','TA','PER'}; %muscles that you want to plot 
normalize = 1;  % 1 to normalize data
normCond = {'TM Base'}; % Condition that you want to use to normalize the data 
%%
%% Baseline condtions
% Here we are plotting treadmill baseline for references 
conds={'TM Base'};
late=[1 1 1];  %0 average of initial strides 1 average of the last strides
strides=[40 40 40]; % Number of strides that you are going to average 
IgnoreStridesEarly=[1 1 1] ;  %number of strides that you are going to ignore at the beginning

%plotting function
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);
set(gcf,'renderer','painters');
saveas(gcf,[strSess '_EMG_Normalized_Base.fig']);
saveas(gcf,[strSess '_EMG_Normalized_Base.png']);

%% Baseline condtions for the 3 usual speeds 
% Here we are okitting the late part of the different baseline conditions 
conds={'TM Base','TM Fast','OG Base'};
late=[1 1 1];  %0 average of initial strides 1 average of the last strides
strides=[40 40 40]; % Number of strides that you are going to average 
IgnoreStridesEarly=[1 1 1] ; %number of strides that you are going to ignore at the beginning
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);
saveas(gcf,[strSess '_EMG_Normalized_BaseTMOGFast.fig']);
saveas(gcf,[strSess '_EMG_Normalized_BaseTMOGFast.png']);

%%  Baseline plus early and late adaptation 
% Here we are plotting treadmill baseline, early adaptation and late
% adaptation 

conds={'TM Base','Adaptation','Adaptation'};
late=[1 0 1];  %0 average of initial strides 1 average of the last strides
strides=[40 40 40]; % Number of strides that you are going to average 
IgnoreStridesEarly=[1 1 0]; %number of strides that you are going to ignore at the beginning
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly); 
saveas(gcf,[strSess '_EMG_Normalized_BaseAdapt.fig']);
saveas(gcf,[strSess '_EMG_Normalized_BaseAdapt.png']);


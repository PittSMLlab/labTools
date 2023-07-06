%%Traces from example subject to show how data is summarized

%You can update this script to your data set 
%Important is to load a ID.mat file
%Choose the conditions that you want to plot 
%Hoe many strides you want to plot 
%IF you want to plot the early or the late part of the conditions 
% IF you want to ignore stides at the early part of the conditon

%% Set muscle to plot
muscle={ 'TFL', 'GLU','HIP', 'SEMB', 'SEMT','BF', 'VM', 'VL', 'RF','SOL', 'LG', 'MG','TA', 'PER'}; %muscles that you want to plot 
normalize = 1;  % 1 to normalize data
normCond = {'TM mid 1'}; % Condition that you want to use to normalize the data 
%%
%% Baseline condtions
% Here we are plotting treadmill baseline for references 
conds={'TM base'};
late=[1 1 1];  %0 average of initial strides 1 average of the last strides
strides=[40 40 40]; % Number of strides that you are going to average 
IgnoreStridesEarly=[1 1 1] ;  %number of strides that you are going to ignore at the beginning

%plotting function
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);

%% Baseline condtions for the 3 usual speeds 
% Here we are okitting the late part of the different baseline conditions 
conds={'TM base','TM fast','TM slow', 'OG base'};
late=[1 1 1];  %0 average of initial strides 1 average of the last strides
strides=[40 40 40]; % Number of strides that you are going to average 
IgnoreStridesEarly=[1 1 1] ; %number of strides that you are going to ignore at the beginning
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly);


%%  Baseline plus early and late adaptation 
% Here we are plotting treadmill baseline, early adaptation and late
% adaptation 

conds={'TM base','Adaptation','Adaptation'};
late=[1 0  1 ];  %0 average of initial strides 1 average of the last strides
strides=[40 40 40]; % Number of strides that you are going to average 
IgnoreStridesEarly=[1 1 0]; %number of strides that you are going to ignore at the beginning
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond,IgnoreStridesEarly); 



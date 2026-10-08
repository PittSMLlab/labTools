%% EMG traces of an example subject
% Script. Plots normalized EMG traces of an example session with
% plotEMGtraces for the treadmill baseline, the three baseline speeds,
% and early and late adaptation, and saves each figure. Edit the muscles,
% conditions, number of strides, and the early/late flags for your data
% set.
%
% Inputs:
%   expData - (workspace) processed experimentData; if it is missing the
%             script loads <strSess>.mat
%   strSess - (workspace) session ID; set to 'C3S12_S1' when expData
%             already exists
%
% Outputs:
%   none - figures only
%
% Side effects: loads <strSess>.mat when expData is not in the workspace;
%   opens one figure per section and saves it as .fig and .png in the
%   current folder (<strSess>_EMG_Normalized_Base, ..._BaseTMOGFast,
%   ..._BaseAdapt).
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox (through
%   plotEMGtraces)
%
% See also PLOTEMGTRACES, NIM_EMG_TRACES_PER_COND.

%% 1: Load Data

if ~exist('expData','var')    % if data file has not been loaded, ...
    load([strSess '.mat']);   % load the data file
else                    % otherwise, ...
    % currently do nothing because adaptData & strSess exist
    strSess = 'C3S12_S1';
end

%% Set muscle to plot
muscle    = {'TFL','GLU','HIP','SEMB','SEMT','BF','VM','VL','RF','SOL', ...
    'LG','MG','TA','PER'}; %muscles that you want to plot
normalize = 1;  % 1 to normalize data
% Condition that you want to use to normalize the data
normCond  = {'TM Base'};

%% Baseline condtions
% Here we are plotting treadmill baseline for references
conds = {'TM Base'};
late = [1 1 1];  %0 average of initial strides 1 average of the last strides
strides = [40 40 40]; % Number of strides that you are going to average
%number of strides that you are going to ignore at the beginning
IgnoreStridesEarly = [1 1 1] ;

%plotting function
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond, ...
    IgnoreStridesEarly);
set(gcf,'renderer','painters');
saveas(gcf,[strSess '_EMG_Normalized_Base.fig']);
saveas(gcf,[strSess '_EMG_Normalized_Base.png']);

%% Baseline condtions for the 3 usual speeds
% Here we are okitting the late part of the different baseline conditions
conds = {'TM Base','TM Fast','OG Base'};
late = [1 1 1];  %0 average of initial strides 1 average of the last strides
strides = [40 40 40]; % Number of strides that you are going to average
%number of strides that you are going to ignore at the beginning
IgnoreStridesEarly = [1 1 1] ;
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond, ...
    IgnoreStridesEarly);
saveas(gcf,[strSess '_EMG_Normalized_BaseTMOGFast.fig']);
saveas(gcf,[strSess '_EMG_Normalized_BaseTMOGFast.png']);

%%  Baseline plus early and late adaptation
% Here we are plotting treadmill baseline, early adaptation and late
% adaptation

conds = {'TM Base','Adaptation','Adaptation'};
late = [1 0 1];  %0 average of initial strides 1 average of the last strides
strides = [40 40 40]; % Number of strides that you are going to average
%number of strides that you are going to ignore at the beginning
IgnoreStridesEarly = [1 1 0];
plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond, ...
    IgnoreStridesEarly);
saveas(gcf,[strSess '_EMG_Normalized_BaseAdapt.fig']);
saveas(gcf,[strSess '_EMG_Normalized_BaseAdapt.png']);


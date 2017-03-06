%This is an example on how to plot parameter time-courses using the
%monoLS() filter to 'clean' the signal

%PRe-requisite:
%A variable named 'adaptData' of the adaptationData class needs to exist in
%the workspace

%Define parameters & conditions to be plotted: can be anything that exists
%on adaptData!
%params={'alphaSlow','alphaFast','singleStanceSpeedSlowAbs'};
params={'spatialContributionP','stepTimeContributionP','velocityContributionP','netContributionP'};
conds={'TM base','Adap','Wash'};

%Do the plots:
%% First plot: no filters
binWidth=1;
[f,~,~,ph]=adaptationData.plotAvgTimeCourse(adaptData,params,conds,binWidth);

%% Second plot: use monotonic LS, constraining derivatives up to 2nd order to
%have no sign changes, using no regularization, and fitting a single
%function for each condition
order=2;
reg=0;
medianAcrossSubj=0;
trialBased=0;
filterFlag=[medianAcrossSubj,order,reg,trialBased];
colorOrder=repmat(.6*ones(1,3),3,1); %Changing colors for plot
%Do the plot:
adaptationData.plotAvgTimeCourse(adaptData,params,conds,binWidth,[],[],[],colorOrder,[],[],[],filterFlag,ph);

%% Third plot: use monotonic LS, constraining derivatives up to 2nd order to
%have no sign changes, using no regularization, and fitting a single
%function for each TRIAL
trialBased=1;
filterFlag=[medianAcrossSubj,order,reg,trialBased];
colorOrder=repmat(0*ones(1,3),3,1); %Changing colors for plot
%Do the plot:
adaptationData.plotAvgTimeCourse(adaptData,params,conds,binWidth,[],[],[],colorOrder,[],[],[],filterFlag,ph);

%% Fourth plot: using median across samples instead (for comparison)
% groupMedian=0;
% sampleMedian=1;
% filterFlag=[sampleMedian, groupMedian];
% binWidth=9;
% colorOrder=repmat([1,0,1],3,1); %Changing colors for plot
% 
% %Do the plot:
% adaptationData.plotAvgTimeCourse(adaptData,params,conds,binWidth,[],[],[],colorOrder,[],[],[],filterFlag,ph);

%% Save figure
saveFig(f,'./','plotParameterTimeCourse_wFilters2')
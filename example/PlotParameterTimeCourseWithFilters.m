%PLOTPARAMETERTIMECOURSEWITHFILTERS Example: parameter time courses with monotonic LS filter.
%
%   Demonstrates adaptationData.plotAvgTimeCourse with and without the
% monoLS filter to smooth parameter signals. Assumes an adaptationData
% object named 'adaptData' exists in the workspace.

%% Define parameters and conditions
% params = {'alphaSlow', 'alphaFast', 'singleStanceSpeedSlowAbs'};
params = {'spatialContributionP', 'stepTimeContributionP', ...
    'velocityContributionP', 'netContributionP'};
conds = {'TM base', 'Adap', 'Wash'};

%% First plot: no filter
binWidth = 1;
[f, ~, ~, ph] = adaptationData.plotAvgTimeCourse( ...
    adaptData, params, conds, binWidth);

%% Second plot: monotonic LS per condition
% Constrains derivatives up to 2nd order to have no sign changes;
% no regularization; fits one function per condition.
order            = 2;
reg              = 0;
medianAcrossSubj = 0;
trialBased       = 0;
filterFlag  = [medianAcrossSubj, order, reg, trialBased];
colorOrder  = repmat(0.6 * ones(1, 3), 3, 1);
adaptationData.plotAvgTimeCourse(adaptData, params, conds, binWidth, ...
    [], [], [], colorOrder, [], [], [], filterFlag, ph);

%% Third plot: monotonic LS per trial
% Same as the second plot but fits one function per trial.
trialBased = 1;
filterFlag = [medianAcrossSubj, order, reg, trialBased];
colorOrder = zeros(3, 3);
adaptationData.plotAvgTimeCourse(adaptData, params, conds, binWidth, ...
    [], [], [], colorOrder, [], [], [], filterFlag, ph);

%% Fourth plot: median across samples (for comparison)
% groupMedian  = 0;
% sampleMedian = 1;
% filterFlag   = [sampleMedian, groupMedian];
% binWidth     = 9;
% colorOrder   = repmat([1, 0, 1], 3, 1);
%
% adaptationData.plotAvgTimeCourse(adaptData, params, conds, binWidth, ...
%     [], [], [], colorOrder, [], [], [], filterFlag, ph);

%% Save figure
saveFig(f, './', 'plotParameterTimeCourse_wFilters2')

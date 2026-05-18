%PLOTINDIVIDUALSINGROUP Example: plot individual behavior within a group.
%
%   Demonstrates groupAdaptationData.plotIndividuals for comparing
% parameters across conditions, correlating with biographical data,
% and visualizing after-effects. Assumes 'gAdaptData' (and optionally
% 'gAdaptData2' for Example 4) exists in the workspace.

%% Set up figure and subplot axes
fh = figure;
for ii = 1:9
    ph(ii) = subplot(3, 3, ii);
end

%% Example 1: compare a single parameter across conditions
param      = {'netContributionNorm2'};
medianFlag = [];  % mean used by default
strideNo   = [20, -40];
conds      = {'Wash', 'Adap'};
exemptNo   = 5;
regFlag    = 1;
gAdaptData.plotIndividuals(param, conds, strideNo, exemptNo, ...
    medianFlag, ph(1), regFlag);

%% Example 2: compare two parameters in the same stride window
param      = {'netContributionNorm2', 'spatialContributionNorm2'};
medianFlag = [];  % mean used by default
strideNo   = 20;
conds      = {'Wash'};
exemptNo   = 5;
regFlag    = 1;
gAdaptData.plotIndividuals(param, conds, strideNo, exemptNo, ...
    medianFlag, ph(2), regFlag);

%% Example 3: compare parameter to biographical data
param      = {'netContributionNorm2', 'subage'};
medianFlag = [];  % mean used by default
strideNo   = 20;
conds      = {'Wash'};
exemptNo   = 5;
regFlag    = 1;
gAdaptData.plotIndividuals(param, conds, strideNo, exemptNo, ...
    medianFlag, ph(3), regFlag);

%% Example 4: overlay two groups
param      = {'netContributionNorm2', 'spatialContributionNorm2'};
medianFlag = [];  % mean used by default
strideNo   = 20;
conds      = {'Wash'};
exemptNo   = 5;
regFlag    = 1;
gAdaptData.plotIndividuals(param, conds, strideNo, exemptNo, ...
    medianFlag, ph(4), regFlag);
gAdaptData2.plotIndividuals(param, conds, strideNo, exemptNo, ...
    medianFlag, ph(4), regFlag);

%% Example 5: compare baseline to early post-adaptation
param      = {'netContributionNorm2'};
medianFlag = 1;
strideNo   = [-40, 20];
conds      = {'Base', 'Wash'};
exemptNo   = 5;
regFlag    = 1;
diffFlag   = 0;
gAdaptData.plotIndividuals(param, conds, strideNo, exemptNo, ...
    medianFlag, ph(5), regFlag, diffFlag);

%% Example 6: baseline vs. change in early post-adaptation
param      = {'netContributionNorm2'};
medianFlag = 1;
strideNo   = [-40, 20];
conds      = {'Base', 'Wash'};
exemptNo   = 5;
regFlag    = 1;
diffFlag   = 1;
gAdaptData.plotIndividuals(param, conds, strideNo, exemptNo, ...
    medianFlag, ph(6), regFlag, diffFlag);

%% Example 7: after-effects vs. bias (unbiased data)
% Same as Example 6 but bias has been removed first.
param      = {'netContributionNorm2', 'biasTMnetContributionNorm2'};
medianFlag = 1;
strideNo   = 20;
conds      = {'Wash'};
exemptNo   = 5;
regFlag    = 1;
diffFlag   = 0;
% gAdaptData = gAdaptData.removeBias();  % alternative approach
% removeAltBias is faster when only TM trials are needed; uses median
% of last 40 strides of TM base, exempting the very last 5.
gAdaptData = gAdaptData.removeAltBias({'TM base'}, -40, 5, 1, 0);
gAdaptData.plotIndividuals(param, conds, strideNo, exemptNo, ...
    medianFlag, ph(7), regFlag, diffFlag);

%% Example 8: after-effects vs. adaptation change (late minus early)
param      = {'netContributionNorm2', 'netContributionNorm2'};
medianFlag = 1;
strideNo   = [-40, -40, 20];
conds      = {'Base', 'Adap', 'Adap'};
exemptNo   = 5;
regFlag    = 1;
diffFlag   = 1;
gAdaptData.plotIndividuals(param, conds, strideNo, exemptNo, ...
    medianFlag, ph(8), regFlag, diffFlag);

%% Example 9: compare changes during adaptation across parameters
% removeAltBias can be called successively; the last call always
% takes effect (earlier calls are effectively overridden).
param      = {'netContributionNorm2', 'stepTimeContributionNorm2'};
medianFlag = 1;
strideNo   = [-40, -40];
conds      = {'Adap'};
exemptNo   = 5;
regFlag    = 1;
diffFlag   = 0;
% Uses median of first 20 strides of adaptation, exempting the first 5.
gAdaptData = gAdaptData.removeAltBias({'Adap'}, 20, 5, 1, diffFlag);
gAdaptData.plotIndividuals(param, conds, strideNo, exemptNo, ...
    medianFlag, ph(9), regFlag, diffFlag);

%% Save figure
saveFig(fh, './', 'plotIndividualsInGroup')

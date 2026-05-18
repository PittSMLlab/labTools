%EMGNORMALIZATION Example: normalize EMG parameters to baseline.
%
%   Demonstrates automated EMG normalization using
% adaptationData.normalizeToBaseline. Assumes an adaptationData object
% named 'adaptData' exists in the workspace with EMG parameter data.

%% Define muscle list
mList = {'TA', 'PER', 'MG', 'LG', 'SOL', 'BF', 'SEMT', 'SEMB', ...
    'VM', 'VL', 'RF', 'ADM', 'HIP', 'TFL', 'GLU'};

% Expand to both sides of body; 's' suffix selects the 12-phase EMG
% amplitude parameters (see computeEMGparameters for parameter names).
expandedMList = [strcat('f', strcat(mList, 's')) ...
    strcat('s', strcat(mList, 's'))];

%% Normalize to baseline
test = adaptData.normalizeToBaseline(expandedMList);

%% Plot normalized data
aa  = test.data.getDataAsVector( ...
    test.data.getLabelsThatMatch('^Norm'));
idx = test.getIndsInCondition('TM base');

nPhases = 12;  % 12-phase EMG amplitude (see computeEMGparameters)
figure;
surf(reshape(mean(aa(idx{1}, :), 'omitnan'), ...
    [nPhases, numel(expandedMList)]), 'EdgeColor', 'None');
clim([-1 1]);

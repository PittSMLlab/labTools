function newData = removeOGbias(adaptData, OGtrials, OGbaseTrials)
%REMOVEOGBIAS Remove spatial bias from overground gait data.
%
%   Orders overground baseline data by spatial position in the lab,
% computes a running-average fit to characterize the position-dependent
% bias, then subtracts that bias from all overground trial data.
%
% Inputs:
%   adaptData    - adaptationData object containing the trial data
%   OGtrials     - indices of all overground trials to debias
%   OGbaseTrials - indices of overground baseline trials used to
%                  fit the spatial bias model
%
% Outputs:
%   newData - debiased parameter data matrix (same size as
%             adaptData.data.Data)
%
% Toolbox Dependencies: None
%
% See also ADAPTATIONDATA, BIN_DATAV1.

%% Separate baseline strides by walking direction
labels  = adaptData.data.labels;
newData = nan(size(adaptData.data.Data));

baseOG1 = [];
baseOG2 = [];
baseData    = adaptData.getParamInTrial(labels, OGbaseTrials);
baseHipVel  = adaptData.getParamInTrial('direction', OGbaseTrials);
baseHipPos  = adaptData.getParamInTrial('hipPos', OGbaseTrials);

for ii = 1:size(baseData, 1)
    if baseHipVel(ii) < 0
        baseOG1 = [baseOG1; ii baseHipPos(ii) baseData(ii,:)]; %#ok<AGROW>
    else
        baseOG2 = [baseOG2; ii baseHipPos(ii) baseData(ii,:)]; %#ok<AGROW>
    end
end

%% Separate all OG strides by walking direction
allOG1 = [];
allOG2 = [];
[allData, inds] = adaptData.getParamInTrial(labels, OGtrials);
allHipVel       = adaptData.getParamInTrial('direction', OGtrials);
allHipPos       = adaptData.getParamInTrial('hipPos', OGtrials);

for ii = 1:size(allData, 1)
    if allHipVel(ii) < 0
        allOG1 = [allOG1; ii allHipPos(ii) allData(ii,:)]; %#ok<AGROW>
    else
        allOG2 = [allOG2; ii allHipPos(ii) allData(ii,:)]; %#ok<AGROW>
    end
end

%% Fit baseline spatial trend and subtract from data
baseOG1     = sortrows(baseOG1, 2);         % sort by hip position
baseOG1Fit  = bin_dataV1(baseOG1, 5);       % 5-point running average
baseOG2     = sortrows(baseOG2, 2);
baseOG2Fit  = bin_dataV1(baseOG2, 5);

for ii = 1:size(allOG1, 1)
    % find fit point closest to data point spatially
    [~, ind] = min(abs(baseOG1Fit(:,2) - allOG1(ii,2)));
    bias = baseOG1Fit(ind, :);
    allOG1(ii, 3:end) = allOG1(ii, 3:end) - bias(3:end);
end
for ii = 1:size(allOG2, 1)
    [~, ind] = min(abs(baseOG2Fit(:,2) - allOG2(ii,2)));
    bias = baseOG2Fit(ind, :);
    allOG2(ii, 3:end) = allOG2(ii, 3:end) - bias(3:end);
end

% re-order by time, then store (skip index and position columns)
newOG = sortrows([allOG1; allOG2], 1);
newData(inds, :) = newOG(:, 3:end);
end

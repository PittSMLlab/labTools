function [allTrialModels, modelScore, badFlag] = ...
    extractMarkerModels(this)
%extractMarkerModels  Builds marker position models from data
%
%   [allTrialModels, modelScore, badFlag] = extractMarkerModels(this)
%   creates statistical models of marker positions for each trial to
%   enable outlier detection
%
%   Inputs:
%       this - experimentData object
%
%   Outputs:
%       allTrialModels - cell array of marker models, one per trial
%       modelScore - vector of model quality scores
%       badFlag - logical vector indicating trials with poor models
%
%   See also: checkMarkerHealth, orientedLabTimeSeries/fixBadLabels

% This flag will prevent trying to find permutations to fix data,
% which can be slow.
noFixFlag = false;
% First: build models
m = cell(length(this.data), 1);
badFlag = false(size(m));
modelScore = nan(size(m));
modelScore2 = nan(size(m));
permuteList = [];
for trial = 1:length(this.data)
    if ~isempty(this.data{trial})
        aux = this.data{trial}.markerData;
        [aux, m{trial}, permuteList, modelScore(trial), ...
            badFlag(trial), modelScore2(trial)] = ...
            aux.fixBadLabels(permuteList);
    end
end
allTrialModels = m;
end


%TESTMARKERHEALTHCHECK Example: validate marker data integrity.
%
%   Demonstrates marker model training, outlier detection, label-switch
% correction, and gap filling. Assumes 'rawExpData' exists in the
% workspace as an experimentData object loaded from a *RAW.mat file.
%
%   NOTE: Most functionality here is also wrapped in
% experimentData.checkMarkerHealth.
%
% See also EXTRACTMARKERMODELS, BUILDNAIVEDISTANCESMODEL,
%   VALIDATEMARKERMODEL.

%% Train marker models across all trials
% load('./data/LI16_Trial9_expData.mat')
% load('/datadump/rawData/Exp0001/matData/raw/C0001RAW.mat')
[allTrialModels, modelScore, badFlag] = extractMarkerModels(rawExpData);
[~, refTrial] = min(modelScore, [], 'omitnan');  % best-scoring trial
referenceModel = allTrialModels{refTrial};

%% Inspect one trial
trial      = 7;
markerData = rawExpData.data{trial}.markerData;

%% Assess missing data
% A: check missing data and fill gaps
[~, ~, markerData] = markerData.assessMissing([], -1);

%% Validate trial model
allTrialModels{trial} = buildNaiveDistancesModel(markerData);
% B: analyze fitted model
[badFlag, mirrorOutliers, outOfBoundsOutlier] = ...
    validateMarkerModel(allTrialModels{trial}, true);

%% Find outliers using reference model
% C: find outliers
markerData = markerData.findOutliers(referenceModel, true);
disp('Outlier data added in Quality field');

%% Fix label switching and remove outliers
markerData = markerData.fixBadLabels();
markerData.Quality = [];
markerData = markerData.removeOutliers(referenceModel);
[~, ~, markerData] = markerData.assessMissing([], -1);

%% Remove outliers (mark as missing)
[~, ~, missing] = markerData.assessMissing([], -1);
markerData.findOutliers(referenceModel, true);

%% Fill missing and bad data
newThis = markerData.fillGaps(referenceModel);  % TODO: not fully implemented

%% Assess reconstruction quality
[~, ~, missing] = newThis.assessMissing([], -1);
newThis.findOutliers(referenceModel, true);

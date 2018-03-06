%% Load some experiment data 
%load ./data/LI16_Trial9_expData.mat
%MOST/ALL of the functionality shown here is part of experimentData.checkMarkerHealth(this,refTrial);
%load /datadump/rawData/Exp0001/matData/raw/C0001RAW.mat

%% For the whole experiment, we can train models and select the best:
[allTrialModels,modelScore,badFlag]=extractMarkerModels(rawExpData);
[~,refTrial]=nanmin(modelScore); %This works if at least one model is good
referenceModel=allTrialModels{refTrial};
%% For any one trial's markerData, we can:
trial=7;
aux=rawExpData.data{trial}.markerData;
%% Assess missing data:
%A: check missing data & fill gaps
[~,~,aux]=aux.assessMissing([],-1);

%% Check if a model trained on it is good:
allTrialModels{trial} = buildNaiveDistancesModel(aux);
%B: analyze fitted models.
[badFlag,mirrorOutliers,outOfBoundsOutlier]=validateMarkerModel(allTrialModels{trial},true);

%% Find outliers, given a reference model:
%C: find outliers
aux=aux.findOutliers(referenceModel,true);
disp(['Outlier data added in Quality field']);

%% Find potential label switching and fix:
aux=aux.fixBadLabels;
aux.Quality=[];
aux=aux.removeOutliers(referenceModel);
[~,~,aux]=aux.assessMissing([],-1);
%% Remove outliers: (make them missing)
[~,~,missing]=aux.assessMissing([],-1); %Missing
aux.findOutliers(referenceModel,true); %Outliers
%% Fix missing/bad data:!
[newThis]=aux.fillGaps(referenceModel); %This doesnt work yet
%% Assess reconstruction:
[~,~,missing]=newThis.assessMissing([],-1); %Missing
newThis.findOutliers(referenceModel,true); %Outliers
function this = checkMarkerHealth(this, refTrial)
%checkMarkerHealth  Validates marker data quality
%
%   this = checkMarkerHealth(this) analyzes marker data across all trials
%   for missing data, label errors, and outliers
%
%   this = checkMarkerHealth(this, refTrial) optionally specifies which
%   trial to use for model training
%
%   Inputs:
%       this - experimentData object
%       refTrial - trial number to use for reference model (optional,
%                  automatically selected if not provided)
%
%   Outputs:
%       this - experimentData object with quality flags added to marker
%              data
%
%   See also: extractMarkerModels, orientedLabTimeSeries/findOutliers

disp('Checking marker health...');

% First: build models
[allTrialModels, modelScore, badFlag] = extractMarkerModels(this);

% Second: select best model
% TODO: move this chunk to its own function?
noOutlierTest = false;
if (nargin < 2 || isempty(refTrial)) && ~all(badFlag)
    modelScore(badFlag) = Inf;
    [~, refTrial] = nanmin(modelScore);
elseif all(badFlag) % Undefined refTrial but all trials are bad
    warning(['Could not find suitable data for model training. ' ...
        'Not testing for outliers.']);
    % This flag prevents the testing for outliers later on.
    noOutlierTest = true;
end
try % If there is a model
    mm = allTrialModels{refTrial};
    fprintf(['Using trial ' num2str(refTrial) ' to train outlier ' ...
        'detection model...\n']);
    mm.seeModel;
catch
    % nop
end

% Third: for each trial, get missing markers, analyze fitted model
% and find outliers through best model
for trial = 1:length(this.data)
    disp(['Checking trial ' num2str(trial) '...']);
    if ~isempty(this.data{trial})
        aux = this.data{trial}.markerData;

        % A: check missing data & fill gaps
        [~, ~, missing] = aux.assessMissing([], -1);

        % B: analyze fitted models
        validateMarkerModel(allTrialModels{trial}, true);

        % C: find outliers
        if ~noOutlierTest
            aux = aux.findOutliers(mm, true);
            this.data{trial}.markerData = aux;
        end
    end
end
disp('Outlier data added in Quality field');
end


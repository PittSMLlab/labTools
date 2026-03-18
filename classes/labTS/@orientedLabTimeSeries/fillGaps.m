function newThis = fillGaps(this, model)
%fillGaps  Fills missing marker data
%
%   newThis = fillGaps(this) fills gaps using self-learned model
%
%   newThis = fillGaps(this, model) uses specified model
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       model - naiveDistances model (optional, learned from data)
%
%   Outputs:
%       newThis - orientedLabTimeSeries with filled gaps
%
%   Note: Meant to be used with markerData only. Uses Bayesian
%         reconstruction.
%
%   See also: buildNaiveDistancesModel, getVirtualOTS

if nargin < 2 || isempty(model)
    % Try to learn from the data itself!
    model = this.buildNaiveDistancesModel;
end
% Meant to be used with markerData only
% PART 1: model free check
% Use kalman filter to estimate likely position of missing markers

% PART 2: model dependent
% Use prior knowledge in a Bayesian setting to fill gaps

% bad = (this.Quality(:, 1:3:end) ~= 0); % Working around anything
% where Quality ~= 0

data = this.getOrientedData(model.markerLabels);
bad = isnan(data(:, :));
data = permute(data, [2, 3, 1]);
idx = any(bad, 2);
idx = find(idx, 50, 'last'); % Fixing 50 frames only
data = data(:, :, idx); % Data to be fixed
D = reshape(nanmedian(this.Data, 1), size(data, 1), size(data, 2));
posSTD = 1.3 * ones(size(data, 1), size(data, 3)); % For good measurements
bad2 = bad(idx, 1:3:end);
data(isnan(data)) = 0; % NaNs need to be removed
posSTD(bad2') = 1e3; % For bad ones
mleData = model.reconstruct(data, posSTD);

% PART 3: merge the two estimations through mle or something

% Put the data back:
newThis = this;
mleData = permute(mleData, [3, 2, 1]);
[~, sortedIdx] = this.isaLabelPrefix(model.markerLabels);
mleData(:, :, sortedIdx) = mleData;
newThis.Data(idx, :) = mleData(:, :);
end


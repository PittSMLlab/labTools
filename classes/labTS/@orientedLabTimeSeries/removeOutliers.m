function newThis = removeOutliers(this, model)
%removeOutliers  Removes outlier data points
%
%   newThis = removeOutliers(this, model) detects and removes outliers
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       model - naiveDistances model for detection
%
%   Outputs:
%       newThis - orientedLabTimeSeries with outliers set to NaN
%
%   See also: findOutliers

% Detect:
newThis = this.findOutliers(model);
% Remove:
bad = (newThis.Quality == 1);
newThis.Data(bad) = NaN;
end


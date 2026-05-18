%LABTSMANIPULATION Example: labTimeSeries operations.
%
%   Demonstrates derivative, integration, and label-based data access
% for labTimeSeries objects. Assumes a labTimeSeries variable is
% available in the workspace — replace 'allMarkers' with your own.

%% Load labTimeSeries object
% NOTE: Replace allMarkers with your own labTimeSeries variable.
lTS = allMarkers;

%% Inspect properties
lTS.sampPeriod   % sampling period
lTS.Time(1)      % initial sample time
lTS.timeRange    % interval of time contained in the series
size(lTS.Data)
size(lTS.labels)

%% Get data by label pattern
% getLabelsThatMatch returns all labels containing the search string.
lTS.getLabelsThatMatch('ANK')                           % ankle labels
lTS.getDataAsVector(lTS.getLabelsThatMatch('ANK'))      % numeric matrix
lTS.getDataAsTS(lTS.getLabelsThatMatch('ANK'))          % labTimeSeries

%% Compute derivative
% 2nd-order differentials (diffOrder = []) lose one sample from each
% end, so dTS.Data is 2 rows shorter than lTS.Data.
diffOrder = [];
dTS = lTS.derivative(diffOrder);
size(dTS.Data)
size(lTS.Data)
dTS.Time(1)  % one full sample later than lTS.Time(1)
lTS.Time(1)

%% Integrate labTimeSeries
% Centered trapezoid rule: initial time of iTS is half a sample before
% lTS.Time(1), but sampling periods are equal.
initialConditions = [];  % default: 0 initial condition for all columns
iTS = lTS.integrate(initialConditions);
iTS.Time(1)
lTS.Time(1)
iTS.sampPeriod
lTS.sampPeriod

%% Derivative and integration as inverse operations
% Derivative and integration are theoretically inverse operations.
% With approximations, exact inversion requires matching orders:
% 1st-order derivative + trapezoid integration with the true initial
% condition exactly recovers the original series.
dTS  = lTS.derivative(1);
lTS2 = dTS.integrate(lTS.Data(1, :));

norm(lTS.Data - lTS2.Data)  % should be 0

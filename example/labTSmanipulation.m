%% Load a labTS object
lTS=allMarkers; %Change this line to something that works for you! lTS needs to be a labTimeSeries object

%% See some properties
lTS.sampPeriod %Sampling period
lTS.Time(1) %Initial sample time
lTS.timeRange %Interval of time contained in timeseries
size(lTS.Data)
size(lTS.labels)

%% GEt data from labTS whose labels match some string
lTS.getLabelsThatMatch('ANK') %For marker data, this will return all labels that contain the string 'ANK': ankle markers!
lTS.getDataAsVector(lTS.getLabelsThatMatch('ANK')) %Get just ankle data: this returns a matrix
lTS.getDataAsTS(lTS.getLabelsThatMatch('ANK')) %Get just ankle data, but preserve it within a labTimeSeries for further manipulation

%% Find the derivative:
diffOrder=[];
dTS=lTS.derivative(diffOrder);  %This computes a numerical approximation of the derivative, using 2nd order differentials by default.
%Because the derivative computation requires using multiple samples, the
%size of the computed data is SMALLER than the original lTS size. Using 2nd
%order differentials we lose two samples: the very first and the very last
%one. Check with:
size(dTS.Data)
size(lTS.Data)
dTS.Time(1) %First sample of dTS: notice this is one full sample later than the first sample of lTS
lTS.Time(1) %First sample of lTS

%% Integrate labTS:
initialConditions=[]; %By default the integration uses 0 as initial condition for all columns in the data
iTS=lTS.integrate(initialConditions); %This implements a simple trapezoid rule to estimate the integral of the TS. It uses a centered trapezoid.
%Notice that because of the centered trapezoid, the initial time of iTS is
%HALF A SAMPLE before of the initial time of lTS, but the sampling periods
%are the same
iTS.Time(1)
lTS.Time(1)
iTS.sampPeriod
lTS.sampPeriod
%% Derivative & integration
%These two functions are, in theory, the inverse of one another. Because
%both use approximations, and because derivation implies a lost of
%information [one sample is lost for 1st order approx, two for 2nd, ...]
%the true inverse is only realized with the proper use of parameters:
dTS=lTS.derivative(1); %This computes a 1st order approx of derivative
lTS2=dTS.integrate(lTS.Data(1,:)); %This computes a trapezoid approximation of the integral, using the original data's (true) initial condition as the initial condition.

%Check that lTS and lTS2 are exactly the same:
norm(lTS.Data-lTS2.Data) %This should be 0


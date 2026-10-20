function newThis = resample(this, newTs, newT0, hiddenFlag)
%RESAMPLE Resamples (override).
%
%   newThis = resample(this, newTs, newT0, hiddenFlag) resamples and
% preserves orientedLabTimeSeries type
%
% Inputs:
%   this       - orientedLabTimeSeries object
%   newTs      - new sampling period
%   newT0      - new initial time
%   hiddenFlag - flag for non-uniform resampling (optional)
%
% Outputs:
%   newThis - resampled orientedLabTimeSeries
%
% Toolbox Dependencies: None
%
% See also LABTIMESERIES/RESAMPLE, RESAMPLEN.

% Resample to a new sampling period
if nargin < 4
    hiddenFlag = [];
end
auxThis = this.resample@labTimeSeries(newTs, newT0, hiddenFlag);
newThis = orientedLabTimeSeries(auxThis.Data, auxThis.Time(1), ...
    auxThis.sampPeriod, auxThis.labels, this.orientation);
end


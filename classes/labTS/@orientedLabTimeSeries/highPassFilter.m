function newThis = highPassFilter(this, fcut)
%HIGHPASSFILTER Applies high-pass filter (override).
%
%   newThis = highPassFilter(this, fcut) filters and preserves
% orientedLabTimeSeries type
%
% Inputs:
%   this - orientedLabTimeSeries object
%   fcut - cutoff frequency in Hz
%
% Outputs:
%   newThis - filtered orientedLabTimeSeries
%
% Toolbox Dependencies: Signal Processing Toolbox (via labTimeSeries)
%
% See also LABTIMESERIES/HIGHPASSFILTER, LOWPASSFILTER.

newThis = highPassFilter@labTimeSeries(this, fcut);
newThis = orientedLabTimeSeries(newThis.Data, newThis.Time(1), ...
    newThis.sampPeriod, newThis.labels, this.orientation);
end


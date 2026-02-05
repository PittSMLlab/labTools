function newTS = synchTo(this, otherTS)
%synchTo  Resamples to match another timeseries
%
%   newTS = synchTo(this, otherTS) resamples the timeseries ensuring
%   that the new time vector coincides with that of otherTS. Pads with
%   NaN if necessary.
%
%   Inputs:
%       this - labTimeSeries object
%       otherTS - labTimeSeries to synchronize to
%
%   Outputs:
%       newTS - resampled labTimeSeries with same time vector as otherTS
%
%   See also: resample, getSample

if ~islogical(this.Data)
    method = [];
else
    method = 'closest';
end
data = squeeze(this.getSample(otherTS.Time, method));
newTS = ...
    labTimeSeries(data, otherTS.Time(1), otherTS.sampPeriod, this.labels);
end


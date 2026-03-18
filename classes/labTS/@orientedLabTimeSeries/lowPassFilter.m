function newThis = lowPassFilter(this, fcut)
%lowPassFilter  Applies low-pass filter (override)
%
%   newThis = lowPassFilter(this, fcut) filters and preserves
%   orientedLabTimeSeries type
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       fcut - cutoff frequency in Hz
%
%   Outputs:
%       newThis - filtered orientedLabTimeSeries
%
%   See also: labTimeSeries/lowPassFilter, highPassFilter

newThis = lowPassFilter@labTimeSeries(this, fcut);
newThis = orientedLabTimeSeries(newThis.Data, newThis.Time(1), ...
    newThis.sampPeriod, newThis.labels, this.orientation);
end


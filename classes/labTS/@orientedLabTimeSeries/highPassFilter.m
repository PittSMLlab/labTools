function newThis = highPassFilter(this, fcut)
%highPassFilter  Applies high-pass filter (override)
%
%   newThis = highPassFilter(this, fcut) filters and preserves
%   orientedLabTimeSeries type
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       fcut - cutoff frequency in Hz
%
%   Outputs:
%       newThis - filtered orientedLabTimeSeries
%
%   See also: labTimeSeries/highPassFilter, lowPassFilter

newThis = highPassFilter@labTimeSeries(this, fcut);
newThis = orientedLabTimeSeries(newThis.Data, newThis.Time(1), ...
    newThis.sampPeriod, newThis.labels, this.orientation);
end


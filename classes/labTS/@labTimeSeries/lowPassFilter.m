function newThis = lowPassFilter(this, fcut)
%lowPassFilter  Applies low-pass filter
%
%   newThis = lowPassFilter(this, fcut) applies Butterworth low-pass
%   filter with specified cutoff frequency
%
%   Inputs:
%       this - labTimeSeries object
%       fcut - cutoff frequency in Hz
%
%   Outputs:
%       newThis - filtered labTimeSeries
%
%   See also: highPassFilter, medianFilter, filtfilthd_short

Wn = fcut * 2 / this.sampFreq;
Wst = min([2 * Wn, Wn + 0.2 * (1 - Wn)]);
filterList{1} = fdesign.lowpass('Fp,Fst,Ap,Ast', Wn, Wst, 3, 10);
lowPassFilter = design(filterList{1}, 'butter');
newData = ...
    filtfilthd_short(lowPassFilter, this.Data, 'reflect', this.sampFreq);
newThis = ...
    labTimeSeries(newData, this.Time(1), this.sampPeriod, this.labels);
if ~isfield(this.UserData, 'processingInfo')
    this.UserData.processingInfo = {};
end
newThis.UserData = this.UserData;
newThis.UserData.processingInfo{end + 1} = filterList{1};
end


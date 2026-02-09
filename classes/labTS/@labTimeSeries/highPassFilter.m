function newThis = highPassFilter(this, fcut)
%highPassFilter  Applies high-pass filter
%
%   newThis = highPassFilter(this, fcut) applies Butterworth high-pass
%   filter with specified cutoff frequency
%
%   Inputs:
%       this - labTimeSeries object
%       fcut - cutoff frequency in Hz
%
%   Outputs:
%       newThis - filtered labTimeSeries
%
%   See also: lowPassFilter, medianFilter, filtfilthd_short

Wn = fcut * 2 / this.sampFreq;
filterList{1} = fdesign.highpass('Fst,Fp,Ast,Ap', Wn / 2, Wn, 10, 3);
highPassFilter = design(filterList{1}, 'butter');
newData = ...
    filtfilthd_short(highPassFilter, this.Data, 'reflect', this.sampFreq);
newThis = ...
    labTimeSeries(newData, this.Time(1), this.sampPeriod, this.labels);
if ~isfield(this.UserData, 'processingInfo')
    this.UserData.processingInfo = {};
end
newThis.UserData = this.UserData;
newThis.UserData.processingInfo{end + 1} = filterList{1};
end


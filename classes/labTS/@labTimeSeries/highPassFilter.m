function newThis = highPassFilter(this, fcut)
%HIGHPASSFILTER Applies high-pass filter.
%
%   newThis = highPassFilter(this, fcut) applies Butterworth high-pass
% filter with specified cutoff frequency
%
% Inputs:
%   this - labTimeSeries object
%   fcut - cutoff frequency in Hz
%
% Outputs:
%   newThis - filtered labTimeSeries
%
% Toolbox Dependencies: Signal Processing Toolbox
%
% See also LOWPASSFILTER, MEDIANFILTER, FILTFILTHD_SHORT.

passAttenDb  = 3;  % dB, Ap in the fdesign spec
stopAttenDb  = 10; % dB, Ast in the fdesign spec
stopFreqDiv  = 2;  % TODO: source? (stopband edge = cutoff / 2)

Wn = fcut * 2 / this.sampFreq;
filterList{1} = fdesign.highpass('Fst,Fp,Ast,Ap', Wn / stopFreqDiv, ...
    Wn, stopAttenDb, passAttenDb);
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


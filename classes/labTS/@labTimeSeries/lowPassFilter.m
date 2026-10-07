function newThis = lowPassFilter(this, fcut)
%LOWPASSFILTER Applies low-pass filter.
%
%   newThis = lowPassFilter(this, fcut) applies Butterworth low-pass filter
% with specified cutoff frequency
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
% See also HIGHPASSFILTER, MEDIANFILTER, FILTFILTHD_SHORT.

passAttenDb  = 3;   % dB, Ap in the fdesign spec
stopAttenDb  = 10;  % dB, Ast in the fdesign spec
stopFreqMult = 2;   % TODO: source? (stopband edge = 2 * cutoff, capped)
stopBandFrac = 0.2; % TODO: source? (cap: 20% of the band above cutoff)

Wn  = fcut * 2 / this.sampFreq;
Wst = min([stopFreqMult * Wn, Wn + stopBandFrac * (1 - Wn)]);
filterList{1} = fdesign.lowpass('Fp,Fst,Ap,Ast', Wn, Wst, ...
    passAttenDb, stopAttenDb);
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


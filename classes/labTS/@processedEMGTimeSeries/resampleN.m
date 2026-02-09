function newThis = resampleN(this, newN)
%resampleN  Resamples to N samples, preserving processing info
%
%   newThis = resampleN(this, newN) resamples the timeseries to newN
%   samples while preserving processing information
%
%   Inputs:
%       this - processedEMGTimeSeries object
%       newN - target number of samples
%
%   Outputs:
%       newThis - resampled processedEMGTimeSeries
%
%   See also: labTimeSeries/resampleN, split

auxThis = this.resampleN@labTimeSeries(newN);
newThis = processedEMGTimeSeries(auxThis.Data, auxThis.Time(1), ...
    auxThis.sampPeriod, auxThis.labels, this.processingInfo);
end


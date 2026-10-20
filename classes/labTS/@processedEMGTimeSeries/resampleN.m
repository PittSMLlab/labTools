function newThis = resampleN(this, newN)
%RESAMPLEN Resamples to N samples, preserving processing info.
%
%   newThis = resampleN(this, newN) resamples the timeseries to newN samples
% while preserving processing information
%
% Inputs:
%   this - processedEMGTimeSeries object
%   newN - target number of samples
%
% Outputs:
%   newThis - resampled processedEMGTimeSeries
%
% Toolbox Dependencies: None
%
% See also LABTIMESERIES/RESAMPLEN, SPLIT.

auxThis = this.resampleN@labTimeSeries(newN);
newThis = processedEMGTimeSeries(auxThis.Data, auxThis.Time(1), ...
    auxThis.sampPeriod, auxThis.labels, this.processingInfo);
end


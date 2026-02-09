function newThis = split(this, t0, t1)
%split  Splits timeseries, preserving processing info
%
%   newThis = split(this, t0, t1) returns a processedEMGTimeSeries
%   containing data in interval [t0, t1) while preserving processing
%   information and quality flags
%
%   Inputs:
%       this - processedEMGTimeSeries object
%       t0 - start time (inclusive)
%       t1 - end time (exclusive)
%
%   Outputs:
%       newThis - split processedEMGTimeSeries
%
%   See also: labTimeSeries/split, resampleN

auxThis = this.split@labTimeSeries(t0, t1);
if auxThis.Nsamples > 0 % Empty series was returned
    newThis = processedEMGTimeSeries(auxThis.Data, auxThis.Time(1), ...
        auxThis.sampPeriod, auxThis.labels, this.processingInfo, ...
        auxThis.Quality, auxThis.QualityInfo);
else
    newThis = processedEMGTimeSeries(auxThis.Data, 0, ...
        auxThis.sampPeriod, auxThis.labels, this.processingInfo, ...
        auxThis.Quality, auxThis.QualityInfo);
end
end


function newThis = split(this, t0, t1)
%split  Splits timeseries (override)
%
%   newThis = split(this, t0, t1) splits and preserves
%   orientedLabTimeSeries type
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       t0 - start time
%       t1 - end time
%
%   Outputs:
%       newThis - split orientedLabTimeSeries
%
%   See also: labTimeSeries/split

auxThis = this.split@labTimeSeries(t0, t1);
newThis = orientedLabTimeSeries(auxThis.Data, t0, auxThis.sampPeriod, ...
    auxThis.labels, this.orientation);
end


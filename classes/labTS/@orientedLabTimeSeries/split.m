function newThis = split(this, t0, t1)
%SPLIT Splits timeseries (override).
%
%   newThis = split(this, t0, t1) splits and preserves orientedLabTimeSeries
% type
%
% Inputs:
%   this - orientedLabTimeSeries object
%   t0   - start time
%   t1   - end time
%
% Outputs:
%   newThis - split orientedLabTimeSeries
%
% Toolbox Dependencies: None
%
% See also LABTIMESERIES/SPLIT.

auxThis = this.split@labTimeSeries(t0, t1);
newThis = orientedLabTimeSeries(auxThis.Data, t0, auxThis.sampPeriod, ...
    auxThis.labels, this.orientation);
end


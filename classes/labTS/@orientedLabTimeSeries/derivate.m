function newThis = derivate(this)
%derivate  Differentiates (override)
%
%   newThis = derivate(this) takes derivative and preserves
%   orientedLabTimeSeries type
%
%   Inputs:
%       this - orientedLabTimeSeries object
%
%   Outputs:
%       newThis - differentiated orientedLabTimeSeries
%
%   See also: labTimeSeries/derivate, derivative

auxThis = this.derivate@labTimeSeries;
newThis = orientedLabTimeSeries(auxThis.Data, auxThis.Time(1), ...
    auxThis.sampPeriod, auxThis.labels, this.orientation);
end


function newThis = derivate(this)
%DERIVATE Differentiates (override).
%
%   newThis = derivate(this) takes derivative and preserves
% orientedLabTimeSeries type
%
% Inputs:
%   this - orientedLabTimeSeries object
%
% Outputs:
%   newThis - differentiated orientedLabTimeSeries
%
% Toolbox Dependencies: None
%
% See also LABTIMESERIES/DERIVATE, DERIVATIVE.

auxThis = this.derivate@labTimeSeries;
newThis = orientedLabTimeSeries(auxThis.Data, auxThis.Time(1), ...
    auxThis.sampPeriod, auxThis.labels, this.orientation);
end


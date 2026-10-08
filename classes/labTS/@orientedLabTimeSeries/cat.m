function newThis = cat(this, other)
%CAT Concatenates (override).
%
%   newThis = cat(this, other) concatenates and preserves
% orientedLabTimeSeries type
%
% Inputs:
%   this  - orientedLabTimeSeries object
%   other - orientedLabTimeSeries to concatenate
%
% Outputs:
%   newThis - concatenated orientedLabTimeSeries
%
% Toolbox Dependencies: None
%
% See also LABTIMESERIES/CAT.

newThis = cat@labTimeSeries(this, other);
newThis = orientedLabTimeSeries(newThis.Data, this.Time(1), ...
    this.sampPeriod, newThis.labels, this.orientation);
end


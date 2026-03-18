function newThis = cat(this, other)
%cat  Concatenates (override)
%
%   newThis = cat(this, other) concatenates and preserves
%   orientedLabTimeSeries type
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       other - orientedLabTimeSeries to concatenate
%
%   Outputs:
%       newThis - concatenated orientedLabTimeSeries
%
%   See also: labTimeSeries/cat

newThis = cat@labTimeSeries(this, other);
newThis = orientedLabTimeSeries(newThis.Data, this.Time(1), ...
    this.sampPeriod, newThis.labels, this.orientation);
end


function newThis = plus(this, other)
%plus  Adds two OTS (override)
%
%   newThis = plus(this, other) adds and preserves orientedLabTimeSeries
%   type with updated labels
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       other - orientedLabTimeSeries to add
%
%   Outputs:
%       newThis - sum as orientedLabTimeSeries
%
%   See also: labTimeSeries/plus, minus, times

newThis = plus@labTimeSeries(this, other);
tL = this.getLabelPrefix;
oL = other.getLabelPrefix;
newLabelPrefixes = cell(size(tL));
for i = 1:length(newLabelPrefixes)
    newLabelPrefixes{i} = ['(' tL{i} ' + ' oL{i} ')'];
end
newLabels = orientedLabTimeSeries.addLabelSuffix(newLabelPrefixes);
newThis = orientedLabTimeSeries(newThis.Data, newThis.Time(1), ...
    newThis.sampPeriod, newLabels, this.orientation);
end


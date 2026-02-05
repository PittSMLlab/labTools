function newThis = castAsOTS(this, orientation)
%castAsOTS  Converts to orientedLabTimeSeries
%
%   newThis = castAsOTS(this) converts to orientedLabTimeSeries with
%   default orientation
%
%   newThis = castAsOTS(this, orientation) uses specified orientation
%
%   Inputs:
%       this - labTimeSeries object
%       orientation - orientationInfo object (optional)
%
%   Outputs:
%       newThis - orientedLabTimeSeries object
%
%   See also: orientedLabTimeSeries, castAsSTS

if nargin < 2 || isempty(orientation)
    orientation = orientationInfo;
end
newThis = orientedLabTimeSeries( ...
    this.Data, this.Time(1), this.sampPeriod, this.labels, orientation);
end


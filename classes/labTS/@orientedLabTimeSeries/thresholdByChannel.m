function newThis = thresholdByChannel(this, th, label, moreThanFlag)
%thresholdByChannel  Thresholds by channel (override)
%
%   newThis = thresholdByChannel(this, th, label, moreThanFlag)
%   thresholds and preserves orientedLabTimeSeries type
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       th - threshold value
%       label - label to use for thresholding
%       moreThanFlag - if 1, zeros when greater than threshold
%                      (optional)
%
%   Outputs:
%       newThis - thresholded orientedLabTimeSeries
%
%   See also: labTimeSeries/thresholdByChannel, threshold

if nargin < 4 || isempty(moreThanFlag)
    moreThanFlag = [];
end
newThis = thresholdByChannel@labTimeSeries(this, th, label, moreThanFlag);
newThis = orientedLabTimeSeries(newThis.Data, this.Time(1), ...
    this.sampPeriod, this.labels, this.orientation);
end


function newThis = threshold(this, th)
%threshold  Thresholds by vector magnitude
%
%   newThis = threshold(this, th) zeros samples where vector magnitude
%   is below threshold
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       th - magnitude threshold value
%
%   Outputs:
%       newThis - thresholded orientedLabTimeSeries
%
%   See also: thresholdByChannel

newThis = this;
newThis.Data(sqrt(sum(newThis.Data.^2)) < th, :) = 0;
end


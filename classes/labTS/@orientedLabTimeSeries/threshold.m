function newThis = threshold(this, th)
%THRESHOLD Thresholds by vector magnitude.
%
%   newThis = threshold(this, th) zeros samples where vector magnitude is
% below threshold
%
% Inputs:
%   this - orientedLabTimeSeries object
%   th   - magnitude threshold value
%
% Outputs:
%   newThis - thresholded orientedLabTimeSeries
%
% Toolbox Dependencies: None
%
% See also THRESHOLDBYCHANNEL.

newThis = this;
newThis.Data(sqrt(sum(newThis.Data.^2)) < th, :) = 0;
end


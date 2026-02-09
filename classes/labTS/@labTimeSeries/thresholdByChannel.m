function newThis = thresholdByChannel(this, th, label, moreThanFlag)
%thresholdByChannel  Zeros data based on threshold
%
%   newThis = thresholdByChannel(this, th, label) zeros all samples
%   where specified label is less than threshold
%
%   newThis = thresholdByChannel(this, th, label, moreThanFlag) zeros
%   where label is greater than threshold if moreThanFlag = 1
%
%   Inputs:
%       this - labTimeSeries object
%       th - threshold value
%       label - label to use for thresholding
%       moreThanFlag - if 1, zeros when greater than threshold
%                      (optional, default: 0)
%
%   Outputs:
%       newThis - thresholded labTimeSeries
%
%   See also: substituteNaNs

newThis = this;
if nargin < 4 || isempty(moreThanFlag) || moreThanFlag == 0
    newThis.Data(newThis.getDataAsVector(label) < th, :) = 0;
elseif moreThanFlag == 1
    newThis.Data(newThis.getDataAsVector(label) > th, :) = 0;
end
end


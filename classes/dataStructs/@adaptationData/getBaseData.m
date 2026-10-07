function [data, baseConds, trialTypes] = getBaseData(this, baseConds, ...
    labels)
%GETBASEDATA Return baseline data: last 40 strides, minus the last 5.
%
%   Takes the last 40 strides of the baseline condition, exempting the
% final 5. If baseConds is not given, it is found with
% GETBASECONDITIONS (same rule as removeBiasV3).
%
% Inputs:
%   this      - adaptationData object
%   baseConds - (optional) cell array of baseline condition names
%   labels    - (optional) parameter labels to return; [] for all
%
% Outputs:
%   data       - parameter data of the first condition returned by
%                GETEARLYLATEDATA_V2
%   baseConds  - baseline conditions used
%   trialTypes - trial types searched ([] if baseConds was given)
%
% Toolbox Dependencies: None
%
% See also GETBASECONDITIONS, GETEARLYLATEDATA_V2.

if nargin < 2 || isempty(baseConds)
    [baseConds, trialTypes] = getBaseConditions(this);
else
    trialTypes = [];
end
if nargin < 3
    labels = [];
end

numberOfStrides = -40;  % negative: count back from the end of the condition
exemptFirst     = 10;
exemptLast      = 5;
removeBiasFlag  = 0;
data = getEarlyLateData_v2(this, labels, baseConds, removeBiasFlag, ...
    numberOfStrides, exemptLast, exemptFirst);
data = data{1};

end

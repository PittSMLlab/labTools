function newThis = getDataAsPS(this, labels, strides, skipFixedParams)
%getDataAsPS  Extracts subset as new parameterSeries
%
%   newThis = getDataAsPS(this, labels, strides, skipFixedParams)
%   creates a new parameterSeries with specified labels and strides
%
%   Inputs:
%       this - parameterSeries object
%       labels - cell array of parameter labels to extract (optional,
%                default: all)
%       strides - vector of stride indices to extract (optional,
%                 default: all)
%       skipFixedParams - if 1, excludes fixed parameters like bad,
%                         trial, initTime (optional, default: 0)
%
%   Outputs:
%       newThis - new parameterSeries with extracted data
%
%   See also: getDataAsVector, getParameter

if nargin < 2 || isempty(labels)
    labels = this.labels;
end
if nargin < 4 || isempty(skipFixedParams) || skipFixedParams ~= 1
    extendedLabels = [this.labels(1:this.fixedParams); labels(:)];
else
    extendedLabels = labels(:);
end
% To avoid repeating bad, trial, initTime
[~, inds] = unique(extendedLabels);
% To avoid the re-sorting 'unique' does
extendedLabels = extendedLabels(sort(inds));
[bool, idx] = this.isaLabel(extendedLabels);
idx = idx(bool);
if nargin < 3 || isempty(strides)
    strides = 1:size(this.Data, 1);
end
newThis = parameterSeries(this.Data(strides, idx), this.labels(idx), ...
    this.hiddenTime(strides), this.description(idx), this.trialTypes);
end


function newThis = linearStretch(this, labels, rangeValues)
%linearStretch  Linearly transforms parameter values
%
%   newThis = linearStretch(this, labels, rangeValues) transforms
%   parameters such that rangeValues(1) maps to 0 and rangeValues(2)
%   maps to 1
%
%   Inputs:
%       this - parameterSeries object
%       labels - cell array of parameter labels to transform
%       rangeValues - 2-element vector [min max] defining range to
%                     normalize
%
%   Outputs:
%       newThis - parameterSeries with normalized parameters added as
%                 'Norm' + original label
%
%   Note: Creates NEW parameters with 'Norm' prefix. Will generate
%         collisions if run multiple times for same parameters.
%
%   See also: adaptationData.normalizeToBaselineEpoch, addNewParameter

if numel(rangeValues) ~= 2
    error('parameterSeries:linearStretch', ...
        'rangeValues has to be a 2 element vector');
end
% [boolFlag, labelIdx] = isaLabel(this, labels);
% for i = 1:length(labels)
%     if boolFlag(i)
%         oldDesc = this.description(labelIdx(i));
%         newDesc = ['Normalized (range = ' num2str(rangeValues(1)) ',' num2str(rangeValues(2)) ') ' oldDesc];
%         funHandle = @(x) (x - rangeValues(1)) / diff(rangeValues);
%         this = addNewParameter(this, strcat('Norm', labels{i}), funHandle, labels(i), newDesc);
%     end
% end
% More efficient:
N = length(labels);
newDesc = repmat({['Normalized to range = [' ...
    num2str(rangeValues(1)) ',' num2str(rangeValues(2)) ']']}, N, 1);
newL = cell(N, 1);
nD = zeros(size(this.Data, 1), N);
for i = 1:N
    funHandle = @(x) (x - rangeValues(1)) / diff(rangeValues);
    newL{i} = strcat('Norm', labels{i});
    nD(:, i) = this.computeNewParameter(newL{i}, funHandle, labels(i));
end
newThis = appendData(this, nD, newL, newDesc);
end


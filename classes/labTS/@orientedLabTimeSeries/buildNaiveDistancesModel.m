function model = buildNaiveDistancesModel(this)
%buildNaiveDistancesModel  Builds statistical marker model
%
%   model = buildNaiveDistancesModel(this) creates naive Bayes model
%   of inter-marker distances
%
%   Inputs:
%       this - orientedLabTimeSeries object
%
%   Outputs:
%       model - naiveDistances model object
%
%   Note: Assumes data is bilateral and sorts L/R by magnitude of third
%         component
%
%   See also: naiveDistances, fixBadLabels, findOutliers

labels = this.getLabelPrefix;
data = this.getOrientedData;
% Assuming the data is bilateral & sorting L/R and by magnitude of
% third component
iL = cellfun(@(x) ~isempty(x), regexp(labels, '^L*'));
iR = cellfun(@(x) ~isempty(x), regexp(labels, '^R*'));
% Can only have paired markers for the model to work
if sum(iL) ~= sum(iR)
    if sum(iL) > sum(iR)
        aux = regexprep(labels(iR), '^R*', 'L');
        [b, iL] = this.isaLabelPrefix(aux);
        iL = iL(b);
        [~, iR] = this.isaLabelPrefix(labels(iR));
        iR = iR(b);
    else
        aux = regexprep(labels(iL), '^L*', 'R');
        [b, iR] = this.isaLabelPrefix(aux);
        iR = iR(b);
        [~, iL] = this.isaLabelPrefix(labels(iL));
        iL = iL(b);
    end
end
dL = data(:, iL, :);
lL = labels(iL);
dR = data(:, iR, :);
lR = labels(iR);
[~, idx1] = sort(nanmean(dL(:, :, 3)), 'ascend');
[~, idx2] = sort(nanmean(dR(:, :, 3)), 'descend');
labels = [lL(idx1) lR(idx2)];
data = cat(2, dL(:, idx1, :), dR(:, idx2, :));
d = permute(data, [2, 3, 1]);
model = naiveDistances.learn(d, labels, true);
end


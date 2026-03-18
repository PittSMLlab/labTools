function virtualOTS = getVirtualOTS(this, ww, meanDiff, stdDiff)
%getVirtualOTS  Computes virtual markers from model
%
%   virtualOTS = getVirtualOTS(this) computes virtual markers using
%   maximum likelihood estimation
%
%   virtualOTS = getVirtualOTS(this, ww, meanDiff, stdDiff) uses
%   specified weights and statistics
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       ww - weight for actual data in units of 1/mm^2 (optional,
%            default: 0)
%       meanDiff - mean difference matrix (optional, computed from data)
%       stdDiff - std of differences (optional, computed from data)
%
%   Outputs:
%       virtualOTS - orientedLabTimeSeries with virtual markers
%
%   Note: Uses naive Bayes approach assuming distances are normally
%         distributed
%
%   See also: buildNaiveDistancesModel, fillGaps

if nargin < 2 || isempty(ww)
    % ww represents the weight given to actual data from the marker
    ww = 0;
end
ll = this.getLabelPrefix;
if nargin < 4 || isempty(meanDiff) || isempty(stdDiff)
    differences = this.computeDifferenceMatrix([], [], ll, ll);
    meanDiff = nanmean(differences, 1); % Mean distance
    % Method: difference Naive Bayes
    stdDiff = nanstd(differences, [], 1);
end

actualData = this.getOrientedData(ll);
virtualData = nan(size(actualData));

for i = 1:length(ll) % For each marker
    xEstim = nan(size(differences, 1), 3, size(differences, 2));
    w = 1 ./ stdDiff(1, i, :, :).^2;
    w(1, 1, i, :) = ww;
    for j = 1:length(ll)
        xEstim(:, :, j) = bsxfun(@times, bsxfun(@plus, ...
            squeeze(actualData(:, j, :)), ...
            squeeze(meanDiff(1, i, j, :))'), ...
            squeeze(w(1, 1, j, :))');
    end
    aux = any(~isnan(xEstim), 2);

    virtualData(:, i, :) = bsxfun(@rdivide, nansum(xEstim, 3), ...
        squeeze(sum(bsxfun(@times, w, aux), 3)));
end
virtualOTS = orientedLabTimeSeries.getOTSfromOrientedData(...
    virtualData, this.Time(1), this.sampPeriod, ll, this.orientation);

end


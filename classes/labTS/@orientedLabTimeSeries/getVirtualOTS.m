function virtualOTS = getVirtualOTS(this, ww, meanDiff, stdDiff)
%GETVIRTUALOTS Computes virtual markers from model.
%
%   virtualOTS = getVirtualOTS(this) computes virtual markers using maximum
% likelihood estimation
%
%   virtualOTS = getVirtualOTS(this, ww, meanDiff, stdDiff) uses specified
% weights and statistics
%
% Inputs:
%   this     - orientedLabTimeSeries object
%   ww       - weight for actual data in units of 1/mm^2 (optional, default:
%              0)
%   meanDiff - mean difference matrix (optional, computed from data)
%   stdDiff  - std of differences (optional, computed from data)
%
% Outputs:
%   virtualOTS - orientedLabTimeSeries with virtual markers
%
%   Note: Uses naive Bayes approach assuming distances are normally
%         distributed
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
%
% See also BUILDNAIVEDISTANCESMODEL, FILLGAPS.

if nargin < 2 || isempty(ww)
    % ww represents the weight given to actual data from the marker
    ww = 0;
end
ll = this.getLabelPrefix;
if nargin < 4 || isempty(meanDiff) || isempty(stdDiff)
    differences = this.computeDifferenceMatrix([], [], ll, ll);
    meanDiff    = mean(differences, 1, 'omitnan'); % Mean distance
    % Method: difference Naive Bayes
    stdDiff = std(differences, [], 1, 'omitnan');
end

actualData  = this.getOrientedData(ll);
virtualData = nan(size(actualData));

for ii = 1:length(ll) % For each marker
    xEstim = nan(size(differences, 1), 3, size(differences, 2));
    w      = 1 ./ stdDiff(1, ii, :, :).^2;
    w(1, 1, ii, :) = ww;
    for jj = 1:length(ll)
        xEstim(:, :, jj) = bsxfun(@times, bsxfun(@plus, ...
            squeeze(actualData(:, jj, :)), ...
            squeeze(meanDiff(1, ii, jj, :))'), ...
            squeeze(w(1, 1, jj, :))');
    end
    aux = any(~isnan(xEstim), 2);

    virtualData(:, ii, :) = bsxfun(@rdivide, sum(xEstim, 3, 'omitnan'), ...
        squeeze(sum(bsxfun(@times, w, aux), 3)));
end
virtualOTS = orientedLabTimeSeries.getOTSfromOrientedData(...
    virtualData, this.Time(1), this.sampPeriod, ll, this.orientation);

end


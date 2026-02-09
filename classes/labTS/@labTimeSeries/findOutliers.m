function [newThis, logL] = findOutliers(this, model, verbose)
%findOutliers  Detects outliers using model
%
%   [newThis, logL] = findOutliers(this, model) uses marker model to
%   detect outliers
%
%   [newThis, logL] = findOutliers(this, model, verbose) controls
%   output verbosity
%
%   Inputs:
%       this - labTimeSeries object
%       model - marker model for outlier detection
%       verbose - if true, displays detailed results (optional)
%
%   Outputs:
%       newThis - labTimeSeries with Quality field indicating outliers
%       logL - log likelihood values
%
%   See also: checkMarkerDataHealth

d = this.getDataAsVector(model.markerLabels)';
l = this.labels;
[out, logL] = model.outlierDetect(d, -4);
[boolF, idx] = this.isaLabel(model.markerLabels);
aux(:, idx(boolF)) = (out == 1)';
this.Quality = aux;
if verbose
    fprintf(['Outlier data in ' num2str(sum(any(out, 1))) '/' ...
        num2str(size(out, 2)) ' frames, avg. ' ...
        num2str(sum(out(:)) / sum(any(out, 1))) ' per frame.\n']);
    for j = 1:size(out, 1)
        if sum(out(j, :) == 1) > 0
            disp([l{j} ': ' num2str(sum(out(j, :) == 1)) ' frames']);
        end
    end
end
% s = naiveDistances.summaryStats(d);
% s = s(model.activeStats, :)';
% m = model.statMedian;
% m = m(model.activeStats);
% ss = model.getRobustStd(.94);
% ss = 3 * ss(model.activeStats); % 3 standard devs
% aux = model.loglikelihood(d) < -4^2 / 2;
% figure; pp = plot(s); axis tight; hold on;
% for j = 1:size(s, 2)
%     patch([1 size(s, 1) size(s, 1) 1], [m(j) - ss(j) m(j) - ss(j) m(j) + ss(j) m(j) + ss(j)], pp(j).Color, 'FaceAlpha', .3, 'EdgeColor', 'None')
%     plot(find(aux(j, :)), s(aux(j, :), j), 'x', 'Color', pp(j).Color, 'MarkerSize', 4);
% end
newThis = this;
end


function [this, logL] = findOutliers(this, model, verbose)
%findOutliers  Detects outliers using model
%
%   [this, logL] = findOutliers(this, model) uses marker model to
%   detect outliers
%
%   [this, logL] = findOutliers(this, model, verbose) controls output
%   verbosity
%
%   Inputs:
%       this - orientedLabTimeSeries object
%       model - naiveDistances model for outlier detection
%       verbose - if true, displays detailed results (optional)
%
%   Outputs:
%       this - orientedLabTimeSeries with Quality field updated
%       logL - log likelihood values (currently unused)
%
%   See also: buildNaiveDistancesModel, removeOutliers

% This assumes ALL markerLabels are present
[d, l] = this.getOrientedData(model.markerLabels);
d = permute(d, [2, 3, 1]);
% Could also use the non-fast version, but it will take time
out = model.outlierDetectFast(d);
[boolF, idx] = this.isaLabelPrefix(model.markerLabels);
aux(:, idx(boolF)) = (out(boolF, :) == 1)';
newQual = reshape(cat(1, aux, aux, aux), size(aux, 1), ...
    size(aux, 2) * 3);
if ~isempty(this.Quality)
    % Replace value for outliers only
    this.Quality(newQual ~= 0) = newQual(newQual ~= 0);
else
    this.Quality = newQual;
end
if nargin > 2 && verbose
    fprintf(['Outlier data in ' num2str(sum(any(out, 1))) '/' ...
        num2str(size(out, 2)) ' frames, avg. ' ...
        num2str(sum(out(:)) / sum(any(out, 1))) ' per frame.\n']);
    for j = 1:size(out, 1)
        if sum(out(j, :) == 1) > 0
            disp([l{j} ': ' num2str(sum(out(j, :) == 1)) ' frames']);
        end
    end
end
end


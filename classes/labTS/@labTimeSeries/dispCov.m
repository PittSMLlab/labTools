function h = dispCov(this)
%dispCov  Displays covariance matrix
%
%   h = dispCov(this) creates a figure displaying the covariance
%   matrix of the data
%
%   Inputs:
%       this - labTimeSeries object
%
%   Outputs:
%       h - figure handle
%
%   See also: cov

h = figure;
dd = cov(this.Data);
imagesc(dd);
set(gca, 'XTick', 1:length(this.labels), 'XTickLabels', this.labels, ...
    'XTickLabelRotation', 90, 'YTick', 1:length(this.labels), ...
    'YTickLabels', this.labels, 'YTickLabelRotation', 0);
colorbar;
caxis([-1 1] * max(dd(:)));
end


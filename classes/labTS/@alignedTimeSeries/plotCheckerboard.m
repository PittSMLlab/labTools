function [fh, ph] = plotCheckerboard(this, fh, ph)
%plotCheckerboard  Displays data as heatmap
%
%   [fh, ph] = plotCheckerboard(this) creates heatmap visualization of
%   mean aligned data
%
%   [fh, ph] = plotCheckerboard(this, fh, ph) uses existing handles
%
%   Inputs:
%       this - alignedTimeSeries object
%       fh - figure handle (optional)
%       ph - plot handle (optional)
%
%   Outputs:
%       fh - figure handle
%       ph - plot handle
%
%   Note: To do - check if events exist and add DS/STANCE/DS/SWING
%         labels
%
%   See also: plot

if nargin < 2
    fh = figure();
else
    figure(fh);
end
if nargin < 3
    ph = gca;
else
    axes(ph);
end
m = this.mean;
% imagesc(m.Data')
surf([this.Time, 2 * this.Time(end) - this.Time(end - 1)], ...
    [0:size(m.Data, 2)], [[m.Data'; m.Data(:, end)'], ...
    [m.Data(end, :)'; 0]], 'EdgeColor', 'none');
view(2);
ax = gca;
ax.YTick = [1:length(this.labels)] - 0.5;
ax.YTickLabels = this.labels;
ax.XTick = [0.5 0.5 + cumsum(this.alignmentVector)] / ...
    sum(this.alignmentVector) * this.Time(end);
ax.XTickLabel = this.alignmentLabels;
axis([this.Time(1) 2 * this.Time(end) - this.Time(end - 1) ...
    0 size(m.Data, 2)]);
% Colormap:
ex2 = [0.2314    0.2980    0.7529];
ex1 = [0.7255    0.0863    0.1608];
gamma = 0.5;
map = [bsxfun(@plus, ex1.^(1 / gamma), bsxfun(@times, ...
    1 - ex1.^(1 / gamma), [0:0.01:1]')); ...
    bsxfun(@plus, ex2.^(1 / gamma), bsxfun(@times, ...
    1 - ex2.^(1 / gamma), [1:-0.01:0]'))].^gamma;
colormap(flipud(map));
try
    caxis([-1 1] * max(abs(m.Data(:)))); % Fails if plotted data is NaN
    colorbar;
catch

end
% TODO: check if the events exist, and add DS/STANCE/DS/SWING labels
end


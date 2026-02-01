function [figHandle, plotHandles] = plotAvgStride(this, field, ...
    conditions, plotHandles, figHandle)
%plotAvgStride  Plots average stride across conditions
%
%   [figHandle, plotHandles] = plotAvgStride(this, field, conditions)
%   creates plots showing the average stride for each condition
%
%   [figHandle, plotHandles] = plotAvgStride(this, field, conditions,
%   plotHandles, figHandle) uses existing plot handles
%
%   Inputs:
%       this - stridedExperimentData object
%       field - name of field to plot (e.g., 'procEMGData',
%               'angleData')
%       conditions - vector of condition indices to plot
%       plotHandles - existing subplot handles (optional)
%       figHandle - existing figure handle (optional)
%
%   Outputs:
%       figHandle - handle to figure
%       plotHandles - array of subplot handles
%
%   See also: plotAllStrides, strideData/plotCellAvg

% Set colors
poster_colors;
% Set colors order
ColorOrder = [p_red; p_orange; p_fade_green; p_fade_blue; p_plum; ...
    p_green; p_blue; p_fade_red; p_lime; p_yellow];
set(gcf, 'DefaultAxesColorOrder', ColorOrder);

if nargin < 5 || isempty(figHandle)
    figHandle = figure('Name', ['Subject ' ...
        num2str(this.subData.ID) ' ' field]);
else
    figure(figHandle); % Only works for one condition!
end
set(figHandle, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
aux = this.getStridesFromCondition(conditions(1));
N = 2^ceil(log2(size(aux{1}.(field).Data, 1)));
structure = this.getDataAsMatrices(field, conditions, N);
if nargin < 4 || isempty(plotHandles)
    M = size(structure{1}, 2);
    [b, a] = getFigStruct(M);
    plotHandles = tight_subplot(b, a, [.04 .02], [.05 .02], ...
        [.04 .05]);
end
for i = 1:M
    % subplot(b, a, i)
    subplot(plotHandles(i));
    hold on;
    legStr = {};
    title(aux{1}.(field).labels{i});
    for cond = conditions
        data = mean(squeeze(structure{cond}(:, i, :)), 2);
        plot([0:N - 1] / N, data, 'LineWidth', 2, 'Color', ...
            ColorOrder(mod(cond - 1, size(ColorOrder, 1)) + 1, :));
        legStr{end + 1} = ['Condition ' num2str(cond)];
    end
    if i == M
        legend(legStr);
    end
    hold off;
end
end


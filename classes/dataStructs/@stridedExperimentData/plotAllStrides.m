function [figHandle, plotHandles] = plotAllStrides(this, field, ...
    conditions, plotHandles, figHandle)
%plotAllStrides  Plots all individual strides for a field
%
%   [figHandle, plotHandles] = plotAllStrides(this, field,
%   conditions) creates plots showing all individual strides for the
%   specified field and conditions
%
%   [figHandle, plotHandles] = plotAllStrides(this, field,
%   conditions, plotHandles, figHandle) uses existing plot handles
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
%   Note: To Do - need to add gait events markers
%
%   See also: plotAvgStride, plotAllStridesBilateral

% To Do: need to add gait Events markers.

% Set colors
poster_colors;
% Set colors order
ColorOrder = [p_red; p_orange; p_fade_green; p_fade_blue; p_plum; ...
    p_green; p_blue; p_fade_red; p_lime; p_yellow];
set(gcf, 'DefaultAxesColorOrder', ColorOrder);

for cond = conditions
    if nargin < 5 || isempty(figHandle)
        figHandle = figure('Name', ['Subject ' ...
            num2str(this.subData.ID) ' Condition ' num2str(cond) ...
            ' ' field]);
    else
        figure(figHandle); % Only works for one condition!
    end
    set(figHandle, 'Units', 'normalized', 'OuterPosition', ...
        [0 0 1 1]);
    aux = this.getStridesFromCondition(cond);
    N = 2^ceil(log2(1.5 / aux{1}.(field).sampPeriod));
    structure = this.getDataAsMatrices(field, cond, N);
    M = size(structure{cond}, 2);
    if nargin < 4 || isempty(plotHandles)
        [b, a] = getFigStruct(M);
        % External function
        plotHandles = tight_subplot(b, a, [.02 .02], [.05 .02], ...
            [.02 .05]);
    end
    if (numel(structure{cond})) > 1e6
        P = floor(1e7 / numel(structure{cond}(:, :, 1)));
        warning(['There are too many strides in this condition ' ...
            'to plot (' num2str(size(structure{cond}, 3)) ...
            '). Only plotting first ' num2str(P) '.']);
        meanStr{cond} = mean(structure{cond}, 3);
        structure{cond} = structure{cond}(:, :, 1:P);
    end
    for i = 1:M
        % subplot(b, a, i)
        subplot(plotHandles(i));
        hold on;
        % title(aux{1}.(field).labels{i})
        data = squeeze(structure{cond}(:, i, :));
        plot([0:N - 1] / N, data, 'Color', [.7, .7, .7]);
        plot([0:N - 1] / N, meanStr{cond}(:, i), 'LineWidth', 2, ...
            'Color', ColorOrder(mod(cond - 1, size(ColorOrder, 1)) + ...
            1, :));
        legend(aux{1}.(field).labels{i});
        hold off;
    end
end

end


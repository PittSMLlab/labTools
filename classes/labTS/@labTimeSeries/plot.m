function [h, plotHandles] = plot(this, h, labels, plotHandles, events, ...
    color, lineWidth)
%plot  Plots data in subplots
%
%   [h, plotHandles] = plot(this) plots all labels in separate subplots
%
%   [h, plotHandles] = plot(this, h, labels, plotHandles, events,
%   color, lineWidth) plots with specified options
%
%   Inputs:
%       this - labTimeSeries object
%       h - figure handle (optional, creates new if empty)
%       labels - cell array of labels to plot (optional, default: all)
%       plotHandles - subplot handles (optional, creates if empty)
%       events - labTimeSeries with events to mark (optional)
%       color - line color (optional)
%       lineWidth - line width (optional, default: 2)
%
%   Outputs:
%       h - figure handle
%       plotHandles - array of subplot handles
%
%   Note: Alternative plot - all traces go in different axes
%
%   See also: bilateralPlot, plotAligned

% Alternative plot: all the traces go in different axes
if nargin < 2 || isempty(h)
    h = figure;
else
    figure(h);
end
N = length(this.labels);
if nargin < 3 || isempty(labels)
    relData = this.Data;
    relLabels = this.labels;
    if ~isempty(this.Quality)
        relQual = this.Quality == 1;
    else
        relQual = true(size(relData));
    end
else
    [relData, ~, relLabels] = this.getDataAsVector(labels);
    N = size(relData, 2);
end
if nargin < 4 || isempty(plotHandles) || ...
        length(plotHandles) < length(relLabels)
    [b, a] = getFigStruct(length(relLabels));
    % External function
    plotHandles = tight_subplot(b, a, [.05 .05], [.05 .05], ...
        [.05 .05]);
end
if nargin < 7 || isempty(lineWidth)
    lineWidth = 2;
end
ax2 = [];
h1 = [];
if any(~isreal(relData(:)))
    warning('labTimeSeries:plot', ...
        'Data is complex, plotting the modulus only.');
    relData = abs(relData);
end
for i = 1:N
    h1(i) = plotHandles(i);
    subplot(h1(i));
    hold on;
    if nargin < 6 || isempty(color)
        pp = plot(this.Time, relData(:, i), 'LineWidth', lineWidth);
    else
        pp = plot(this.Time, relData(:, i), 'LineWidth', lineWidth, ...
            'Color', color);
    end
    % plot(this.Time(relQual(:, i)), relData(relQual(:, i), i), 'rx')
    uistack(pp, 'top');
    ylabel(relLabels{i});
    % if i == ceil(N / 2)
    %     xlabel('Time (s)')
    % end
    hold off;
    if nargin > 4 && ~isempty(events)
        lls = {'LHS', 'RTO', 'RHS', 'LTO'};
        [ii, jj] = find(events.getDataAsTS(lls).Data);
        [ii, iaux] = sort(ii);
        jj = jj(iaux);
        ax1 = gca;
        % ax2(i) = axes('Position', ax1.Position, ...
        %     'XAxisLocation', 'top', ...
        %     'YAxisLocation', 'right', ...
        %     'Color', 'none'); %, 'XColor', 'r', 'YColor', 'r');
        % [tt, i2] = unique(events.Time(ii));
        set(ax1, 'XTick', events.Time(ii), 'XTickLabel', lls(jj));
        grid on;
    end
end
% linkaxes([h1, ax2], 'x')
plotHandles = h1;
end


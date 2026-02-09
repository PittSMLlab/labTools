function [figHandle, plotHandles, plottedInds] = plot(this, ...
    figHandle, plotHandles, meanColor, events, ...
    individualLineStyle, plottedInds, bounds, medianFlag)
%plot  Plots aligned data with mean
%
%   [figHandle, plotHandles, plottedInds] = plot(this) plots
%   individual strides and mean
%
%   [figHandle, plotHandles, plottedInds] = plot(this, figHandle,
%   plotHandles, meanColor, events, individualLineStyle, plottedInds,
%   bounds, medianFlag) plots with full customization
%
%   Inputs:
%       this - alignedTimeSeries object
%       figHandle - figure handle (optional)
%       plotHandles - subplot handles (optional)
%       meanColor - RGB color for mean line (optional, default: red)
%       events - alignedTimeSeries with events to mark (optional)
%       individualLineStyle - line style for individual strides
%                             (optional, 0 to skip)
%       plottedInds - stride indices to plot (optional, auto-limited
%                     if too many)
%       bounds - percentile bounds for shading or lines (optional)
%       medianFlag - if 1 uses median, if 0 uses mean (optional,
%                    default: 1)
%
%   Outputs:
%       figHandle - figure handle
%       plotHandles - subplot handles
%       plottedInds - indices of strides actually plotted
%
%   Note: Plots individual instances (strides) and overlays mean. Uses
%         one subplot per label. If events given, displays average
%         event times.
%
%   See also: labTimeSeries/plot, plotCheckerboard

% Plot individual instances (strides) of the time-series, and overlays
% the mean of all of them Uses one subplot for each label in the
% timeseries (same as labTimeSeries.plot). If events are given
% (alignedTimeSeries with the same time vector and number of strides),
% it will display the average event-time ocurrence in the plot,
% instead of the time in the x-axis. See also labTimeSeries.plot
%
% SYNTAX:
% [figHandle, plotHandles] = plot(this, figHandle, plotHandles,
%     meanColor, events)
%
% INPUTS:
% this: alignedTimeSeries object to plot
% figHandle: handle to the figure to be used. If absent, creates a new
% figure.
% plotHandles: handles to the subplots being used. There need to be at
% least as many handles as labels in the data.
% meanColor: color to use for the plot of the mean. % FIXME
% events: alignedTimeSeries of events.
%
% OUTPUT:
% figHandle: handle to the figure used.
% plotHandles: handles to the subplots used.
%
if nargin < 4 || isempty(meanColor)
    meanColor = [1, 0, 0];
end
if nargin < 9 || isempty(medianFlag)
    medianFlag = 1;
end
structure = this.Data;
if nargin < 2 || isempty(figHandle)
    figHandle = figure();
else
    figure(figHandle); % Only works for one condition!
end
set(figHandle, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
M = size(structure, 2);
if nargin < 3 || isempty(plotHandles) || ...
        length(plotHandles) < size(this.Data, 2)
    [b, a] = getFigStruct(M);
    % External function
    plotHandles = tight_subplot(b, a, [.02 .02], [.05 .05], ...
        [.05 .05]);
end
meanStr = mean(structure, 3);
if nargin < 7 || isempty(plottedInds)
    plottedInds = 1:size(structure, 3);
    if (numel(structure)) > 1e7
        P = floor(1e7 / numel(structure(:, :, 1)));
        warning(['There are too many strides in this condition to ' ...
            'plot (' num2str(size(structure, 3)) '). Only plotting ' ...
            'first ' num2str(P) '.']);
        plottedInds = 1:P;
        structure = structure(:, :, plottedInds);
    end
elseif any(plottedInds <= 0) % Counting from the back
    plottedInds(plottedInds <= 0) = size(structure, 3) + ...
        plottedInds(plottedInds <= 0);
end


% Define centerline plot:
if medianFlag == 1
    centerline = this.median.castAsTS; % Could do mean or median
else
    centerline = this.mean.castAsTS;
end

% Plot percentiles (bounds)
if nargin < 5 || isempty(events)
    events = [];
    meanEvents = [];
else
    if isa(events, 'alignedTimeSeries')
        [meanEvents, ss] = mean(events);
        meanEvents = meanEvents.castAsTS;
    else
        meanEvents = events;
        ss = [];
    end
    [i2, ~] = find(meanEvents.Data);
end
if ~islogical(this.Data) && nargin > 7 && ~isempty(bounds)
    if length(bounds) == 2 % Alt visualization: add patch
        if any(bounds) == 0
            if medianFlag == 1
                st = this.stdRobust.castAsTS;
            else
                st = this.std.castAsTS;
            end
            if all(bounds) == 0 % Plots ste
                aux1 = centerline + (st .* 1 / sqrt(size(this.Data, 3)));
                aux2 = centerline - (st .* 1 / sqrt(size(this.Data, 3)));
            else % Plots std
                aux1 = centerline + (st);
                aux2 = centerline - (st);
            end
        else
            aux1 = prctile(this, bounds(1));
            aux2 = prctile(this, bounds(2));
        end
        for i = 1:M
            subplot(plotHandles(i));
            hold on;
            if size(aux1.Time, 1) == numel(aux1.Time) % column vector
                megaTime = [aux1.Time; aux1.Time(end:-1:1)];
            else % row vector
                megaTime = [aux1.Time, aux1.Time(end:-1:1)];
            end
            megaData = [aux1.Data(:, i); aux2.Data(end:-1:1, i)];
            megaData(isnan(megaData)) = 0;
            pp = patch(megaTime, megaData, meanColor, 'FaceAlpha', .4, ...
                'EdgeColor', 'none');
            uistack(pp, 'bottom');
            hold off;
        end
    else % Plot each percentile line
        for k = 1:length(bounds)
            [figHandle, plotHandles] = ...
                plot(this.prctile(bounds(k)).castAsTS, figHandle, [], ...
                plotHandles, [], meanColor * .8, .5);
        end
    end
end

% Plot mean trace
% Plotting mean data
[figHandle, plotHandles] = plot(centerline, figHandle, [], ...
    plotHandles, meanEvents, meanColor);

% Plot individual traces
for i = 1:M % Go over labels
    % subplot(b, a, i)
    subplot(plotHandles(i));
    hold on;
    % title(aux{1}.(field).labels{i})
    data = squeeze(structure(:, i, :));
    N = size(data, 1);
    if nargin < 6 || isempty(individualLineStyle)
        ppp = plot(this.Time, data, 'Color', [.7, .7, .7]);
        uistack(ppp, 'bottom');
    elseif individualLineStyle == 0
        % nop
    else
        ppp = plot(this.Time, data, individualLineStyle);
        uistack(ppp, 'bottom');
    end

    % plot([0:N - 1] / N, meanStr(:, i), 'LineWidth', 2, 'Color',
    %     meanColor);
    % legend(this.labels{i})
    % maxM(i) = 5 * norm(data(:)) / sqrt(length(data(:)));
    meanM(i) = prctile(data(:), 50);
    maxM(i) = 2 * (prctile(data(:), 99) - meanM(i)) + meanM(i) + eps;
    minM(i) = 2 * (prctile(data(:), 1) - meanM(i)) + meanM(i);
    axis([this.Time(1) this.Time(end) minM(i) maxM(i)]);
    hold off;
end

if ~isempty(events)
    % For each plot, plot a standard deviation bar indicating how
    % disperse are events with respect to their mean/median (XTick set)
    for i = 1:length(plotHandles)
        eventSampPeriod = (events.Time(2) - events.Time(1));
        subplot(plotHandles(i));
        hold on;
        for j = 1:length(ss)
            plot(events.Time(i2(j)) + ss(j) * [-1, 1] * ...
                eventSampPeriod, [0, 0], 'k', 'LineWidth', 1);
        end
        % axis tight % TO DO: not use axis tight, but find proper axes
        % limits by computing the rms value of the signal, or
        % something like that.
        hold off;
    end
else
    % For each plot, plot a standard deviation bar indicating how
    % disperse are events with respect to their mean/median (XTick set)
    for i = 1:length(plotHandles)
        subplot(plotHandles(i));
        xt = get(gca, 'XTick');
        xt = [this.Time(1) + [0, cumsum(this.alignmentVector)] * ...
            (this.Time(end) - this.Time(1)) / ...
            sum(this.alignmentVector)];
        xtl = [[this.alignmentLabels, this.alignmentLabels(1)]];
        set(gca, 'XTick', xt, 'XTickLabel', xtl);
        set(gca, 'xgrid', 'on');
    end
end
end


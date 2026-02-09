function [h, plotHandles] = bilateralPlot(this, h, labels, ...
    plotHandles, events, color, lineWidth)
%bilateralPlot  Plots bilateral comparison
%
%   [h, plotHandles] = bilateralPlot(this) plots 'L' and 'R' labeled
%   data overlaid for comparison
%
%   [h, plotHandles] = bilateralPlot(this, h, labels, plotHandles,
%   events, color, lineWidth) plots with specified options
%
%   Inputs:
%       this - labTimeSeries object
%       h - figure handle (optional, creates new if empty)
%       labels - labels to plot (optional, default: all)
%       plotHandles - subplot handles (optional, creates if empty)
%       events - labTimeSeries with events to mark (optional)
%       color - line color (optional)
%       lineWidth - line width (optional, default: 2)
%
%   Outputs:
%       h - figure handle
%       plotHandles - array of subplot handles
%
%   Note: Ideally plots 'L' and 'R' timeseries on top of each other
%         for bilateral comparison
%
%   See also: plot, plotAligned

% Ideally we would plot 'L' and 'R' timeseries on top of each other,
% to do a bilateral comparison. Need to implement.
if nargin < 2 || isempty(h)
    h = figure;
else
    figure(h);
end
if nargin < 5 || isempty(events)
    events = [];
end
if nargin < 6 || isempty(color)
    color = [];
end
if nargin < 3 || isempty(labels)
    labels = this.labels;
end
suffix = unique(cellfun(@(x) x(2:end), labels, 'UniformOutput', ...
    false));
if nargin < 4 || isempty(plotHandles) || ...
        length(plotHandles) < length(suffix)
    [b, a] = getFigStruct(length(suffix));
    % External function
    plotHandles = tight_subplot(b, a, [.05 .05], [.05 .05], ...
        [.05 .05]);
end
if nargin < 7 || isempty(lineWidth)
    lineWidth = 2;
end
[h, plotHandles] = plot(this, h, strcat('L', suffix), plotHandles, ...
    events, color, lineWidth);
[h, plotHandles] = plot(this, h, strcat('R', suffix), plotHandles, ...
    events, color, lineWidth);
for i = 1:length(suffix)
    subplot(plotHandles(i));
    ylabel(suffix{i});
    if i == length(suffix)
        legend('L', 'R');
    end
end
end


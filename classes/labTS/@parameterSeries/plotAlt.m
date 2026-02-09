function [h, h1] = plotAlt(this, h, labels, plotHandles, color)
%plotAlt  Plots parameters as scatter
%
%   [h, h1] = plotAlt(this) plots all parameters as scatter plot
%
%   [h, h1] = plotAlt(this, h, labels, plotHandles, color) plots with
%   specified options
%
%   Inputs:
%       this - parameterSeries object
%       h - figure handle (optional)
%       labels - cell array of labels to plot (optional)
%       plotHandles - subplot handles (optional)
%       color - line/marker color (optional)
%
%   Outputs:
%       h - figure handle
%       h1 - array of subplot handles
%
%   See also: plot, labTimeSeries/plot

if nargin < 5
    color = [];
end
if nargin < 4
    plotHandles = [];
end
if nargin < 3
    labels = [];
end
if nargin < 2
    h = [];
end
[h, h1] = this.plot(h, labels, plotHandles, [], color, 1);
ll = findobj(h, 'Type', 'Line');
set(ll, 'LineStyle', 'None', 'Marker', '.');
linkaxes(h1, 'x');
end


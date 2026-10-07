function [h, plotHandles] = plotAligned(this, h, labels, plotHandles, ...
    events, color, lineWidth)
%PLOTALIGNED Plots aligned data (unimplemented).
%
%   [h, plotHandles] = plotAligned(this, h, labels, plotHandles, events,
% color, lineWidth) would plot data aligned to events
%
% Inputs:
%   this        - labTimeSeries object
%   h           - figure handle (optional)
%   labels      - labels to plot (optional)
%   plotHandles - subplot handles (optional)
%   events      - events for alignment (optional)
%   color       - line color (optional)
%   lineWidth   - line width (optional)
%
% Outputs:
%   h           - figure handle
%   plotHandles - subplot handles
%
%   Note: Unimplemented
%
% Toolbox Dependencies: None
%
% See also PLOT, ALIGN.

error('labTS:plotAligned', 'Unimplemented');
% Sketch: align the data to the first column of events provided
% for i = 1:length(ee)
%    this.split(t1, t2).plot
% end
end


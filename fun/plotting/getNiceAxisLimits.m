function [xl,yl] = getNiceAxisLimits(axHandle,pad)
%GETNICEAXISLIMITS Tight axis limits with a margin around the data.
%
%   Like axis tight, but pads each side so that no data point touches the
% limits of the plot box, and applies the limits to the axes.
%
% Side effects: sets the axes to tight and then sets XLim and YLim.
%
% Inputs:
%   axHandle - (optional) axes handle (default: gca)
%   pad      - (optional) margin on each side as a fraction of the tight
%              range (default: 0.1, i.e., 20% wider in total)
%
% Outputs:
%   xl - X axis limits
%   yl - Y axis limits
%
% Toolbox Dependencies: None

if nargin < 1 || isempty(axHandle)
    axHandle = gca;
end
if nargin < 2
    pad = 0.1; %10% whitespace margins
end
axis(axHandle,'tight');
xl = get(axHandle,'XLim');
yl = get(axHandle,'YLim');
xl = -pad*mean(xl) + (1+pad)*xl;
yl = -pad*mean(yl) + (1+pad)*yl;
set(axHandle,'XLim',xl);
set(axHandle,'YLim',yl);
end


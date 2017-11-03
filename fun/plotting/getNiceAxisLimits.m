function [xl,yl] = getNiceAxisLimits(axHandle,pad)
%Similar to axis tight, but with pre-determined padding so no datapoints
%are against the limits of the plotting box
%INPUT:
%axHandle: axes handle, optional, defaults to gca
%pad: margin size as % of axis limits with axis tight (e.g. pad=.1 gives a
%20% larger axis, with 10% on each side). Default pad=.1
%OUTPUT:
%xl,yl: axis limits for X and Y respectively
if nargin<1 || isempty(axHandle)
    axHandle=gca;
end
if nargin<2
pad=.1; %10% whitespace margins
end
axis(axHandle,'tight');
xl=get(axHandle,'XLim');
yl=get(axHandle,'YLim');
xl=-pad*mean(xl) + (1+pad)*xl;
yl=-pad*mean(yl) + (1+pad)*yl;
set(axHandle,'XLim',xl);
set(axHandle,'YLim',yl);
end


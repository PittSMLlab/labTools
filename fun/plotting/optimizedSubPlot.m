function [axesHandles,figHandle] = optimizedSubPlot(Nplots,rowAspect, ...
    colAspect,order,axesFontSize,labelFontSize,titleFontSize)
%OPTIMIZEDSUBPLOT Full-screen figure of axes with minimal white space.
%
%   [ah,figh] = OPTIMIZEDSUBPLOT(Nplots) opens a full-screen figure with
% Nplots empty axes laid out so that the plots are as large as possible,
% and returns the axes handles and the figure handle.
%
%   OPTIMIZEDSUBPLOT(Nplots,relR,relC) uses the layout whose row:column
% ratio is closest to relR:relC (e.g., optimizedSubPlot(20,2,1) gives 7
% rows and 3 columns).
%
%   OPTIMIZEDSUBPLOT(Nplots,relR,relC,order) returns the handles from top
% to bottom, then over a column, for order 'tb', or from left to right,
% then down a row, for order 'lr' (default: 'lr').
%
%   OPTIMIZEDSUBPLOT(Nplots,relR,relC,order,axesFS,labelFS,titleFS) pads
% the plots according to the font sizes of tick labels, axis labels, and
% title (default: 10 for all).
%
% Side effects: opens a full-screen figure through figureFullScreen and
%   sets its default axes color order (poster_colors); errors with
%   optimizedSubPlot:InvalidInput if order is not 'tb' or 'lr'.
%
% Inputs:
%   Nplots        - number of axes
%   rowAspect     - (optional) relative number of rows (default: 1)
%   colAspect     - (optional) relative number of columns (default: 1)
%   order         - (optional) 'tb' or 'lr' (default: 'lr')
%   axesFontSize  - (optional) tick label font size (default: 10)
%   labelFontSize - (optional) axis label font size (default: 10)
%   titleFontSize - (optional) title font size (default: 10)
%
% Outputs:
%   axesHandles - 1 x Nplots axes handles
%   figHandle   - figure handle
%
% Example:
%   [ah,fh] = optimizedSubPlot(15,2,1,'tb',15,0,0);
%   for ii = 1:length(ah)
%       plot(ah(ii),rand(100,1),'b')
%       set(ah(ii),'fontSize',15)
%   end
%
% Toolbox Dependencies: None
%
% Copyright 2014 HMRL.
%
% See also SUBPLOT, SUBPLOTSIZE, FIGUREFULLSCREEN.

%% Check Inputs
if nargin < 2
    rowAspect = 1;
end
if nargin < 3
    colAspect = 1;
end

if nargin < 4 || isempty(order)
    order = 'lr';
else
    if ~strcmpi(order,'lr') && ~strcmpi(order,'tb')
        ME = MException('optimizedSubPlot:InvalidInput', ...
            'order must be ''tb'' or ''lr'' if specified');
        throw(ME);
    end
end

%if font sizes aren't specified, assume default
if nargin < 5 || isempty(axesFontSize)
    axesFontSize = 10;
end
if nargin < 6 || isempty(labelFontSize)
    labelFontSize = 10;
end
if nargin < 7 || isempty(titleFontSize)
    titleFontSize = 10;
end

%% Generate Subplot
[figHandle,scrsz] = figureFullScreen; % Maybe this could be an option?
figsz = [0 0 1 1];

%in pixels:
vertpad_top    = (titleFontSize+20)/scrsz(4); %padding on the top of figure
%padding on the bottom of figure
vertpad_bottom = (axesFontSize+labelFontSize+20)/scrsz(4);
%padding on the left of figure
horpad         = (axesFontSize*3+labelFontSize+20)/scrsz(3);

%find subplot size with rowAspect:colAspect ratio
[rows,cols] = subplotSize(Nplots,rowAspect,colAspect);

% Set colors
poster_colors;
% Set colors order
ColorOrder = [p_red; p_orange; p_fade_green; p_fade_blue; p_plum; ...
    p_green; p_blue; p_fade_red; p_lime; p_yellow];
set(gcf,'DefaultAxesColorOrder',ColorOrder);

W = (figsz(3)/cols)-(horpad+axesFontSize/scrsz(3));
H = (figsz(4)/rows)-(vertpad_bottom+vertpad_top);
if strcmpi(order,'lr') %plots left to right then goes down a row
    rowind      = 1;
    colind      = 0;
    axesHandles = NaN(1,Nplots);
    for ii = 1:Nplots
        bottom = figsz(4)-(rowind*figsz(4)/rows)+vertpad_bottom;
        left   = colind*(figsz(3))/cols+horpad;
        colind = colind+1;
        if colind == cols
            rowind = rowind+1;
            colind = 0;
        end
        axesHandles(ii) = subplot('Position',[left bottom W H],'Parent', ...
            figHandle);
    end
else %default behavior (plots top to bottom then goes over a column)
    rowind      = 1;
    colind      = 0;
    axesHandles = NaN(1,Nplots);
    for ii = 1:Nplots
        %find graph location
        bottom = figsz(4)-(rowind*figsz(4)/rows)+vertpad_bottom;
        left   = colind*(figsz(3))/cols+horpad;
        rowind = rowind+1;
        if rowind > rows
            colind = colind+1;
            rowind = 1;
        end
        axesHandles(ii) = subplot('Position',[left bottom W H],'Parent', ...
            figHandle);
    end
end
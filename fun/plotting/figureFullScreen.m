function [h,scrsz] = figureFullScreen()
%FIGUREFULLSCREEN Open a figure that fills the screen.
%
%   Opens a figure with normalized outer position [0 0 1 1] and returns its
% handle and the screen size.
%
% Side effects: opens a figure.
%
% Inputs:
%   none
%
% Outputs:
%   h     - figure handle
%   scrsz - screen size [left bottom width height] in pixels
%
% Toolbox Dependencies: None
%
% See also OPTIMIZEDSUBPLOT.

scrsz = get(0,'ScreenSize'); % left, bottom, width, height
%for windows:
%figure('OuterPosition',[scrsz(1) scrsz(2)+50 scrsz(3) ...
%    scrsz(4)-50]); %50 is the number of pixels of the bar at bottom of
%    screen
%for linux or mac:
h = figure('Units','normalized','OuterPosition',[0 0 1 1]);
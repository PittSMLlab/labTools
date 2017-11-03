%figureFullScreen
function [h,scrsz]=figureFullScreen()

scrsz = get(0,'ScreenSize'); % left, bottom, width, height
%for windows:
%figure('OuterPosition',[scrsz(1) scrsz(2)+50 scrsz(3) scrsz(4)-50]); %50 is the number of pixels of the bar at bottom of screen
%for linux or mac:
h=figure('Units','normalized','OuterPosition',[0 0 1 1]);
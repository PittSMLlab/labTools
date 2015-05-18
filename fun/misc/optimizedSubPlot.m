function [axesHandles,figHandle]=optimizedSubPlot(Nplots,rowAspect,colAspect,order,axesFontSize,labelFontSize,titleFontSize)
%order is either 'ltr' or 'ttb'

if nargin<5 || isempty(axesFontSize)
    axesFontSize=10;
end
if nargin<6 || isempty(labelFontSize)
    labelFontSize=10;
end
if nargin<7 || isempty(titleFontSize)
    titleFontSize=10;
end

[figHandle,scrsz]=figureFullScreen; % Maybe make this could be an option?
figsz=[0 0 1 1];

%in pixels:
vertpad_top = (titleFontSize+20)/scrsz(4); %padding on the top and bottom of figure--> theses can probably be in absolute terms...
vertpad_bottom= (axesFontSize+labelFontSize+20)/scrsz(4);
horpad = (axesFontSize*2+labelFontSize+20)/scrsz(3);  %padding on the left and right of figure

%find subplot size with rowAspect:colAspect ratio
[rows,cols]=subplotSize(Nplots,rowAspect,colAspect);

% Set colors
poster_colors;
% Set colors order
ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow];
set(gcf,'DefaultAxesColorOrder',ColorOrder);

if nargin>3 && strcmpi(order,'ltr') %plots left to right then goes down a row
    rowind=1;
    colind=0;
    axesHandles=NaN(1,Nplots);
    for i=1:Nplots
        bottom=figsz(4)-(rowind*figsz(4)/rows)+vertpad_bottom;
        left=colind*(figsz(3))/cols+horpad;
        colind=colind+1;
        if colind==cols
            rowind=rowind+1;
            colind=0;
        end
        axesHandles(i)=subplot('Position',[left bottom (figsz(3)/cols)-(horpad+10/scrsz(3)) (figsz(4)/rows)-(vertpad_bottom+vertpad_top)]);
    end
else    %default behavior (plots top to bottom then goes over a column)    
    rowind=1;
    colind=0;
    axesHandles=NaN(1,Nplots);
    for i=1:Nplots
        %find graph location
        bottom=figsz(4)-(rowind*figsz(4)/rows)+vertpad_bottom;        
        left=colind*(figsz(3))/cols+horpad;
        rowind=rowind+1;
        if rowind>rows
            colind=colind+1;
            rowind=1;
        end
        axesHandles(i)=subplot('Position',[left bottom (figsz(3)/cols)-(horpad+10/scrsz(3)) (figsz(4)/rows)-(vertpad_bottom+vertpad_top)]);
    end
end
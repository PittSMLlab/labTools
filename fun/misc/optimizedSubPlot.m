function [axesHandles,figHandle]=optimizedSubPlot(Nplots,rowAspect,colAspect,order,axesFontSize,labelFontSize,titleFontSize)
%OPTIMIZEDSUBPLOT generates a full-screen figure of empty subplots that
%minizes the amount of "white space" surrounding each plot, esenitally
%making the actual plots as big as possible.
%   [ah,figh] = OPTIMIZEDSUBPLOT(Nplots) generates a figure with Nplots 
%   axes and returns a handle for the figure created and a vector of axis 
%   handles for each axis created.  
%
%   [ah,figh] = OPTIMIZEDSUBPLOT(Nplots,relR,relC) generates a figure with
%   Nplots axes that have a row:col ratio close to the relR:relC
%   ratio entered (ex. optimizedSubPlot(20,2,1) generates a figure with 7
%   rows and 3 cols of axes)
%
%   [ah,figh] = OPTIMIZEDSUBPLOT(Nplots,relR,relC,order) returns the axis
%   handles in order from top to bottom (and then over a column) if order
%   is 'tb' or in order from left to right (and then down a row) if order
%   is 'lr'. Default behavior is 'tb'
%
%   [ah,figh] = OPTIMIZEDSUBPLOT(Nplots,relR,relC,order,axesFS,labelFS,titleFS)
%   generates a figure with padding around plots based on the font sizes of
%   the axis tick labels, axis labels, and title as specified. If font
%   sizes are not specified, the default MATLAB behaviour (font size 10 for
%   everyhting) is assumed
%
%   Example: [ah,fh]=optimizedSubPlot(15,2,1,'ttb',15,0,0);
%            for i=1:length(ah)
%                plot(ah(i),rand(100,1),'b')
%                set(ah(i),'fontSize',15)
%            end
%
%   Compare to:
%            figureFullScreen;
%            for i=1:15
%                subplot(5,3,i)
%                plot(rand(100,1),'b')
%                set(gca,'fontSize',15)
%            end
%
%   See also subplot subplotSize figureFullScreen

%   Copyright 2014 HMRL.

%% Check Inputs

if nargin<2 
    rowAspect=1; 
end
if nargin<3    
    colAspect=1;
end

if nargin<4 || isempty(order)
     order='lr';    
else
    if ~strcmpi(order,'lr') && ~strcmpi(order,'tb')
        ME=MException('optimizedSubPlot:InvalidInput','order must be ''tb'' or ''lr'' if specified');
        throw(ME);
    end   
end

%if font sizes aren't specified, assume default
if nargin<5 || isempty(axesFontSize)    
    axesFontSize=10;
end
if nargin<6 || isempty(labelFontSize)    
    labelFontSize=10;
end
if nargin<7 || isempty(titleFontSize)
    titleFontSize=10;
end

%% Generate Subplot
[figHandle,scrsz]=figureFullScreen; % Maybe this could be an option?
figsz=[0 0 1 1];

%in pixels:
vertpad_top = (titleFontSize+20)/scrsz(4); %padding on the top of figure
vertpad_bottom= (axesFontSize+labelFontSize+20)/scrsz(4);%padding on the bottom of figure
horpad = (axesFontSize*3+labelFontSize+20)/scrsz(3);  %padding on the left of figure

%find subplot size with rowAspect:colAspect ratio
[rows,cols]=subplotSize(Nplots,rowAspect,colAspect);

% Set colors
poster_colors;
% Set colors order
ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow];
set(gcf,'DefaultAxesColorOrder',ColorOrder);

W=(figsz(3)/cols)-(horpad+axesFontSize/scrsz(3));
H=(figsz(4)/rows)-(vertpad_bottom+vertpad_top);
if strcmpi(order,'lr') %plots left to right then goes down a row
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
        axesHandles(i)=subplot('Position',[left bottom W H],'Parent',figHandle);
    end
else %default behavior (plots top to bottom then goes over a column)    
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
        axesHandles(i)=subplot('Position',[left bottom W H],'Parent',figHandle);
    end
end
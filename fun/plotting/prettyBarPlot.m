function [fh,ph] = prettyBarPlot(data,colors,medianFlag,pairingLines, ...
    groupNames, conditionNames,plotHandle)
%PRETTYBARPLOT Grouped bar plot with spread and individual data points.
%
%   Draws bars of the median (or mean) of each condition and group with
% IQR (or standard deviation) error bars, and optionally the individual
% data points or pairing lines.
%
% Side effects: opens a figure unless plotHandle is given; loads the
%   colors through figuresColorMap when colors is empty; adds a legend and
%   condition tick labels.
%
% Inputs:
%   data           - P x M x N array: P data points, M conditions (x
%                    axis), N groups (colored)
%   colors         - (optional) N x 3 colors (default: condColors from
%                    figuresColorMap)
%   medianFlag     - (optional) 1 for median and IQR, 0 for mean and SD
%                    (default: 1)
%   pairingLines   - (optional) 0 none, 1 lines between groups, 2
%                    individual data points (default: 2)
%   groupNames     - (optional) cell array of N group names
%   conditionNames - (optional) cell array of M condition names
%   plotHandle     - (optional) axes to plot on (default: new figure)
%
% Outputs:
%   fh - figure handle
%   ph - axes handle
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox (iqr)
%
% See also FIGURESCOLORMAP.

P = size(data,1); %#datapoints
M = size(data,2); %Conditions (x spacing)
N = size(data,3); %Groups (colored)

%Parse input:
if nargin < 2 || isempty(colors)
    figuresColorMap
    colors = condColors;
end
if nargin < 3 || isempty(medianFlag)
    medianFlag = 1; %Median +- iqr as plot default
end
if nargin < 4 || isempty(pairingLines)
    pairingLines = 2; %Individual datapoints as default
end
if nargin < 5 || isempty(groupNames) || length(groupNames) ~= N
    groupNames = strcat('Group ', num2str([1:N]'));
end
if nargin < 6 || isempty(conditionNames) || length(conditionNames) ~= M
    conditionNames = strcat('Condition ', num2str([1:M]'));
end

%PLOT------------
if nargin < 7 || isempty(plotHandle)
    fh = figure('Units','Normalized','OuterPosition',[0 0.5 0.3 0.5]);
    ph = gca;
    hold on
else
    axes(plotHandle);
    ph = gca;
    fh = gcf;
    hold on
end
%Bars:
if medianFlag == 1
    m = squeeze(median(data, 'omitnan'));
    s = squeeze(iqr(data));
else
    m = squeeze(mean(data, 'omitnan'));
    s = squeeze(std(data, 0, 'omitnan'));
end
bb = bar(m,'FaceAlpha',0.6,'EdgeColor','none');
pause(0.1) %Without this the graphics engine doesnt return proper handles
xo = nan(N,1);
for ii = 1:length(bb) %length(bb) should be N
    xo(ii) = get(bb(ii),'xoffset');
    bb(ii).FaceColor = colors(ii,:);
end
%Add mean and std of pop:
%errorbar(reshape(.15*[-1 1]+[1; 2],4,1),mean(data),std(data),'Color', ...
%    'k','LineWidth',2,'LineStyle','none')
for ii = 1:N
    errorbar(xo(ii)+[1:M]',m(:,ii),[],s(:,ii),'Color',colors(ii,:), ...
        'LineWidth',2,'LineStyle','none')
end

%Add individual datapoints:
switch pairingLines
    case 0
        %nop
        %pairing lines (this is for side-by-side bars, corresponding to the
        %same condition in two groups)
    case 1
        for ii = 1:M
            pp1 = plot(ii+xo-0.05*sign(xo),squeeze(data(:,ii,:)),'k');
        end
    case 2 %single datapoints
        for ii = 1:N
            %Optional: hide half of the bars
            dX = mean(diff(xo))/2;
            for jj = 1:M
                %rectangle((xo(i)+j)+[0,dX,dX,0],[0 0 1 1]*bb(i).YData(j));
                h = bb(ii).YData(jj);
                if h >= 0
                    rectangle('Position',[xo(ii)+jj+0.01 0 dX h], ...
                        'EdgeColor','None','FaceColor','w');
                else
                    rectangle('Position',[xo(ii)+jj+0.01 h dX -h], ...
                        'EdgeColor','None','FaceColor','w');
                end
                scatter(xo(ii)+jj+0.01*randn(size(data,1),1)+dX/2, ...
                    squeeze(data(:,jj,ii)),50,colors(ii,:),'filled', ...
                    'MarkerFaceAlpha',0.6);
            end
            %pp1=plot(xo(i)+[1:M]+.01*randn(size(data,1),1)+dX/2, ...
            %    squeeze(data(:,:,i)),'o','MarkerFaceColor',colors(i,:), ...
            %    'MarkerEdgeColor','none');

        end
end

legend(groupNames);
set(gca,'XTick',[1:M],'XTickLabel',conditionNames);
end
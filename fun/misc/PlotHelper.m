%PLOTHELPER helper function with static functions to make common plots
% Current support: 1. correlation plot: scatter plots with a best fit
% regression line (y=mx + b) and text printout of the pearson and spearman
% correlation results
% 2. bar plots with individual subjects dot
% 3. confidence intervals
% 4. boot strap of correlations
% 5. regression diagnostics (residual normality and homoscedasticity)
% 6. tight margin of plots (shrink empty space between the plot and the figure window)
%
% 
% $Author: Shuqi Liu $	$Date: 2022/08/22 10:06:49 $	$Revision: 0.1 $
% Copyright: Sensorimotor Learning Laboratory 2022
classdef PlotHelper
    
    properties (Constant)
         colorOrder = [colororder;    
        1.0000         0         0
        1.0000    0.5333         0
        1.0000    1.0000         0
             0    0.7333         0
             0.2 0.8 0.8
            0.75 0.75 0.75
             0         0    1.0000
        0.3333         0    1.0000
        0.6667         0    1.0000];
    end
    
    methods(Static)

        function f = computeAndPlotCorrelations(xData, yData, subjectIDs, titleStr, xlabels, ylabels, saveResAndFigure, savePath, xylabelOnceOnly, controlVar, controlVarXIdx, controlVarYIdx,performKws, plotDiagnostic)
        %compute correlations and plot a figure with subplots of correlations
        %between each columns in x and y data.
        % 
        % [OUTPUTARGS]: f, the fingure handle; typically a full figure
        % with subplots.
        % InputArgs: - xData: 2D matrix of data, subjects x columns
        %            - yData: 2D matrix of data to plot on the yaxis, subjects x columns
        %            - subjectIDs: cell array of strings of subject IDs used in
        %            legend
        %            - titleStr: string, subplots title (main title for all plots)
        %            - xlabels: cell array of strings for xlabel (per column)
        %            - ylabels: cell aray of strings for ylabel (per row)
        %            - saveResAndFigure: boolean whether or not to save the
        %            figure
        %            - savePath: the full path (directory and name) to save
        %            the figures.
        %            - xylabelOnceOnly: boolean indicate if label should
        %               only be used once (at bottom row and first column)
        %               otherwise label all grpahs.
        %           - controlVar: OPTIONAL. 2D matrix of data to control for in a
        %               partial correlation, in subjects x variableColumns
        %           - controlVarXIdx: OPTIONAL. integer or integer array, if the
        %               controlled variable is part of the xData, corresponding
        %               data columns in xData that's the contrlled var. Pass
        %               NaN if the controlled var is not part of the xData.
        %           - controlVarYIdx: OPTIONAL. integer or integer array, if the
        %               controlled variable is part of the yData, corresponding
        %               data columns in xData that's the contrlled var. Pass
        %               NaN or omit the arg if the controlled var is not part of the yData.
        %           - performKws: OPTIONAL. boolean flag for if
        %               kruskalwallis should be performed. Default false.
        %           - plotDiagnostic: OPTIONAL. Default False. boolean flag. True if
        %               plotting residual diagnostics of the fitted
        %               regressions.     

            if nargin <=12 %no performKws given
                performKws = false;
            end
            if nargin <=13 %no performKws given
                plotDiagnostic = false;
            end
            % calclulate partial corr if controlVar is provided, otherwise regular
            % correlation.
            numNans = sum(isnan(yData),'all') + sum(isnan(xData),'all');
            if numNans
                warning([num2str([numNans]) ' NAN Value found in the data. Will only use non-nan values to compute correlation'])
            end
            if nargin >=10 && ~isempty(controlVar) && ~any(isnan(controlVar),'all')
                [rho,p] = partialcorr(xData, yData,controlVar,'Rows','complete'); %resulting size x by y
                [rhoSpearman,pSpearman] = partialcorr(xData, yData,controlVar,'Type','Spearman','Rows','complete');
                if nargin>=11 && ~isnan(controlVarXIdx) %the variable controlled is part of the xData.
                    [rho(controlVarXIdx,:),p(controlVarXIdx,:)] = corr(controlVar, yData,'Rows','complete');
                    [rhoSpearman(controlVarXIdx,:),pSpearman(controlVarXIdx,:)] = corr(controlVar, yData,'Type','Spearman','Rows','complete');
                end
                if nargin>=12 && ~isnan(controlVarYIdx) %the variable controlled is part of the yData.
                    [rho(:,controlVarYIdx),p(:,controlVarYIdx)] = corr(xData, controlVar,'Rows','complete');
                    [rhoSpearman(:,controlVarYIdx),pSpearman(:,controlVarYIdx)] = corr(xData, controlVar,'Type','Spearman','Rows','complete');
                end
            else
                [rho,p] = corr(xData,yData,'Rows','complete');
                [rhoSpearman,pSpearman] = corr(xData,yData,'Type','Spearman','Rows','complete');
            end
            f = PlotHelper.plotCorrelations(xData, yData, subjectIDs, titleStr, xlabels, ylabels, saveResAndFigure, savePath, xylabelOnceOnly,rho, p, rhoSpearman, pSpearman, performKws, plotDiagnostic);
        end
        
        function f = plotCorrelations(xData, yData, subjectIDs, titleStr, xlabels, ylabels, saveResAndFigure, savePath, xylabelOnceOnly,rho, p, rhoSpearman, pSpearman, performKws, plotDiagnostic)
        % plot correlations. the pearson and spearman correlations are
        % computed ahead of time. 
        % 
        % [OUTPUTARGS]: f, the fingure handle; typically a full figure
        % with subplots.
        %
        % See also: computeAndPlotCorrelations for input argument
        % requirements. 
        % 
        % InputArgs: - first few args see computeAndPlotCorrelations
        %            - rho: 2D matrix of Pearson's correlation coefficient,
        %                   Y by X where X is number of variables (columns) in xData and Y is number of
        %                   variable (columns) in yData
        %            - p: 2D matrix of the p-value for pearson's
        %                   correlation
        %            - rhoSpearman: 2D matrix of Spearman's correlation coefficient,
        %                   Y by X where X is number of variables (columns) in xData and Y is number of
        %                   variable (columns) in yData
        %            - pSpearman: 2D matrix of the p-value for Spearman's
        %                   correlation   
        %            - performKws: OPTIONAL. Default false. boolean flag for if kruskalwallis test
        %               should be performed instead of correlations (proper
        %               for categorical data). 
        %            - plotDiagnostic: OPTIONAL. Default False. boolean flag. True if
        %               plotting residual diagnostics of the fitted
        %               regressions. 
            if nargin <=13 %no performKws given
                performKws = false;
            end
            if nargin <= 14 %no plotDiagnostic given
                plotDiagnostic = false;
            end
            colorOrder = PlotHelper.colorOrder; %load colorOrder

            if plotDiagnostic
                %make diagnostic figure first. then the focus will be on
                %the regression plot to start with.
                fDiagnostic = figure('units','normalized','outerposition',[0 0 1 1]);
            end
            f = figure('units','normalized','outerposition',[0 0 1 1]);%('Position', get(0, 'Screensize'));
%             markerOrder = {'o','+','*','^','x','_','|','.','d','s'};
            
            for rowIdx = 1:size(yData,2) %row
                for colIdx = 1:size(xData,2) %col
                    subplot(size(yData,2),size(xData,2),(rowIdx-1)*size(xData,2)+colIdx); hold on;
                    axis square;
                    xToPlot = xData(:,colIdx); %put fnir on the x-axis
                    yToPlot = yData(:,rowIdx);
                    for subIdx = 1:length(subjectIDs)
                        colorIdx = rem(subIdx,size(colorOrder,1));
                        if colorIdx == 0 %avoid 0
                            colorIdx = size(colorOrder,1);
                        end
                        plot(xToPlot(subIdx),yToPlot(subIdx),'o','Color',colorOrder(colorIdx,:),'LineWidth',2,'MarkerSize',7,'DisplayName',subjectIDs{subIdx});
                    end
                    % Do the regression with an intercept of 0 and plot the line
                    linFit = fitlm(xToPlot,yToPlot,'RobustOpts','on');
                    plotFitX = xlim;
                    if pSpearman(colIdx, rowIdx) < 0.1 %plot the line if spearman significant only; p(colIdx, rowIdx) < 0.1 || 
                        %plot the regression line only if the p-value for
                        %either test is <0.05
                        plotFitY = linFit.Coefficients.Estimate(2) * plotFitX + linFit.Coefficients.Estimate(1);
                        if pSpearman(colIdx, rowIdx) < 0.05 %solid line for significant %plot the line if spearman significant only p(colIdx, rowIdx) < 0.05 || 
                            plot(xlim,plotFitY,'k','LineWidth',2.5,'handleVisibility','off');
                        else %dashed line for trending.
                            plot(xlim,plotFitY,'k--','LineWidth',2.5,'handleVisibility','off');
                        end
                    end
                    txtY = ylim;
                    if p(colIdx, rowIdx) < 0.05 %show the text in red
                        textColorPearson = 'r';
                    else
                        textColorPearson = 'k';
                    end
                    if pSpearman(colIdx, rowIdx) < 0.05 %show the text in red
                        textColorSpearman = 'r';
                    else
                        textColorSpearman = 'k';
                    end
                    if performKws
                        kws = kruskalwallis(yToPlot,xToPlot,'off');
                        if kws < 0.05
                            textColorKws = 'r';
                        else
                            textColorKws = 'k';
                        end
                        text(plotFitX(1),txtY(2)-range(txtY)*0.35,sprintf('K-W p=%.4f',kws),'FontSize',40,'Color',textColorKws)
                    end
                    %0.15, 25 for top; 7 and .8 for btm
                    text(plotFitX(1),txtY(2)-range(txtY)*0.65,sprintf('RobustR=%.2f',linFit.Rsquared.Ordinary^0.5),'FontSize',40,'Color',textColorPearson)
                    text(plotFitX(1),txtY(2)-range(txtY)*0.75,sprintf('P:r=%.3f,p=%.4f',rho(colIdx, rowIdx),p(colIdx, rowIdx)),'FontSize',40,'Color',textColorPearson)
                    text(plotFitX(1),txtY(2)-range(txtY)*0.85,sprintf('S:\\rho=%.3f,p=%.4f',rhoSpearman(colIdx, rowIdx),pSpearman(colIdx, rowIdx)),'FontSize',40,'Color',textColorSpearman)
                    xlim(plotFitX)
                    if xylabelOnceOnly
                        if colIdx == 1 %first column, give y label
                            ylabel(ylabels{rowIdx});
                        end
                        if rowIdx == size(yData,2) %last row, give x label
                            xlabel(xlabels{colIdx});
                        end
                    else
                        xlabel(xlabels{colIdx});
                        ylabel(ylabels{rowIdx});
                    end
                    
                    % check if there is outlier in the data in x or y.
                    curLabel = xlabels{colIdx};
                    dataAxis = 'X';
                    for dataToPlot = {xToPlot, yToPlot}
                        %Outliers are defined as elements more than three scaled MAD from the median.
                        outlierSubj = isoutlier(dataToPlot{1},'mean');
                        if any(outlierSubj)
%                             fprintf('\n%s: Outlier in %s column %s',titleStr, dataAxis, curLabel)
%                             disp(subjectIDs(outlierSubj))
                        end
                        curLabel = ylabels{rowIdx};
                        dataAxis = 'Y';
                    end
                    clear dataToPlot curLabel outlierSubj dataAxis

                    if plotDiagnostic %by default plot leverage and cook's D 2 diagnostic graph per regression (2 rows 1 column)
                        %options to plot:
                        %contour plot, if points fall outside of cook's d (have
                        %a high cook's d value), likely influential points.
                        % High leverage points are outliers in the x-space, they 
                        %tend to have extreme values in one or more of the x’s 
                        %or represent an unusual combo of x values.
                        %Cook’s distance is a weighted sum of terms(betaj betaj(-i)), function of the leverages and studentized residuals            
                        %DFFITS quantify how much the fitted values change if the ith observation was deleted from the dataset
                        %DFBETAs quantify how much each coefficient would change (in s.e. units) if the ith observation was deleted from the dataset
                        figure(fDiagnostic);
                        subplot(size(yData,2)*2,size(xData,2),(rowIdx-1)*size(xData,2)*2+colIdx); 
                        plotDiagnostics(linFit);
                        ref_leverage = 2*linFit.NumCoefficients/linFit.NumObservations;
                        high_leveragePts = linFit.Diagnostics.Leverage > ref_leverage;
                        fprintf([titleStr '\nX=' xlabels{colIdx} ', Y=' ylabels{rowIdx} '\nHigh leverage points index: ' num2str(find(high_leveragePts)') ' Subjects: '])
                        disp(subjectIDs(high_leveragePts));
                        %plot on row 2
                        subplot(size(yData,2)*2,size(xData,2),(rowIdx*2-1)*size(xData,2)+colIdx); 
                        plotDiagnostics(linFit,'cookd');
                        ref_cookd = 3*mean(linFit.Diagnostics.CooksDistance,'omitnan');
                        high_cookdPts = linFit.Diagnostics.CooksDistance > ref_cookd;
                        fprintf(['\nHigh cooks d (influential) points index: ' num2str(find(high_cookdPts)') ' Subjects: '])
                        disp(subjectIDs(high_cookdPts))
    %                     subplot(1,3,3); plotDiagnostics(linFit,'contour');
    %                     subplot(1,3,3); plotDiagnostics(linFit,'dfbetas');
    %                     subplot(2,2,4); plotDiagnostics(linFit,'dffits');
                        figure(f);
                        linFit = fitlm(xToPlot,yToPlot,'RobustOpts','on');
                        fprintf('\nr from robust regression: ')
                        disp((linFit.Rsquared.Ordinary).^0.5)
                    end
                end
            end
            legend()
        %     sgtitle(['Correlation Btw Cognitive Measures and ' scaleString])
            sgtitle(titleStr)
            set(findall(gcf,'-property','FontSize'),'FontSize',15)
            if plotDiagnostic
                figure(fDiagnostic);
                sgtitle([titleStr ' Diagnostic']);
                set(findall(gcf,'-property','FontSize'),'FontSize',15)
            end
            if saveResAndFigure
                figure(f)
                set(gcf,'renderer','painters')
                saveas(f, [savePath '.fig'])
                s = findobj('type','legend'); delete(s)
                saveas(f, [savePath '.png'])
                if plotDiagnostic
                    figure(fDiagnostic)
                    set(gcf,'renderer','painters')
                    saveas(f, [savePath 'Diagnostic.fig'])
                    saveas(f, [savePath 'Diagnostic.png'])
                end
            end
        end
        
        function plotSingleCorrelation(xToPlot, yToPlot, subjectIDs)
        %Plot on the current figure (a subplot should have 
        %been opened and configured before calling this function) correlations
        %between x and yToPlot
        % 
        % [OUTPUTARGS]: none, this function simply draws on existing
        % figure.
        % with subplots.
        % InputArgs:    -xToPlot: a row vector of data to plot on x-axis
        %               -yToPlot: a row vector of double to plot on y-axis
        %               -subjectIDs: cell array of string of subjectIDs
        %               for legend.
        %
            hold on;
            colorOrder = PlotHelper.colorOrder;
            colorLength = size(colorOrder, 1);
            for dIdx = 1:length(xToPlot)
                plot(xToPlot(dIdx),yToPlot(dIdx),'o','Color',colorOrder(mod(dIdx-1, colorLength)+1,:),'LineWidth',2,'MarkerSize',7,'DisplayName',subjectIDs{dIdx});
            end
            numNans = sum(isnan(xToPlot),'all') + sum(isnan(yToPlot),'all');
            if numNans
                warning([num2str(numNans) ' NAN Value found in the data. Will only use non-nan values to compute correlation'])
            end
            [rho,p] = corr(xToPlot',yToPlot','Rows','complete');
            [rhoSpearman,pSpearman] = corr(xToPlot',yToPlot','Type','Spearman','Rows','complete');
            linFit = fitlm(xToPlot,yToPlot);
            plotFitX = xlim;
            if pSpearman < 0.1 %plot reg line only if corr for pearson is significant
                plotFitY = linFit.Coefficients.Estimate(2) * plotFitX + linFit.Coefficients.Estimate(1);
                if pSpearman < 0.05 %solid line for significant
                    plot(xlim,plotFitY,'k','LineWidth',2.5,'handleVisibility','off');
                else %dashed line for trending.
                    plot(xlim,plotFitY,'k--','LineWidth',2.5,'handleVisibility','off');
                end
            end
            txtY = ylim;
            if p < 0.05 %show the text in red
                textColorPearson = 'r';
            else
                textColorPearson = 'k';
            end
            if pSpearman < 0.05 %show the text in red
                textColorSpearman = 'r';
            else
                textColorSpearman = 'k';
            end
            %0.15, 25 for top; 7 and .8 for btm
            text(plotFitX(1),txtY(2)-range(txtY)*0.7,sprintf('P:r=%.3f,p=%.3f',rho,p),'FontSize',20,'Color',textColorPearson)
            text(plotFitX(1),txtY(2)-range(txtY)*0.8,sprintf('S:\\rho=%.3f,p=%.3f',rhoSpearman,pSpearman),'FontSize',20,'Color',textColorSpearman)
            xlim(plotFitX)
            axis square
        end
        
        function barPlotWithIndiv(dataToPlot, subjectIDs, xlabelStrings, ylabelString, titleString, saveResAndFigure, savePath, f, addJitter, MarkerColor,connectLine)
        %Plot bar graph with dataToPlot, 1 bar per row in data, also plot
        %individual subjects and connect them with a line across bars (if
        %connectLine is true or default). Plot on existing figure if a
        %figure is given; otherwise create a new figure.
        % 
        % [OUTPUTARGS]: none.
        %
        % [InputArgs]: - dataToPlot: 2d matrix in columns(bars) x subjects
        %              - subjectIDs: cell array of strings of subject IDs used in
        %              legend
        %              - xlabelStrings: cell array of the xtick labels.
        %              - ylabelString: string for yaxis label
        %              - titleString: string for the plot title
        %              - saveResAndFigure: boolean for if the plot should
        %              be saved.
        %              - savePath: if saveResAndFigure TRUE, save the
        %              figure to the given path. Should provide a string of
        %              the full path including directories and figure file name.
        %              - f: OPTIONAL figure handle. If not provided will
        %              create a new one.
        %              - addJitter: OPTIONAL boolean. Default false. If
        %              true, will add jitter to the data points to better
        %              visualize data with same/similar values.
        %              - MarkerColor: OPTIONAL. Any matlab accepted color
        %              format (e.g., 'k', or vector of 3 doubles for RGB,
        %              see MATLAB documentation). Default rotate through PlotHelper.colorOrder
        %              - connectLine: OPTIONAL. Default true. Connect the
        %              dots from the same subjects with a line across bars.
            if nargin < 8 || isempty(f) || isnan(f) %no figure handle provided, create a new figure; if figure is provided, simply plot
                f = figure('units','normalized','outerposition',[0 0 1 1]);%('Position', get(0, 'Screensize'));
            end
            if nargin < 9 || isempty(addJitter) || isnan(addJitter)
                addJitter = false;
            end
            if nargin < 11 || isempty(connectLine) || isnan(connectLine) || connectLine
                markerSymbol = 'o-'; %default connect line
            else %specified not connect line, plot symbol only.
                markerSymbol = 'o'; 
            end
            colorOrder = PlotHelper.colorOrder;
            colorLength = size(colorOrder, 1);
            avgPerf = nanmean(dataToPlot,2); %in order: pre, training, post
            stdBarHeight = nanstd(dataToPlot,0,2); %2nd arg is weight, 0 means equal weight
            hold on;
            bar(avgPerf,'FaceColor','none','LineWidth',5,'DisplayName','Avg')
            xticks(1:length(avgPerf));
            xticklabels(xlabelStrings);
            er = errorbar(1:length(avgPerf),avgPerf,stdBarHeight,stdBarHeight,'DisplayName','SD');    
            er.Color = [0 0 0];                            
            er.LineStyle = 'none';
            er.LineWidth = 5;
            for dIdx = 1:length(subjectIDs)
                if addJitter %shifts individual data with some jitter to see overlapping data points
                    jitter = (rand-0.5)./2;
                else %default just shift all data slightly to the side of the error bar.
                    jitter = 0.1;
                end
                if nargin >= 10 && ~any(isnan(MarkerColor)) && ~isempty(MarkerColor)
                    plot([1:length(avgPerf)]+jitter,dataToPlot(:,dIdx)',markerSymbol,'Color',MarkerColor,'LineWidth',2.5,'MarkerSize',10,'DisplayName',subjectIDs{dIdx});
                else
                    plot([1:length(avgPerf)]+jitter,dataToPlot(:,dIdx)',markerSymbol,'Color',colorOrder(mod(dIdx-1, colorLength)+1,:),'LineWidth',2.5,'MarkerSize',10,'DisplayName',subjectIDs{dIdx});
                end
            end
            legend();%,'Location','bestoutside') %legend on 2nd plot only
            ylabel(ylabelString) 
            
            if length(avgPerf) == 2 %perform t-tests
                [h,p] = ttest(dataToPlot(1,:)',dataToPlot(2,:)');
                txtY = ylim;
                if p < 0.05
                    textColor = 'r';
                else
                    textColor = 'k';
                end
                text(2.3,txtY(2)-range(txtY)*0.80,sprintf('T:p=%.3f',p),'FontSize',20,'Color',textColor);
            end
            sgtitle(titleString)
            set(findall(gcf,'-property','FontSize'),'FontSize',25)
            if saveResAndFigure
                set(gcf,'renderer','painters')
                saveas(f,savePath)
                s = findobj('type','legend'); delete(s)
                saveas(f,[savePath '.png'])
            end
        end
        
        function plotCI(x, y, lineColor, dataLabel, showMeanCILegend, colorNonZeroRed)
        %Plot confidence interval of the y, and printout the y range (min,
        %max), mean, and 95%CI.
        %This function doesn't create a blank figure canvas, plots on the
        %current focused figure.
        % 
        % [OUTPUTARGS]: none. 
        % [InputArgs]:    
        %           - x: an integer/double of where along the x-axis to
        %           plot the y values.
        %           - y: a column vector of doubles of y values to plot,
        %           compute CI from
        %           - lineColor: color to plot the y (could be any matlab
        %           accepted color format, either single character like 'k'
        %           or a row vector of 3 numbers between[0,1] for r,g,b. 
        %           - dataLabel: string display name of the y variable.
        %           - showMeanCILegend: boolean determining if legend of
        %           graph items (CI and mean) will be shown.
        %           - colorNonZeroRed: OPTIONAL boolean flag to indicate if
        %           CI that doesn't contain 0 should be colored red
        %           (ignoring the given line color command). Default false.
            if nargin < 6 || ~exist('colorNonZeroRed','var') || isnan(colorNonZeroRed)
                colorNonZeroRed = false;
            end
            hold on;
            N = length(y);
            yMean = mean(y);
            ySEM = std(y);
            CI95 = tinv([0.025 0.975], N-1);                    % Calculate 95% Probability Intervals Of t-Distribution
            yCI95 = bsxfun(@times, ySEM, CI95(:));
            yCI95 = yCI95 + yMean;
            if colorNonZeroRed && (yCI95(1) > 0 || yCI95(2) < 0)
                lineColor = 'r';
            end
            if showMeanCILegend %show legend to indicate what's mean and CI.
                plot(x, yMean,'.','Color',lineColor,'LineWidth',3.5,'MarkerSize',38,'DisplayName','Mean'); 
                plot([x,x], yCI95,'Color',lineColor,'LineWidth',3.5,'Marker','None','DisplayName','95%CI');
            else %don't show legend for mean and CI. Show legend to identify the group of data only.
                plot(x, yMean,'.','Color',lineColor,'LineWidth',3.5,'MarkerSize',38,'HandleVisibility','off'); 
                plot([x,x], yCI95,'Color',lineColor,'LineWidth',3.5,'Marker','None','HandleVisibility','off');
            end
            plot(x*ones(size(y))+0.4,y,'o','Color',lineColor, 'LineWidth',1,'MarkerSize',10,'DisplayName',dataLabel)
            grid on;
            set(findall(gcf,'-property','FontSize'),'FontSize',25)
            [miny, maxy] = bounds(y);
%             fprintf('\n%s: Range[min, max]: [%f, %f]; Mean: %f, CI: [%f, %f]\n',dataLabel, miny, maxy, yMean, yCI95);
        end
        
        function plotRegressionDiagnostics(mdl, actualYs, saveResAndFigure, savePath)
        %Plot diagnosis plot of the linear regression model from mdl.
        %Top left: residual histogram for visualization of normality; top right: QQ plot for normality test. 
        %Bottom left: residual vs yhat for homeoscadesticity (equal
        %variance across all y values). Bottom right: fitted vs actual y to
        %evalute the fit results.
        % 
        % [OUTPUTARGS]: none. 
        % [InputArgs]:    
        %           - mdl: a LinearModel object from matlab (regression output)
        %           - actualYs: the actual y values (a column vector)
        %           - saveResAndFigure: boolean determining if plot should
        %           be saved.
        %           - savePath: string of the location and name to save the
        %               figure (absolute path recommended)
        %
            f = figure('units','normalized','outerposition',[0 0 1 1]);%('Position', get(0, 'Screensize'));
            subplot(2,2,1); histogram(mdl.Residuals.Raw); %histogram(mdl.Residuals.Studentized); 
            title('Residual Histogram'); xlabel('Residuals (y-yhat)');
    %         xRange = xlim;
    %         hold on; plot(xRange(1):0.1:xRange(2), normpdf(xRange(1):0.1:xRange(2), 0,1))
            pd = fitdist(mdl.Residuals.Raw,'Normal'); %pd = fitdist(mdl.Residuals.Studentized,'Normal'); 
            [h, p] = kstest(normalize(mdl.Residuals.Raw)); %[h, p] = kstest(mdl.Residuals.Studentized); 
            subplot(2,2,2); qqplot(mdl.Residuals.Raw); %qqplot(mdl.Residuals.Studentized); 
            title(['Residual vs Standard Normal: kstest (0:normal) = ' num2str(h)]);
            fprintf('Residual is normal (kstest, 0 = normal): %d, p = %f',h,p)
            subplot(2,2,3); scatter(mdl.Fitted, mdl.Residuals.Raw);%scatter(mdl.Fitted, mdl.Residuals.Studentized);
            hold on; yline(0);
            xlabel('Fitted'); ylabel('Residuals'); title('Homoscedasticity Check');
            subplot(2,2,4); scatter(mdl.Fitted, actualYs);
            hold on; plot(xlim, xlim); legend({'Data','y=x'});
            ylabel('ActualY'); xlabel('Fitted'); title('Fitted vs Actual Data Check');
            figureTitleStr = split(savePath, filesep);
            sgtitle(figureTitleStr{end}); %last part is file name and figure title.
            %TODO: sgtitle find the last part of the saveRes
            set(findall(gcf,'-property','FontSize'),'FontSize',15)
            if saveResAndFigure
                set(gcf,'renderer','painters')
                saveas(f,savePath)
%                 s = findobj('type','legend'); delete(s)
                saveas(f,[savePath '.png'])
            end
        end
        
        function plotBootStrapCorrSpearman(xData, yData, xlabels, ylabels, titleStr, saveResAndFigure, savePath, iterations, controlVar, controlVarXIdx, controlVarYIdx, f)
            %Plot boot strapping results of spearman's correlation between
            %columns in xData and yData. Resample with replacement
            %#iteration times to get a distribution of the rhos.
            %Top: histogram of the bootstrapped rho (coefficient of
            %correlation) -- %commented out right now.
            %Bottom: 95%CI, mean and each bootstrapped value of rho
            %For each pairs of x and y column, get 1 column of 2 figures (2rows). E.g., xData column 2 and yData column 3 will
            %have 2 plots in (5:6,2)
            % [OUTPUTARGS]: none. 
            % [InputArgs]:    
            %    - xData: 2D matrix of data, subjects x columns
            %    - yData: 2D matrix of data to plot on the yaxis, subjects x columns
            %    - xlabels: cell array of strings for xlabel (per column)
            %    - ylabels: cell aray of strings for ylabel (per row)
            %    - saveResAndFigure: boolean whether or not to save the
            %            figure
            %    - savePath: the full path (directory and name) to save
            %            the figures.
            %    - iterations: OPTIONAL. Default 1000. integer number
            %    specifcying how many iterations of resample to run.
            %    - controlVar: OPTIONAL. 2D matrix of data to control for in a
            %            partial correlation, in subjects x variableColumns
            %    - controlVarXIdx: OPTIONAL. integer or integer array, if the
            %            controlled variable is part of the xData, corresponding
            %            data columns in xData that's the contrlled var. Pass
            %            NaN if the controlled var is not part of the xData.
            %   - controlVarYIdx: OPTIONAL. integer or integer array, if the
            %            controlled variable is part of the yData, corresponding
            %            data columns in xData that's the contrlled var. Pass
            %            NaN or omit the arg if the controlled var is not part of the yData.
            %   - controlVarYIdx: OPTIONAL. figure handle. If not
            %   provided, or provide empty, create a new one.
            if nargin < 8 || isempty(iterations) %iterations default.
                iterations = 1000;
            end
            if nargin >= 9 && ~isempty(controlVar) && ~any(isnan(controlVar),'all')%partial correlation
                bootStrpStatement = "bootstat = bootstrp(iterations, @(x,y, controlVar)partialcorr(x,y,controlVar,'Type','Spearman','Rows','complete'),xToPlot,yToPlot, controlVar);";
            else %regular correlation
                bootStrpStatement = "bootstat = bootstrp(iterations, @(x,y)corr(x,y,'Type','Spearman','Rows','complete'),xToPlot,yToPlot);";
            end
            if nargin < 12 || isempty(f)
                f = figure('units','normalized','outerposition',[0 0 1 1]);%('Position', get(0, 'Screensize'));
            end
            for rowIdx = 1:size(yData,2) %row
                for colIdx = 1:size(xData,2) %col
                    xToPlot = xData(:,colIdx); %put fnir on the x-axis
                    yToPlot = yData(:,rowIdx);
                    eval(bootStrpStatement);
%                     bootstat = bootstrp(iterations, @(x,y)corr(x,y,'Type','Spearman','Rows','complete'),xToPlot,yToPlot);
%                     subplot(size(yData,2)*2,size(xData,2),(rowIdx-1)*size(xData,2)*2+colIdx);
%                     hold on; %row 1
%                     histogram(bootstat); title([xlabels{colIdx},' ',ylabels{rowIdx}])
%                     subplot(size(yData,2)*2,size(xData,2),(rowIdx*2-1)*size(xData,2)+colIdx);  %row 2
                    if size(yData,2) > 1 || size(xData,2) > 1
                        subplot(size(yData,2),size(xData,2),(rowIdx-1)*size(xData,2)+colIdx); %row 1
                    end
                    PlotHelper.plotCI(1,bootstat,'k',['\rho(' xlabels{colIdx},',',ylabels{rowIdx} ')'],true, true)
                    if size(yData,2) == 1 %1 row only use y label (have enough height)
                        ylabel(['\rho(' xlabels{colIdx},',',ylabels{rowIdx} ')']);
                    else
                        title(['\rho(' xlabels{colIdx},',',ylabels{rowIdx} ')']);
                    end
                end
            end
%             legend();
            sgtitle(titleStr)
            set(findall(gcf,'-property','FontSize'),'FontSize',13)
            if saveResAndFigure
                set(gcf,'renderer','painters')
                saveas(f,[savePath '.fig'])
%                 s = findobj('type','legend'); delete(s)
                saveas(f,[savePath '.png'])
            end
        end
        
        function [SigMdlSum] = compileModelSummaries(mdl, SigMdlSum)
            % Generate and save summaries for linear models into SigMdlSum.
            %
            % [OUTPUTARGS]: SigMdlSum: a cell array of model summaries with
            % table header in the first row. 
            %
            % [InputArgs]:    
            %    - mdl: A matlab linear model object.
            %    - SigMdlSum: OPTIONAL. the model summary arrays to append the data
            %    to. The same object with new entries will be the returned. If not provided, will create a new one and return it. 
            alpha = 0.05;
%             trendingThreshold = 0.1;
            if nargin < 2 %no existing mdlSum array provided, intialize, first row is header.
                SigMdlSum = {'ResponseName','Predictors','SigRegressor','R2Ordinary','R2Adjusted','CogVarBeta','pValue','ResidualAbnormal(0Normal)','LackOfFit(1lack)','Model'};
            end
%             if nargin < 3 %no existing mdlSum array provided, intialize, first row is header.
%                 trendingMdlSum = {'ResponseName','Predictors','SigRegressor','R2Ordinary','R2Adjusted','ResidualAbnormal(0Normal)'};
%             end
            
            mdlStats=anova(mdl,'summary');
%             if mdlStats{'Model','pValue'} > 0.2
%                 return 
%             end
            
            if ismember('. Lack of fit',mdlStats.Row) && mdlStats{'. Lack of fit','pValue'} <= alpha
                lackOfFit = true;
            else
                lackOfFit = false;
            end
            coefPVal = mdl.Coefficients.pValue;
            sigCoef = mdl.CoefficientNames(coefPVal<= alpha);
            sigCoef = strjoin(sigCoef);
%             [h,~] = kstest(mdl.Residuals.Studentized);
            h=nan;
            cogVarIdx = contains(mdl.CoefficientNames,{'traila','trailb','MMSE_total'});
            if any(cogVarIdx)
                cogVarBeta = mdl.Coefficients{mdl.CoefficientNames(cogVarIdx),'Estimate'};
            else
                cogVarBeta = nan;
            end
            
            SigMdlSum(end+1,:) = {mdl.Formula.ResponseName,mdl.Formula.LinearPredictor,sigCoef,mdl.Rsquared.Ordinary,mdl.Rsquared.Adjusted,...
                cogVarBeta,mdlStats{'Model','pValue'},h,lackOfFit,mdl};
        end
        
        function tightMargin(ax)
            % Decrease the margin size of the given figure. Adapted from https://www.mathworks.com/matlabcentral/answers/369399-removing-the-grey-margin-of-a-plot
            %
            % [OUTPUTARGS]: none
            %
            % [InputArgs]:    
            %    - ax: figure handle, usually get by calling gca on the
            %    active figure.
            outerpos = ax.OuterPosition;
            ti = ax.TightInset; 
            left = outerpos(1) + 2*ti(1);
            bottom = outerpos(2)+ ti(2);
            ax_width = outerpos(3) - 3*ti(1) - 3*ti(3); 
            ax_height = outerpos(4) - ti(2) - ti(4);
            %to have no margin at all, use the following
%             left = outerpos(1) + ti(1);
%             bottom = outerpos(2) + ti(2);
%             ax_width = outerpos(3) - ti(1) - ti(3); %make left and right exactly the same as the figure
%             ax_height = outerpos(4) - ti(2) - ti(4);
            ax.Position = [left bottom ax_width ax_height];
        end
    end
end


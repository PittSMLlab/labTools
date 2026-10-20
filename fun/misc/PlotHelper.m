classdef PlotHelper
    %PLOTHELPER Collection of static methods for common research plots.
    %
    %   Provides static methods for correlation scatter plots with
    % regression lines, bar plots with individual subject overlays,
    % confidence interval plots, bootstrap Spearman correlation tests,
    % regression diagnostic plots, and figure margin tightening.
    % Optional arguments may be passed as [] or NaN to skip them.
    %
    % PlotHelper properties:
    %   colorOrder - default MATLAB colors followed by nine extra colors
    %
    % PlotHelper static methods:
    %   computeAndPlotCorrelations - compute and plot pairwise correlations
    %   plotCorrelations           - plot precomputed correlations
    %   plotSingleCorrelation      - plot one correlation on current axes
    %   barPlotWithIndiv           - bar plot with individual subjects
    %   plotCI                     - plot a mean and 95% CI
    %   plotRegression             - plot a regression model's fit
    %   plotRegressionDiagnostics  - six-panel regression diagnostics
    %   plotBootStrapCorrSpearman  - bootstrapped Spearman correlations
    %   compileModelSummaries      - tabulate linear model summaries
    %   tightMargin                - shrink figure margins
    %
    % $Author: Shuqi Liu $  $Date: 2022/08/22$  $Revision: 0.1 $
    % Copyright: Sensorimotor Learning Laboratory 2022
    %
    % Toolbox Dependencies:
    %   Statistics and Machine Learning Toolbox
    %
    % See also NANJACKKNIFE.

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

        function f = computeAndPlotCorrelations(xData, yData, ...
            subjectIDs, titleStr, xlabels, ylabels, saveResAndFigure, ...
            savePath, xylabelOnceOnly, controlVar, controlVarXIdx, ...
            controlVarYIdx,performKws, plotDiagnostic)
            %COMPUTEANDPLOTCORRELATIONS Plot pairwise correlations.
            %
            %   Computes Pearson and Spearman correlations (partial
            % correlations when CONTROLVAR is given) between every column
            % of XDATA and every column of YDATA, then draws them as a
            % grid of scatter subplots through PLOTCORRELATIONS. NaNs are
            % excluded pairwise and a warning reports how many were found.
            %
            % Inputs:
            %   xData            - subjects x columns matrix, plotted on the
            %                      x axis
            %   yData            - subjects x columns matrix, plotted on the
            %                      y axis
            %   subjectIDs       - cell array of subject IDs, used in the
            %                      legend
            %   titleStr         - main title for all subplots
            %   xlabels          - cell array of x labels (one per column)
            %   ylabels          - cell array of y labels (one per row)
            %   saveResAndFigure - true to save the figure
            %   savePath         - full path (directory and name) of the
            %                      saved figure
            %   xylabelOnceOnly  - true to label only the bottom row and
            %                      first column of the grid; false to label
            %                      every subplot
            %   controlVar       - (optional) subjects x variables matrix to
            %                      control for (partial correlation)
            %   controlVarXIdx   - (optional) column(s) of XDATA that hold
            %                      the controlled variable; NaN if not part
            %                      of XDATA
            %   controlVarYIdx   - (optional) column(s) of YDATA that hold
            %                      the controlled variable; NaN or omit if
            %                      not part of YDATA
            %   performKws       - (optional) true to run kruskalwallis
            %                      instead of correlations; default false
            %   plotDiagnostic   - (optional) true to also plot residual
            %                      diagnostics of the fitted regressions;
            %                      default false
            %
            % Outputs:
            %   f - handle of the figure (a full figure with subplots)
            %
            % Example:
            %   f = PlotHelper.computeAndPlotCorrelations(xs, ys, ...
            %       {'S01','S02'}, 'Title', {'xlabel1','xlabel2'}, ...
            %       {'ylabel1','ylabel2'}, true, ...
            %       'C:/Documents/myfigure.png', true);
            %
            % Toolbox Dependencies:
            %   Statistics and Machine Learning Toolbox (corr, partialcorr)
            %
            % See also PLOTHELPER.PLOTCORRELATIONS,
            % PLOTHELPER.PLOTSINGLECORRELATION.

            %no performKws given
            if nargin <= 12 || isnan(performKws) || isempty(performKws)
                performKws = false;
            end
            %no plotDiagnostic given
            if nargin <= 13 || isnan(plotDiagnostic) || isempty(performKws)
                plotDiagnostic = false;
            end
            % calclulate partial corr if controlVar is provided, otherwise
            % regular
            % correlation.
            numNans = sum(isnan(yData),'all') + sum(isnan(xData),'all');
            if numNans
                warning([num2str([numNans]) ...
                    ' NAN Value found in the data. Will only use ' ...
                    'non-nan values to compute correlation'])
            end
            if nargin >= 10 && ~isempty(controlVar) && ...
                    ~any(isnan(controlVar),'all')
                [rho,p] = partialcorr(xData, yData,controlVar,'Rows', ...
                    'complete'); %resulting size x by y
                [rhoSpearman,pSpearman] = ...
                    partialcorr(xData, yData,controlVar,'Type', ...
                    'Spearman','Rows','complete');
                %the variable controlled is part of the xData.
                if nargin >= 11 && ~isempty(controlVarXIdx) && ...
                        ~any(isnan(controlVarXIdx),'all')
                    [rho(controlVarXIdx,:),p(controlVarXIdx,:)] = ...
                        corr(controlVar, yData,'Rows','complete');
                    [rhoSpearman(controlVarXIdx,:), ...
                        pSpearman(controlVarXIdx,:)] = corr(controlVar, ...
                        yData,'Type','Spearman','Rows','complete');
                end
                %the variable controlled is part of the yData.
                if nargin >= 12 && ~isempty(controlVarYIdx) && ...
                        ~any(isnan(controlVarYIdx),'all')
                    [rho(:,controlVarYIdx),p(:,controlVarYIdx)] = ...
                        corr(xData, controlVar,'Rows','complete');
                    [rhoSpearman(:,controlVarYIdx), ...
                        pSpearman(:,controlVarYIdx)] = corr(xData, ...
                        controlVar,'Type','Spearman','Rows','complete');
                end
            else
                [rho,p] = corr(xData,yData,'Rows','complete');
                [rhoSpearman,pSpearman] = ...
                    corr(xData,yData,'Type','Spearman','Rows','complete');
            end
            f = PlotHelper.plotCorrelations(xData, yData, subjectIDs, ...
                titleStr, xlabels, ylabels, saveResAndFigure, savePath, ...
                xylabelOnceOnly,rho, p, rhoSpearman, pSpearman, ...
                performKws, plotDiagnostic);
        end

        function f = plotCorrelations(xData, yData, subjectIDs, ...
            titleStr, xlabels, ylabels, saveResAndFigure, savePath, ...
            xylabelOnceOnly,rho, p, rhoSpearman, pSpearman, performKws, ...
            plotDiagnostic)
            %PLOTCORRELATIONS Plot correlations as a subplot grid.
            %
            %   Draws one scatter subplot per x-column / y-column pair using
            % the correlation coefficients and p-values supplied by the
            % caller. Use COMPUTEANDPLOTCORRELATIONS to compute them as
            % well, and PLOTSINGLECORRELATION to plot a single pair.
            %
            % Inputs:
            %   xData ... xylabelOnceOnly - as in COMPUTEANDPLOTCORRELATIONS
            %   rho         - Pearson correlation coefficients, Y x X
            %                 (number of yData columns by number of xData
            %                 columns)
            %   p           - p-values of rho, same size
            %   rhoSpearman - Spearman correlation coefficients, same size
            %   pSpearman   - p-values of rhoSpearman, same size
            %   performKws  - (optional) true to run a kruskalwallis test
            %                 instead of correlations (for categorical
            %                 data); default false
            %   plotDiagnostic - (optional) true to plot residual
            %                    diagnostics of the
            %                 fitted regressions; default false
            %
            % Outputs:
            %   f - handle of the figure (a full figure with subplots)
            %
            % Example:
            %   f = PlotHelper.plotCorrelations(xs, ys, ...
            %       {'S01','S02'}, 'Title', {'xlabel1','xlabel2'}, ...
            %       {'ylabel1','ylabel2'}, true, ...
            %       'C:/Documents/myfigure.png', true, rhoMatrix, ...
            %       pMatrix, rhoSpearmanMatrix, pSpearmanMatrix);
            %
            % Toolbox Dependencies:
            %   Statistics and Machine Learning Toolbox (fitlm,
            % kruskalwallis)
            %
            % See also PLOTHELPER.COMPUTEANDPLOTCORRELATIONS,
            % PLOTHELPER.PLOTSINGLECORRELATION.

            %no performKws given
            if nargin <= 13 || isnan(performKws) || isempty(performKws)
                performKws = false;
            end
            if nargin <= 14 || isnan(plotDiagnostic) || ...
                    isempty(plotDiagnostic) %no plotDiagnostic given
                plotDiagnostic = false;
            end
            colorOrder = PlotHelper.colorOrder; %load colorOrder

            if plotDiagnostic
                %make diagnostic figure first. then the focus will be on
                %the regression plot to start with.
                fDiagnostic = figure('units','normalized', ...
                    'outerposition',[0 0 1 1]);
            end
            %('Position', get(0, 'Screensize'));
            f = figure('units','normalized','outerposition',[0 0 1 1]);
            %             markerOrder =
            %             {'o','+','*','^','x','_','|','.','d','s'};

            for rowIdx = 1:size(yData,2) %row
                for colIdx = 1:size(xData,2) %col
                    subplot(size(yData,2),size(xData,2), ...
                        (rowIdx-1)*size(xData,2)+colIdx); hold on;
                    axis square;
                    xToPlot = xData(:,colIdx); %put fnir on the x-axis
                    yToPlot = yData(:,rowIdx);
                    for subIdx = 1:length(subjectIDs)
                        colorIdx = rem(subIdx,size(colorOrder,1));
                        if colorIdx == 0 %avoid 0
                            colorIdx = size(colorOrder,1);
                        end
                        plot(xToPlot(subIdx),yToPlot(subIdx),'o', ...
                            'MarkerFaceColor',colorOrder(colorIdx,:), ...
                            'LineWidth',2,'MarkerSize',7,'DisplayName', ...
                            subjectIDs{subIdx},'MarkerEdgeColor','none');
                    end
                    % Do the regression with an intercept of 0 and plot the
                    % line
                    linFit = fitlm(xToPlot,yToPlot,'RobustOpts','on');
                    plotFitX = xlim;
                    %plot the line if spearman significant only; p(colIdx,
                    %rowIdx) < 0.1 ||
                    if pSpearman(colIdx, rowIdx) < 0.1
                        %plot the regression line only if the p-value for
                        %either test is <0.05
                        plotFitY = linFit.Coefficients.Estimate(2) * ...
                            plotFitX + linFit.Coefficients.Estimate(1);
                        %solid line for significant %plot the line if
                        %spearman significant only p(colIdx, rowIdx) < 0.05
                        %||
                        if pSpearman(colIdx, rowIdx) < 0.05
                            plot(xlim,plotFitY,'k','LineWidth',2.5, ...
                                'handleVisibility','off');
                        else %dashed line for trending.
                            plot(xlim,plotFitY,'k--','LineWidth',2.5, ...
                                'handleVisibility','off');
                        end
                    end
                    txtY = ylim;
                    if p(colIdx, rowIdx) < 0.05 %show the text in red
                        textColorPearson = 'r';
                    else
                        textColorPearson = 'k';
                    end
                    %show the text in red
                    if pSpearman(colIdx, rowIdx) < 0.05
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
                        text(plotFitX(1),txtY(2)-range(txtY)*0.35, ...
                            sprintf('K-W p=%.4f',kws),'FontSize',40, ...
                            'Color',textColorKws)
                    end
                    %0.15, 25 for top; 7 and .8 for btm
                    %                     text(plotFitX(1), ...
                    %    txtY(2)-range(txtY)*0.65, ...
                    %    sprintf('RobustR=%.2f', ...
                    %    linFit.Rsquared.Ordinary^0.5),'FontSize',40, ...
                    %    'Color',textColorPearson)
                    text(plotFitX(1),txtY(2)-range(txtY)*0.75, ...
                        sprintf('P:r=%.3f,p=%.4f',rho(colIdx, rowIdx), ...
                        p(colIdx, rowIdx)),'FontSize',40,'Color', ...
                        textColorPearson)
                    text(plotFitX(1),txtY(2)-range(txtY)*0.85, ...
                        sprintf('S:\\rho=%.3f,p=%.4f', ...
                        rhoSpearman(colIdx, rowIdx), ...
                        pSpearman(colIdx, rowIdx)),'FontSize',40, ...
                        'Color',textColorSpearman)
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
                        %Outliers are defined as elements more than three
                        %scaled MAD from the median.
                        outlierSubj = isoutlier(dataToPlot{1},'mean');
                        if any(outlierSubj)
                            fprintf('\n%s: Outlier in %s column %s', ...
                                titleStr, dataAxis, curLabel)
                            disp(subjectIDs(outlierSubj))
                        end
                        curLabel = ylabels{rowIdx};
                        dataAxis = 'Y';
                    end
                    clear dataToPlot curLabel outlierSubj dataAxis

                    %by default plot leverage and cook's D 2 diagnostic
                    %graph per regression (2 rows 1 column)
                    if plotDiagnostic
                        %options to plot:
                        %contour plot, if points fall outside of cook's d
                        %(have
                        %a high cook's d value), likely influential points.
                        % High leverage points are outliers in the x-space,
                        % they
                        %tend to have extreme values in one or more of the
                        %x’s
                        %or represent an unusual combo of x values.
                        %Cook’s distance is a weighted sum of terms(betaj
                        %betaj(-i)), function of the leverages and
                        %studentized residuals
                        %DFFITS quantify how much the fitted values change
                        %if the ith observation was deleted from the dataset
                        %DFBETAs quantify how much each coefficient would
                        %change (in s.e. units) if the ith observation was
                        %deleted from the dataset
                        figure(fDiagnostic);
                        subplot(size(yData,2)*2,size(xData,2), ...
                            (rowIdx-1)*size(xData,2)*2+colIdx);
                        plotDiagnostics(linFit);
                        ref_leverage = ...
                            2*linFit.NumCoefficients/linFit.NumObservations;
                        high_leveragePts = ...
                            linFit.Diagnostics.Leverage > ref_leverage;
                        fprintf([titleStr '\nX=' xlabels{colIdx} ', Y=' ...
                            ylabels{rowIdx} '\nHigh leverage points ' ...
                            'index: ' num2str( ...
                            find(high_leveragePts)') ' Subjects: '])
                        disp(subjectIDs(high_leveragePts));
                        %plot on row 2
                        subplot(size(yData,2)*2,size(xData,2), ...
                            (rowIdx*2-1)*size(xData,2)+colIdx);
                        plotDiagnostics(linFit,'cookd');
                        ref_cookd = ...
                            3*mean(linFit.Diagnostics.CooksDistance, ...
                            'omitnan');
                        high_cookdPts = ...
                            linFit.Diagnostics.CooksDistance > ref_cookd;
                        fprintf([ ...
                            '\nHigh cooks d (influential) points ' ...
                            'index: ' num2str( ...
                            find(high_cookdPts)') ' Subjects: '])
                        disp(subjectIDs(high_cookdPts))
                        %                     subplot(1,3,3);
                        %                     plotDiagnostics(linFit, ...
                        %    'contour');
                        %                     subplot(1,3,3);
                        %                     plotDiagnostics(linFit, ...
                        %    'dfbetas');
                        %                     subplot(2,2,4);
                        %                     plotDiagnostics(linFit, ...
                        %    'dffits');
                        figure(f);
                        linFit = fitlm(xToPlot,yToPlot,'RobustOpts','on');
                        fprintf('\nr from robust regression: ')
                        disp((linFit.Rsquared.Ordinary).^0.5)
                    end
                end
            end
            legend()
            %     sgtitle(['Correlation Btw Cognitive Measures and '
            %     scaleString])
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
                %                 s = findobj('type','legend'); delete(s)
                saveas(f, [savePath '.png'])
                if plotDiagnostic
                    figure(fDiagnostic)
                    set(gcf,'renderer','painters')
                    saveas(f, [savePath 'Diagnostic.fig'])
                    saveas(f, [savePath 'Diagnostic.png'])
                end
            end
        end

        function plotSingleCorrelation(xToPlot, yToPlot, subjectIDs, ...
            xlabelString, ylabelString,partialVar, pointColor, ...
            groupName, textLocRatio, rmOutlier, plotRegDiagnostics, ...
            spearmanOnly)
            %PLOTSINGLECORRELATION Plot one correlation on the current axes.
            %
            %   Scatter-plots YTOPLOT against XTOPLOT on the current axes
            % (open and configure a subplot first), with the Pearson and
            % Spearman results and the normality check printed on the
            % plot. Draws on the existing figure.
            %
            % Inputs:
            %   xToPlot            - row vector plotted on the x axis
            %   yToPlot            - row vector plotted on the y axis
            %   subjectIDs         - cell array of subject IDs, used in the
            %                        legend
            %   xlabelString       - (optional) x axis label; default ''
            %   ylabelString       - (optional) y axis label; default ''
            %   partialVar         - (optional) row vector to control for
            %                        (partial correlation)
            %   pointColor         - (optional) any MATLAB color (e.g., 'k'
            %                        or an RGB row such as [0.15 0.15 0.15])
            %                        for the scatter points; default rotates
            %                        through PlotHelper.colorOrder
            %   groupName          - (optional) name of the data group, used
            %                        in the legend, the normality/outlier
            %                        printout and the title; default ''
            %   textLocRatio       - (optional) vertical position of the
            %                        result text, at (ymax - textLocRatio *
            %                        yRange); three lines (normality,
            %                        Pearson, Spearman); default 0.7
            %   rmOutlier          - (optional) true to remove outliers in x
            %                        or y before correlating; default false
            %   plotRegDiagnostics - (optional) true to plot the diagnostics
            %                        of the linear model fit; default false
            %   spearmanOnly       - (optional) true to report Spearman only
            %
            % Outputs:
            %   None. Draws on the current axes.
            %
            % Example:
            %   PlotHelper.plotSingleCorrelation(xRow, yRow, subjectIDs, ...
            %       'AGI W2', '(Pre-Post)/Pre earlyAda', [], 'b', 'OA', ...
            %       0.7, false, false, true);
            %
            % Toolbox Dependencies:
            %   Statistics and Machine Learning Toolbox (fitlm, partialcorr,
            % corr)
            %
            % See also PLOTHELPER.PLOTCORRELATIONS.
            hold on;
            if nargin < 4 || (isnumeric(ylabelString) && ...
                    any(isnan(xlabelString))) || (isempty(xlabelString))
                xlabelString = '';
            end

            if nargin < 5 || (isnumeric(ylabelString) && ...
                    any(isnan(ylabelString))) || (isempty(ylabelString))
                ylabelString = '';
            end

            if nargin < 11 || isempty(plotRegDiagnostics)
                %default to false, don't remove data.
                plotRegDiagnostics = false;
            end

            if nargin < 10 || isempty(rmOutlier)
                rmOutlier = false; %default to false, don't remove data.
            end

            if nargin < 8 || any(isnan(groupName)) || (isempty(groupName))
                groupName = ''; %give empty for default.
            end

            if rmOutlier
                outliersFound = isoutlier(xToPlot) | isoutlier(yToPlot);
                fprintf(['Outliers found: %s. They will be removed ' ...
                    'from the scatter plot and correlations\n'], ...
                    strjoin(subjectIDs(outliersFound),' '))
                %over lay these points to mark them with X, color in grey is
                %no color provided, or use the provided color if there is
                %any.
                if nargin >= 7 && (~isnan(pointColor)) && ...
                        (~isempty(pointColor))
                    %the X symbol the markerfacecolor doesn't make a
                    %difference
                    scatter(xToPlot(outliersFound), ...
                        yToPlot(outliersFound),55,'Marker','x', ...
                        'LineWidth',0.5,'MarkerEdgeColor',pointColor, ...
                        'DisplayName','excluded')
                else
                    scatter(xToPlot(outliersFound), ...
                        yToPlot(outliersFound),55,'Marker','x', ...
                        'LineWidth',0.5,'MarkerEdgeColor',[0.5 0.5 0.5], ...
                        'DisplayName','excluded')
                end
                xToPlot = xToPlot(~outliersFound);
                yToPlot = yToPlot(~outliersFound);
                %remove corresponding rows in the partial control var to for
                %size consistency
                if all(~isnan(partialVar)) && (~isempty(partialVar))
                    partialVar = partialVar(:,~outliersFound);
                end
            end

            if nargin >= 7 && (isnumeric(pointColor) && ...
                    ~any(isnan(pointColor))) && (~isempty(pointColor))
                scatter(xToPlot,yToPlot,35,'MarkerEdgeColor','k', ...
                    'LineWidth',0.5,'MarkerFaceColor',pointColor, ...
                    'DisplayName',groupName)
                lineColor = pointColor;
            else
                colorOrder = PlotHelper.colorOrder;
                colorLength = size(colorOrder, 1);
                for dIdx = 1:length(xToPlot)
                    scatter(xToPlot(dIdx),yToPlot(dIdx),35, ...
                        'MarkerFaceColor', ...
                        colorOrder(mod(dIdx-1, colorLength)+1,:), ...
                        'MarkerEdgeColor','k','DisplayName', ...
                        subjectIDs{dIdx},'LineWidth',0.5);
                end
                lineColor = [0.5 0.5 0.5];
            end

            numNans = sum(isnan(xToPlot),'all') + sum(isnan(yToPlot),'all');
            if numNans
                warning([num2str(numNans) ...
                    ' NAN Value found in the data. Will only use ' ...
                    'non-nan values to compute correlation'])
            end

            if nargin >= 6 && all(~isnan(partialVar)) && ...
                    (~isempty(partialVar))
                [rho,p] = partialcorr(xToPlot',yToPlot',partialVar', ...
                    'Rows','complete');
                [rhoSpearman,pSpearman] = ...
                    partialcorr(xToPlot',yToPlot',partialVar','Type', ...
                    'Spearman','Rows','complete');
            else
                [rho,p] = corr(xToPlot',yToPlot','Rows','complete');
                [rhoSpearman,pSpearman] = ...
                    corr(xToPlot',yToPlot','Type','Spearman','Rows', ...
                    'complete');
            end

            %check assumptions for pearson's corr: no outlier, and data is
            %bivariate normal (harder to test, so test individual normal)

            if plotRegDiagnostics
                %save a handle to the current axes (could be the whole
                %figure or one subplot)
                axesOriginal = gca;
                figure(); %start a new figure
                [hx, px] = utils.normalityTestWithFig(xToPlot, ...
                    [groupName ' ' xlabelString], subplot(2,2,1), ...
                    subplot(2,2,2), [], plotRegDiagnostics);
                [hy, py] = utils.normalityTestWithFig(yToPlot, ...
                    [groupName ' ' ylabelString], subplot(2,2,3), ...
                    subplot(2,2,4), [], plotRegDiagnostics);
                %when done bring focus  to the original canvas and axes
                %again
                axes(axesOriginal);
            else
                %when not plotting, provide [] for subplot axes bc
                %otherwise will create new subplot on the current canvas
                [hx, px] = utils.normalityTestWithFig(xToPlot, ...
                    [groupName ' ' xlabelString], [], [], [], ...
                    plotRegDiagnostics);
                [hy, py] = utils.normalityTestWithFig(yToPlot, ...
                    [groupName ' ' ylabelString], [], [], [], ...
                    plotRegDiagnostics);
            end

            %put the correlation result on the figure.
            txtY = ylim;
            if hx || hy
                %grey if failed assumptions.
                textColorPearson = [0.5 0.5 0.5];
            else
                if p < 0.05 %show the text in red
                    textColorPearson = 'r';
                else
                    textColorPearson = 'k';
                end
            end

            if pSpearman < 0.05 %show the text in red
                textColorSpearman = 'r';
            else
                textColorSpearman = 'k';
            end

            linFit = fitlm(xToPlot,yToPlot);
            plotFitX = xlim;
            if ((hx || hy || spearmanOnly) && pSpearman < 0.1) || ...
                    ((~hx) && (~hy) && p < 0.1 && (~spearmanOnly))
                %if specified spearmanOnly will plot corr if pSearman < 0.1
                %regardless of normality check, and regardless of if
                %peaerson is < 0.1. Otherwise plot when pearson  is
                %significant with normal data,
                %or when spearman is significant with non-normal datam
                plotFitY = linFit.Coefficients.Estimate(2) * plotFitX + ...
                    linFit.Coefficients.Estimate(1);
                %solid line for significant
                if ((hx || hy || spearmanOnly) && pSpearman < 0.05) || ...
                        ((~hx) && (~hy) && p < 0.05 && (~spearmanOnly))
                    plot(xlim,plotFitY,'LineWidth',2.5, ...
                        'handleVisibility','off','Color',lineColor);
                else %dashed line for trending.
                    plot(xlim,plotFitY,'--','LineWidth',2.5, ...
                        'handleVisibility','off','Color',lineColor);
                end
            end

            if nargin >= 9 && all(~isnan(textLocRatio)) && ...
                    (~isempty(textLocRatio))
                text(plotFitX(1),txtY(2)-range(txtY)*(textLocRatio-0.1), ...
                    sprintf('%s DataNormal:%d',groupName,(~hx) && ...
                    (~hy)),'FontSize',12,'Color','k')
                %show spearman only, normality failed,
                if hx || hy || spearmanOnly
                    %this is right thing to do, show 1 result only but in
                    %exploration phase will keep both texts on
                    text(plotFitX(1), ...
                        txtY(2)-range(txtY)*(textLocRatio+0.1), ...
                        sprintf('%s S:\\rho=%.3f,p=%.3f',groupName, ...
                        rhoSpearman,pSpearman),'FontSize',12,'Color', ...
                        textColorSpearman)
                else %show pearson when normality satisfied
                    text(plotFitX(1),txtY(2)-range(txtY)*textLocRatio, ...
                        sprintf('%s P:r=%.3f,p=%.3f',groupName,rho,p), ...
                        'FontSize',12,'Color',textColorPearson)
                end
            else
                %0.15, 25 for top; 7 and .8 for btm
                text(plotFitX(1),txtY(2)-range(txtY)*0.6, ...
                    sprintf('%s DataNormal:%d',groupName,(~hx) && ...
                    (~hy)),'FontSize',12,'Color','k')
                %show spearman only, normality failed
                if hx || hy || spearmanOnly
                    text(plotFitX(1),txtY(2)-range(txtY)*0.8, ...
                        sprintf('%s S:\\rho=%.3f,p=%.3f',groupName, ...
                        rhoSpearman,pSpearman),'FontSize',12,'Color', ...
                        textColorSpearman)
                else%show pearson when normality satisfied
                    text(plotFitX(1),txtY(2)-range(txtY)*0.7, ...
                        sprintf('%s P:r=%.3f,p=%.3f',groupName,rho,p), ...
                        'FontSize',12,'Color',textColorPearson)
                end
            end

            %             xlim(plotFitX)
            axis square

            xlabel(xlabelString)
            ylabel(ylabelString)

            %             if plotRegDiagnostics
            %                 %plot these in the end in new figures bc this
            %                 function
            %                 %doesn't create a canvas and plot on existing
            %                 canvas
            %                 %instead so don't want to lose focus to
            %                 original canvas
            %                 %untill we are donw drawing there.
            % %                 figure();
            % %                 plotDiagnostics(linFit);
            % %                 sgtitle([groupName ' ' xlabelString ' vs '
            % ylabelString]);
            % %                 PlotHelper.plotRegressionDiagnostics(linFit,
            % yToPlot, false,'') %no info at this level to save, so don't
            % save it for now.
            %                 %plot the histrogram of the data to visualize
            %                 normality
            %                 figure(); subplot(2,2,1)
            %                 qqplot(xToPlot); title([groupName ' '
            %                 xlabelString]);
            %                 subplot(2,2,2);
            %                 histogram(xToPlot);title([groupName ' '
            %                 xlabelString]);
            %                 subplot(2,2,3); qqplot(yToPlot);
            %                 title([groupName ' ' ylabelString]);
            %                 subplot(2,2,4);
            %                 histogram(yToPlot);title([groupName ' '
            %                 ylabelString]);
            %             end
        end

        function barPlotWithIndiv(dataToPlot, subjectIDs, xlabelStrings, ...
            ylabelString, titleString, saveResAndFigure, savePath, f, ...
            addJitter, MarkerColor,connectLine,performTtest)
            %BARPLOTWITHINDIV Bar plot with individual subjects overlaid.
            %
            %   Draws one bar per row of DATATOPLOT and overlays each
            % subject's points, connected by a line across bars (when
            % CONNECTLINE is true). Plots on the given figure, or on a new
            % one.
            %
            % Inputs:
            %   dataToPlot       - bars (categories) x subjects matrix
            %   subjectIDs       - cell array of subject IDs, used in the
            %                      legend
            %   xlabelStrings    - cell array of x tick labels
            %   ylabelString     - y axis label
            %   titleString      - plot title
            %   saveResAndFigure - true to save the figure
            %   savePath         - full path (directories and file name) of
            %                      the saved figure, used if
            %                      saveResAndFigure is true
            %   f                - (optional) figure handle; a new figure if
            %                      omitted
            %   addJitter        - (optional) true to jitter the points so
            %                      similar values stay visible; default
            %                      false
            %   MarkerColor      - (optional) any MATLAB color (e.g., 'k' or
            %                      an RGB triplet); default rotates through
            %                      PlotHelper.colorOrder
            %   connectLine      - (optional) true to connect each subject's
            %                      points across bars; default true
            %   performTtest     - (optional) true to run a paired ttest
            %                      when there are two rows of data; default
            %                      true
            %
            % Outputs:
            %   None.
            %
            % Examples:
            %   PlotHelper.barPlotWithIndiv(data, {'S01','S02'}, ...
            %       {'tick1','tick2'}, 'ylabel', 'title', true, ...
            %       'C:/document/saveMyFig.png');
            %   % Jitter the points and do not connect them:
            %   PlotHelper.barPlotWithIndiv(data, {'S01','S02'}, ...
            %       'xlabel', 'ylabel', 'title', true, ...
            %       'C:/document/saveMyFig.png', figureHandle, ...
            %       true, [], false);
            %
            % Toolbox Dependencies:
            %   Statistics and Machine Learning Toolbox (ttest)
            %
            % See also PLOTHELPER.PLOTCI.

            %no figure handle provided, create a new figure; if figure is
            %provided, simply plot
            if nargin < 8 || isempty(f) || isnan(double(f))
                %('Position', get(0, 'Screensize'));
                f = figure('units','normalized','outerposition',[0 0 1 1]);
            end
            if nargin < 9 || isempty(addJitter) || isnan(addJitter)
                addJitter = false;
            end
            if nargin < 11 || isempty(connectLine) || ...
                    isnan(connectLine) || connectLine
                markerSymbol = '.-'; %default connect line
            else %specified not connect line, plot symbol only.
                markerSymbol = '.';
            end
            if nargin < 12 || isempty(performTtest) || isnan(performTtest)
                performTtest = true;
            end
            colorOrder = PlotHelper.colorOrder;
            colorLength = size(colorOrder, 1);
            %in order: pre, training, post
            avgPerf = mean(dataToPlot, 2, 'omitnan');
            %2nd arg is weight, 0 means equal weight
            stdBarHeight = std(dataToPlot, 0, 2, 'omitnan');
            hold on;
            bar(avgPerf,'FaceColor','none','LineWidth',5,'DisplayName', ...
                'Avg')
            xticks(1:length(avgPerf));
            xticklabels(xlabelStrings);
            er = errorbar(1:length(avgPerf),avgPerf,stdBarHeight, ...
                stdBarHeight,'DisplayName','SD');
            er.Color = [0 0 0];
            er.LineStyle = 'none';
            er.LineWidth = 5;
            for dIdx = 1:length(subjectIDs)
                %shifts individual data with some jitter to see overlapping
                %data points
                if addJitter
                    jitter = (rand-0.5)./2;
                %default just shift all data slightly to the side of the
                %error bar.
                else
                    jitter = 0.1;
                end
                if nargin >= 10 &&  ~isempty(MarkerColor) && ...
                        ~any(isnan(MarkerColor))
                    plot([1:length(avgPerf)]+jitter,dataToPlot(:,dIdx)', ...
                        markerSymbol,'Color',MarkerColor,'LineWidth', ...
                        2.5,'MarkerSize',17,'DisplayName',subjectIDs{dIdx});
                else
                    plot([1:length(avgPerf)]+jitter,dataToPlot(:,dIdx)', ...
                        markerSymbol,'Color', ...
                        colorOrder(mod(dIdx-1, colorLength)+1,:), ...
                        'LineWidth',2.5,'MarkerSize',17,'DisplayName', ...
                        subjectIDs{dIdx});
                end
            end
            legend();%,'Location','bestoutside') %legend on 2nd plot only
            ylabel(ylabelString)

            if length(avgPerf) == 2 && performTtest %perform t-tests
                %this is test for x-y = 0
                [h,p] = ttest(dataToPlot(1,:)',dataToPlot(2,:)');
                txtY = ylim;
                if p < 0.05
                    textColor = 'r';
                else
                    textColor = 'k';
                end
                text(2.3,txtY(2)-range(txtY)*0.80,sprintf('T:p=%.3f',p), ...
                    'FontSize',20,'Color',textColor);
            end
            title(titleString)
            set(findall(gcf,'-property','FontSize'),'FontSize',25)
            if saveResAndFigure
                set(gcf,'renderer','painters')
                saveas(f,savePath)
                %                 s = findobj('type','legend'); delete(s)
                saveas(f,[savePath '.png'])
            end
        end

        function plotCI(x, y, lineColor, dataLabel, showMeanCILegend, ...
            colorNonZeroRed, typeOfCI)
            %PLOTCI Plot the confidence interval of a data vector.
            %
            %   Plots the mean and 95% confidence interval of Y at position
            % X on the current figure (no new canvas is created) and
            % prints the range (min, max), mean and 95% CI. Adapted from
            % MATLAB Answers 159417; see also paramci of
            % prob.NormalDistribution.
            %
            % Inputs:
            %   x                - position along the x axis
            %   y                - column vector of values to summarize
            %   lineColor        - any MATLAB color (e.g., 'k' or an RGB row
            %                      in [0, 1])
            %   dataLabel        - display name of the y variable
            %   showMeanCILegend - true to show the legend of the CI and the
            %                      mean
            %   colorNonZeroRed  - (optional) true to color CIs that exclude
            %                      0 red, ignoring LINECOLOR; default false.
            %                      Use NaN or [] to skip
            %   typeOfCI         - (optional) 'tinv' (default) for the 95%
            %                      interval computed from the data with
            %                      tinv, or '95data' for the central 95% of
            %                      the data (e.g., after bootstrapping,
            %                      where tinv is not needed again)
            %
            % Outputs:
            %   None.
            %
            % Example:
            %   for ii = 1:10
            %       PlotHelper.plotCI(ii, yMatrix(:, ii), 'k', ...
            %           labels{ii}, false, true, '95data');
            %   end
            %
            % Toolbox Dependencies:
            %   Statistics and Machine Learning Toolbox (tinv, prctile)
            %
            % See also PLOTHELPER.BARPLOTWITHINDIV.
            if nargin < 6 || ~exist('colorNonZeroRed','var') || ...
                    any(isnan(colorNonZeroRed)) || isempty(colorNonZeroRed)
                colorNonZeroRed = false;
            end
            if nargin < 7 || ~exist('typeOfCI','var') || ...
                    any(isnan(typeOfCI)) || isempty(typeOfCI)
                typeOfCI = 'tinv';
            end
            hold on;
            N = length(y);
            yMean = mean(y);
            %this is the default 95% of CI computed from the data and its
            %spread
            if strcmp(typeOfCI,'tinv')
                ySEM = std(y)/sqrt(N);
                % Calculate 95% Probability Intervals Of t-Distribution
                CI95 = tinv([0.025 0.975], N-1);
                yCI95 = bsxfun(@times, ySEM, CI95(:));
                yCI95 = yCI95 + yMean;
            elseif strcmp(typeOfCI,'95data')
                yCI95 = prctile(y, [2.5 97.5]);
            else
                error(['\nInvalid typeOfCI plotted. Only tinv or ' ...
                    '95data is accepted.\n'])
            end
            %             yCI95 = mean(y) + [-std(y), std(y)]; %temp to plot
            %             std
            if colorNonZeroRed && (yCI95(1) > 0 || yCI95(2) < 0)
                lineColor = 'r';
            end
            if showMeanCILegend %show legend to indicate what's mean and CI.
                plot(x, yMean,'.','Color',lineColor,'LineWidth',3.5, ...
                    'MarkerSize',38,'DisplayName','Mean');
                plot([x,x], yCI95,'Color',lineColor,'LineWidth',3.5, ...
                    'Marker','None','DisplayName','95%CI');
            %don't show legend for mean and CI. Show legend to identify the
            %group of data only.
            else
                plot(x, yMean,'.','Color',lineColor,'LineWidth',3.5, ...
                    'MarkerSize',38,'HandleVisibility','off');
                plot([x,x], yCI95,'Color',lineColor,'LineWidth',3.5, ...
                    'Marker','None','HandleVisibility','off');
            end
            plot(x*ones(size(y))+0.4,y,'o','Color',lineColor, ...
                'LineWidth',1,'MarkerSize',10,'DisplayName',dataLabel)
            grid on;
            set(findall(gcf,'-property','FontSize'),'FontSize',25)
            [miny, maxy] = bounds(y);
            %             fprintf('\n%s: Range[min, max]: [%f, %f]; Mean:
            %             %f, CI: [%f, %f]\n',dataLabel, miny, maxy, yMean,
            %             yCI95);
        end

        function f = plotRegression(mdl, xVariable, yVariable, ...
            saveResAndFigure, savePath, f, lineColor)
            %PLOTREGRESSION Plot a regression model's fit.
            %
            %   Scatter-plots YVARIABLE against XVARIABLE from the table
            % behind MDL and draws the fitted line if the fit is
            % significant.
            %
            % Inputs:
            %   mdl              - LinearModel object (regression output)
            %   xVariable        - name of the mdl.Variables column for the
            %                      x axis
            %   yVariable        - name of the mdl.Variables column for the
            %                      y axis
            %   saveResAndFigure - (optional) true to save the plot; default
            %                      false
            %   savePath         - (optional) full path (absolute
            %                      recommended) of the saved figure;
            %                      required if saveResAndFigure is true
            %   f                - (optional) figure or subplot handle to
            %                      plot on; a new figure if omitted
            %   lineColor        - (optional) 1x3 color of the line; default
            %                      is the first color of
            %                      PlotHelper.colorOrder
            %
            % Outputs:
            %   f - handle of the figure plotted on
            %
            % Example:
            %   PlotHelper.plotRegression(linearModel, 'Age', 'AGI', ...
            %       true, 'C:/Documents/saveMyData.png');
            %
            % Toolbox Dependencies:
            %   Statistics and Machine Learning Toolbox (LinearModel)
            %
            % See also PLOTHELPER.PLOTREGRESSIONDIAGNOSTICS.

            %no figure handle provided, create a new figure; if figure is
            %provided, simply plot
            if nargin < 4 || isempty(saveResAndFigure) || ...
                    isnan(double(saveResAndFigure))
                saveResAndFigure = false; %default false
                savePath = [];
            end
            %no figure handle provided, create a new figure; if figure is
            %provided, simply plot
            if nargin < 5 || isempty(f) || isnan(double(f))
                %('Position', get(0, 'Screensize'));
                f = figure('units','normalized','outerposition',[0 0 1 1]);
            end
            if nargin < 6 || isempty(lineColor) || ...
                    all(isnan(double(lineColor)))
                %use a default random one
                lineColor = PlotHelper.colorOrder(1,:);
            end

            hold on;
            scatter(eval(['mdl.Variables.' xVariable]), ...
                eval(['mdl.Variables.' yVariable]),400,'k','.');
            xlabel(xVariable);
            ylabel(yVariable);
            axis square

            [p,f] = coefTest(mdl);
            %plot reg line only if corr for pearson is significant
            if p < 0.1
                plotFitX = xlim;
                plotFitY = mdl.Coefficients.Estimate(2) * plotFitX + ...
                    mdl.Coefficients.Estimate(1);
                %                 h = plot(linFit);
                %                 for i = 2:4
                %                     h(i).Color =
                %                     colorByNetwork(networks,:);
                %                     h(i).LineWidth = 2.5;
                %                     h(i).HandleVisibility = 'off';
                %                 end
                %                 h(2).LineWidth = 4;%the middle fitted line
                if p < 0.05 %solid line for significant
                    plot(xlim,plotFitY,'Color',lineColor,'LineWidth', ...
                        4.5,'handleVisibility','off');
                    title(sprintf( ...
                        'Model-p = %.3f,\nR^2 Adjusted = %.3f',p, ...
                        mdl.Rsquared.Adjusted),'FontSize',20,'Color','r');
                    %                     h(2).LineStyle ='-';
                else %dashed line for trending.
                    plot(xlim,plotFitY,'--','Color',lineColor, ...
                        'LineWidth',4.5,'handleVisibility','off');
                    title(sprintf( ...
                        'Model-p = %.3f,\nR^2 Adjusted = %.3f',p, ...
                        mdl.Rsquared.Adjusted),'FontSize',20,'Color','y');
                    %                     h(2).LineStyle ='--'; %the middle
                    %                     fitted line
                end
            end
            set(findall(gcf,'-property','FontSize'),'FontSize',20)

            if saveResAndFigure
                set(gcf,'renderer','painters')
                saveas(f,[savePath])
                saveas(f,[savePath], 'png')
            end
        end

        function [high_leveragePts,high_cookdPts, p_norm, ...
            p_scedasticity] = plotRegressionDiagnostics(mdl, actualYs, ...
            saveResAndFigure, savePath)
            %PLOTREGRESSIONDIAGNOSTICS Plot regression diagnostics.
            %
            %   Draws six panels for the model MDL: residual histogram (top
            % left, normality), QQ plot (top right, expected to be
            % normal), residuals vs fitted values (middle left,
            % homoscedasticity: equal variance across y), fitted vs actual
            % y (middle right, expected to follow the diagonal), points
            % with high leverage (bottom left, outliers in x that can
            % change the fit) and Cook's distance (bottom right, points
            % whose removal changes the fit substantially). Influential
            % points are usually outliers in x or y.
            %
            % Inputs:
            %   mdl              - LinearModel object (regression output)
            %   actualYs         - column vector of the actual y values
            %   saveResAndFigure - true to save the figure
            %   savePath         - full path (absolute recommended) of the
            %                      saved figure
            %
            % Outputs:
            %   high_leveragePts - indices of high-leverage points
            %   high_cookdPts    - indices of points with high Cook's
            %                      distance
            %   p_norm           - p-value of the residual normality test
            %   p_scedasticity   - p-value of the Breusch-Pagan test
            %                      for heteroscedasticity (BPTEST)
            %
            % Example:
            %   PlotHelper.plotRegressionDiagnostics(linearModel, ys, ...
            %       true, 'C:/Documents/saveMyData.png');
            %
            % Toolbox Dependencies:
            %   Statistics and Machine Learning Toolbox (LinearModel,
            % qqplot, kstest)
            %
            % See also PLOTHELPER.PLOTREGRESSION.

            %('Position', get(0, 'Screensize'));
            f = figure('units','normalized','outerposition',[0 0 1 1]);
            %TODO: refactor here to call the normality helper
            %histogram(mdl.Residuals.Studentized);
            subplot(3,2,1); histogram(mdl.Residuals.Raw);
            title('Residual Histogram'); xlabel('Residuals (y-yhat)');
            %         xRange = xlim;
            %         hold on; plot(xRange(1):0.1:xRange(2),
            %         normpdf(xRange(1):0.1:xRange(2), 0,1))
            %pd = fitdist(mdl.Residuals.Studentized,'Normal');
            pd = fitdist(mdl.Residuals.Raw,'Normal');
            %[h, p] = kstest(mdl.Residuals.Studentized);
            [h, p_norm] = kstest(normalize(mdl.Residuals.Raw));

            %qqplot(mdl.Residuals.Studentized);
            subplot(3,2,2); qqplot(mdl.Residuals.Raw);
            title(['Residual vs Standard Normal: kstest (0:normal) = ' ...
                num2str(h)]);
            fprintf(['\nResidual is normal (kstest, 0 = normal): %d, p ' ...
                '= %f'],h,p_norm)

            %scatter(mdl.Fitted, mdl.Residuals.Studentized);
            subplot(3,2,3); scatter(mdl.Fitted, mdl.Residuals.Raw);
            hold on; yline(0);
            xlabel('Fitted'); ylabel('Residuals'); title( ...
                'Homoscedasticity Check');
            %test for it
            %use original formula
            [BPstats, p_scedasticity, df] = BPtest(mdl, false);
            if p_scedasticity < 0.05
                fprintf(['\nHomoscedasticity violated, p = %.2f, df =  ' ...
                    '%.2f, BPstats = %.2f'],p_scedasticity,df,BPstats)
            else
                fprintf(['\nHomoscedasticity pass, p = %.2f, df =  ' ...
                    '%.2f, BPstats = %.2f'],p_scedasticity,df,BPstats)
            end

            subplot(3,2,4); scatter(mdl.Fitted, actualYs);
            hold on; plot(xlim, xlim); legend({'Data','y=x'});
            ylabel('ActualY'); xlabel('Fitted'); title( ...
                'Fitted vs Actual Data Check');
            axis square

            %Now inspect influential points (deletion causes substantial
            %change to the fitted model),
            %High leverage points are outliers in the x-space, they
            %tend to have extreme values in one or more of the x’s
            %or represent an unusual combo of x values. A point with
            %leverage > 2p/n where p = # of coefficient can be a high
            %leverage point. Ref:
            %https://www.mathworks.com/help/stats/leverage.html
            %Cook’s distance measures the influence of each data point on
            %the fitted response. A point with cook's D > 3x mean(Cook's d)
            %could be an outlier. Ref:
            %https://www.mathworks.com/help/stats/cooks-distance.html
            %Other options: DFFITS quantify how much the fitted values
            %change if the ith observation was deleted from the dataset
            %DFBETAs quantify how much each coefficient would change (in
            %s.e. units) if the ith observation was deleted from the dataset
            subplot(3,2,5);
            plotDiagnostics(mdl);
            ref_leverage = 2*mdl.NumCoefficients/mdl.NumObservations;
            hold on;
            yline(ref_leverage,'--','r','LineWidth',2);
            high_leveragePts = mdl.Diagnostics.Leverage > ref_leverage;
            fprintf(['\nHigh leverage points index: ' ...
                num2str(find(high_leveragePts)')])

            subplot(3,2,6);
            plotDiagnostics(mdl,'cookd');
            ref_cookd = 3*mean(mdl.Diagnostics.CooksDistance,'omitnan');
            hold on;
            yline(ref_cookd,'--','r','LineWidth',2);
            high_cookdPts = mdl.Diagnostics.CooksDistance > ref_cookd;
            fprintf(['\nHigh cooks d (influential) points index: ' ...
                num2str(find(high_cookdPts)') '\n'])

            figureTitleStr = split(savePath, filesep);
            %last part is file name and figure title.
            sgtitle(figureTitleStr{end});
            set(findall(gcf,'-property','FontSize'),'FontSize',15)

            %Now plot where the influential points are in the original data
            %space, are they problematic?
            %('Position', get(0, 'Screensize'));
            f2 = figure('units','normalized','outerposition',[0 0 1 1]);
            cols = 3;
            rows = ceil(length(mdl.PredictorNames)/cols);
            ys = eval(['mdl.Variables.' mdl.ResponseName]);
            for ii = 1:length(mdl.PredictorNames)
                subplot(rows,cols,ii); hold on;
                xs = eval(['mdl.Variables.' mdl.PredictorNames{ii}]);
                scatter(xs,ys,225,'k.');
                scatter(xs(high_leveragePts),ys(high_leveragePts),225,'r.');
                scatter(xs(high_cookdPts),ys(high_cookdPts),110,'bo');

                xlabel(mdl.PredictorNames{ii})
                ylabel(mdl.ResponseName)
                axis square
            end
            subplot(rows,cols,1); legend({'AllData','HighLeverage', ...
                'High CookD'}); %put legend in subplot1
            sgtitle('High Leverage or CookD Point')
            set(findall(gcf,'-property','FontSize'),'FontSize',20)

            if saveResAndFigure
                figure(f); set(gcf,'renderer','painters')
                saveas(f,savePath)
                %                 s = findobj('type','legend'); delete(s)
                saveas(f,[savePath '.png'])

                figure(f2);
                set(gcf,'renderer','painters')
                saveas(f2,[savePath 'InfluentPointLoc'])
                %                 s = findobj('type','legend'); delete(s)
                saveas(f2,[savePath 'InfluentPointLoc.png'])
            end
        end

        function plotBootStrapCorrSpearman(xData, yData, xlabels, ...
            ylabels, titleStr, saveResAndFigure, savePath, iterations, ...
            controlVar, controlVarXIdx, controlVarYIdx, f)
            %PLOTBOOTSTRAPCORRSPEARMAN Plot bootstrapped Spearman rho.
            %
            %   For every x-column / y-column pair, resamples with
            % replacement ITERATIONS times to build a distribution of the
            % Spearman rho (partial correlation when CONTROLVAR is given)
            % and plots the 95% CI, the mean and each bootstrapped value
            % of rho. Each pair takes one column of two subplot rows
            % (e.g., xData column 2 and yData column 3 use subplots 5:6 of
            % column 2); the top histogram row is currently commented out.
            %
            % Inputs:
            %   xData            - subjects x columns matrix
            %   yData            - subjects x columns matrix
            %   xlabels          - cell array of x labels (one per column)
            %   ylabels          - cell array of y labels (one per row)
            %   titleStr         - overall plot title
            %   saveResAndFigure - true to save the figure
            %   savePath         - full path (directory and name) of the
            %                      saved figure
            %   iterations       - (optional) number of resamples; default
            %                      1000
            %   controlVar       - (optional) subjects x variables matrix to
            %                      control for (partial correlation)
            %   controlVarXIdx   - (optional) column(s) of XDATA that hold
            %                      the controlled variable; NaN if not part
            %                      of XDATA
            %   controlVarYIdx   - (optional) column(s) of YDATA that hold
            %                      the controlled variable; NaN or omit if
            %                      not part of YDATA
            %   f                - (optional) figure handle; a new figure if
            %                      omitted or empty
            %
            % Outputs:
            %   None.
            %
            % Example:
            %   PlotHelper.plotBootStrapCorrSpearman(x, y, ...
            %       {'xlabel1','xlabel2'}, {'ylabel1','ylabel2'}, ...
            %       'title', true, 'C:/Documents/saveFolder/myFig.png');
            %
            % Toolbox Dependencies:
            %   Statistics and Machine Learning Toolbox (bootstrp, corr,
            %   partialcorr)
            %
            % See also PLOTHELPER.PLOTCI.

            %iterations default.
            if nargin < 8 || isempty(iterations) || any(isnan(iterations))
                iterations = 1000;
            end
            if nargin >= 9 && ~isempty(controlVar) && ...
                    ~any(isnan(controlVar),'all') %partial correlation
                bootStrpStatement = "bootstat = bootstrp(iterations, " + ...
                    "@(x,y, controlVar)partialcorr(x,y,controlVar," + ...
                    "'Type','Spearman','Rows','complete')," + ...
                    "xToPlot,yToPlot, controlVar);";
            else %regular correlation
                bootStrpStatement = "bootstat = bootstrp(iterations, " + ...
                    "@(x,y)corr(x,y,'Type','Spearman','Rows'," + ...
                    "'complete'),xToPlot,yToPlot);";
            end
            if nargin < 12 || isempty(f) || any(isnan(f))
                %('Position', get(0, 'Screensize'));
                f = figure('units','normalized','outerposition',[0 0 1 1]);
            end
            for rowIdx = 1:size(yData,2) %row
                for colIdx = 1:size(xData,2) %col
                    xToPlot = xData(:,colIdx); %put fnir on the x-axis
                    yToPlot = yData(:,rowIdx);
                    eval(bootStrpStatement);
                    %                     bootstat = bootstrp(iterations,
                    %                     @(x,y)corr(x,y,'Type', ...
                    %    'Spearman','Rows','complete'),xToPlot,yToPlot);
                    %                     subplot(size(yData,2)*2, ...
                    %    size(xData,2),(rowIdx-1)*size(xData,2)*2+colIdx);
                    %                     hold on; %row 1
                    %                     histogram(bootstat);
                    %                     title([xlabels{colIdx},'
                    %                     ',ylabels{rowIdx}])
                    %                     subplot(size(yData,2)*2, ...
                    %    size(xData,2),(rowIdx*2-1)*size(xData,2)+colIdx);
                    %                     %row 2
                    if size(yData,2) > 1 || size(xData,2) > 1
                        subplot(size(yData,2),size(xData,2), ...
                            (rowIdx-1)*size(xData,2)+colIdx); %row 1
                    end
                    PlotHelper.plotCI(1,bootstat,'k', ...
                        ['\rho(' xlabels{colIdx},',',ylabels{rowIdx} ...
                        ')'],true, true)
                    %1 row only use y label (have enough height)
                    if size(yData,2) == 1
                        ylabel(['\rho(' xlabels{colIdx},',', ...
                            ylabels{rowIdx} ')']);
                    else
                        title(['\rho(' xlabels{colIdx},',', ...
                            ylabels{rowIdx} ')']);
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

        function SigMdlSum = compileModelSummaries(mdl, SigMdlSum, ...
            modelType)
            %COMPILEMODELSUMMARIES Append a model summary to a table.
            %
            %   Generates the summary of the linear model MDL and appends it
            % to SIGMDLSUM, a cell array whose first row is the table
            % header.
            %
            % Inputs:
            %   mdl        - MATLAB linear model object
            %   SigMdlSum  - (optional) summary cell array to append to;
            %                created (with header) if omitted or []
            %   modelType  - (optional) analysis type (primary, secondary,
            %                sensitivity, confirmatory, ...) used to track
            %                the planned analysis; default ''
            %
            % Outputs:
            %   SigMdlSum - summary cell array with the new entry, header in
            %               row 1
            %
            % Example:
            %   modelSumCell = PlotHelper.compileModelSummaries(newMdl, ...
            %       modelSumCell);
            %
            % Toolbox Dependencies:
            %   Statistics and Machine Learning Toolbox (linear model
            % properties)
            %
            % See also PLOTHELPER.PLOTREGRESSION.
            alpha = 0.05;
            %             trendingThreshold = 0.1;
            %no existing mdlSum array provided, intialize, first row is
            %header.
            if nargin < 2 || isempty(SigMdlSum)
                SigMdlSum = {'ResponseName','Predictors','SigRegressor', ...
                    'R2Ordinary','R2Adjusted','CogVarBeta','pValue', ...
                    'AIC','BIC','ResidualAbnormal(0Normal)', ...
                    'LackOfFit(1lack)','RobustOpt','NumSub','Model', ...
                    'AnalysisType(Primary,Secondary, etc.)'};
            end

            if nargin < 3 || isempty(modelType)
                modelType = ''; %default type is empty
            end
            %             if nargin < 3 %no existing mdlSum array provided,
            %             intialize, first row is header.
            %                 trendingMdlSum =
            %                 {'ResponseName','Predictors', ...
            %    'SigRegressor','R2Ordinary','R2Adjusted', ...
            %    'ResidualAbnormal(0Normal)'};
            %             end

            mdlStats = anova(mdl,'summary');
            %             if mdlStats{'Model','pValue'} > 0.2
            %                 return
            %             end

            if ismember('. Lack of fit',mdlStats.Row) && ...
                    mdlStats{'. Lack of fit','pValue'} <= alpha
                lackOfFit = true;
            else
                lackOfFit = false;
            end
            coefPVal = mdl.Coefficients.pValue;
            sigCoef = mdl.CoefficientNames(coefPVal <= alpha);
            sigCoef = strjoin(sigCoef);
            try
                %TODO: refactor here to call the normality helper
                [h,~] = kstest(mdl.Residuals.Studentized);
            catch
                warning(['\nCannot compute normality test on residual, ' ...
                    'reporting NaN.'])
                mdl.Formula
                h = nan;
            end
            cogVarIdx = contains(mdl.CoefficientNames, ...
                {'TMTBMinusTMTA','traila','trailb','MMSE_total'});
            if any(cogVarIdx)
                cogVarBeta = ...
                    mdl.Coefficients{mdl.CoefficientNames(cogVarIdx), ...
                    'Estimate'};
            else
                cogVarBeta = nan;
            end

            SigMdlSum(end+1,:) = {mdl.Formula.ResponseName, ...
                mdl.Formula.LinearPredictor,sigCoef, ...
                mdl.Rsquared.Ordinary,mdl.Rsquared.Adjusted,...
                cogVarBeta,mdlStats{'Model','pValue'}, ...
                mdl.ModelCriterion.AIC, mdl.ModelCriterion.BIC,h, ...
                lackOfFit,mdl.Robust,mdl.NumObservations,mdl, modelType};
        end

        function tightMargin(ax)
            %TIGHTMARGIN Reduce the margins around the axes of a figure.
            %
            %   Shrinks the margin of the figure containing AX. Adapted from
            % MATLAB Answers 369399 (removing the grey margin of a plot).
            %
            % Inputs:
            %   ax - axes handle, usually from gca on the active figure
            %
            % Outputs:
            %   None.
            %
            % Example:
            %   PlotHelper.tightMargin(gca);
            %
            % Toolbox Dependencies: None
            %
            % See also GCA.
            outerpos = ax.OuterPosition;
            ti = ax.TightInset;
            left = outerpos(1) + 2*ti(1);
            bottom = outerpos(2)+ ti(2);
            ax_width = outerpos(3) - 3*ti(1) - 3*ti(3);
            ax_height = outerpos(4) - ti(2) - ti(4);
            %to have no margin at all, use the following
            %             left = outerpos(1) + ti(1);
            %             bottom = outerpos(2) + ti(2);
            %             ax_width = outerpos(3) - ti(1) - ti(3); %make left
            %             and right exactly the same as the figure
            %             ax_height = outerpos(4) - ti(2) - ti(4);
            ax.Position = [left bottom ax_width ax_height];
        end
    end
end


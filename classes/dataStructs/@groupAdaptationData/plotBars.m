function [figHandle,allData] = plotBars(this,label,removeBiasFlag, ...
    plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast, ...
    legendNames,significanceThreshold,plotHandles,colors, ...
    significancePlotMatrix)
%PLOTBARS Bar plot of stride-group parameter means for one group.
%
%   Plots, for each label, one bar per stride group and condition (see
% PLOTMULTIPLEGROUPSBARS) and overlays paired t-test significance bars
% between the stride groups selected in significancePlotMatrix.
%
% Inputs:
%   this                   - groupAdaptationData object
%   label                  - cell array of parameter labels, one subplot
%                            each
%   removeBiasFlag         - passed to the bar plot (default 0, with a
%                            warning)
%   plotIndividualsFlag    - plot each subject (default [])
%   condList               - cell array of condition names
%   numberOfStrides        - strides per group: positive values take the
%                            first N, negative the last N
%   exemptFirst            - strides skipped at the start
%   exemptLast             - strides skipped at the end
%   legendNames            - group names for the legend
%   significanceThreshold  - p-value threshold; a bar is drawn if the
%                            paired t-test p-value is below it divided by
%                            the number of compared pairs. If empty, no
%                            tests are run.
%   plotHandles            - axes handles, one per label
%   colors                 - Nx3 group colors
%   significancePlotMatrix - square matrix over the condition x stride
%                            group bars; nonzero entries select the
%                            compared pairs (default: consecutive bars and
%                            the second bar against all later ones)
%
% Outputs:
%   figHandle - figure handle
%   allData   - struct with allData.group{1}, a conditions x stride
%               groups x labels x subjects array of means over strides
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
%
% See also PLOTMULTIPLEGROUPSBARS, ADAPTATIONDATA/PLOTGROUPEDSUBJECTSBARSV2.

% TODO: check that the numberOfStrides groups and the conditions in
% condList are given in chronological order. The plot works if they are
% not, but the statistical testing plots may not, as they expect ordered
% input.

if nargin < 3 || isempty(removeBiasFlag)
    %For efficiency, subjects should remove bias before hand, as it is a
    %computationally intensive task that should be done the least number of
    %times possible
    warning('RemoveBiasFlag argument not provided, will NOT remove bias.')
    removeBiasFlag = 0;
end
if nargin < 4
    plotIndividualsFlag = [];
end
if nargin < 5
    condList = [];
end
if nargin < 6
    numberOfStrides = [];
end
if nargin < 7
    exemptFirst = [];
end
if nargin < 8
    exemptLast = [];
end
if nargin < 9
    legendNames = [];
end
if nargin < 10
    significanceThreshold = [];
end
if nargin < 11
    plotHandles = [];
end
if nargin < 12
    colors = [];
end
if nargin < 13 || isempty(significancePlotMatrix)
    M = length(condList)*length(numberOfStrides);
    %significancePlotMatrix=ones(M);
    significancePlotMatrix = zeros(M);
    %Comparing all consecutive strideGroups
    significancePlotMatrix(sub2ind([M,M],[2:M-1],[3:M])) = 1;
    %Comparing second strideGroup vs. every other (except 1st)
    significancePlotMatrix(2,3:M) = 1;
end
[figHandle,allData] = groupAdaptationData.plotMultipleGroupsBars({this}, ...
    label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides, ...
    exemptFirst,exemptLast,legendNames,[],plotHandles,colors);
if ~isempty(significanceThreshold)
    %[p,table,stats,postHoc,postHocEstimates,data]=anova1RM(this,label, ...
    %    condList,numberOfStrides,exemptFirst,exemptLast);
    %[pf,tablef,statsf,postHocf,postHocEstimatesf,dataf]=friedman(this, ...
    %    label,condList,numberOfStrides,exemptFirst,exemptLast);
    %if ~isa(postHoc,'cell')
    %    postHoc={postHoc};
    %    postHocf={postHocf};
    %end
    ch = findobj(figHandle,'Type','Axes');
    for ii = 1:length(ch)
        aux = find(strcmp(label,ch(ii).Title.String));
        clear XData YData
        subplot(ch(ii))
        hold on
        b = findobj(ch(ii),'Type','Bar');
        for jj = 1:length(b)
            XData(jj,:) = b(end-jj+1).XData;
            YData(jj,:) = b(end-jj+1).YData;
        end
        XData = XData(:);
        YData = YData(:);
        yRef  = (max(YData)-min(YData));
        yOff  = max(YData);
        for jj = 1:length(XData)
            [a1,a2] = ...
                ind2sub([size(allData.group{1},2), ...
                size(allData.group{1},1)],jj);
            data1 = squeeze(allData.group{1}(a2,a1,aux,:));
            for k = (jj+1):length(XData)
                [b1,b2] = ...
                    ind2sub([size(allData.group{1},2), ...
                    size(allData.group{1},1)],k);
                data2 = squeeze(allData.group{1}(b2,b1,aux,:));
                %Sanity check:
                %data2 is the data I believe is plotted in the bar
                %positioned in x=XData(k), and should have height y=YData(k)
                if mean(data2, 'omitnan') ~= YData(k)
                    %Mismatch means that I am wrong, and
                    %therefore should not be overlaying the
                    %stats on the given bar plots
                    error('Stride group order is different than expected')
                end
                if (significancePlotMatrix(k,jj) == 1 || ...
                        significancePlotMatrix(jj,k) == 1)
                    %Anova, bonferroni post-hoc:
                    %if postHoc{aux}(j,k)<significanceThreshold
                    %    plot(XData([j,k]), ...
                    %    (yOff+yRef*(.5*j/length(XData) ...
                    %    +k/length(XData)^2))*[1,1],'k','LineWidth',2)
                    %    text(XData(j), ...
                    %    (yOff+yRef*(.5*j/length(XData) ...
                    %    +k/length(XData)^2))*1.05, ...
                    %    ['p=' num2str(postHoc{aux}(j,k))])
                    %end
                    %Friedman:
                    %if postHocf{aux}(j, ...
                    %    k)<significanceThreshold/sum( ...
                    %    significancePlotMatrix(:)~=0)
                    %    plot(XData([j,k]), ...
                    %    (yOff+yRef*(.5*j/length(XData) ...
                    %    +k/length(XData)^2))*[1,1],'r','LineWidth',1)
                    %end
                    %Paired t-test:
                    %Use ttest2 to do independent 2-sample t-test
                    [~,pp] = ttest(data1,data2);
                    if pp < significanceThreshold/sum( ...
                            significancePlotMatrix(:) ~= 0)
                        plot(XData([jj,k]), ...
                            (yOff+yRef*(0.5*jj/length(XData) ...
                            +k/length(XData)^2))*[1,1],'k','LineWidth',2)
                        text(XData(k)-1.5, ...
                            (yOff+yRef*(0.5*jj/length(XData) ...
                            +k/length(XData)^2))*0.95, ...
                            ['p=' num2str(pp)],'Color','k')
                    end
                end
            end
        end
        axis tight
        hold off
    end
end
end

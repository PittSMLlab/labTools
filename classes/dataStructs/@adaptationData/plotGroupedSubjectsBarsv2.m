function [figHandle,allData] = plotGroupedSubjectsBarsv2(adaptDataList, ...
    label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides, ...
    exemptFirst,exemptLast,legendNames,significanceThreshold, ...
    plotHandles,colors,medianFlag)
%PLOTGROUPEDSUBJECTSBARSV2 Bar plot of stride-group parameter means.
%
%   For each label, plots one bar set per group of strides (e.g., first
% 5 and last 20) and condition, with groups side by side. Bars show the
% mean (or median) across subjects with std (or half the 16-84
% percentile range) as error bars; individual subjects are optionally
% overlaid as red dots. Conditions alternate a gray background.
%
% Inputs:
%   adaptDataList         - groupAdaptationData object, or cell array of
%                           them (one per group)
%   label                 - cell array of parameter labels, one subplot
%                           each
%   removeBiasFlag        - passed to GETGROUPEDDATA (default 1)
%   plotIndividualsFlag   - plot each subject (default true)
%   condList              - cell array of condition names
%   numberOfStrides       - strides per group: positive values take the
%                           first N, negative the last N (default
%                           [5, -20])
%   exemptFirst           - strides skipped at the start (default 0)
%   exemptLast            - strides skipped at the end (default 5)
%   legendNames           - group names for the legend (default
%                           'Group #(n=...)')
%   significanceThreshold - accepted but unused
%   plotHandles           - axes handles, one per label (default: new
%                           figure)
%   colors                - Nx3 group colors, N >= number of groups
%                           (default from COLORSCHEME)
%   medianFlag            - 1 to plot medians instead of means (default
%                           0)
%
% Outputs:
%   figHandle - figure handle
%   allData   - struct with allData.group{g}, a conditions x stride
%               groups x labels x subjects array of means over strides
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
%
% See also GROUPADAPTATIONDATA, GETGROUPEDDATA, OPTIMIZEDSUBPLOT.

mode = 1; % 1 is bars +- std, 2 is lines +- std, 3 is boxplots

if nargin < 4 || isempty(plotIndividualsFlag)
    plotIndividualsFlag = true;
end
if nargin < 9
    legendNames = {};
end
%if ~plotIndividualsFlag
%    legendNames={};
%end
if nargin < 3 || isempty(removeBiasFlag)
    removeBiasFlag = 1;
end
if nargin < 5 || isempty(condList)
    condList = [];
end

%% Parse inputs
%First: see if adaptDataList is a single groupAdaptData object
%or a cell-array of it
if isa(adaptDataList,'groupAdaptationData')
    auxList = {adaptDataList};
elseif isa(adaptDataList,'cell') && ~isa(adaptDataList{1}, ...
        'groupAdaptationData')
    error();
elseif isa(adaptDataList,'cell')
    auxList = adaptDataList;
end

Ngroups = length(auxList);
if nargin < 12 || isempty(colors) || size(colors,1) < Ngroups
    colorScheme
    for ii = 1:Ngroups
        colors(ii,:) = colorGroups{mod(ii-1,length(colorGroups))+1};
    end
end
if nargin < 13 || isempty(medianFlag)
    medianFlag = 0;
end

%% Set stride counts
%Default number of strides to average:
if nargin < 6 || isempty(numberOfStrides)
    N2 = [5,-20];
else
    N2 = numberOfStrides;
end
if nargin < 7 || isempty(exemptFirst)
    Nf = 0;
else
    Nf = exemptFirst;
end
if nargin < 8 || isempty(exemptLast)
    Ne = 5;
else
    Ne = exemptLast;
end
if nargin < 10 || isempty(significanceThreshold)
    significanceThreshold = [];
end


nConds = length(condList);
nLabs  = length(label);
%% Get data
for ii = 1:Ngroups
    data = auxList{ii}.getGroupedData(label,condList,removeBiasFlag,N2, ...
        Nf,Ne); %(1:nConds,1:abs(numberOfStrides(ii)),1:nLabs,subject)
    nSubs = length(auxList{ii}.ID);
    allData.group{ii} = nan(nConds,length(data),nLabs,nSubs);
    for jj = 1:length(data)
        %Averaging across strides; cell across groups, conds x strideGroups
        %x parameters x subs
        allData.group{ii}(1:nConds,jj,1:nLabs,1:nSubs) = ...
            mean(data{jj}, 2, 'omitnan');
    end
end

%% Plot
if nargin < 11 || isempty(plotHandles) || ...
        numel(plotHandles) ~= length(label)
    [ah,figHandle] = optimizedSubPlot(length(label),2,2);
    figure(figHandle)
else
    figHandle = figure(gcf);
    ah        = plotHandles;
end

for ii = 1:length(ah) %For each paramter
    subplot(ah(ii))
    for jj = 1:Ngroups %For each group
        nSubs = size(allData.group{jj},4);
        if isempty(legendNames)
            gName{jj} = ['Group ' num2str(jj) '(n=' num2str(nSubs) ')'];
        else
            gName{jj} = legendNames{jj};
        end
        %For each set of strides to be plotted (e.g first 20, last 50, ...)
        for k = 1:length(N2)
            if medianFlag == 0
                %Avg. across subjects. We end up with:
                %conditionsxStrideSetxGroups
                relevantMean = mean(allData.group{jj}(:,k,ii,:), 4, ...
                    'omitnan');
                %/sqrt(nSubs); %Avg. across subjects. We end up with:
                %conditionsxStrideSetxGroups
                relevantSte = std(allData.group{jj}(:,k,ii,:), [], 4, ...
                    'omitnan');
            else
                %Median  across subjects. We end up with:
                %conditionsxStrideSetxGroups
                relevantMean = median(allData.group{jj}(:,k,ii,:), 4, ...
                    'omitnan');
                %relevantSte=.5*iqr(allData.group{j}(:,k,i,:), ...
                %    4);%/sqrt(nSubs);
                %%.5 times Interquartile range across subjects, normalized
                %to sqrt(Number of subjects) to be consistent with STE
                %Using half of the 16-84 percentile (which in a normal dist
                %corresponds to 1 stdev)
                relevantSte = ...
                    0.5*diff(prctile(allData.group{jj}(:,k,ii,:), ...
                    [16,84],4),[],4);
            end
            xPos = (jj+(k-1)*(Ngroups+1)): ...
                length(N2)*(Ngroups+1):nConds*length(N2)*(Ngroups+1);
            if N2(k) < 0
                bName{k} = [' last ' num2str(abs(N2(k))) ' strides.'];
            else
                bName{k} = [' first ' num2str(abs(N2(k))) ' strides.'];
            end
            hold on
            %Mean bars +- std or median bars +- half the 16-84 percentile
            %range
            if mode == 1
                try
                    bb(jj,k) = bar(xPos,relevantMean,'BarWidth', ...
                        0.9/((Ngroups+1)*length(N2)),'FaceColor', ...
                        colors(jj,:),'FaceAlpha',(k/length(N2)), ...
                        'DisplayName',strcat(gName{jj},bName{k}), ...
                        'EdgeColor',colors(jj,:).^(k/length(N2)));
                    %old matlab versions don't allow for 'FaceAlpha'
                    %property on bars
                catch
                    %,'FaceAlpha',(k/length(N2)));
                    bb(jj,k) = bar(xPos,relevantMean,'BarWidth', ...
                        0.9/((Ngroups+1)*length(N2)),'FaceColor', ...
                        colors(jj,:).^(1-((k-1)/length(N2))), ...
                        'DisplayName',strcat(gName{jj},bName{k}), ...
                        'EdgeColor',colors(jj,:),'LineWidth',2);
                end
                bb(jj,k).Tag = ['Group' num2str(jj) ',Cond' num2str(k)];
                hC = errorbar(xPos,relevantMean,relevantSte,'LineStyle', ...
                    'none','LineWidth',2,'Color','k');
                set(get(get(hC,'Annotation'),'LegendInformation'), ...
                    'IconDisplayStyle','off');
                %Mean/median lines +- std or 16-84 percentile range
            elseif mode == 2
                errorbar(xPos,relevantMean, relevantSte,'DisplayName', ...
                    strcat(gName{jj},bName{k}),'LineWidth',2,'Color', ...
                    colors(jj,:).^(1-((k-1)/length(N2))))
            elseif mode == 3 %Boxplots
                boxplot(squeeze(allData.group{jj}(:,k,ii,:))', ...
                    'positions',xPos,'widths',0.9,'symbol','+','colors', ...
                    colors(jj,:).^(k/length(N2)),'boxstyle','outline');
            end
            if plotIndividualsFlag == 1
                indivColors = [];
                hC = plot(xPos-0.1, ...
                    reshape(allData.group{jj}(:,k,ii,:),nConds,nSubs),'r.');
                %Exclude from legend:
                hCGroup = hggroup; %Create group
                set(hC,'Parent',hCGroup)%Grouping all lines plotted
                set(get(get(hCGroup,'Annotation'),'LegendInformation'), ...
                    'IconDisplayStyle','off');
            end
            hold off
        end

    end
    % xPos=((length(N2)*Ngroups+1)/2): ...
    %     length(N2)*Ngroups:nConds*length(N2)*Ngroups;
    % xPos=((Ngroups+1)/2):(Ngroups+1):nConds*length(N2)*(Ngroups+1);
    % tickList=cell(length(N2),length(condList));
    % for k=1:length(N2)
    %     tickList(k,:)=strcat(['Set ' num2str(k) ' '],condList);
    % end
    % tickList=tickList(:);
    xPos = ((length(N2)*(Ngroups+1))/2): ...
        length(N2)*(Ngroups+1):nConds*length(N2)*(Ngroups+1);
    tickList = condList;
    set(gca,'XTick',xPos,'XTickLabel',tickList);
    if ii == length(ah)
        legend(gca,'show')
        %legend(bb(:,k),gName)
    end
    if removeBiasFlag == 1
        title([label{ii} ' w/o bias'])
    else
        title(label{ii})
    end
    axis tight
    aa = axis;
    for jj = 2:2:nConds
        hC = patch(xPos(jj) +[-1,1,1,-1]*(length(N2)*(Ngroups+1))/2, ...
            [aa(3) aa(3) aa(4) aa(4)],[0.8,0.8,0.8],'EdgeColor','none', ...
            'FaceAlpha',0.6);
        set(get(get(hC,'Annotation'),'LegendInformation'), ...
            'IconDisplayStyle','off');
        uistack(hC,'bottom')
    end
    axis(aa)
end

end

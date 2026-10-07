function figHandle = scatterPlotLab(adaptDataList,labels,conditionIdxs, ...
    figHandle,marker,binSize,trajectoryColor,removeBias,addID)
%SCATTERPLOTLAB Plot up to 3 parameters as coordinates in one axes.
%
%   For each subject, plots the median of 2 or 3 parameters in each
% condition and joins consecutive conditions with a line, so each
% subject traces a trajectory through parameter space. Markers differ by
% group; the legend lists subject IDs.
%
% Inputs:
%   adaptDataList   - adaptationData objects: a cell array (one group) or
%                     a cell array of cell arrays (several groups)
%   labels          - cell array of 2 or 3 parameter labels
%   conditionIdxs   - condition indices, or a cell array of condition
%                     names (resolved per subject)
%   figHandle       - (optional) existing figure to draw into
%   marker          - unused; the marker is chosen per group
%   binSize         - [] (default) plots no individual strides; 1 plots
%                     every stride; >1 averages blocks of binSize
%                     strides (smoothed for 3 parameters)
%   trajectoryColor - (optional) color(s) of the trajectories
%   removeBias      - 1 to remove bias first (default 0)
%   addID           - 1 (default) to label the first point with the
%                     subject ID
%
% Outputs:
%   figHandle - figure handle
%
% Toolbox Dependencies: Curve Fitting Toolbox (SMOOTH), Statistics and
%   Machine Learning Toolbox
%
% See also GETPARAMINCOND, REMOVEBIAS.

if isa(adaptDataList,'cell')
    if ~isa(adaptDataList{1},'cell')
        adaptDataList = {adaptDataList};
    end
elseif isa(adaptDataList,'char')
    adaptDataList = {{adaptDataList}};
end
Ngroups = length(adaptDataList);

if nargin < 8 || isempty(removeBias)
    removeBias = 0;
end
if nargin < 5 || isempty(figHandle)
    figHandle = figure;
else
    figure(figHandle);
    hold on
end
markerList = {'v','o','h','+','*','s','x','^','d','.','p','<','>'};
poster_colors;
colorOrder = [p_red; p_orange; p_fade_green; p_fade_blue; p_plum; ...
    p_green; p_blue; p_fade_red; p_lime; [0 0 0];p_yellow];
color = [colorOrder;colorOrder.^5];


if nargin < 3 || isempty(conditionIdxs)
    conditionIdxs = [];
end
if nargin < 4 || isempty(binSize)
    binSize = [];
end

if nargin < 9 || isempty(addID)
    addID = 1;
end

if Ngroups > 1
    labelID = [];
    dot     = [];
end

% if nargin<5 || isempty(marker)
%     marker=markerList{randi(length(markerList),1)};
% end

for g = 1:Ngroups
    marker = markerList{g};
    for sub = 1:length(adaptDataList{g})
        r = (sub-1)/(length(adaptDataList{g})-1);
        if nargin < 7 || isempty(trajectoryColor)
            trajectoryColor = [1,0,0] + r*[-1,0,1];
        elseif iscell(trajectoryColor)
            trajectoryColor = trajectoryColor{sub};
        elseif size(trajectoryColor,2) == 3
            trajectoryColor = ...
                trajectoryColor(mod(sub,size(trajectoryColor,1))+1,:);
        else
            warning('Could not interpret trajecColors input')
            trajectoryColor = 'k';
        end
        this      = adaptDataList{g}{sub};
        fieldList = fields(this);
        a         = this.(fieldList{1});
        %This gives the possibility to pass condition names instead of the
        %indexes for each subject, which might be different
        if iscell(conditionIdxs)
            conditionIdxs1 = getConditionIdxsFromName(a,conditionIdxs);
        else
            conditionIdxs1 = conditionIdxs;
        end

        if removeBias == 1
            this = this.removeBias();
        end

        colorScheme

        aux = cell2mat(colorConds');
        set(gca,'ColorOrder',aux(1:length(conditionIdxs),:));
        hold on
        if length(labels) > 3
            error('adaptationData:scatterPlot', ...
                'Cannot plot more than 3 parameters at a time')
        end

        if length(labels) == 3
            last = [];
            for c = 1:length(conditionIdxs)

                [data,~,~,origTrials] = ...
                    getParamInCond(this,labels,conditionIdxs(c));
                if nargin > 5 && ~isempty(binSize) && binSize > 1

                    for ii = 1:size(data,2)
                        data(:,ii) = smooth(data(:,ii),binSize,'rlowess');
                    end
                end
                if ~isempty(binSize) && binSize ~= 0
                    hh(c) = plot3(data(:,1),data(:,2),data(:,3),marker, ...
                        'LineWidth',1,'MarkerFaceColor',color(sub,:), ...
                        'MarkerEdgeColor',color(sub,:));
                    uistack(hh(c),'bottom')
                end
                if ~isempty(last)
                    h = plot3(data(:,1),data(:,2),data(:,3),'Color', ...
                        color(sub,:),'LineWidth',1);
                    uistack(h,'bottom')
                    plot3([median(data(:,1), 'omitnan')], ...
                        [median(data(:,2), 'omitnan')], ...
                        [median(data(:,3), 'omitnan')],'o', ...
                        'MarkerFaceColor',color(sub,:),'Color',color(sub,:))
                else
                    if addID == 1
                        hhh = text([median(data(:,1), 'omitnan')], ...
                            [median(data(:,2), 'omitnan')], ...
                            [median(data(:,3), 'omitnan')],this.subData.ID);
                        set(hhh,'LineWidth',1,'FontSize',14);
                    end
                end
                last = median(data, 1, 'omitnan');
            end
            xlabel(labels{1})
            ylabel(labels{2})
            zlabel(labels{3})
        elseif length(labels) == 2
            last = [];
            for c = 1:length(conditionIdxs)

                [data,~,~,origTrials] = ...
                    getParamInCond(this,labels,conditionIdxs(c));
                if nargin > 5 && ~isempty(binSize) && binSize > 1
                    data2 = conv2(data,ones(binSize,1)/binSize);
                    data  = data2(1:binSize:end,:);
                    hh(c) = plot(data(:,1),data(:,2),marker,'LineWidth', ...
                        1,'MarkerFaceColor',color(sub,:), ...
                        'MarkerEdgeColor',color(sub,:));
                end
                cc = aux(mod(c,size(aux,1))+1,:);
                if nargin > 5 && ~isempty(binSize) && binSize == 1
                    hh(c) = plot(data(:,1),data(:,2),marker,'LineWidth', ...
                        1,'MarkerFaceColor',color(sub,:), ...
                        'MarkerEdgeColor',color(sub,:));
                    uistack(hh(c),'bottom')
                end
                if ~isempty(last)
                    h = plot([last(1) median(data(:,1), 'omitnan')], ...
                        [last(2) median(data(:,2), 'omitnan')],'Color', ...
                        color(sub,:),'LineWidth',2);
                    uistack(h,'bottom')
                    plot([median(data(:,1), 'omitnan')], ...
                        [median(data(:,2), 'omitnan')],'o','Color', ...
                        color(sub,:),'MarkerFaceColor',color(sub,:))
                end

                last = median(data, 1, 'omitnan');
            end
            xlabel(labels{1})
            ylabel(labels{2})
        end

        if length(conditionIdxs) == 1 && Ngroups == 1
            labelID{sub} = this.subData.ID;
            dot{sub} = hh;
        elseif length(conditionIdxs) > 1 && Ngroups == 1
            labelID{sub} = this.subData.ID;
            dot{sub} = hh(1);
        elseif length(conditionIdxs) > 1 && Ngroups > 1
            labelID2{sub} = this.subData.ID;
            dot2{sub} = hh(1);

        elseif length(conditionIdxs) == 1 && Ngroups > 1
            labelID2{sub} = this.subData.ID;
            dot2{sub} = hh(1);
        end
    end
    if Ngroups > 1
        labelID = [labelID labelID2];
        dot     = [dot dot2];
    end

end

legend([dot{:}],[labelID(:)])
end
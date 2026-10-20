function [figHandle,plotHandles] = plotParamBarsByConditionsv2(this, ...
    label,number,exemptLast,exemptFirst,condList,mode,plotHandles)
%PLOTPARAMBARSBYCONDITIONSV2 Bar plot of stride groups per condition.
%
%   For each label, plots the mean over strides of each stride group
% (e.g., first 5 and first 20) in every condition, with standard error
% bars. Called by the adaptationData wrappers PLOTPARAMBARSBYCONDITIONS
% and PLOTAVGTIMECOURSE.
%
% TODO: update to call PLOTGROUPEDBARS
%
% Inputs:
%   this        - adaptationData object
%   label       - cell array of parameter labels, one subplot each
%   number      - strides per group: positive values take the first N,
%                 negative the last N (default [5, 20])
%   exemptLast  - strides skipped at the end (default 5)
%   exemptFirst - strides skipped at the start (default 0)
%   condList    - cell array of condition names (default: all named)
%   mode        - 1 (default): grouped bars; otherwise error-bar lines
%   plotHandles - axes handles, one per label (default: new figure)
%
% Outputs:
%   figHandle   - figure handle (unset when plotHandles is given)
%   plotHandles - axes handles used
%
% Toolbox Dependencies: None
%
% See also GETEARLYLATEDATA_V2, OPTIMIZEDSUBPLOT.

if nargin < 3 || isempty(number)
    n = [5,20]; %early number of points
else
    n = number;
end
if nargin < 4 || isempty(exemptLast)
    Ne = 5;
else
    Ne = exemptLast;
end
if nargin < 5 || isempty(exemptFirst)
    Nf = 0;
else
    Nf = exemptLast;
end

if nargin < 8 || isempty(plotHandles) || ...
        length(label) ~= length(plotHandles)
    [ah,figHandle] = optimizedSubPlot(length(label),4,1);
else
    ah = plotHandles;
end
if nargin < 6 || isempty(condList)
    conds = find(~cellfun(@isempty,this.metaData.conditionName));
else
    conds = this.getConditionIdxsFromName(condList);
    conds = conds(~isnan(conds));
end
nConds = length(conds);
dataPoints = getEarlyLateData_v2(this,label, ...
    this.metaData.conditionName(conds),0,n,Ne,Nf);
legStr = cell(size(n));
for l = 1:length(label)
    dd = nan(length(conds),length(dataPoints));
    ee = nan(length(conds),length(dataPoints));
    for jj = 1:length(dataPoints)
        %Mean for each condition, along dim=2
        dd(:,jj) = mean(dataPoints{jj}(:,:,l), 2, 'omitnan');
        ee(:,jj) = std(dataPoints{jj}(:,:,l), [], 2, ...
            'omitnan')/sqrt(size(dataPoints{jj},2));
        xx(:,jj) = [jj:(length(dataPoints)+1):(numel(dd)+length(conds))]';
        if n(jj) < 0
            legStr{jj} = ['Last ' num2str(-n(jj)) ' strides'];
        else
            legStr{jj} = ['First ' num2str(n(jj)) ' strides'];
        end
    end

    %axes(ah(l))
    subplot(ah(l))
    hold on
    if nargin < 7 ||isempty(mode)
        mode = 1;
    end
    switch mode
        case 1
            hBar = bar(dd);
            %This is needed, otherwise hBar.XOffset is ill-defined on the
            %next line
            drawnow
            xb = bsxfun(@plus, hBar(1).XData, [hBar.XOffset]');
            errorbar(xb',dd,ee,'.','LineWidth',2)
            xTickPos = mean(xb,1);
        otherwise
            if length(n) > 1
                dd = [dd'; nan(length(conds),2)'];
                ee = [ee'; nan(length(conds),2)'];
            end
            errorbar(dd(:),ee(:),'LineWidth',2)
            xTickPos = [1:size(dd,1):numel(dd)] +(length(dataPoints)-1)/2;
            legStr2  = this.subData.ID;
    end


    set(gca,'XTick',xTickPos,'XTickLabel', ...
        this.metaData.conditionName(conds))
    axis tight
    title([label{l},' (',this.subData.ID ')'])
    hold off
end
switch mode
    case 1
        legend(legStr);
    case 2
        legend(legStr2)
end
plotHandles = ah;
end

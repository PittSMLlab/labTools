function figHandle = plotParamBarsByConditions(this,label,earlyNumber, ...
    lateNumber,exemptLast,condList,significanceThreshold)
%PLOTPARAMBARSBYCONDITIONS Bar plot of very early/early/late strides.
%
%   For each label, plots the mean over strides of the first N1 (very
% early), first N2 (early) and last N3 (late, skipping the last Ne)
% strides of each condition, with standard error bars.
%
% Inputs:
%   this                  - adaptationData object
%   label                 - cell array of parameter labels, one subplot
%                           each
%   earlyNumber           - strides in the early set (default 5)
%   lateNumber            - strides in the late set (default 20)
%   exemptLast            - strides skipped at the end (default 5)
%   condList              - cell array of condition names (default: all
%                           named)
%   significanceThreshold - accepted but unused
%
% Outputs:
%   figHandle - figure handle
%
% NOTE: superseded by PLOTPARAMBARSBYCONDITIONSV2. No repo caller.
%
% Toolbox Dependencies: None
%
% See also PLOTPARAMBARSBYCONDITIONSV2, GETEARLYLATEDATA.

N1 = 3; %very early number of points
if nargin < 3 || isempty(earlyNumber)
    N2 = 5; %early number of points
else
    N2 = earlyNumber;
end
if nargin < 4 || isempty(lateNumber)
    N3 = 20; %late number of points
else
    N3 = lateNumber;
end
if nargin < 5 || isempty(exemptLast)
    Ne = 5;
else
    Ne = exemptLast;
end

[ah,figHandle] = optimizedSubPlot(length(label),4,1);

if nargin < 6 || isempty(condList)
    conds = find(~cellfun(@isempty,this.metaData.conditionName));
else
    conds = this.getConditionIdxsFromName(condList);
    conds = conds(~isnan(conds));
end
nConds = length(conds);
[allVeryEarlyPoints,allEarlyPoints,allLatePoints] = getEarlyLateData...
    (this,label,this.metaData.conditionName(conds),0,N2,N3,Ne);
for l = 1:length(label)
    earlyPoints     = allEarlyPoints(:,:,l);
    veryEarlyPoints = allVeryEarlyPoints(:,:,l);
    latePoints      = allLatePoints(:,:,l);
    % earlyPoints=NaN(nConds,N2);
    % veryEarlyPoints=NaN(nConds,N1);
    % latePoints=NaN(nConds,N3);
    % for i=1:nConds
    %     aux=this.getParamInCond(label(l),conds(i));
    %     try %Try to get the first strides, if there are enough
    %         veryEarlyPoints(i,:)=aux(1:N1);
    %         earlyPoints(i,:)=aux(1:N2);
    %     catch %In case there aren't enough strides, assign NaNs to all
    %         veryEarlyPoints(i,:)=NaN;
    %         earlyPoints(i,:)=NaN;
    %     end
    %     %Last 20 steps, excepting the very last 5
    %     try
    %         latePoints(i,:)=aux(end-N3-Ne+1:end-Ne);
    %     catch
    %         latePoints(i,:)=NaN;
    %     end
    % end
    axes(ah(l))
    hold on

    bar((1:3:3*nConds)-0.25,mean(veryEarlyPoints, 2, 'omitnan'),0.15, ...
        'FaceColor',[0.8,0.8,0.8])
    bar((1:3:3*nConds)+0.25,mean(earlyPoints, 2, 'omitnan'),0.15, ...
        'FaceColor',[0.6,0.6,0.6])
    bar(2:3:3*nConds,mean(latePoints, 2, 'omitnan'),0.3,'FaceColor', ...
        [0,0.3,0.6])
    errorbar((1:3:3*nConds)-0.25,mean(veryEarlyPoints, 2, 'omitnan'), ...
        std(veryEarlyPoints, [], 2, ...
        'omitnan')/sqrt(size(veryEarlyPoints,2)),'.','LineWidth',2)
    errorbar((1:3:3*nConds)+0.25,mean(earlyPoints, 2, 'omitnan'), ...
        std(earlyPoints, [], 2, 'omitnan')/sqrt(size(earlyPoints,2)), ...
        '.','LineWidth',2)
    errorbar(2:3:3*nConds,mean(latePoints, 2, 'omitnan'), ...
        std(latePoints, [], 2, 'omitnan')/sqrt(size(latePoints,2)),'.', ...
        'LineWidth',2)
    %plot([1:3:3*nConds]-.25,veryEarlyPoints,'x','LineWidth',2,'Color', ...
    %    [0,.8,.3])
    %plot([1:3:3*nConds]+.25,earlyPoints,'x','LineWidth',2,'Color', ...
    %    [0,.8,.3])
    %plot(2:3:3*nConds,latePoints,'x','LineWidth',2,'Color',[0,.6,.2])
    xTickPos = (1:3:3*nConds)+0.5;
    set(gca,'XTick',xTickPos,'XTickLabel', ...
        this.metaData.conditionName(conds))
    axis tight
    title([label{l},' (',this.subData.ID ')'])
    hold off
end
legend(['First ' num2str(N1) ' strides'], ...
    ['First ' num2str(N2) ' strides)'], ...
    ['Last ' num2str(N3) '(-' num2str(Ne) ') strides)']);
end

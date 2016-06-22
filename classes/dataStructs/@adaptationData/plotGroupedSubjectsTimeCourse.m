function [figHandle,allData]=plotGroupedSubjectsTimeCourse(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,earlyNumber,lateNumber,exemptLast,legendNames)
error('This function needs fixing, try using adaptationData.plotAvgTimeCourse')
%% This function needs fixing, suggestion, call on this piece of code:

% colorScheme
% color_palette=color_palette([1,3,2,4:size(color_palette,1)],:);
% binwidth=10;
% trialMarkerFlag=0;
% indivFlag=0; %This uses different subplots for each parameter, otherwise they are on top of each other (?)
% indivSubs=[];
% colorOrder=color_palette;
% colors=color_palette;
% biofeedback=[];
% groupNames={'Keyboard','Alpha'};
% medianFlag=1;
% plotIndividualsFlag=0;
% legendNames=[];
% significanceThreshold=.05;
% numberOfStrides=[100 -50];
% labels=kG.adaptData{1}.data.getLabelsThatMatch('Norm2$')';
% removeBiasFlag=0;
% significancePlotMatrix=[];
% alignEnd=abs(numberOfStrides(2));
% signifPlotMatrixConds=zeros(6);
% signifPlotMatrixConds(2,[5,6])=1;
% signifPlotMatrixConds(sub2ind([6,6],[1:5],[2:6]))=1;
% %Time courses:
% %fh=adaptationData.plotAvgTimeCourse({patientsNoP15Unbiased.adaptData,groupsUnbiased{2}.adaptData},labels,conds,binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder,biofeedback,removeBiasFlag,groupNames,medianFlag,ph(:,1),alignEnd);
% fh=adaptationData.plotAvgTimeCourse({kGUnb.adaptData,bGUnb.adaptData},labels,conds,binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder,biofeedback,removeBiasFlag,groupNames,medianFlag,[],alignEnd);

%%
colorScheme
if nargin<4 || isempty(plotIndividualsFlag)
    plotIndividualsFlag=true;
end
if nargin<9 || isempty(legendNames) || length(legendNames)<length(adaptDataList)
    legendNames=adaptDataList;
end

%First: see if adaptDataList is a single subject (char), a cell
%array of subject names (one group of subjects), or a cell array of cell arrays of
%subjects names (several groups of subjects), and put all the
%cases into the same format
if isa(adaptDataList,'cell')
    if isa(adaptDataList{1},'cell')
        auxList=adaptDataList;
    else
        auxList{1}=adaptDataList;
    end
elseif isa(adaptDataList,'char')
    auxList{1}={adaptDataList};
end
Ngroups=length(auxList);

if nargin<6 || isempty(earlyNumber)
    N2=5; %early number of points
else
    N2=earlyNumber;
end
if nargin<7 || isempty(lateNumber)
    N3=20; %late number of points
else
    N3=lateNumber;
end
if nargin<8 || isempty(exemptLast)
    Ne=5;
else
    Ne=exemptLast;
end

[ah,figHandle]=optimizedSubPlot(length(label),4,1);

a=load(auxList{1}{1});
aux=fields(a);
this=a.(aux{1});
if nargin<5 || isempty(condList)
    condList=this.metaData.conditionName(~cellfun(@isempty,this.metaData.conditionName));
    conds=condList;
else
    conds=condList;
    for i=1:length(condList)
        if iscell(condList{i})
            condList{i}=condList{i}{1};
        end
    end
end
nConds=length(conds);
for l=1:length(label)
    axes(ah(l))
    hold on
    
    for group=1:Ngroups
        [veryEarlyPoints,earlyPoints,latePoints]=adaptationData.getGroupedData(auxList{group},label(l),conds,removeBiasFlag,N2,N3,Ne);
        %plot
        offset=(N2+N3+15);
        plot([1 offset*nConds],[0,0],'k--')
        for i=1:nConds
            clear hLeg
            %Early part
            xCoord=(i-1)*offset + [1:N2];
            yCoord=nanmean(earlyPoints(i,:,:),3);
            yStd=nanstd(earlyPoints(i,:,:),[],3);
            hh=patch([xCoord,xCoord(end:-1:1)],[yCoord-yStd,yCoord(end:-1:1)+yStd(end:-1:1)],colorGroups{group},'EdgeColor','none','FaceAlpha',.5);
            uistack(hh,'bottom')
            hLeg(1)=plot(xCoord,yCoord,'LineWidth',3,'Color',colorGroups{group});
            if plotIndividualsFlag==1
                for j=1:size(earlyPoints,3)
                    hLeg(j+1)=plot((i-1)*offset + [1:N2],squeeze(earlyPoints(i,:,j)),'Color',colorConds{mod(j,length(colorConds))+1});
                end
            end
            %LAte part:
            xCoord=(i-1)*offset + [offset-N3-4:offset-5];
            yCoord=nanmean(latePoints(i,:,:),3);
            yStd=nanstd(latePoints(i,:,:),[],3);
            hh=patch([xCoord,xCoord(end:-1:1)],[yCoord-yStd,yCoord(end:-1:1)+yStd(end:-1:1)],colorGroups{group},'EdgeColor','none','FaceAlpha',.5);
            uistack(hh,'bottom')
            plot(xCoord,yCoord,'LineWidth',3,'Color',colorGroups{group})
            if plotIndividualsFlag==1
                for j=1:size(earlyPoints,3)
                    plot((i-1)*offset + [offset-N3-4:offset-5],squeeze(latePoints(i,:,j)),'Color',colorConds{mod(j,length(colorConds))+1})
                end
            end
        end
        %Save all data plotted into struct
        if Ngroups==1
            allData{l}.early=earlyPoints;
            allData{l}.late=latePoints;
            allData{l}.veryEarly=veryEarlyPoints;
            allData{l}.subIDs=auxList{group};
        else
            allData{l}.group{group}.early=earlyPoints;
            allData{l}.group{group}.late=latePoints;
            allData{l}.group{group}.veryEarly=veryEarlyPoints;
            allData{l}.group{group}.subIDs=auxList{group};
        end
        allData{l}.parameterLabel=label{l};
    end
    xTickPos=N2+5+[0:nConds-1]*offset;
    set(gca,'XTick',xTickPos,'XTickLabel',condList)
    if removeBiasFlag==1
        title([label{l} ' w/o Bias'])
    else
        title([label{l}])
    end
    hold off
end
linkaxes(ah,'x')
axis tight
condDes = this.metaData.conditionName;
if Ngroups==1
    legend(hLeg,[{'Group mean'}, legendNames]);
else
    legStr={};
    for group=1:Ngroups
        legStr=[legStr, {['Group ' num2str(group) ' average']}];
    end
    legend(legStr)
end
end


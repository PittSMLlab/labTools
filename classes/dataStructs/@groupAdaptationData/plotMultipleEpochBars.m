function [figHandle,allData]=plotMultipleEpochBars(groups,labels,eps,plotIndividualsFlag,legendNames,plotHandles,colors,medianFlag,significanceThreshold,posthocGroupFlag,posthocEpochFlag,posthocGroupByEpochFlag,posthocEpochByGroupFlag,removeBaseEpochFlag)



%This function replaces plotMultipleGroupBars

%TODO: replace repeated functionality with a call to plotPrettyBars()

%This wil fail if plotHandles is not given -Pablo
set(plotHandles,'Clipping','off')

if isempty(colors)
    colorScheme
    colors=color_palette;
end

%make doing stats optimal
if isempty(significanceThreshold)
    statsFlag=0;
else
    statsFlag=1;
end

if isa(eps,'cell')
    dt=NaN(length(groups,1));
    for i=1:length(groups)
        dt(i)=size(eps{1},1);
    end
    nep=max(dt);
else
    nep=size(eps,1);
end

if isempty(medianFlag)
    medianFlag=0;
end

if isa(groups,'struct')
    ff=fields(groups);
    aux=cell(size(ff));
    for i=1:length(ff)
        aux{i}=getfield(groups,ff{i});
    end
    groups=aux;
end
if ~isa(groups,'cell') || ~isa(groups{1},'groupAdaptationData')
    error('First argument needs to be a cell array of groupAdaptationData objects')
end


if isempty(removeBaseEpochFlag)
    removeBaseEpochFlag=0;
end

nsubs=NaN(length(groups),1);
for i=1:length(groups)
    nsubs(i)=length(groups{i}.adaptData);
end
nsub=max(nsubs);

if removeBaseEpochFlag==1%remove baseline epoch for plotting, but not for stats
    for i=1:length(groups)
        group2{i}=groups{i};
        groups{i}=groups{i}.removeBadStrides;
        groups{i}=groups{i}.removeBaselineEpoch(eps(1,:),[]);
    end
else group2=groups;
end

%[figHandle,allData]=adaptationData.plotGroupedSubjectsBarsv2(groups,label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,[],plotHandles,colors,medianFlag);
allData=NaN(length(groups),length(labels),nep,nsub);
for i=1:length(groups)
    if isa(eps,'cell')%this allows for different eps for each group
        groupOutcomes{i}=groups{i}.getEpochData(eps{i},labels);% nLabels x neps x nSubjects
    else
        groupOutcomes{i}=groups{i}.getEpochData(eps,labels);% nLabels x neps x nSubjects
    end
    allData(i,1:length(labels),1:nep,1:size(groupOutcomes{i},3))=groupOutcomes{i};%nGroups x nLabels x neps x nSubjects
    %I think this will fail if different # of epochs are defined for each group
end




%generate xlocations and matrices to plot
xData=1:nep+1;xData=xData*(length(groups)+1);xData=xData-length(groups);
for i=1:length(groups)
    xval(:,i)=xData+(i-1)';

end
xval=xval(1:end-1,:);

if medianFlag==0;
    plotData=nanmean(allData,4);
    tempVarData=nanstd(allData,false,4);
    varData=NaN(size(tempVarData));
    for i=1:length(groups)
        varData(i,:,:)=tempVarData(i,:,:)./sqrt(size(groupOutcomes{i},3));
    end
else
    plotData=nanmedian(allData,4);
    tempVarData=nanstd(allData,false,4);
    varData=NaN(size(tempVarData));
    for i=1:length(groups)
        varData(i,:,:)=tempVarData(i,:,:)./sqrt(size(groupOutcomes{i},3));
    end

end

%plot each parameter in different axis
for p=1:length(labels)%each parameter has different axis, eps are plotted in single axis
    hold(plotHandles(p))
    for i=1:length(groups)
        bar(plotHandles(p),xval(:,i),squeeze(plotData(i,p,:)),'FaceColor',colors(i,:),'BarWidth',0.2)
        errorbar(plotHandles(p),xval(:,i),squeeze(plotData(i,p,:)),squeeze(varData(i,p,:)),'LineStyle','none','color','k','LineWidth',2)
        if plotIndividualsFlag==1
            plot(plotHandles(p),xval(:,i)-.3,squeeze(allData(i,p,:,:)),'.','MarkerSize', 15, 'Color',[150 150 150]./255)
        end
    end


    if isa(eps,'cell')
        set(plotHandles(p),'XTick',mean(xval,1),'XTickLabels',eps{1}.Properties.ObsNames,'FontSize',12)
    else
        set(plotHandles(p),'XTick',mean(xval,2),'XTickLabels',eps.Properties.ObsNames,'FontSize',12)
    end
    title(plotHandles(p),labels{p});


   if  statsFlag==1
    %perform stats
    [model,btab,wtab,maineff,posthocGroup,posthocEpoch,posthocEpochByGroup,posthocGroupByEpoch]=groupAdaptationData.AnovaEpochs(group2,legendNames,labels(p),eps,significanceThreshold);
    %determine y positions of sign bars
    yrange=get(gca,'Ylim');
    delta=abs(yrange(1)-yrange(2))/20;

    if posthocGroupFlag==1
    elseif posthocEpochFlag==1 && maineff.p(2)<significanceThreshold%indicate signficant differences between epochs for the groups combined
        ymax=max(yrange)+delta;
        % find comparison of interest and check for significance
        for c=1:size(posthocEpoch,1)
            if posthocEpoch.pvalBonferroni(c)<significanceThreshold
                ep1=find(not(cellfun('isempty',regexp(eps.Properties.ObsNames,['^',posthocEpoch.ep1{c}]))));
                ep2=find(not(cellfun('isempty',regexp(eps.Properties.ObsNames,['^',posthocEpoch.ep2{c}]))));
                plot(plotHandles(p),[mean(xval(ep1,:)) mean(xval(ep2,:))],[ymax,ymax],'Color',[0.5 0.5 0.5],'LineWidth',2)
                ymax=ymax+delta;
            end
        end
    elseif posthocEpochByGroupFlag==1 (maineff.p(2)<significanceThreshold || maineff.p(3)<significanceThreshold)%indicate significant differences between epochs per group
        ymax=max(yrange)+0.5*delta;
        % find comparison of interest and check for significance
        for c=1:size(posthocEpochByGroup,1)
            if posthocEpochByGroup.pvalBonferroni(c)<significanceThreshold
                ep1=find(not(cellfun('isempty',regexp(eps.Properties.ObsNames,['^',posthocEpochByGroup.ep1{c}]))));
                ep2=find(not(cellfun('isempty',regexp(eps.Properties.ObsNames,['^',posthocEpochByGroup.ep2{c}]))));
                g=find(not(cellfun('isempty',regexp(legendNames,['^',posthocEpochByGroup.group{c}]))));
                plot(plotHandles(p),[xval(ep1,g),xval(ep2,g)],[ymax,ymax],'Color',colors(g,:))
                ymax=ymax+0.5*delta;
            end
        end
    elseif posthocGroupByEpochFlag==1 && (maineff.p(1)<significanceThreshold || maineff.p(3)<significanceThreshold)%indicate significant differences between groups by epoch
        prevEpoch=0;ymax=max(yrange);
        for c=1:size(posthocGroupByEpoch,1)
            epoch=find(not(cellfun('isempty',regexp(eps.Properties.ObsNames,['^',posthocGroupByEpoch.epoch{c}]))));
            if epoch>prevEpoch;
                ymax=max(yrange);
            end
            if posthocGroupByEpoch.pvalBonferroni(c)<significanceThreshold
                g1=find(not(cellfun('isempty',regexp(legendNames,['^',posthocGroupByEpoch.group_1{c}]))));
                g2=find(not(cellfun('isempty',regexp(legendNames,['^',posthocGroupByEpoch.group_2{c}]))));
                plot(plotHandles(p),[xval(epoch,g1), xval(epoch,g2)],[ymax,ymax],'Color',[0.5 0.5 0.5],'LineWidth',2)
                ymax=ymax+delta;
            end
            prevEpoch=epoch;
        end
    end
    if p==1
        ll=findobj(plotHandles(p),'Type','Bar');
        h=legend(ll(fliplr(1:length(ll))),legendNames);
    end
   end
end
set(plotHandles,'FontSize',20)
figHandle=gcf;

%TO DO: add stats
%
%
%
%     for e=1:length(eps)
%         %subplot(nrows,ncols,p*nrows-ncols+e)
%         %hold on
%           hold(ha(p,e))
%         for i = 1:length(groupOrder)
%
%             bar(ha(p,e),xval(i),nanmean(groupOutcomes{groupInd(i)}(ParInd(p),epInd(e),:)),'FaceColor',colcodes(groupInd(i),:));
%             errorbar(ha(p,e),xval(i),nanmean(groupOutcomes{groupInd(i)}(ParInd(p),epInd(e),:)),nanstd(groupOutcomes{groupInd(i)}(ParInd(p),epInd(e),:))./sqrt(10),'LineWidth',2,'Color','k')
%             if indSubFlag==1;
%                 plot(ha(p,e),xval(i)+0.2,squeeze(groupOutcomes{groupInd(i)}(ParInd(p),epInd(e),:)),'ok')
%             end
%             %xorder(i)=groupInd(i);
%         end
%         if e==1
%             ylabel(ha(p,e),pars{p})
%         end
%         if p==nrows
%             xlabel(ha(p,e),eps{e})
%         end
%         if p==1 && e==ncols
%            ll=findobj(ha(p,e),'Type','Bar');
%            legend(ha(p,e),ll(fliplr(xval)),groupOrder)
%         end
%
%         if sameScaleFlag==0
%             lims=get(ha(p,e),'YLim');
%             set(ha(p,e),'YLim',[min(lims) max(lims)],'YTick',[min(lims) max(lims)]);
%             set(ha(p,e),'YTickLabel',[min(lims) max(lims)],'XLim',[0.5 length(xval)+0.5],'FontSize',12);
%         end
%
%     end
%     %lims=cell2mat(get(ha(p,:),'YLim'));
%     if sameScaleFlag==1;
%         lims=get(ha(p,:),'YLim');
%         if length(eps)>1
%             lims=cell2mat(lims);
%         end
%         set(ha(p,:),'YLim',[min(min(lims)) max(max(lims))],'YTick',[min(min(lims)) max(max(lims))],'XLim',[0.5 length(xval)+0.5],'FontSize',12);
%         set(ha(p,1),'YTickLabel',[min(min(lims)) max(max(lims))]);
%     end
% end
%
%
% %Add bars comparing groups:
% nGroups=length(groups);
% if nGroups>1
%     %[p]=compareTwoGroups(groups,label,condition,numberOfStrides,exemptFirst,exemptLast);
%     if ~isempty(significanceThreshold)
%         ch=findobj(figHandle,'Type','Axes');
%         for i=1:length(ch)
%             aux=find(strcmp(label,ch(i).Title.String));
%             if ~isempty(aux)
%                 subplot(ch(i))
%                 hold on
%
%                 clear XData YData
%                 b=findobj(ch(i),'Type','Bar');
%                 if ~isempty(b)
%                     for j=1:length(b)
%                         XData(j,:)=b(end-j+1).XData;
%                         YData(j,:)=b(end-j+1).YData;
%                     end
%                     try
%                         XData=reshape(XData,[length(numberOfStrides),nGroups,length(condList)]);
%                         YData=reshape(YData,[length(numberOfStrides),nGroups,length(condList)]);
%                     catch %For back compatibility with bar command
%                         XData=reshape(XData(1:2:end,:),[length(numberOfStrides),nGroups,length(condList)]);
%                         YData=reshape(YData(1:2:end,:),[length(numberOfStrides),nGroups,length(condList)]);
%                     end
%                     %yRef=.1*(max(YData(:))-min(YData(:)));
%                     %yRef=.5*std(YData(:));
%                     aa=axis;
%                     yOff=max([max(YData(:)) aa(4)]);
%                     yOff2=min([min(YData(:)) aa(3)]);
%                     yRef=.05*(yOff-yOff2);
%                     yOff2=yOff2+5*yRef;
%                     XData=squeeze(XData(:,1,:));
%                     XData=XData(:);
%                     YData=squeeze(YData(:,1,:));
%                     YData=YData(:);
%
%                     counter=0;
%                     signifPlotMatrixConds=signifPlotMatrixConds==1 | signifPlotMatrixConds'==1;
%                     M=size(signifPlotMatrixConds,2);
%                     NN=sum(signifPlotMatrixConds(:)==1)/2; %Total number of comparisons to be made
%                     for j=1:length(XData) %For each condition
%                         [a1,a2]=ind2sub([size(allData.group{1},2),size(allData.group{1},1)],j);
%                         data1=squeeze(allData.group{1}(a2,a1,aux,:));
%                         [b1,b2]=ind2sub([size(allData.group{2},2),size(allData.group{1},1)],j);
%                         data2=squeeze(allData.group{2}(b2,b1,aux,:));
%                         %Sanity check:
%                         if medianFlag==0
%                             sData=nanmean(data1);
%                         else
%                             sData=nanmedian(data1);
%                         end
%                         if sData~=YData(j) %data2 is the data I believe is plotted in the bar positioned in x=XData(k), and should have height y=YData(k)
%                             %Mismatch means that I am wrong, and
%                             %therefore should not be overlaying the
%                             %stats on the given bar plots
%                             error('Stride group order is different than expected')
%                         end
%
%                         %2-sample t-test btw the first two groups:
%                         if significancePlotMatrixGroups(1,2)==1 || significancePlotMatrixGroups(2,1)==1
%                             if medianFlag==0
%                                 [~,pp]=ttest2(data1,data2); %Use ttest2 to do independent 2-sample t-test
%                             else
%                                 [pp]=ranksum(data1,data2); %Use ranksum 2 to do independent 2-sample non-param testing
%                             end
%                             if pp<significanceThreshold%/(length(numberOfStrides)*length(condList))
%                                 lh=plot(XData(j)+[0,1],yOff+yRef*[1,1],'m','LineWidth',2);
%                                 lh.Annotation.LegendInformation.IconDisplayStyle='off';
%                                 %text(XData(j)-.25,yOff+yRef*1.8,[num2str(pp,'%1.1g')],'Color','m')
%                                 if pp>significanceThreshold/10
%                                     text(XData(j)+.25,yOff+yRef*1.4,['*'],'Color','m')
%                                 else
%                                     text(XData(j)+.25,yOff+yRef*1.4,['**'],'Color','m')
%                                 end
%                             end
%                         end
%                         %paired t-tests btw baseline and each other
%                         %condition for each group
%
%                         NNN=sum(signifPlotMatrixConds(j,[j+1:end])); %Comparisons for this specific condition
%
%                         for l=[j+1:M]
%                             if signifPlotMatrixConds(j,l)==1
%                                 counter=counter+1;
%                                 for k=1:length(allData.group)
%                                     [a1,a2]=ind2sub([size(allData.group{k},2),size(allData.group{k},1)],l);
%                                     data1=squeeze(allData.group{k}(a2,a1,aux,:));
%                                     [b1,b2]=ind2sub([size(allData.group{k},2),size(allData.group{k},1)],j);
%                                     data2=squeeze(allData.group{k}(b2,b1,aux,:));
%                                     if medianFlag==0
%                                         [~,pp]=ttest(data1,data2); %Use ttest to do paired t-test
%                                     else
%                                         [pp]=signrank(data1,data2); %Use signrank to paired non-param testing
%                                     end
%                                     if pp<significanceThreshold%/(length(numberOfStrides)*length(condList))
%                                         %    plot([XData(l) XData(j)]+(k-1),yOff2-yRef*[1,1]*4*(k + (counter-1)/NN),'Color','k','LineWidth',1)
%                                         %    %text(XData(l)-1.5,yOff2-yRef*4*(k + (counter-1.5)/NN),[num2str(pp,'%1.1g')],'Color',colors(k,:))
%                                         %    if pp>significanceThreshold/10
%                                         %        text(XData(l)-1.5+(k-1),yOff2-yRef*4*(k + (counter-1.5)/NN),['o'],'Color',colors(mod(k-1,length(colors))+1,:))
%                                         %    else
%                                         %        text(XData(l)-1.5+(k-1),yOff2-yRef*4*(k + (counter-1.5)/NN),['oo'],'Color',colors(mod(k-1,length(colors))+1,:))
%                                         %    end
%                                         %end
%                                     end
%                                 end
%                             end
%
%                         end
%                     end
%                     aa=axis;
%                     try
%                         axis([aa(1:2) min([yOff2-yRef*4*(length(allData.group)+1) aa(3)]) max([yOff+2*yRef aa(4)])])
%                     catch
%                         axis tight
%                     end
%                     %Alt way - using RM stats (works with only two groups
%                     %so far!)
%                     relevantData=reshape(permute(allData.group{1}(:,:,aux,:),[2,1,3,4]),length(condList)*2,length(groups{1}.ID));
%                     groupMembership=ones(length(groups{1}.ID),1);
%                     IDs=repmat(groups{1}.ID(1),length(groups{1}.ID),1);
%                     %Cat all groups:
%                     for kk=2:length(allData.group)
%                         relevantData=cat(2,relevantData,reshape(permute(allData.group{kk}(:,:,aux,:),[2,1,3,4]),length(condList)*2,length(groups{kk}.ID)));
%                         groupMembership=[groupMembership; kk*ones(length(groups{kk}.ID),1)];
%                         IDs=[IDs; repmat(groups{kk}.ID(1),length(groups{kk}.ID),1)]; %Each group gets assigned the ID of the first member
%                     end
%                     dim1Names=[strcat('Early',condList);strcat('Late',condList)];
%                     %dim1Names=[strcat('Early',condList)';strcat('Late',condList)']; %Order in which XData is indexed;
%                     dim1Names=dim1Names(:);
%                     dim1Names=cellfun(@(x)  regexprep(x,'[^\w'']',''),dim1Names(1:end),'UniformOutput',false);
%                     Groups=IDs;
%                     auxStr=['t = table(IDs,Groups'];
%                     auxStr2=[];
%                     for aauxCounter=1:size(relevantData,1)
%                         auxStr=[auxStr ',relevantData(' num2str(aauxCounter) ',:)'''];
%                         auxStr2=[auxStr2 ',''t' num2str(aauxCounter-1) ''''];
%                     end
%                     auxStr=[auxStr ',''VariableNames'',{''ID'',''Group''' auxStr2 '});'];
%                     eval(auxStr)
%                     wt=table(dim1Names,'VariableNames',{'Condition'});
%                     rm = fitrm(t,['t0-t' num2str(size(relevantData,1)-1) ' ~ Group'],'WithinDesign',wt,'WithinModel','Condition');
%                     ra=ranova(rm);
%                     aa=anova(rm);
%                     %[~,tbl]=anova2(relevantData',size(allData.group{1},4),'off'); %This fails for imbalanced groups
%                     phoc=rm.multcompare('Condition','By','Group','ComparisonType','lsd'); %Unpaired t-tests; this is NOT fine, conditions are naturally paired
%                     phoc2=rm.multcompare('Group','By','Condition','ComparisonType','lsd'); %Unpaired t-tests; this is fine
%                     xx=get(gca,'YLim');
%                     xx2=diff(xx);
%                     xx=mean(xx);
%                     yy=get(gca,'XLim');
%                     yk=-.01;
%                     text(mean(yy(2))-yk*diff(yy),xx+1.75*xx2/8,'Mauchly:','FontWeight','bold')
%                     if rm.mauchly.pValue>.05
%                         text(mean(yy(2))-yk*diff(yy),xx+1*xx2/8,['p= ' num2str(rm.mauchly.pValue)])
%                     else
%                         text(mean(yy(2))-yk*diff(yy),xx+1*xx2/8,['p= ' num2str(rm.mauchly.pValue)],'Color','b')
%                     end
%                     text(mean(yy(2))-yk*diff(yy),xx+.25*xx2/8,'RM-ANOVA stats:','FontWeight','bold')
%                     text(mean(yy(2))-yk*diff(yy),xx-.5*xx2/8,['Group: F=' num2str(aa.F(2),2) ', p=' num2str(aa.pValue(2),2)],'Fontsize',10)
%                     if rm.mauchly.pValue>.05
%                         text(mean(yy(2))-yk*diff(yy),xx-1.25*xx2/8,['Cond: F=' num2str(ra.F(1),2) ', p=' num2str(ra.pValue(1),2)],'Fontsize',10)
%                         text(mean(yy(2))-yk*diff(yy),xx-2*xx2/8,['Interac.: F=' num2str(ra.F(2),2) ', p=' num2str(ra.pValue(2),2)],'Fontsize',10)
%                     else
%                         text(mean(yy(2))-yk*diff(yy),xx-1.25*xx2/8,['Cond: F=' num2str(ra.F(1),2) ', pGG=' num2str(ra.pValueGG(1),2)],'Fontsize',10,'Color','b')
%                         text(mean(yy(2))-yk*diff(yy),xx-2*xx2/8,['Interac.: F=' num2str(ra.F(2),2) ', pGG=' num2str(ra.pValueGG(2),2)],'Fontsize',10,'Color','b')
%                     end
%                     text(mean(yy(2))-yk*diff(yy),xx-2.75*xx2/8,['Post-hoc (unpr.):'],'Fontsize',10,'FontWeight','bold')
%                     text(mean(yy(2)),xx-3.5*xx2/8,['* p<.05'],'Fontsize',10)
%                     text(mean(yy(2)),xx-4.25*xx2/8,['** p<Bonferroni'],'Fontsize',10)
%                     %text(mean(yy(2))-.1*diff(yy),xx-2.75*xx2/8,'2-ANOVA stats:')
%                     %text(mean(yy(2))-.1*diff(yy),xx-3.5*xx2/8,['Group: F=' num2str(tbl{3,5},2) ', p=' num2str(tbl{3,6},2)],'Fontsize',10,'FontWeight','bold')
%                     %text(mean(yy(2))-.1*diff(yy),xx-4.25*xx2/8,['Cond: F=' num2str(tbl{2,5},2) ', p=' num2str(tbl{2,6},2)],'Fontsize',10,'FontWeight','bold')
%                     %text(mean(yy(2))-.1*diff(yy),xx-5*xx2/8,['Interac.: F=' num2str(tbl{4,5},2) ', p=' num2str(tbl{4,6},2)],'Fontsize',10,'FontWeight','bold')
%
%                     Ncomp=sum(sum(triu(signifPlotMatrixConds),2),1) * length(allData.group); %Number of comparisons being done across eps
%                     Ncomp2=(.5*length(allData.group)*(length(allData.group)-1))*size(relevantData,1) ;%Number of comparisons being done across groups
%                     for kk=1:length(allData.group) %all groups
%                         counter=0;
%                         for ii=1:M %Each epoch
%                             for ll=[kk+1:length(allData.group)] %All the other groups
%                                 [~,pp3]=ttest2(relevantData(ii,groupMembership==kk),relevantData(ii,groupMembership==ll),'VarType','Unequal'); %Use ttest2 to do unpaired t-test
%                                 if medianFlag==1
%                                     [pp3]=ranksum(relevantData(ii,groupMembership==kk),relevantData(ii,groupMembership==ll)); %Use ranksum to paired non-param testing
%                                 end
%                                 c1=strcmp(dim1Names{ii},phoc2.Condition); %Finding comparisons that relate to condition ii
%                                 c2=strcmp(groups{kk}.ID{1},phoc2.Group_1);
%                                 c3=strcmp(groups{ll}.ID{1},phoc2.Group_2);
%                                 pp=phoc2.pValue(c1 & c2 & c3);%This is the same as using pp3
%                                 %disp(['post-hoc=' num2str(pp) ', t-test (unp)=' num2str(pp3) ', ranksum=' num2str(pp2)]) %This is to check that the post-hoc is indeed an unpaired t-test
%                                 if pp3<significanceThreshold
%                                     lh=plot(XData(ii)+[0,1],yOff+yRef*[1,1],'m','LineWidth',2);
%                                     lh.Annotation.LegendInformation.IconDisplayStyle='off';
%                                     %text(XData(j)-.25,yOff+yRef*1.8,[num2str(pp,'%1.1g')],'Color','m')
%                                     if pp>(significanceThreshold/Ncomp2) %Bonferroni threshold
%                                         text(XData(ii)+.25,yOff+yRef*1.4,['*'],'Color','m')
%                                     else
%                                         text(XData(ii)+.25,yOff+yRef*1.4,['**'],'Color','m')
%                                     end
%                                 end
%                             end
%                             for jj=[ii+1:M]
%                                 if signifPlotMatrixConds(ii,jj)==1
%                                     counter=counter+1;
%                                     %error('This doesnt work, figure it out')
%                                     [~,pp1]=ttest(relevantData(ii,groupMembership==kk),relevantData(jj,groupMembership==kk)); %Use ttest to do paired t-test
%                                     [~,pp3]=ttest2(relevantData(ii,groupMembership==kk),relevantData(jj,groupMembership==kk)); %Use ttest2 to do unpaired t-test. Should we use 'Vartype','unequal' ?
%                                     if medianFlag==1
%                                         [pp1]=signrank(relevantData(ii,groupMembership==kk),relevantData(jj,groupMembership==kk)); %Use signrank to paired non-param testing
%                                     end
%                                     c1=strcmp(dim1Names{ii},phoc.Condition_1); %Finding comparisons that relate to condition ii
%                                     c2=strcmp(dim1Names{jj},phoc.Condition_2);
%                                     c3=strcmp(groups{kk}.ID{1},phoc.Group);
%                                     pp=phoc.pValue(c1 & c2 & c3);
%                                     %disp(['post-hoc=' num2str(pp) ', t-test (paired)=' num2str(pp1) ', t-test (unp)=' num2str(pp3) ', signrank=' num2str(pp2)])
%                                     if pp1<(significanceThreshold)
%                                         lh=plot([XData(ii) XData(jj)]+(kk-1),yOff2-yRef*[1,1]*5*(kk + (counter-1.5)/NN),'Color',colors(mod(kk-1,length(colors))+1,:),'LineWidth',2);
%                                         lh.Annotation.LegendInformation.IconDisplayStyle='off';
%                                         if pp1>(significanceThreshold/(.5*Ncomp)) %Does not pass Bonferroni's criteria for significance
%                                             text(XData(jj)+kk-1,yOff2-yRef*5*(kk + (counter-1.5)/NN),['*'],'Color',colors(mod(kk-1,length(colors))+1,:))
%                                         else %Passes Bonferroni criteria
%                                             text(XData(jj)+kk-1,yOff2-yRef*5*(kk + (counter-1.5)/NN),['**'],'Color',colors(mod(kk-1,length(colors))+1,:))
%                                         end
%                                     end
%                                 end
%                             end
%                         end
%                     end
%                     aa=axis;
%                     axis tight
%                     bb=axis;
%                     axis([aa(1:2) bb(3) aa(4)])
%                     hold off
%                 end
%             end
%         end
%     end
%
% end

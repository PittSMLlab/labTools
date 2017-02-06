function [figHandle,allData]=plotMultipleGroupsBars(groups,label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,significanceThreshold,plotHandles,colors,significancePlotMatrixGroups,medianFlag,signifPlotMatrixConds)
            if nargin<3 || isempty(removeBiasFlag)
               warning('RemoveBiasFlag argument not provided, will NOT remove bias.')  %For efficiency, subjects should remove bias before hand, as it is a computationally intensive task that should be done the least number of times possible
               removeBiasFlag=0; 
            end
            if nargin<4
                plotIndividualsFlag=[];
            end
            if nargin<5
                condList=[];
            end
            if nargin<6
                numberOfStrides=[];
            end
            if nargin<7
                exemptFirst=[];
            end
            if nargin<8
                exemptLast=[];
            end
            if nargin<9
                legendNames=[];
            end
            if nargin<10
                significanceThreshold=[];
            end
            if nargin<11
                plotHandles=[];
            end
            if nargin<12 || isempty(colors)
                colorScheme
                colors=color_palette;
            end
            
            if nargin<14 || isempty(medianFlag)
                medianFlag=0;
            end
            if nargin<15 || isempty(signifPlotMatrixConds)
                M=length(condList)*length(numberOfStrides);
               signifPlotMatrixConds=zeros(M); 
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
            if nargin<13 || isempty(significancePlotMatrixGroups)
                M=length(groups);
                significancePlotMatrixGroups=ones(M);
            end
            [figHandle,allData]=adaptationData.plotGroupedSubjectsBarsv2(groups,label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,[],plotHandles,colors,medianFlag);
            
            %Add bars comparing groups:
            nGroups=length(groups);
            if nGroups>1
            %[p]=compareTwoGroups(groups,label,condition,numberOfStrides,exemptFirst,exemptLast);
            if ~isempty(significanceThreshold)
                ch=findobj(figHandle,'Type','Axes');
                for i=1:length(ch)
                    aux=find(strcmp(label,ch(i).Title.String));
                    if ~isempty(aux)
                    subplot(ch(i))
                    hold on

                    clear XData YData
                    b=findobj(ch(i),'Type','Bar');
                    if ~isempty(b)
                    for j=1:length(b)
                        XData(j,:)=b(end-j+1).XData;
                        YData(j,:)=b(end-j+1).YData;
                    end
                    try
                    XData=reshape(XData,[length(numberOfStrides),nGroups,length(condList)]);
                    YData=reshape(YData,[length(numberOfStrides),nGroups,length(condList)]);
                    catch %For back compatibility with bar command
                        XData=reshape(XData(1:2:end,:),[length(numberOfStrides),nGroups,length(condList)]);
                        YData=reshape(YData(1:2:end,:),[length(numberOfStrides),nGroups,length(condList)]);
                    end
                    %yRef=.1*(max(YData(:))-min(YData(:)));
                    %yRef=.5*std(YData(:));
                    aa=axis;
                    yOff=max([max(YData(:)) aa(4)]);
                    yOff2=min([min(YData(:)) aa(3)]);
                    yRef=.05*(yOff-yOff2);
                    yOff2=yOff2+5*yRef;
                    XData=squeeze(XData(:,1,:));
                    XData=XData(:);
                    YData=squeeze(YData(:,1,:));
                    YData=YData(:);
                    
                    counter=0;
                    signifPlotMatrixConds=signifPlotMatrixConds==1 | signifPlotMatrixConds'==1;
                    M=size(signifPlotMatrixConds,2);
                    NN=sum(signifPlotMatrixConds(:)==1)/2; %Total number of comparisons to be made
                    for j=1:length(XData) %For each condition 
                        [a1,a2]=ind2sub([size(allData.group{1},2),size(allData.group{1},1)],j);
                        data1=squeeze(allData.group{1}(a2,a1,aux,:));
                        [b1,b2]=ind2sub([size(allData.group{2},2),size(allData.group{1},1)],j);
                        data2=squeeze(allData.group{2}(b2,b1,aux,:));
                            %Sanity check:
                            if medianFlag==0
                                sData=nanmean(data1);
                            else
                                sData=nanmedian(data1);
                            end
                            if sData~=YData(j) %data2 is the data I believe is plotted in the bar positioned in x=XData(k), and should have height y=YData(k)
                                %Mismatch means that I am wrong, and
                                %therefore should not be overlaying the
                                %stats on the given bar plots
                                error('Stride group order is different than expected')
                            end
                            
                            %2-sample t-test btw the first two groups:
                            if significancePlotMatrixGroups(1,2)==1 || significancePlotMatrixGroups(2,1)==1
                                if medianFlag==0
                                    [~,pp]=ttest2(data1,data2); %Use ttest2 to do independent 2-sample t-test
                                else
                                    [pp]=ranksum(data1,data2); %Use ranksum 2 to do independent 2-sample non-param testing
                                end
                                if pp<significanceThreshold%/(length(numberOfStrides)*length(condList))
                                    plot(XData(j)+[0,1],yOff+yRef*[1,1],'m','LineWidth',2)
                                    %text(XData(j)-.25,yOff+yRef*1.8,[num2str(pp,'%1.1g')],'Color','m')
                                    if pp>significanceThreshold/10
                                        text(XData(j)+.25,yOff+yRef*1.4,['*'],'Color','m')
                                    else
                                        text(XData(j)+.25,yOff+yRef*1.4,['**'],'Color','m')
                                    end
                                end
                            end
                            %paired t-tests btw baseline and each other
                            %condition for each group
                            
                            NNN=sum(signifPlotMatrixConds(j,[j+1:end])); %Comparisons for this specific condition
                            
                            for l=[j+1:M]
                            if signifPlotMatrixConds(j,l)==1 
                                counter=counter+1;
                                for k=1:length(allData.group)
                                    [a1,a2]=ind2sub([size(allData.group{k},2),size(allData.group{k},1)],l);
                                    data1=squeeze(allData.group{k}(a2,a1,aux,:));
                                    [b1,b2]=ind2sub([size(allData.group{k},2),size(allData.group{k},1)],j);
                                    data2=squeeze(allData.group{k}(b2,b1,aux,:));
                                    if medianFlag==0
                                        [~,pp]=ttest(data1,data2); %Use ttest to do paired t-test
                                    else
                                        [pp]=signrank(data1,data2); %Use signrank to paired non-param testing
                                    end
                                    if pp<significanceThreshold%/(length(numberOfStrides)*length(condList))
                                    %    plot([XData(l) XData(j)]+(k-1),yOff2-yRef*[1,1]*4*(k + (counter-1)/NN),'Color','k','LineWidth',1)
                                    %    %text(XData(l)-1.5,yOff2-yRef*4*(k + (counter-1.5)/NN),[num2str(pp,'%1.1g')],'Color',colors(k,:))
                                    %    if pp>significanceThreshold/10
                                    %        text(XData(l)-1.5+(k-1),yOff2-yRef*4*(k + (counter-1.5)/NN),['o'],'Color',colors(mod(k-1,length(colors))+1,:))
                                    %    else
                                    %        text(XData(l)-1.5+(k-1),yOff2-yRef*4*(k + (counter-1.5)/NN),['oo'],'Color',colors(mod(k-1,length(colors))+1,:))
                                    %    end
                                    %end
                                end
                            end
                            end
                            
                    end
                    end
                    aa=axis;
                    try
                        axis([aa(1:2) min([yOff2-yRef*4*(length(allData.group)+1) aa(3)]) max([yOff+2*yRef aa(4)])])
                    catch
                        axis tight
                    end
                    %Alt way - using RM stats (works with only two groups
                    %so far!)
                    relevantData=reshape(permute(allData.group{1}(:,:,aux,:),[2,1,3,4]),length(condList)*2,length(groups{1}.ID));
                    groupMembership=ones(length(groups{1}.ID),1);
                    IDs=repmat(groups{1}.ID(1),length(groups{1}.ID),1);
                    %Cat all groups:
                    for kk=2:length(allData.group)
                        relevantData=cat(2,relevantData,reshape(permute(allData.group{kk}(:,:,aux,:),[2,1,3,4]),length(condList)*2,length(groups{kk}.ID)));
                        groupMembership=[groupMembership; kk*ones(length(groups{kk}.ID),1)];
                        IDs=[IDs; repmat(groups{kk}.ID(1),length(groups{kk}.ID),1)]; %Each group gets assigned the ID of the first member
                    end
                    dim1Names=[strcat('Early',condList);strcat('Late',condList)];
                    %dim1Names=[strcat('Early',condList)';strcat('Late',condList)']; %Order in which XData is indexed;
                    dim1Names=dim1Names(:);
                    dim1Names=cellfun(@(x)  regexprep(x,'[^\w'']',''),dim1Names(1:end),'UniformOutput',false);
                    Groups=IDs; 
                    auxStr=['t = table(IDs,Groups'];
                    auxStr2=[];
                    for aauxCounter=1:size(relevantData,1)
                        auxStr=[auxStr ',relevantData(' num2str(aauxCounter) ',:)'''];
                        auxStr2=[auxStr2 ',''t' num2str(aauxCounter-1) ''''];
                    end
                    auxStr=[auxStr ',''VariableNames'',{''ID'',''Group''' auxStr2 '});'];
                    eval(auxStr)
                    wt=table(dim1Names,'VariableNames',{'Condition'});
                    rm = fitrm(t,['t0-t' num2str(size(relevantData,1)-1) ' ~ Group'],'WithinDesign',wt,'WithinModel','Condition');
                    ra=ranova(rm);
                    aa=anova(rm);
                    %[~,tbl]=anova2(relevantData',size(allData.group{1},4),'off'); %This fails for imbalanced groups
                    phoc=rm.multcompare('Condition','By','Group','ComparisonType','lsd'); %Unpaired t-tests; this is NOT fine, conditions are naturally paired
                    phoc2=rm.multcompare('Group','By','Condition','ComparisonType','lsd'); %Unpaired t-tests; this is fine
                    xx=get(gca,'YLim');
                    xx2=diff(xx);
                    xx=mean(xx);
                    yy=get(gca,'XLim');
                    yk=-.01;
                    text(mean(yy(2))-yk*diff(yy),xx+1.75*xx2/8,'Mauchly:','FontWeight','bold')
                    if rm.mauchly.pValue>.05
                        text(mean(yy(2))-yk*diff(yy),xx+1*xx2/8,['p= ' num2str(rm.mauchly.pValue)])
                    else
                        text(mean(yy(2))-yk*diff(yy),xx+1*xx2/8,['p= ' num2str(rm.mauchly.pValue)],'Color','b')
                    end
                    text(mean(yy(2))-yk*diff(yy),xx+.25*xx2/8,'RM-ANOVA stats:','FontWeight','bold')
                    text(mean(yy(2))-yk*diff(yy),xx-.5*xx2/8,['Group: F=' num2str(aa.F(2),2) ', p=' num2str(aa.pValue(2),2)],'Fontsize',10)
                    if rm.mauchly.pValue>.05
                        text(mean(yy(2))-yk*diff(yy),xx-1.25*xx2/8,['Cond: F=' num2str(ra.F(1),2) ', p=' num2str(ra.pValue(1),2)],'Fontsize',10)
                        text(mean(yy(2))-yk*diff(yy),xx-2*xx2/8,['Interac.: F=' num2str(ra.F(2),2) ', p=' num2str(ra.pValue(2),2)],'Fontsize',10)
                    else
                        text(mean(yy(2))-yk*diff(yy),xx-1.25*xx2/8,['Cond: F=' num2str(ra.F(1),2) ', pGG=' num2str(ra.pValueGG(1),2)],'Fontsize',10,'Color','b')
                        text(mean(yy(2))-yk*diff(yy),xx-2*xx2/8,['Interac.: F=' num2str(ra.F(2),2) ', pGG=' num2str(ra.pValueGG(2),2)],'Fontsize',10,'Color','b')
                    end
                    text(mean(yy(2))-yk*diff(yy),xx-2.75*xx2/8,['Post-hoc (unpr.):'],'Fontsize',10,'FontWeight','bold')
                    text(mean(yy(2)),xx-3.5*xx2/8,['* p<.05'],'Fontsize',10)
                    text(mean(yy(2)),xx-4.25*xx2/8,['** p<Bonferroni'],'Fontsize',10)
                    %text(mean(yy(2))-.1*diff(yy),xx-2.75*xx2/8,'2-ANOVA stats:')
                    %text(mean(yy(2))-.1*diff(yy),xx-3.5*xx2/8,['Group: F=' num2str(tbl{3,5},2) ', p=' num2str(tbl{3,6},2)],'Fontsize',10,'FontWeight','bold')
                    %text(mean(yy(2))-.1*diff(yy),xx-4.25*xx2/8,['Cond: F=' num2str(tbl{2,5},2) ', p=' num2str(tbl{2,6},2)],'Fontsize',10,'FontWeight','bold')
                    %text(mean(yy(2))-.1*diff(yy),xx-5*xx2/8,['Interac.: F=' num2str(tbl{4,5},2) ', p=' num2str(tbl{4,6},2)],'Fontsize',10,'FontWeight','bold')
                    
                    Ncomp=sum(sum(triu(signifPlotMatrixConds),2),1) * length(allData.group); %Number of comparisons being done across epochs
                    Ncomp2=(.5*length(allData.group)*(length(allData.group)-1))*size(relevantData,1) ;%Number of comparisons being done across groups
                    for kk=1:length(allData.group) %all groups
                        counter=0;
                    for ii=1:M %Each epoch
                            for ll=[kk+1:length(allData.group)] %All the other groups
                                [~,pp3]=ttest2(relevantData(ii,groupMembership==kk),relevantData(ii,groupMembership==ll),'VarType','Unequal'); %Use ttest2 to do unpaired t-test
                                if medianFlag==1
                                    [pp3]=ranksum(relevantData(ii,groupMembership==kk),relevantData(ii,groupMembership==ll)); %Use ranksum to paired non-param testing
                                end
                                c1=strcmp(dim1Names{ii},phoc2.Condition); %Finding comparisons that relate to condition ii
                                c2=strcmp(groups{kk}.ID{1},phoc2.Group_1);
                                c3=strcmp(groups{ll}.ID{1},phoc2.Group_2);
                                pp=phoc2.pValue(c1 & c2 & c3);%This is the same as using pp3
                                %disp(['post-hoc=' num2str(pp) ', t-test (unp)=' num2str(pp3) ', ranksum=' num2str(pp2)]) %This is to check that the post-hoc is indeed an unpaired t-test
                                if pp3<significanceThreshold 
                                    plot(XData(ii)+[0,1],yOff+yRef*[1,1],'m','LineWidth',2)
                                    %text(XData(j)-.25,yOff+yRef*1.8,[num2str(pp,'%1.1g')],'Color','m')
                                    if pp>(significanceThreshold/Ncomp2) %Bonferroni threshold
                                        text(XData(ii)+.25,yOff+yRef*1.4,['*'],'Color','m')
                                    else
                                        text(XData(ii)+.25,yOff+yRef*1.4,['**'],'Color','m')
                                    end
                                end
                            end
                            for jj=[ii+1:M]
                                if signifPlotMatrixConds(ii,jj)==1
                                    counter=counter+1;
                                    %error('This doesnt work, figure it out')
                                    [~,pp1]=ttest(relevantData(ii,groupMembership==kk),relevantData(jj,groupMembership==kk)); %Use ttest to do paired t-test
                                    [~,pp3]=ttest2(relevantData(ii,groupMembership==kk),relevantData(jj,groupMembership==kk)); %Use ttest2 to do unpaired t-test. Should we use 'Vartype','unequal' ?
                                    if medianFlag==1
                                        [pp1]=signrank(relevantData(ii,groupMembership==kk),relevantData(jj,groupMembership==kk)); %Use signrank to paired non-param testing
                                    end
                                    c1=strcmp(dim1Names{ii},phoc.Condition_1); %Finding comparisons that relate to condition ii
                                    c2=strcmp(dim1Names{jj},phoc.Condition_2);
                                    c3=strcmp(groups{kk}.ID{1},phoc.Group);
                                    pp=phoc.pValue(c1 & c2 & c3);
                                    %disp(['post-hoc=' num2str(pp) ', t-test (paired)=' num2str(pp1) ', t-test (unp)=' num2str(pp3) ', signrank=' num2str(pp2)])
                                    if pp1<(significanceThreshold) 
                                        plot([XData(ii) XData(jj)]+(kk-1),yOff2-yRef*[1,1]*5*(kk + (counter-1.5)/NN),'Color',colors(mod(kk-1,length(colors))+1,:),'LineWidth',2)
                                        if pp1>(significanceThreshold/(.5*Ncomp)) %Does not pass Bonferroni's criteria for significance
                                            text(XData(jj)+kk-1,yOff2-yRef*5*(kk + (counter-1.5)/NN),['*'],'Color',colors(mod(kk-1,length(colors))+1,:))
                                        else %Passes Bonferroni criteria
                                            text(XData(jj)+kk-1,yOff2-yRef*5*(kk + (counter-1.5)/NN),['**'],'Color',colors(mod(kk-1,length(colors))+1,:))
                                        end
                                    end
                                end
                            end
                        end
                    end
                    aa=axis;
                    axis tight
                    bb=axis;
                    axis([aa(1:2) bb(3) aa(4)])
                    hold off
                    end
                end
            end
            end
            
end

function [figHandle,allData]=plotGroupedSubjectsBarsv2(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,significanceThreshold,plotHandles,colors,medianFlag)
            mode=1; %1 is bars +- std, 2 is lines +- std, 3 is boxplots
            
            
            if nargin<4 || isempty(plotIndividualsFlag)
                plotIndividualsFlag=true;
            end
            if nargin<9 
                legendNames={};
            end
            %if ~plotIndividualsFlag
            %    legendNames={};
            %end
            if nargin<3 || isempty(removeBiasFlag)
                removeBiasFlag=1;
            end
            if nargin<5 || isempty(condList)
               condList=[]; 
            end
            
            %First: see if adaptDataList is a single groupAdaptData object
            %or a cell-array of it
            if isa(adaptDataList,'groupAdaptationData')
                auxList={adaptDataList};
            elseif isa(adaptDataList,'cell') && ~isa(adaptDataList{1},'groupAdaptationData')
                error();
            elseif isa(adaptDataList,'cell')
               auxList=adaptDataList; 
            end
                
            Ngroups=length(auxList);
            if nargin<12 || isempty(colors) || size(colors,1)<Ngroups
                colorScheme
                for i=1:Ngroups
                    colors(i,:)=colorGroups{mod(i-1,length(colorGroups))+1};
                end
            end
            if nargin<13 || isempty(medianFlag)
                medianFlag=0;
            end
            
            %Default number of strides to average:
            if nargin<6 || isempty(numberOfStrides)
                N2=[5,-20];
            else
                N2=numberOfStrides;
            end
            if nargin<7 || isempty(exemptFirst)
                Nf=0; 
            else
                Nf=exemptFirst;
            end
            if nargin<8 || isempty(exemptLast)
                Ne=5;
            else
                Ne=exemptLast;
            end
            if nargin<10 || isempty(significanceThreshold)
                significanceThreshold=[];
            end
            
            
            nConds=length(condList);
            nLabs=length(label);
            %Get data:
            for i=1:Ngroups
                data=auxList{i}.getGroupedData(label,condList,removeBiasFlag,N2,Nf,Ne); %(1:nConds,1:abs(numberOfStrides(i)),1:nLabs,subject)
                nSubs=length(auxList{i}.ID);
                allData.group{i}=nan(nConds,length(data),nLabs,nSubs);
                for j=1:length(data)
                    allData.group{i}(1:nConds,j,1:nLabs,1:nSubs)=nanmean(data{j},2); %Averaging across strides; cell across groups, conds x strideGroups x parameters x subs
                end
            end
            
            %Do plot:
            if nargin<11 || isempty(plotHandles) || numel(plotHandles)~=length(label)
                [ah,figHandle]=optimizedSubPlot(length(label),2,2);
                figure(figHandle)
            else
                figHandle=figure(gcf);
                ah=plotHandles;
            end
            
            for i=1:length(ah) %For each paramter
                subplot(ah(i))
                for j=1:Ngroups %For each group
                    nSubs=size(allData.group{j},4);
                    if isempty(legendNames)
                        gName{j}=['Group ' num2str(j) '(n=' num2str(nSubs) ')'];
                    else
                        gName{j}=legendNames{j};
                    end
                    for k=1:length(N2) %For each set of strides to be plotted (e.g first 20, last 50, ...)
                        if medianFlag==0
                        relevantMean=nanmean(allData.group{j}(:,k,i,:),4); %Avg. across subjects. We end up with: conditionsxStrideSetxGroups
                        relevantSte=nanstd(allData.group{j}(:,k,i,:),[],4);%/sqrt(nSubs); %Avg. across subjects. We end up with: conditionsxStrideSetxGroups
                        else
                        relevantMean=nanmedian(allData.group{j}(:,k,i,:),4); %Median  across subjects. We end up with: conditionsxStrideSetxGroups
                        %relevantSte=.5*iqr(allData.group{j}(:,k,i,:),4);%/sqrt(nSubs); %.5 times Interquartile range across subjects, normalized to sqrt(Number of subjects) to be consistent with STE
                        relevantSte=.5*diff(prctile(allData.group{j}(:,k,i,:),[16,84],4),[],4); %Using half of the 16-84 percentile (which in a normal dist corresponds to 1 stdev)
                        end
                        xPos=(j+(k-1)*(Ngroups+1)):length(N2)*(Ngroups+1):nConds*length(N2)*(Ngroups+1);
                        if N2(k)<0
                        bName{k}=[' last ' num2str(abs(N2(k))) ' strides.'];
                        else
                            bName{k}=[' first ' num2str(abs(N2(k))) ' strides.'];
                        end
                        hold on
                        if mode==1 %Mean bars +- std or median bars +- half the 16-84 percentile range
                            try
                                bb(j,k)=bar(xPos,relevantMean,'BarWidth',.9/((Ngroups+1)*length(N2)),'FaceColor',colors(j,:),'FaceAlpha',(k/length(N2)),'DisplayName',strcat(gName{j},bName{k}),'EdgeColor',colors(j,:).^(k/length(N2)));
                            catch %old matlab versions don't allow for 'FaceAlpha' property on bars
                                bb(j,k)=bar(xPos,relevantMean,'BarWidth',.9/((Ngroups+1)*length(N2)),'FaceColor',colors(j,:).^(1-((k-1)/length(N2))),'DisplayName',strcat(gName{j},bName{k}),'EdgeColor',colors(j,:),'LineWidth',2);%,'FaceAlpha',(k/length(N2)));
                            end
                            bb(j,k).Tag=['Group' num2str(j) ',Cond' num2str(k)];
                            hC=errorbar(xPos,relevantMean,relevantSte,'LineStyle','none','LineWidth',2,'Color','k');
                            set(get(get(hC,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                        elseif mode==2 %Mean/median lines +- std or 16-84 percentile range
                            errorbar(xPos,relevantMean, relevantSte,'DisplayName',strcat(gName{j},bName{k}),'LineWidth',2,'Color',colors(j,:).^(1-((k-1)/length(N2))))
                        elseif mode==3 %Boxplots
                            boxplot(squeeze(allData.group{j}(:,k,i,:))','positions',xPos,'widths',.9,'symbol','+','colors',colors(j,:).^(k/length(N2)),'boxstyle','outline');
                        end
                        if plotIndividualsFlag==1
                            indivColors=[];
                           hC=plot(xPos-.1,reshape(allData.group{j}(:,k,i,:),nConds,nSubs),'r.');
                           %Exclude from legend:
                           hCGroup = hggroup; %Create group
                           set(hC,'Parent',hCGroup)%Grouping all lines plotted
                           set(get(get(hCGroup,'Annotation'),'LegendInformation'),'IconDisplayStyle','off'); 
                        end
                        hold off
                    end
                    
                end
%                 xPos=((length(N2)*Ngroups+1)/2):length(N2)*Ngroups:nConds*length(N2)*Ngroups;
%                 xPos=((Ngroups+1)/2):(Ngroups+1):nConds*length(N2)*(Ngroups+1);
%                 tickList=cell(length(N2),length(condList));
%                 for k=1:length(N2)
%                     tickList(k,:)=strcat(['Set ' num2str(k) ' '],condList);
%                 end
%                 tickList=tickList(:);
                xPos=((length(N2)*(Ngroups+1))/2):length(N2)*(Ngroups+1):nConds*length(N2)*(Ngroups+1);
                tickList=condList;
                set(gca,'XTick',xPos,'XTickLabel',tickList);
                if i==length(ah)
                    legend(gca,'show')
                    %legend(bb(:,k),gName)
                end
                if removeBiasFlag==1
                title([label{i} ' w/o bias'])
                else
                    title(label{i})
                end
                axis tight
                aa=axis;
                for j=2:2:nConds
                   hC=patch(xPos(j) +[-1,1,1,-1]*(length(N2)*(Ngroups+1))/2,[aa(3) aa(3) aa(4) aa(4)],[.8,.8,.8],'EdgeColor','none','FaceAlpha',.6); 
                   set(get(get(hC,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
                   uistack(hC,'bottom')
                end
                axis(aa)
            end
            
            
            
            
 
end

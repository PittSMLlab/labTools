function [figHandle,allData]=plotGroupedSubjectsBars(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,earlyNumber,lateNumber,exemptLast,legendNames,significanceThreshold)
            colorScheme
            if nargin<4 || isempty(plotIndividualsFlag)
                plotIndividualsFlag=true;
            end
            if nargin<9 || isempty(legendNames) || length(legendNames)<length(adaptDataList)
                legendNames=adaptDataList;
            end
            if ~plotIndividualsFlag
                legendNames={};
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
            
            %Default number of strides to average:
            N1=3; %very early number of points
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
            if nargin<10 || isempty(significanceThreshold)
                significanceThreshold=[];
            end
            [ah,figHandle]=optimizedSubPlot(length(label),4,1);
            
            a=load(auxList{1}{1});
            aux=fields(a);
            this=a.(aux{1});
            if nargin<5 || isempty(condList)
                conds=this.metaData.conditionName(~cellfun(@isempty,this.metaData.conditionName));
            else
                conds=condList;
                for i=1:length(condList)
                    if iscell(condList{i})
                        condList{i}=condList{i}{1};
                    end
                end
            end
            nConds=length(conds);
            allData={};
            for l=1:length(label)
                axes(ah(l))
                hold on
                for group=1:Ngroups
                    [veryEarlyPoints,earlyPoints,latePoints,pEarly,pLate,pChange,pSwitch]=adaptationData.getGroupedData(auxList{group},label(l),conds,removeBiasFlag,N2,N3,Ne);
                    veryEarlyPoints=permute(nanmean(veryEarlyPoints,2),[1,4,2,3]); %Averaging over strides for each sub
                    earlyPoints=permute(nanmean(earlyPoints,2),[1,4,2,3]); %Averaging over strides for each sub
                    latePoints=permute(nanmean(latePoints,2),[1,4,2,3]); %Averaging over strides for each sub
                    %plot bars
                    if Ngroups==1  && isempty(significanceThreshold)%Only plotting first N1 strides AND first N2 strides if there is only one group, and no stats are being shown
                        bar((1:3:3*nConds)-.25+(group-1)/Ngroups,nanmean(veryEarlyPoints,2),.15/Ngroups,'FaceColor',[.85,.85,.85].^group)
                        bar((1:3:3*nConds)+.25+(group-1)/Ngroups,nanmean(earlyPoints,2),.15/Ngroups,'FaceColor',[.7,.7,.7].^group)
                    else
                        h(2*(group-1)+1)=bar((1:3:3*nConds)+(group-1)/Ngroups,nanmean(earlyPoints,2),.3/Ngroups,'FaceColor',[.6,.6,.6].^group);                        
                    end
                    h(2*group)=bar((2:3:3*nConds)+(group-1)/Ngroups,nanmean(latePoints,2),.3/Ngroups,'FaceColor',[0,.4,.7].^group);
                    %plot individual data points
                    if plotIndividualsFlag==1
                        set(gca,'ColorOrder',cell2mat(colorConds(1:min([size(veryEarlyPoints,2),length(colorConds)]))'));
                        if Ngroups==1 && isempty(significanceThreshold) %Only plotting individual subject performance if there is only one group, or flag is set
                            plot((1:3:3*nConds)-.25+(group-1)/Ngroups,veryEarlyPoints,'o','LineWidth',2)
                            plot((1:3:3*nConds)+.25+(group-1)/Ngroups,earlyPoints,'o','LineWidth',2)
                            plot((2:3:3*nConds)+(group-1)/Ngroups,latePoints,'o','LineWidth',2)
                        else
                            plot((1:3:3*nConds)+(group-1)/Ngroups,earlyPoints,'o','LineWidth',2)
                            plot((2:3:3*nConds)+(group-1)/Ngroups,latePoints,'o','LineWidth',2)
                        end
                    end
                    %plot stat markers for the case there is a single group
                    topOffset=max(earlyPoints(:));
                    if Ngroups==1
                        if ~isempty(significanceThreshold) %Only works with a single group, no stats across groups, yet
                           topOffset=max(earlyPoints(:));
                           changes=find(pChange<significanceThreshold);
                           for j=1:length(changes)
                              plot((changes(j)-1)*3+[1.1,1.9],1.2*topOffset*[1,1],'k','LineWidth',2); 
                           end
                           switches=find(pSwitch<significanceThreshold);
                           for j=1:length(switches)
                              plot((switches(j)-1)*3+[2.1,3.9],1.2*topOffset*[1,1],'k','LineWidth',2); 
                           end
                           interCond=find(pLate(1,:)<significanceThreshold);
                           for j=1:length(interCond)
                              plot([2.1,(interCond(j)-1)*3+2.1],(1.2 +.1*interCond(j))*topOffset*[1,1],'k','LineWidth',2); 
                           end
                        end
                    end
                        
                    %plot error bars (using standard error)
                    if Ngroups==1 && isempty(significanceThreshold) %Only plotting first 3 strides AND first 5 strides if there is only one group
                        errorbar((1:3:3*nConds)-.25+(group-1)/Ngroups,nanmean(veryEarlyPoints,2), nanstd(veryEarlyPoints,[],2)/sqrt(size(veryEarlyPoints,2)),'.','LineWidth',2,'Color',[1,0,0])
                        errorbar((1:3:3*nConds)+.25+(group-1)/Ngroups,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2,'Color',[1,0,0])
                    else
                        errorbar((1:3:3*nConds)+(group-1)/Ngroups,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2,'Color',[1,0,0])
                    end
                    errorbar((2:3:3*nConds)+(group-1)/Ngroups,nanmean(latePoints,2), nanstd(latePoints,[],2)/sqrt(size(latePoints,2)),'.','LineWidth',2,'Color',[1,0,0])
                    
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
                %Plot stat markers for in-between group comparisons (group
                %1 vs all other groups)
                if Ngroups>1 && ~isempty(significanceThreshold)
                    for i=2:Ngroups
                            [~,pEarly(:,i-1)]=ttest2(allData{l}.group{1}.early',allData{l}.group{i}.early');
                            [~,pLate(:,i-1)]=ttest2(allData{l}.group{1}.late',allData{l}.group{i}.late');
                            for j=1:nConds
                                if pEarly(j,i-1)<significanceThreshold
                                    plot([3*(j-1)+1 3*(j-1)+1+(i-1)/Ngroups],(1.2 +.1*(i-1))*topOffset*[1,1],'k','LineWidth',2); 
                                end
                                if pLate(j,i-1)<significanceThreshold
                                    plot([3*(j-1)+2 3*(j-1)+2+(i-1)/Ngroups],(1.2+.1*(i-1))*topOffset*[1,1],'k','LineWidth',2); 
                                end
                            end
                    end
                end
                xTickPos=(1:3:3*nConds)+.5;
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
            if ~isempty(legendNames) && isa(legendNames{1},'cell') %Case in which the list of subjects is of the form {{'name1','name2',...}}, so there is actually a single group. Without this fix it fails to write the legend.
                legendNames=legendNames{1};
            end
            if Ngroups==1 && isempty(significanceThreshold)
                legend([{['Very early (first ' num2str(N1) ' strides)'],['Early (first ' num2str(N2) ' strides)'],['Late (last ' num2str(N3) ' (-' num2str(Ne) ') strides)']}, legendNames ]);
            elseif Ngroups==1
                legend([{['Early (first ' num2str(N2) ' strides)'],['Late (last ' num2str(N3) ' (-' num2str(Ne) ') strides)']}, legendNames ]);
            else
                legStr={};
                for group=1:Ngroups
				    load([adaptDataList{group}{1,1}])
                    group2=adaptData.subData.ID;
                    spaces=find(group2==' ');
                    abrevGroup=group2(spaces+1);
                    group2=group2(ismember(group2,['A':'Z' 'a':'z']));
                    abrevGroup=[group2];
                    legStr=[legStr, {['Early (first ' num2str(N2) '), Group ' abrevGroup],['Late (last ' num2str(N3) ' (-' num2str(Ne) '), Group ' abrevGroup]}];
                end
                legend(h,legStr)
            end
end

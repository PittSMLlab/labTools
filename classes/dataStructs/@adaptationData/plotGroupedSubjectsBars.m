function [figHandle,veryEarlyPoints,earlyPoints,latePoints]=plotGroupedSubjectsBars(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,earlyNumber,lateNumber,exemptLast,legendNames,significanceThreshold)
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
            for l=1:length(label)
                axes(ah(l))
                hold on
                
                for group=1:Ngroups
                    [veryEarlyPoints,earlyPoints,latePoints,pEarly,pLate,pChange,pSwitch]=adaptationData.getGroupedData(auxList{group},label(l),conds,removeBiasFlag,N2,N3,Ne);
                    veryEarlyPoints=squeeze(nanmean(veryEarlyPoints,2)); %Averaging over strides for each sub
                    earlyPoints=squeeze(nanmean(earlyPoints,2)); %Averaging over strides for each sub
                    latePoints=squeeze(nanmean(latePoints,2)); %Averaging over strides for each sub
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
                        set(gca,'ColorOrder',cell2mat(colorConds(1:size(veryEarlyPoints,2))'));
                        if Ngroups==1 && isempty(significanceThreshold) %Only plotting individual subject performance if there is only one group, or flag is set
                            plot((1:3:3*nConds)-.25+(group-1)/Ngroups,veryEarlyPoints,'o','LineWidth',2)
                            plot((1:3:3*nConds)+.25+(group-1)/Ngroups,earlyPoints,'o','LineWidth',2)
                            plot((2:3:3*nConds)+(group-1)/Ngroups,latePoints,'o','LineWidth',2)
                        else
                            plot((1:3:3*nConds)+(group-1)/Ngroups,earlyPoints,'o','LineWidth',2)
                            plot((2:3:3*nConds)+(group-1)/Ngroups,latePoints,'o','LineWidth',2)
                        end
                    end
                    %plot stat markers
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
                        
                    %plot error bars (using standard error)
                    if Ngroups==1 && isempty(significanceThreshold) %Only plotting first 3 strides AND first 5 strides if there is only one group
                        errorbar((1:3:3*nConds)-.25+(group-1)/Ngroups,nanmean(veryEarlyPoints,2), nanstd(veryEarlyPoints,[],2)/sqrt(size(veryEarlyPoints,2)),'.','LineWidth',2)
                        errorbar((1:3:3*nConds)+.25+(group-1)/Ngroups,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2)
                    else
                        errorbar((1:3:3*nConds)+(group-1)/Ngroups,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2)
                    end
                    errorbar((2:3:3*nConds)+(group-1)/Ngroups,nanmean(latePoints,2), nanstd(latePoints,[],2)/sqrt(size(latePoints,2)),'.','LineWidth',2)
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
            if Ngroups==1 && isempty(significanceThreshold)
                legend([{['Very early (first ' num2str(N1) ' strides)'],['Early (first ' num2str(N2) ' strides)'],['Late (last ' num2str(N3) ' (-' num2str(Ne) ') strides)']}, legendNames ]);
            elseif Ngroups==1
                legend([{['Early (first ' num2str(N2) ' strides)'],['Late (last ' num2str(N3) ' (-' num2str(Ne) ') strides)']}, legendNames ]);
            else
                legStr={};
                for group=1:Ngroups
                    legStr=[legStr, {['Early (first ' num2str(N1) '), Group ' num2str(group)],['Late (last ' num2str(N3) ' (-' num2str(Ne) '), Group ' num2str(group)]}];
                end
                legend(h,legStr)
            end
        end

function [figHandle,veryEarlyPoints,earlyPoints,latePoints]=plotGroupedSubjectsBars(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,earlyNumber,lateNumber,exemptLast,legendNames)
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
            
            %UPDATE LEGEND IF THESE LINES ARE CHANGED
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
                    earlyPoints=[];
                    veryEarlyPoints=[];
                    latePoints=[];
                    for subject=1:length(auxList{group}) %Getting data for each subject in the list
                        a=load(auxList{group}{subject});
                        aux=fields(a);
                        this=a.(aux{1});
                        if nargin<3 || isempty(removeBiasFlag) || removeBiasFlag==1
                            this=this.removeBias; %Default behaviour
                        else
                            %this=adaptData;
                        end
                        for i=1:nConds
                            %First: find if there is a condition with a
                            %similar name to the one given
                            clear condName
                            if iscell(conds{i})
                                for j=1:length(conds{i})
                                    condName{j}=lower(conds{i}{j});
                                end
                            else
                                condName{1}=lower(conds{i}); %Lower case
                            end
                            allConds=lower(this.metaData.conditionName);
                            condIdx=[];
                            j=0;
                            while isempty(condIdx) && j<length(condName)
                                j=j+1;
                                condIdx=find(~cellfun(@isempty,strfind(allConds,condName{j})),1,'first');
                            end
                            aux=this.getParamInCond(label(l),condIdx);
                            if ~isempty(condIdx) && ~isempty(aux)
                                
                                try %Try to get the first strides, if there are enough
                                    veryEarlyPoints(i,subject)=mean(aux(1:N1));
                                    earlyPoints(i,subject)=mean(aux(1:N2));
                                catch %In case there aren't enough strides, assign NaNs to all
                                    veryEarlyPoints(i,subject)=NaN;
                                    earlyPoints(i,subject)=NaN;
                                end
                                
                                %Last 20 steps, excepting the very last 5
                                try                                    
                                    latePoints(i,subject)=mean(aux(end-N3-Ne+1:end-Ne));
                                catch
                                    latePoints(i,subject)=NaN;
                                end
                            else
                                disp(['Condition ' conds{i} ' not found for subject ' this.subData.ID])
                                veryEarlyPoints(i,subject)=NaN;
                                earlyPoints(i,subject)=NaN;
                                latePoints(i,subject)=NaN;
                            end
                        end
                    end
                    %plot bars
                    if Ngroups==1 %Only plotting first 3 strides AND first 5 strides if there is only one group
                        bar((1:3:3*nConds)-.25+(group-1)/Ngroups,nanmean(veryEarlyPoints,2),.15/Ngroups,'FaceColor',[.85,.85,.85].^group)
                        bar((1:3:3*nConds)+.25+(group-1)/Ngroups,nanmean(earlyPoints,2),.15/Ngroups,'FaceColor',[.7,.7,.7].^group)
                    else
                        h(2*(group-1)+1)=bar((1:3:3*nConds)+(group-1)/Ngroups,nanmean(earlyPoints,2),.3/Ngroups,'FaceColor',[.6,.6,.6].^group);
                    end
                    h(2*group)=bar((2:3:3*nConds)+(group-1)/Ngroups,nanmean(latePoints,2),.3/Ngroups,'FaceColor',[0,.4,.7].^group);
                    %plot individual data points
                    if Ngroups==1 || plotIndividualsFlag %Only plotting individual subject performance if there is only one group, or flag is set
                        set(gca,'ColorOrder',cell2mat(colorConds(1:size(veryEarlyPoints,2))'));
                        if Ngroups==1 || plotIndividualsFlag==1
                            plot((1:3:3*nConds)-.25+(group-1)/Ngroups,veryEarlyPoints,'o','LineWidth',2)
                            plot((1:3:3*nConds)+.25+(group-1)/Ngroups,earlyPoints,'o','LineWidth',2)
                        else
                            plot((1:3:3*nConds)+(group-1)/Ngroups,earlyPoints,'o','LineWidth',2)
                        end
                        plot((2:3:3*nConds)+(group-1)/Ngroups,latePoints,'o','LineWidth',2)
                    end
                    %plot error bars (using standard error)
                    if Ngroups==1 %Only plotting first 3 strides AND first 5 strides if there is only one group
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
            if Ngroups==1
                legend([{['Very early (first ' num2str(N1) ' strides)'],['Early (first ' num2str(N2) ' strides)'],['Late (last ' num2str(N3) ' (-' num2str(Ne) ') strides)']}, legendNames ]);
            else
                legStr={};
                for group=1:Ngroups
                    legStr=[legStr, {['Early (first ' num2str(N1) '), Group ' num2str(group)],['Late (last ' num2str(N3) ' (-' num2str(Ne) '), Group ' num2str(group)]}];
                end
                legend(h,legStr)
            end
        end

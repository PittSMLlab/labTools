function [figHandle,veryEarlyPoints,earlyPoints,latePoints]=plotGroupedSubjectsTimeCourse(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,earlyNumber,lateNumber,exemptLast,legendNames)
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
                                    earlyPoints(i,subject,:)=aux(1:N2);
                                catch %In case there aren't enough strides, assign NaNs to all
                                    earlyPoints(i,subject,:)=NaN;
                                end
                                
                                %Last 20 steps, excepting the very last 5
                                try                                    
                                    latePoints(i,subject,:)=aux(end-N3-Ne+1:end-Ne);
                                catch
                                    latePoints(i,subject,:)=NaN;
                                end
                            else
                                disp(['Condition ' conds{i} ' not found for subject ' this.subData.ID])
                                earlyPoints(i,subject,1:N2)=NaN;
                                latePoints(i,subject,1:N3)=NaN;
                            end
                        end
                    end
                    %plot
                    offset=(N2+N3+15);
                    plot([1 offset*nConds],[0,0],'k--')
                    for i=1:nConds
                        clear hLeg
                        %Early part
                        xCoord=(i-1)*offset + [1:N2];
                        yCoord=squeeze(nanmean(earlyPoints(i,:,:),2));
                        yStd=squeeze(nanstd(earlyPoints(i,:,:),[],2));
                        hh=patch([xCoord,xCoord(end:-1:1)],[yCoord'-yStd',yCoord(end:-1:1)'+yStd(end:-1:1)'],[.6,.6,.6]);
                        hLeg(1)=plot(xCoord,yCoord,'LineWidth',3,'Color',colorGroups{group});
                        if plotIndividualsFlag==1
                           for j=1:size(earlyPoints,2)
                               hLeg(j+1)=plot((i-1)*offset + [1:N2],squeeze(earlyPoints(i,j,:)),'Color',colorConds{j});
                           end
                        end
                        %LAte part:
                        xCoord=(i-1)*offset + [offset-N3-4:offset-5];
                        yCoord=squeeze(nanmean(latePoints(i,:,:),2));
                        yStd=squeeze(nanstd(latePoints(i,:,:),[],2));
                        hh=patch([xCoord,xCoord(end:-1:1)],[yCoord'-yStd',yCoord(end:-1:1)'+yStd(end:-1:1)'],[.6,.6,.6]);
                        plot(xCoord,yCoord,'LineWidth',3,'Color',colorGroups{group})
                        if plotIndividualsFlag==1
                           for j=1:size(earlyPoints,2)
                               plot((i-1)*offset + [offset-N3-4:offset-5],squeeze(latePoints(i,j,:)),'Color',colorConds{j})
                           end
                        end
                    end
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


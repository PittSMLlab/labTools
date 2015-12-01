function [figHandle,allData]=plotMultipleGroupsBars(groups,label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,significanceThreshold,plotHandles,colors,significancePlotMatrix)
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
            if nargin<12
                colors=[];
            end
            if nargin<13 || isempty(significancePlotMatrix)
                M=length(condList)*length(numberOfStrides);
                significancePlotMatrix=ones(M);
            end
            if ~isa(groups,'cell') || ~isa(groups{1},'groupAdaptationData')
                error('First argument needs to be a cell array of groupAdaptationData objects')
            end
            [figHandle,allData]=adaptationData.plotGroupedSubjectsBarsv2(groups,label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,[],plotHandles,colors);
            
            %Add bars comparing groups:
            nGroups=length(groups);
            if nGroups>1
            %[p]=compareTwoGroups(groups,label,condition,numberOfStrides,exemptFirst,exemptLast);
            if ~isempty(significanceThreshold)
                ch=findobj(figHandle,'Type','Axes');
                for i=1:length(ch)
                    aux=find(strcmp(label,ch(i).Title.String));
                    clear XData YData
                    subplot(ch(i))
                    hold on
                    b=findobj(ch(i),'Type','Bar');
                    for j=1:length(b)
                        XData(j,:)=b(end-j+1).XData;
                        YData(j,:)=b(end-j+1).YData;
                    end
                    XData=reshape(XData,[length(numberOfStrides),nGroups,length(condList)]);
                    YData=reshape(YData,[length(numberOfStrides),nGroups,length(condList)]);
                    XData=squeeze(XData(:,1,:));
                    XData=XData(:);
                    YData=squeeze(YData(:,1,:));
                    YData=YData(:);
                    yRef=(max(YData)-min(YData));
                    yOff=max(YData);
                    for j=1:length(XData)
                        XData(j)
                        [a1,a2]=ind2sub([size(allData.group{1},2),size(allData.group{1},1)],j);
                        data1=squeeze(allData.group{1}(a2,a1,aux,:));
                        [b1,b2]=ind2sub([size(allData.group{2},2),size(allData.group{1},1)],j);
                        data2=squeeze(allData.group{2}(b2,b1,aux,:));
                            %Sanity check:
                            if nanmean(data1)~=YData(j) %data2 is the data I believe is plotted in the bar positioned in x=XData(k), and should have height y=YData(k)
                                %Mismatch means that I am wrong, and
                                %therefore should not be overlaying the
                                %stats on the given bar plots
                                error('Stride group order is different than expected')
                            end
                            %2-sample t-test btw the first two groups:
                            if significancePlotMatrix(1,2)==1 || significancePlotMatrix(2,1)==1
                                [~,pp]=ttest2(data1,data2); %Use ttest2 to do independent 2-sample t-test
                                if pp<significanceThreshold%/(length(numberOfStrides)*length(condList))
                                    plot(XData(j)+[0,1],yOff+yRef*[1,1],'k','LineWidth',2)
                                    text(XData(j),yOff+yRef*1.05,['p=' num2str(pp)])
                                end
                            end
                    end
                    axis tight
                    hold off
                end
            end
            end
            
end

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
                    clear XData YData
                    subplot(ch(i))
                    hold on
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
                    yRef=.1*(max(YData(:))-min(YData(:)));
                    %yRef=.5*std(YData(:));
                    yOff=max(YData(:));
                    yOff2=min(YData(:));
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
                                        plot([XData(l) XData(j)]+(k-1),yOff2-yRef*[1,1]*4*(k + (counter-1)/NN),'Color',colors(mod(k-1,length(colors))+1,:),'LineWidth',2)
                                        %text(XData(l)-1.5,yOff2-yRef*4*(k + (counter-1.5)/NN),[num2str(pp,'%1.1g')],'Color',colors(k,:))
                                        if pp>significanceThreshold/10
                                            text(XData(l)-1.5+(k-1),yOff2-yRef*4*(k + (counter-1.5)/NN),['*'],'Color',colors(mod(k-1,length(colors))+1,:))
                                        else
                                            text(XData(l)-1.5+(k-1),yOff2-yRef*4*(k + (counter-1.5)/NN),['**'],'Color',colors(mod(k-1,length(colors))+1,:))
                                        end
                                    end
                                end
                            end
                            end
                            
                    end
                    end
                    aa=axis;
                    try
                    axis([aa(1:2) yOff2-yRef*4*(length(allData.group)+1) yOff+2*yRef])
                    catch
                        axis tight
                    end
                    hold off
                end
            end
            end
            
end

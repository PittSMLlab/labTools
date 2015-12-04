function [figHandle,allData]=plotBars(this,label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,significanceThreshold,plotHandles,colors,significancePlotMatrix)
            %TODO: Should check that numberOfStrides groups are given in
            %chronological order & that so are the conditions in condList
            %This will work if they are not, but the statistical testing
            %plots may not work properly, as it expects ordered things.

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
                %significancePlotMatrix=ones(M);
                significancePlotMatrix=zeros(M);
                significancePlotMatrix(sub2ind([M,M],[2:M-1],[3:M]))=1; %Comparing all consecutive strideGroups
                significancePlotMatrix(2,3:M)=1; %Comparing second strideGroup vs. every other (except 1st)
            end
            [figHandle,allData]=groupAdaptationData.plotMultipleGroupsBars({this},label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,[],plotHandles,colors);
            if ~isempty(significanceThreshold)
                %[p,table,stats,postHoc,postHocEstimates,data]=anova1RM(this,label,condList,numberOfStrides,exemptFirst,exemptLast);
                %[pf,tablef,statsf,postHocf,postHocEstimatesf,dataf]=friedman(this,label,condList,numberOfStrides,exemptFirst,exemptLast);
                %if ~isa(postHoc,'cell')
                %    postHoc={postHoc};
                %    postHocf={postHocf};
                %end
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
                    XData=XData(:);
                    YData=YData(:);
                    yRef=(max(YData)-min(YData));
                    yOff=max(YData);
                    for j=1:length(XData)
                        [a1,a2]=ind2sub([size(allData.group{1},2),size(allData.group{1},1)],j);
                        data1=squeeze(allData.group{1}(a2,a1,aux,:));
                        for k=(j+1):length(XData)
                            [b1,b2]=ind2sub([size(allData.group{1},2),size(allData.group{1},1)],k);
                            data2=squeeze(allData.group{1}(b2,b1,aux,:));
                            %Sanity check:
                            if nanmean(data2)~=YData(k) %data2 is the data I believe is plotted in the bar positioned in x=XData(k), and should have height y=YData(k)
                                %Mismatch means that I am wrong, and
                                %therefore should not be overlaying the
                                %stats on the given bar plots
                                error('Stride group order is different than expected')
                            end
                            if (significancePlotMatrix(k,j)==1 || significancePlotMatrix(j,k)==1)
                                %Anova, bonferroni post-hoc:
                                %if postHoc{aux}(j,k)<significanceThreshold
                                %    plot(XData([j,k]),(yOff+yRef*(.5*j/length(XData) +k/length(XData)^2))*[1,1],'k','LineWidth',2)
                                %    text(XData(j),(yOff+yRef*(.5*j/length(XData) +k/length(XData)^2))*1.05,['p=' num2str(postHoc{aux}(j,k))])
                                %end
                                %Friedman:
                                %if postHocf{aux}(j,k)<significanceThreshold/sum(significancePlotMatrix(:)~=0)
                                %    plot(XData([j,k]),(yOff+yRef*(.5*j/length(XData) +k/length(XData)^2))*[1,1],'r','LineWidth',1)
                                %end
                                %Paired t-test:
                                [~,pp]=ttest(data1,data2); %Use ttest2 to do independent 2-sample t-test
                                if pp<significanceThreshold/sum(significancePlotMatrix(:)~=0)
                                    plot(XData([j,k]),(yOff+yRef*(.5*j/length(XData) +k/length(XData)^2))*[1,1],'k','LineWidth',2)
                                    text(XData(k)-1.5,(yOff+yRef*(.5*j/length(XData) +k/length(XData)^2))*.95,['p=' num2str(pp)],'Color','k')
                                end
                            end
                        end
                    end
                    axis tight
                    hold off
                end
            end
end

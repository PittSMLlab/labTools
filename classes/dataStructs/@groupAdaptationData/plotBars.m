function [figHandle,allData]=plotBars(this,label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,significanceThreshold,plotHandles,colors)
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
            [figHandle,allData]=groupAdaptationData.plotMultipleGroupsBars({this},label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,significanceThreshold,plotHandles,colors);
end

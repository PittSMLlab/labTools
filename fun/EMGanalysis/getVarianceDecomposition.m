function [decomposition,meanValue,avgStride,trial2trialVariability] = getVarianceDecomposition(alignedData)

avgStride=mean(alignedData,3);
meanValue=mean(avgStride,1);
trial2trialVariability=bsxfun(@minus,alignedData,avgStride);
avgStride=bsxfun(@minus,avgStride,meanValue);


decomposition(1,:)=meanValue.^2 * size(alignedData,3) * size(alignedData,1);
decomposition(2,:)=sum(avgStride.^2,1) * size(alignedData,3);
decomposition(3,:)=sum(sum(trial2trialVariability.^2,3),1);


end


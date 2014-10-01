function [decomposition,meanValue,avgStride,trial2trialVariability] = getVarianceDecomposition(alignedData)

avgStride=mean(alignedData,3);
meanValue=mean(avgStride,1);
trial2trialVariability=bsxfun(@minus,alignedData,avgStride);
avgStride=bsxfun(@minus,avgStride,meanValue);


decomposition(1,:)=meanValue.^2 * size(alignedData,3) * size(alignedData,1);
decomposition(2,:)=sum(avgStride.^2,1) * size(alignedData,3);
decomposition(3,:)=sum(sum(trial2trialVariability.^2,3),1);


%Check: difference btw decomposition and actual energy is not more than .1%
%of total energy
if any(sum(decomposition,1)-sum(sum(alignedData.^2,3),1)>.001*sum(sum(alignedData.^2,3),1))
    warning('Decomposition does not add up to actual signal energy')
end


%Normalize decomposition so we get RMS values of each component:
decomposition=sqrt(decomposition/(size(alignedData,3)*size(alignedData,1)));
end


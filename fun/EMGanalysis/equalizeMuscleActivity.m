function [equalizedData,weights] = equalizeMuscleActivity(alignedStrides,weights)

if nargin<2 || isempty(weights)
    weights=sum(sum(alignedStrides.^2,1),3);
end

equalizedData=bsxfun(@rdivide,alignedStrides,weights);
    
end


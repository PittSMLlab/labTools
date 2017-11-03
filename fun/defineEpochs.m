function [epochs] = defineEpochs(epochNames,condition,strideNo,exemptFirst,exemptLast)
%defineEpochs is used to create a dataset object that defines relevant
%epochs in the analysis of experimental data. It is used by several
%functions within studyData, groupAdaptationData and adaptationData
%epochNames has to be a Nx1 cell array of strings.
%condition, strideNo and exemptStrides can be Nx1 or scalars. If scalars,
%the same value is applied to all conditions.
%condition has to be cell array of strings, or string
%strideNo has to be a non-zero integer array: negative numbers are interpreted as
%'last M strides' while positive numbers are interpreted as 'first M
%strides'
%exemptStrides has to be positive, and is interpreted as 'first M' or 'last
%M' according to the interpretation from strideNo

N=length(epochNames);
if isa(condition,'char')
    condition={condtion};
end

if numel(condition)==1
    condition=repmat(condition,N,1);
end
if numel(strideNo)==1
    strideNo=repmat(strideNo,N,1);
end
if numel(exemptFirst)==1
    exemptFirst=repmat(exemptFirst,N,1);
end
if numel(exemptLast)==1
    exemptLast=repmat(exemptLast,N,1);
end
earlyOrLate=sign(strideNo)==-1;

epochs=dataset(condition,abs(strideNo),exemptFirst,exemptLast,earlyOrLate,'VarNames',{'Condition','Stride_No','ExemptFirst','ExemptLast','EarlyOrLate'},'ObsNames',epochNames);
end


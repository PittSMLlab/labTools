function [epochs] = defineEpochs(epochNames,condition,strideNo,exemptFirst,exemptLast,summaryMethod,shortName)
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
%exemptFirst has to be positive
%exemptLast has to be positive
%summaryMethod is a cell array of strings, with the name of the function
%used to summarize accross strides, default is 'nanmean'
%Ex: [epochs] = defineEpochs({'Initial_A1','Last_A1','Initial_A2','Last_A2'},{'Adaptation 1','Adaptation 1','Adaptation 1(2nd time)','Adaptation 1(2nd time)'},[5 -40 5 -40],5,5,{'nanmean'})

N=length(epochNames);
if isa(condition,'char')
    condition={condtion};
end
if nargin<6 || isempty(summaryMethod)
    summaryMethod='nanmean';
end

if isa(summaryMethod,'char') %To allow for summaryMethod to be given as string directly
    summaryMethod={summaryMethod};
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
if numel(summaryMethod)==1
    summaryMethod=repmat(summaryMethod,N,1);
end
earlyOrLate=sign(strideNo)==1;
if nargin<7 || isempty(shortName)
    shortName=cell(size(epochNames));
elseif numel(shortName)==1
    shortName=repmat(shortName,N,1);
end

epochs=dataset(condition(:),abs(strideNo(:)),exemptFirst(:),exemptLast(:),earlyOrLate(:),summaryMethod(:),shortName(:),'VarNames',{'Condition','Stride_No','ExemptFirst','ExemptLast','EarlyOrLate','summaryMethod','shortName'},'ObsNames',epochNames);
end


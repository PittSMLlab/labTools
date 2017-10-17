function [data,baseConds,trialTypes]=getBaseData(this,baseConds,labels)
%Returns data from last 40 strides of baseline, exempting the last 5.
%If baseConds is not given, it will find conditions that match the string 'base' for each trial type (same as removeBiasV3)

if nargin<2 || isempty(baseConds)
    [baseConds,trialTypes]=getBaseConditions(this);
else
    trialTypes=[]; %Doxy
end
if nargin<3
  labels=[];
end

numberOfStrides=-40;
exemptFirst=10;
exemptLast=5;
removeBiasFlag=0;
[data]=getEarlyLateData_v2(this,labels,baseConds,removeBiasFlag,numberOfStrides,exemptLast,exemptFirst);
data=data{1};


end

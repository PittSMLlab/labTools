function out = calcExperimentalParams(in,subData,eventClass,initEventSide)
%Calculate parameters: 
%
%INPUTS
%'in' must be an instance of the class "processedlabData"
%'subData' is the instance of subjectData e.g. subject.mat/expData.subData
%'eventClass' 
%'initEventSide' can be either 'R' or 'L', if blank this comes from come from
%subjectRAW.mat/rawExpData.data{i,j}.metaData.refLeg, or the first input
%'in'

if nargin<2 || isempty(eventClass)
    eventClass='';
end
if nargin<3 || isempty(initEventSide)
    refLeg=in.metaData.refLeg;
else
    refLeg=initEventSide; 
end

if strcmp(refLeg,'R')
    s = 'R';    f = 'L';
elseif strcmp(refLeg,'L')
    s = 'L';    f = 'R';
else
    ME=MException('MakeParameters:refLegError','the refLeg property of metaData must be either ''L'' or ''R''.');
    throw(ME);
end



%% Find number of strides
good=in.adaptParams.getDataAsVector({'good'}); %Getting data from 'good' label
ts=~isnan(good);
good=good(ts);
Nstrides=length(good);%Using lenght of the 'good' parameter already calculated in calcParams

%% get events
eventTypes={[s,'HS'],[f,'TO'],[f,'HS'],[s,'TO']};
eventTypes=strcat(eventClass,eventTypes);
eventTypes2={['SHS'],['FTO'],['FHS'],['STO']};
triggerEvent=eventTypes{1};
[strideIdxs,initTime,endTime]=getStrideInfo(in,triggerEvent);

%% Compute params
aux1={ 'fakeParam', 'fakeDescription'};
paramLabels=aux1(:,1);
description=aux1(:,2);
fakeParam=nan(Nstrides,1);

%% Save all the params in the data matrix & generate labTimeSeries
for i=1:length(paramLabels)
    eval(['data(:,i)=',paramLabels{i},';'])
end

%%
out=parameterSeries(data,paramLabels,in.adaptParams.hiddenTime,description);


function out = calcParameters(trialData,subData,eventClass,initEventSide)
%Computes gait parameters on a per-stride basis
%out = calcParameters(trialData,subData,eventClass,initEvent)
%INPUT:
%trialData: processedLabData object
%subData: subjectMetaData object
%eventClass: string containing the prefix to an existing event class: {'force','kin',''} (Optional, defaults to '')
%initEvent: 'L' or 'R'. Optional, defaults to trialData.metaData.refLeg

if nargin<3 || isempty(eventClass)
    eventClass=[];
end
if nargin<4 || isempty(initEventSide)
    initEventSide=[];
end
%out = calcParametersNew(trialData,subData); %Calling new function
out = calcParametersNew_test(trialData,subData,eventClass,initEventSide); %Calling new function

%Uncomment this line to compute the old way:
%out = calcParameters_legacy(trialData,subData);
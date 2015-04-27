function out = calcExperimentalParams(in,subData,eventClass,initEventType)

if nargin<2 || isempty(subData)
    subData=[]; %ToDo: not allow this to be empty
end
if nargin<3 || isempty(eventClass)
    eventClass=[];
end
if nargin<4 || isempty(initEventType)
    initEventType=[];
end

    out = calcExperimentalParamsNew(in,subData,eventClass,initEventType);
    
    %out = calcExperimentalParams_legacy(in);
end
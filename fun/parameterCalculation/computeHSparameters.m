function [out] = computeHSparameters(someTS,gaitEvents,eventType)
%This function averages labTS data across given phases.
%The output is a parameterSeries object, which can be concatenated with
%other parameterSeries objects, for example with those from
%computeTemporalParameters. 
%See also computeSpatialParameters, computeTemporalParameters,
%computeForceParameters, parameterSeries

%%INPUT:
%someTS: labTS object to discretize
%gaitEvents: eventTS
%eventTypes: either a cell array of strings, or a single char indicating
%the slow leg
%alignmentVector: integer vector of same size as eventType

%TODO: this should be a method of labTS

%get slow heel strikes times
% T_HS=labTimeSeries.getArrayedEvents(gaitEvents,{[slowleg 'HS'],[getOtherLeg(slowleg) 'HS']});
T_HS=labTimeSeries.getArrayedEvents(gaitEvents,eventType);
nstrides=size(T_HS,1);
%keyboard
% iSHS=find(ismember(someTS.Time,T_HS(2:end,1)));
% iFHS=find(ismember(someTS.Time,T_HS(1:end-1,2)));

% iSHS=find(ismember(someTS.Time,round(strideEvents.tSHS2,6)));
% iFHS=find(ismember(someTS.Time,round(strideEvents.tFHS,6)));

%extract parameters
Ang_SHS=squeeze(someTS.getSample(T_HS(2:end,1)));

try
    Ang_FHS=squeeze(someTS.getSample(T_HS(1:end-1,2)));   
catch
    Ang_FHS=NaN(size(Ang_SHS));%NEEDS FIX
     disp('no gait events for fast leg!')
end   

%rename labels
Slabs=strcat(someTS.labels,{'AtSHS'});
Flabs=strcat(someTS.labels,{'AtFHS'});
%Ang_SHS=Ang_SHS.renameLabels(Ang_SHS.labels,strcat(Ang_SHS.labels,{'@SHS'}));
%Ang_FHS=Ang_FHS.renameLabels(Ang_FHS.labels,strcat(Ang_FHS.labels,{'@FHS'}));
PangSHS=parameterSeries(Ang_SHS(:,:),Slabs,[],Slabs);
PangFHS=parameterSeries(Ang_FHS(:,:),Flabs,[],Flabs);
out=cat(PangSHS,PangFHS);

end


function [out] = computeTSdiscreteParameters(someTS,gaitEvents,eventTypes,alignmentVector,summaryFun)
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

if nargin<4 || isempty(alignmentVector)
    
    if ~isa(eventTypes,'cell') %Allow to change the type of event post-processing 
        
        if ~isa(eventTypes,'char')
            error('Bad argument for eventTypes')
        end
        
        s=eventTypes;    f=getOtherLeg(s);
        eventTypes={[s 'HS'],[f 'TO'],[f 'HS'],[s 'TO']};
    end
  
    alignmentVector=[2,4,2,4];
    desc2={'SHS to mid DS1','mid DS1 to FTO',...
        'FTO to 1/4 fast swing','1/4 to mid fast swing',...
        'mid fast swing to 3/4','3/4 fast swing to FHS',...
        'FHS to mid DS2', 'mid DS2 to STO',...
        'STO to 1/4 slow swing','1/4  to mid slow swing',...
        'mid slow swing to 3/4','3/4 slow swing to SHS'}';
else
    if length(eventTypes)~=length(alignmentVector) 
        if ~isempty(alignmentVector)
            error('Inconsistent sizes of eventTypes and alignmentVector')
        end
    end
    desc2=cell(sum(alignmentVector),1);
end
if nargin<5
    summaryFun=[];
end
someTS.Quality=[];%Needed to avoid error %TODO: use quality info to mark parameters as BAD if necessary
[DTS,~]=someTS.discretize(gaitEvents,eventTypes,alignmentVector,summaryFun);
[N,M,P]=size(DTS.Data);
%Make labels:
ll=strcat(repmat(strcat(DTS.labels,'_s'),N,1),repmat(mat2cell(num2str([1:N]'),ones(N,1),2),1,M));
%Make descriptions:
desc=strcat(strcat(strcat('Mean of data in TS ', repmat(DTS.labels,N,1)), ' from '), repmat(desc2,1,M));
out= parameterSeries(reshape(DTS.Data,N*M,P)',ll(:),1:P,desc(:));
end
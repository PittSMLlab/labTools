function [numSteps,initTime,endTime,initEventSide]=...
    getStepInfo(this,triggerEvent)
%getStepInfo  Returns step count and timing information
%
%   [numSteps,initTime,endTime,initEventSide] =
%   getStepInfo(this) returns step information using heel
%   strike as the default trigger event
%
%   [numSteps,initTime,endTime,initEventSide] =
%   getStepInfo(this,triggerEvent) returns step information
%   using the specified trigger event
%
%   Inputs:
%       triggerEvent - event type for step boundaries
%                      (default: 'HS')
%                      Note: Do not include leg identifier
%
%   Outputs:
%       numSteps - number of complete steps
%       initTime - vector of step start times
%       endTime - vector of step end times
%       initEventSide - cell array indicating which leg ('R' or
%                       'L') initiated each step
%
%   See also: getStrideInfo

if nargin<2 || isempty(triggerEvent)
    triggerEvent='HS';
    %Using HS as default event for striding.
end

%Find starting events:
rEventList=this.getPartialGaitEvents(['R' triggerEvent]);
rIdxLst=find(rEventList==1);
lEventList=this.getPartialGaitEvents(['L' triggerEvent]);
lIdxLst=find(lEventList==1);

auxTime=this.gaitEvents.Time;

i=0;
noEnd=true;
firstIdx=min([rIdxLst;lIdxLst]);
numSteps=0;
initTime=[];
endTime=[];
initEventSide={};
if ~isempty(firstIdx)
    initTime(1)=auxTime(firstIdx);
    if any(rIdxLst==firstIdx)
        lastSideRight=true;
    else
        lastSideRight=false;
    end
    while noEnd %This is an infinite loop...
        i=i+1;
        if lastSideRight
            aux=find(auxTime(lIdxLst)>initTime(i),1,'first');
            t=auxTime(lIdxLst(aux));
            initEventSide{i}='R';
        else
            aux=find(auxTime(rIdxLst)>initTime(i),1,'first');
            t=auxTime(rIdxLst(aux));
            initEventSide{i}='L';
        end
        lastSideRight=~lastSideRight;
        if ~isempty(aux)
            endTime(i)=t;
            initTime(i+1)=t;
        else
            endTime(i)=NaN;
            noEnd=false;
        end
    end
    numSteps=i;
end
end


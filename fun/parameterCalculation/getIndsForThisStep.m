function [indSHS,indFTO,indFHS,indSTO,indSHS2,indFTO2,indFHS2,indSTO2,timeSHS,timeFTO,timeFHS,timeSTO,timeSHS2,timeFTO2,timeFHS2,timeSTO2] = getIndsForThisStep(events,eventsTime,step)

SHS=events(:,1);
FHS=events(:,2);
STO=events(:,3);
FTO=events(:,4);
inds=find(SHS); 

    indSHS=inds(step);
    timeSHS=eventsTime(indSHS);
    indFTO=find((eventsTime>timeSHS)&FTO,1);
    timeFTO=eventsTime(indFTO);
    indFHS=find((eventsTime>timeFTO)&FHS,1);
    timeFHS=eventsTime(indFHS);
    indSTO=find((eventsTime>timeFHS)&STO,1);
    timeSTO=eventsTime(indSTO);
    indSHS2=inds(step+1);
    timeSHS2=eventsTime(indSHS2);
    if ~isempty(timeSHS2)
        indFTO2=find((eventsTime>timeSHS2)&FTO,1);
        timeFTO2=eventsTime(indFTO2);
        if ~isempty(timeFTO2)
            indFHS2=find((eventsTime>timeFTO2)&FHS,1);
            timeFHS2=eventsTime(indFHS2);
            if ~isempty(timeFHS2)
                indSTO2=find((eventsTime>timeFHS2)&STO,1);
                timeSTO2=eventsTime(indSTO2);
            else
                indSTO2=[];
                timeSTO2=[];
            end
        else
            indFHS2=[];
            timeFHS2=[];
            indSTO2=[];
            timeSTO2=[];
        end
    else
        indFTO2=[];
        timeFTO2=[];
        indFHS2=[];
        timeFHS2=[];
        indSTO2=[];
        timeSTO2=[];
    end

end


function [indData] = getIndsForAllSteps(gaitEvents,s,f)
%Returns index of occurrence and time of occurrence for first 8 (eight!)
%events, starting with a SHS.
%Output structure contains both the data and the labels for each column

eventList={[s 'HS'],[f 'TO'],[f 'HS'],[s 'TO']};
N=length(eventList);
events=gaitEvents.getDataAsVector(eventList);

for i=1:N
    eval([eventList{i} '=events(:,i);']);
end

eventsTime=gaitEvents.Time;
aux=find(SHS); 
M=length(aux)-1;
inds=NaN(M,2*N);
times=NaN(M,2*N);

%Set ind and time for all SHS events
inds(:,1)=aux(1:M);
times(:,1)=eventsTime(aux(1:M));

%Set other events for all steps except last
for step=1:M-1;
    for i=2:N
        eval(['inds(step,i)=find((eventsTime>times(step,i-1))&' eventList{i} ',1);']);
        times(step,i)=eventsTime(inds(step,i));
    end
    inds(step,N+1)=inds(step+1,1);
    times(step,N+1)=eventsTime(inds(step,N+1));
    for i=N+2:2*N
        eval(['inds(step,i)=find((eventsTime>times(step,i-1))&' eventList{i} ',1);']);
        times(step,i)=eventsTime(inds(step,i));
    end
end

%Set for last step:
step=M;
for i=2:N
    eval(['inds(step,i)=find((eventsTime>times(step,i-1))&' eventList{i} ',1);']);
    times(step,i)=eventsTime(inds(step,i));
end
inds(step,N+1)=aux(M+1);
times(step,N+1)=eventsTime(inds(step,N+1));
for i=N+2:2*N
    eval(['aux=find((eventsTime>times(step,i-1))&' eventList{i} ',1);']); %There is no assurance that these events exist, as we only now that there are M+1 SHS events, but not FTO, FHS, STO
    if ~isempty(aux) %In case an event was actually found, if not, leave NaN in place
        inds(step,i)=aux;
        times(step,i)=eventsTime(inds(step,i));
    end
end


%Set labels for events
labels=cell(4*N,1);
labels(1:N)=eventList;
for i=1:N
    labels(i)=['inds' eventList{i}];
    labels(N+i)=['inds' eventList{i} '2'];
    labels(2*N+i)=['times' eventList{i}];
    labels(3*N+i)=['times' eventList{i} '2'];
end

indData.Data=[inds,times];
indData.labels=labels;

end


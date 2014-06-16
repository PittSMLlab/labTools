function [LHS,RHS,LTO,RTO] = getEventsFromForces(FzL,FzR,fsample)

%% Get stance phases
[stanceL] = getStanceFromForces(FzL, 35, fsample);
[stanceR] = getStanceFromForces(FzR, 35, fsample);

%% Get events from stance
[LHS,RHS,LTO,RTO] = getEventsFromStance(stanceL,stanceR);

%% Eliminate any events that ocurr prior to actual activity in the trial
Rheel=FzR;
Lheel=FzL;
aux=Rheel(:,1)-Rheel(1,1); %Zero initial value
aux2=cumsum(aux.^2); %Cumulative energy 
begin_index1=find(aux2>.001*aux2(end),1); %First element whose cumulative energy is at least .1% of total energy
aux=Lheel(:,1)-Lheel(1,1); %Zero initial value
aux2=cumsum(aux.^2); %Cumulative energy 
begin_index2=find(aux2>.001*aux2(end),1); %First element whose cumulative energy is at least .1% of total energy

begin_index=max([begin_index1,begin_index2]);

LHS(1:begin_index)=false;
RHS(1:begin_index)=false;
LTO(1:begin_index)=false;
RTO(1:begin_index)=false;


%% Check consistency
[consistent] = checkEventConsistency(LHS,RHS,LTO,RTO);



end


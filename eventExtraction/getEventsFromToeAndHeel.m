function [LHS,RHS,LTO,RTO] = getEventsFromToeAndHeel(Ltoe,Lheel,Rtoe,Rheel,fsample)

%% Get stance phases
[stanceL] = getStanceFromToeAndHeel(Lheel, Ltoe, fsample); %Lheel and Ltoe need to be 
[stanceR] = getStanceFromToeAndHeel(Rheel, Rtoe, fsample);

%% Get events from stance
[LHS,RHS,LTO,RTO] = getEventsFromStance(stanceL,stanceR);
badInds=any(isnan(Lheel'))|any(isnan(Ltoe'))|any(isnan(Rheel'))|any(isnan(Rtoe'));
LHS(badInds)=false;
RHS(badInds)=false;
LTO(badInds)=false;
RTO(badInds)=false;

%% Eliminate any events that ocurr prior to actual activity in the trial
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
%[consistent] = checkEventConsistency(LHS,RHS,LTO,RTO);



end


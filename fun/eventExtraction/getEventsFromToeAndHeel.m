function [LHS,RHS,LTO,RTO] = ...
    getEventsFromToeAndHeel(Ltoe,Lheel,Rtoe,Rheel,fsample)

% retrieve stance gait phases from toe and heel
stanceL = getStanceFromToeAndHeel(Lheel,Ltoe,fsample);
stanceR = getStanceFromToeAndHeel(Rheel,Rtoe,fsample);

% retrieve gait events from stance phase
[LHS,RHS,LTO,RTO] = getEventsFromStance(stanceL,stanceR);
badInds = any(isnan(Lheel')) | any(isnan(Ltoe')) | ...
    any(isnan(Rheel')) | any(isnan(Rtoe'));
LHS(badInds) = false;
RHS(badInds) = false;
LTO(badInds) = false;
RTO(badInds) = false;

% eliminate any events that ocurr prior to actual activity in the trial
aux = Rheel(:,1) - Rheel(1,1);  % zero initial value (right leg)
aux2 = cumsum(aux .^ 2);        % cumulative energy
% first element whose cumulative energy is at least 0.1% of total energy
begin_index1 = find(aux2 > 0.001*aux2(end),1);
aux = Lheel(:,1) - Lheel(1,1);  % zero initial value (left leg)
aux2 = cumsum(aux .^ 2);        % cumulative energy
begin_index2 = find(aux2 > 0.001*aux2(end),1);
begin_index = max([begin_index1 begin_index2]);

LHS(1:begin_index) = false;
RHS(1:begin_index) = false;
LTO(1:begin_index) = false;
RTO(1:begin_index) = false;

% verify that all gait events are consistent
% consistent = checkEventConsistency(LHS,RHS,LTO,RTO);

end


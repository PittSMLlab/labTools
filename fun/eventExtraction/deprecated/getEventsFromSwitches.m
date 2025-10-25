function [LHS,RHS,LTO,RTO] = getEventsFromSwitches(Lft_sw,Rft_sw,fsample)

% retrieve left and right leg stance phases
stanceL = getStanceFromSwitches(Lft_sw,fsample);
stanceR = getStanceFromSwitches(Rft_sw,fsample);

% retrieve gait events from stance phases
[LHS,RHS,LTO,RTO] = getEventsFromStance(stanceL,stanceR);

% verify that all gait events are consistent
% consistent = checkEventConsistency(LHS,RHS,LTO,RTO);

end


function [LHS,RHS,LTO,RTO] = getEventsFromSwitches(Lft_sw,Rft_sw,fsample)

%% Get stance phases
[stanceL] = getStanceFromSwitches(Lft_sw, fsample);
[stanceR] = getStanceFromSwitches(Rft_sw, fsample);

%% Get events from stance
[LHS,RHS,LTO,RTO] = getEventsFromStance(stanceL,stanceR);

%% Check consistency
[consistent] = checkEventConsistency(LHS,RHS,LTO,RTO);



end


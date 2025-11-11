function isConsistent = checkEventConsistency(LHS,RHS,LTO,RTO)

isConsistent = true;                % initialize to events being consistent
% gait event sequence should be: LHS -> RTO -> RHS -> LTO -> LHS -> repeat
aux5 = LHS + 2*RTO + 4*RHS + 8*LTO; % events sequence: 1, 2, 4, 8, 1, ...
aux6 = aux5(aux5 ~= 0);             % remove zeros (i.e., non-events)
aux7 = diff(aux6);                  % should be only '1's,'2's,'4's, or -3s
if any((aux7 ~= 1) & (aux7 ~= 2) & (aux7 ~= 4) & (aux7 ~= -7))
    disp('Warning: Inconsistent event detection.');
    isConsistent = false;           % there is a trial inconsistency
    if ~any((aux7 ~= 1) & (aux7 ~= 2) & (aux7 ~= 4) & (aux7 ~= -7))
        disp('It is probable that the trial is backwards.');
    end
end

end


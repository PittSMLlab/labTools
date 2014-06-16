function [consistent] = checkEventConsistency(LHS,RHS,LTO,RTO)

consistent=true;
%The sequence should be LHS RTO RHS LTO LHS ...
%%
aux5=LHS+2*RTO+4*RHS+8*LTO; %This should get events in the sequence 1,2,4,8,1... with 0 for non-events
aux6=aux5(aux5~=0); %This should get rid of 0s
aux7=diff(aux6); %This should only return 1s,2s,4s or -3s
if any((aux7~=1)&(aux7~=2)&(aux7~=4)&(aux7~=-7))
    disp('Warning: Non consistent event detection')
    consistent=false;
    if ~any((aux7~=1)&(aux7~=2)&(aux7~=4)&(aux7~=-7))
        disp('Probable backwards trial');
    end
end

end


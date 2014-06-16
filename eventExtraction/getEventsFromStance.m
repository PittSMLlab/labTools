function [LHS,RHS,LTO,RTO] = getEventsFromStance(stanceL,stanceR)

%First step:
LTO=([false;diff(double(stanceL))==-1]);%& stanceR;
LHS=([false;diff(double(stanceL))==1]) ;%& stanceR;
RTO=([false;diff(double(stanceR))==-1]) ;%& stanceL;
RHS=([false;diff(double(stanceR))==1]) ;%& stanceL;

end


 function [stance] = getStanceFromForces(Fz, threshold, fsample)
%Get stance from acceleration

stance=abs(Fz)>threshold;


%% STEP N: Eliminate stance & swing phases shorter than 200 ms
stance = deleteShortPhases(stance,fsample,0.2);

end


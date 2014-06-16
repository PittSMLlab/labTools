 function [stance] = getStanceFromSwitches(ft_sw, fsample)
%Get stance from acceleration

stance=ft_sw>.2;


%% STEP N: Eliminate stance & swing phases shorter than 200 ms
stance = deleteShortPhases(stance,fsample,0.2);

end


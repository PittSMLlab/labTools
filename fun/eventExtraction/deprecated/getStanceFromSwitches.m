function stance = getStanceFromSwitches(ft_sw,fsample)
%GETSTANCEFROMSWITCHES Retrieve stance phase from acceleration

stance = ft_sw > 0.2;
% remove stance and swing phases shorter than 200 ms
stance = deleteShortPhases(stance,fsample,0.2);

end


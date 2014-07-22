function [procData,f_cut,BW,notchList] =extractMuscleActivityFromEMG(data,fs,f_cut,BW,notchList)
% Extract EMG amplitude


if nargin<3
    f_cut=10;
end

[data] = filterEMG(data,fs,BW,notchList); %Filtering
amp=amp_estim(data,fs,1,f_cut); %linear estimator of amplitude
procData=(amp>=0).*amp; %kills negative samples, which should not ocurr anyway
    
end


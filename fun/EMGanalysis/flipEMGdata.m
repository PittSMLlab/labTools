function [flippedEMGData] =flipEMGdata(EMGdata,phaseDim,muscleDim)
%This function swaps the first and second half of EMGdata along phaseDim, 
%but only for the SECOND half of the array EMGdata along dimension muscleDim
N=size(EMGdata,muscleDim);
EMGdata1=sliceArray(EMGdata,1:N/2,muscleDim);
EMGdata2=sliceArray(EMGdata,(N/2+1):N,muscleDim);
flippedEMGData=cat(muscleDim, EMGdata1, fftshift(EMGdata2,phaseDim));
end


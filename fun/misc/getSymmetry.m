function [symData] = getSymmetry(EMGdata,muscleDim)
%Returns the differences of the two halves of the EMGdata array along
%dimension muscleDim
N=size(EMGdata,muscleDim);
EMGdata1=sliceArray(EMGdata,1:N/2,muscleDim);
EMGdata2=sliceArray(EMGdata,(N/2+1):N,muscleDim);
symData=EMGdata1-EMGdata2;
end


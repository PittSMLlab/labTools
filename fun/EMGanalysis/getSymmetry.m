function symData = getSymmetry(EMGdata,muscleDim)
%GETSYMMETRY Difference between the two halves of an array.
%
%   Splits the array in two halves along muscleDim and returns the first
% half minus the second half.
%
% Inputs:
%   EMGdata   - array of EMG data
%   muscleDim - dimension to split in halves
%
% Outputs:
%   symData - first half minus second half along muscleDim
%
% Toolbox Dependencies: None
%
% See also FLIPEMGDATA, SLICEARRAY.

N        = size(EMGdata,muscleDim);
EMGdata1 = sliceArray(EMGdata,1:N/2,muscleDim);
EMGdata2 = sliceArray(EMGdata,(N/2+1):N,muscleDim);
symData  = EMGdata1-EMGdata2;
end


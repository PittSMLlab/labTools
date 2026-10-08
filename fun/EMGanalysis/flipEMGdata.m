function flippedEMGData = flipEMGdata(EMGdata,phaseDim,muscleDim)
%FLIPEMGDATA Swap the halves of the phase dimension for half the muscles.
%
%   Splits the array in two halves along muscleDim and circularly shifts
% (fftshift) only the second half along phaseDim, which swaps the first
% and second half of the gait phase for those muscles.
%
% Inputs:
%   EMGdata   - array of EMG data
%   phaseDim  - dimension holding the gait phase
%   muscleDim - dimension holding the muscles (first half left, second
%               half shifted)
%
% Outputs:
%   flippedEMGData - array with the second half of muscleDim shifted
%
% Toolbox Dependencies: None
%
% See also GETSYMMETRY, SLICEARRAY.

N = size(EMGdata,muscleDim);
EMGdata1 = sliceArray(EMGdata,1:N/2,muscleDim);
EMGdata2 = sliceArray(EMGdata,(N/2+1):N,muscleDim);
flippedEMGData = cat(muscleDim, EMGdata1, fftshift(EMGdata2,phaseDim));
end


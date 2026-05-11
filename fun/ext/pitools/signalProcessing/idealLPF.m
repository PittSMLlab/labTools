function filteredData = idealLPF(data, fcut)
%IDEALLPF Apply an ideal (brick-wall) lowpass filter with zero phase lag.
%
%   Filters data in the frequency domain by zeroing all frequency
% components above fcut. Uses the DTFT/IDTFT pair via FFT, with the
% spectrum shifted to center zero frequency before masking. Zero phase
% lag is achieved because the mask is applied symmetrically to the
% centered spectrum.
%
% Inputs:
%   data - (N×C) double, data to filter (columns are channels)
%   fcut - scalar double, normalized cutoff frequency in [0, 0.5]
%          (i.e., fcut = f_cutoff_Hz / fsample)
%
% Outputs:
%   filteredData - (N×C) double, filtered data (same size as input)
%
% Toolbox Dependencies: None
%
% See also DISCRETETIMEFOURIERTRANSFORM, LOWPASSFILTERING2.

arguments
    data (:,:) double
    fcut (1,1) double {mustBeInRange(fcut, 0, 0.5)}
end

%% Transform to frequency domain (centered spectrum)
[Fdata, fvector] = DiscreteTimeFourierTransform(data, 1);

%% Apply brick-wall lowpass mask
% Broadcasting: (abs(fvector) <= fcut) is Nx1; Fdata is NxC.
% MATLAB automatically replicates the mask across columns.
Fdata = Fdata .* (abs(fvector) <= fcut);

%% Inverse transform; ifftshift undoes the centering before ifft
filteredData = ifft(ifftshift(Fdata, 1));

end

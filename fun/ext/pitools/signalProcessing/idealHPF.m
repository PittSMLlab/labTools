function filteredData = idealHPF(data, fcut)
%IDEALHPF Apply an ideal zero-lag high-pass filter in the frequency domain.
%
%   Computes the DTFT of data, zeroes all frequency components with
% absolute normalized frequency below fcut, then inverts back to the
% time domain. Because filtering is done in the frequency domain without
% windowing, this is an ideal (brick-wall) filter with zero phase lag.
%
% Inputs:
%   data - (N x C) double array of time series; filtering is applied
%          along rows (dimension 1)
%   fcut - cutoff frequency in normalized units [0, 0.5]; components
%          with |f| < fcut are zeroed
%
% Outputs:
%   filteredData - high-pass filtered signal, same size as data
%
% Toolbox Dependencies: None
%
% See also DISCRETETIMEFOURIERTRANSFORM.

arguments
    data (:,:) double
    fcut (1,1) double {mustBeInRange(fcut, 0, 0.5)}
end

%% Apply Ideal High-Pass Filter
[Fdata, fvector] = DiscreteTimeFourierTransform(data, 1);
Fdata = Fdata .* repmat((abs(fvector) > fcut), 1, size(Fdata, 2));

%% Invert to Time Domain
filteredData = ifft(ifftshift(Fdata, 1));

end

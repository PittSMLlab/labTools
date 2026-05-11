data2 = fft(dataAux) .* abs(fft(h*ones(1,size(datafile,2)))).^2;

data=ifft(data2);
data1=data(1:size(datafile,1),:);


%Filter characteristics
% figure
% plot(abs(fft(h)))

function data = lowpassfiltering2(data, fcut, filterOrder, fsample)
%LOWPASSFILTERING2 Apply a zero-phase Butterworth lowpass filter with
%mirrored-boundary padding.
%
%   Applies a Butterworth lowpass filter with mirrored boundary padding to
% avoid edge transients. The filter is applied using an FFT-based zero-phase
% method: the impulse response is computed, its magnitude squared is applied
% to the data spectrum, and the result is inverse-transformed. Mirrors the
% input signal end-to-end before filtering so that boundary conditions are
% smooth, then returns only the first half of the filtered result.
%
% Inputs:
%   data        - (N×C) double, data to filter (columns are channels)
%   fcut        - scalar double, lowpass cutoff frequency (Hz)
%   filterOrder - scalar integer, Butterworth filter order
%   fsample     - scalar double, sampling frequency (Hz)
%
% Outputs:
%   data - (N×C) double, filtered data (same size as input)
%
% Toolbox Dependencies: None (butter, filter, fft, ifft are core MATLAB)
%
% See also LOWPASSFILTERING, FILTFILTHD_SHORT.

arguments
    data        (:,:) double
    fcut        (1,1) double {mustBePositive}
    filterOrder (1,1) double {mustBePositive, mustBeInteger}
    fsample     (1,1) double {mustBePositive}
end

%% Pad data with mirrored reflection to avoid edge transients
dataMirrored = [data; data(end:-1:1, :)];

%% Design filter and compute its impulse response
nyquist      = 0.5 * fsample;             % Nyquist frequency (Hz)
[b, a]       = butter(filterOrder, fcut / nyquist);
impulse      = [1; zeros(size(dataMirrored, 1) - 1, 1)];
filterImpulse = filter(b, a, impulse);


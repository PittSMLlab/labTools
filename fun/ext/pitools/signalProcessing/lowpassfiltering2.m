function data1 = lowpassfiltering2(datafile, cutoff, complexity, fs)

%lowpassfilter function, making sure that there is continuity on borders
%(mirror/circular continuity)
%PI 07/2013

%pass the 'lowpassfilter' function:  1) a data array for filtering,
                                    %2) the freqency you want removed, and
                                    %3) the sampling frequency
%'lowpassfilter' function returns the data array that has been filtered with a
%lowpass Butterworth filter, with the specified complexity and cutoff frequency

dataAux=[datafile;datafile(end:-1:1,:)];

[b,a]=butter(complexity, (cutoff/(.5*fs)));   %get lowpass filter vectors
h = filter(b,a,[1;zeros(size(dataAux,1)-1,1)]);

data2 = fft(dataAux) .* abs(fft(h*ones(1,size(datafile,2)))).^2;

data=ifft(data2);
data1=data(1:size(datafile,1),:);


%Filter characteristics
% figure
% plot(abs(fft(h)))

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


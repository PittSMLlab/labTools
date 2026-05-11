function data = lowpassfiltering(data, fcut, filterOrder, fsample)
%LOWPASSFILTERING Apply a zero-phase Butterworth lowpass filter.
%
%   Filters data using MATLAB's filtfilt to achieve zero phase shift.
% Designed for offline (non-real-time) use where the full signal is
% available.
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
% Toolbox Dependencies: None (butter, filtfilt are core MATLAB)
%
% See also LOWPASSFILTERING2, FILTFILTHD_SHORT.

arguments
    data        (:,:) double
    fcut        (1,1) double {mustBePositive}
    filterOrder (1,1) double {mustBePositive, mustBeInteger}
    fsample     (1,1) double {mustBePositive}
end

nyquist    = 0.5 * fsample;  % Nyquist frequency (Hz)
[b, a]     = butter(filterOrder, fcut / nyquist);
data       = filtfilt(b, a, data);  % zero-phase filtering

end

function data = lowpassfiltering(datafile, cutoff, complexity, samp);
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


%pass the 'lowpassfilter' function:  1) a data array for filtering,
                                    %2) the freqency you want removed, and
                                    %3) the sampling frequency
%'lowpassfilter' function returns the data array that has been filtered with a
%lowpass Butterworth filter, with the specified complexity and cutoff frequency



[b,a]=butter(complexity, (cutoff/(.5*samp)));   %get lowpass filter vectors
data = filtfilt(b,a,datafile);  %filter using filtfilt funtion to avoid phase shifts

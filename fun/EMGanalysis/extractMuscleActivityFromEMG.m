function [procData,filteredData,filterList,procList] = ...
    extractMuscleActivityFromEMG(data,fs,f_cut,BW,notchList)
%EXTRACTMUSCLEACTIVITYFROMEMG Estimate the EMG amplitude envelope.
%
%   Wrapper that band-pass filters the raw EMG (and optionally notch
% filters it) with filterEMG, then estimates the amplitude envelope with
% amp_estim.
%
% Inputs:
%   data      - raw EMG, samples x channels
%   fs        - sampling frequency (Hz)
%   f_cut     - (optional) cutoff frequency (Hz) of the envelope estimate
%               (default: 10)
%   BW        - (optional) band-pass edges [low high] (Hz); empty uses the
%               filterEMG default
%   notchList - (optional) frequencies (Hz) to notch out (default: none)
%
% Outputs:
%   procData     - amplitude envelope of each channel
%   filteredData - band-pass (and notch) filtered EMG
%   filterList   - filter objects used by filterEMG
%   procList     - filter objects used by amp_estim
%
% Toolbox Dependencies: Signal Processing Toolbox (through filterEMG)
%
% See also FILTEREMG, AMP_ESTIM.

N = size(data,2); %Number of channels
if nargin < 3
    f_cut = 10;
end
if nargin < 4
    BW = [];
end
if nargin < 5
    notchList = [];
end

%Does a band-pass filter of the data, and removes some specific frequencies
%through notch-filters
[filteredData,filterList] = filterEMG(data,fs,BW,notchList);

%Amplitude estimation. 3rd argument defines order of estimation.
[procData,procList] = amp_estim(filteredData,fs,1,f_cut);

end


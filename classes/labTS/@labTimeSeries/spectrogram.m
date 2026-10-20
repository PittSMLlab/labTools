function Sthis = spectrogram(this, labels, nFFT, tWin, tOverlap)
%SPECTROGRAM Computes spectrogram.
%
%   Sthis = spectrogram(this) computes spectrogram with default parameters
%
%   Sthis = spectrogram(this, labels, nFFT, tWin, tOverlap) computes for
% specified labels and parameters
%
% Inputs:
%   this     - labTimeSeries object
%   labels   - labels to include (optional)
%   nFFT     - FFT length (optional)
%   tWin     - window duration (optional)
%   tOverlap - overlap duration (optional)
%
% Outputs:
%   Sthis - spectroTimeSeries object
%
%   NOTE: the spectroTimeSeries class is not part of this repository.
%
% Toolbox Dependencies: None
%
% See also SPECTROTIMESERIES, FOURIERTRANSFORM.

if nargin < 2
    labels = [];
end
if nargin < 3
    nFFT = [];
end
if nargin < 4
    tWin = [];
end
if nargin < 5
    tOverlap = [];
end
Sthis = spectroTimeSeries.getSTSfromTS(this, labels, nFFT, tWin, tOverlap);
end


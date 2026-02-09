function Sthis = spectrogram(this, labels, nFFT, tWin, tOverlap)
%spectrogram  Computes spectrogram
%
%   Sthis = spectrogram(this) computes spectrogram with default
%   parameters
%
%   Sthis = spectrogram(this, labels, nFFT, tWin, tOverlap) computes
%   for specified labels and parameters
%
%   Inputs:
%       this - labTimeSeries object
%       labels - labels to include (optional)
%       nFFT - FFT length (optional)
%       tWin - window duration (optional)
%       tOverlap - overlap duration (optional)
%
%   Outputs:
%       Sthis - spectroTimeSeries object
%
%   See also: spectroTimeSeries, fourierTransform

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


function this = medianFilter(this, N)
%MEDIANFILTER Applies median filter.
%
%   this = medianFilter(this, N) applies median filter of order N
%
% Inputs:
%   this - labTimeSeries object
%   N    - filter order (must be odd)
%
% Outputs:
%   this - filtered labTimeSeries with NaN at edges
%
% Toolbox Dependencies: Signal Processing Toolbox
%
% See also MEDFILT1, LOWPASSFILTER.

if mod(N, 2) == 0
    error('labTS:medianFilter', 'Only odd filter orders are allowed');
    % This actually works with even orders, but then the data gets
    % shifted by half a sample, which is undesirable.
end

% NOTE: medfilt1 is called without 'omitnan', so a window that contains a
% NaN gives NaN ('includenan' behavior).
% this.Data = medfilt1(this.Data, N, 1, 'omitnan');
this.Data = medfilt1(double(this.Data), double(N), double(1));
% Setting the samples outside the filter to NaN:
this.Data(1:floor(N / 2), :) = NaN;
this.Data(end - floor(N / 2) + 1:end, :) = NaN;
end


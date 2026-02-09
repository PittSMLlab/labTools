function this = medianFilter(this, N)
%medianFilter  Applies median filter
%
%   this = medianFilter(this, N) applies median filter of order N
%
%   Inputs:
%       this - labTimeSeries object
%       N - filter order (must be odd)
%
%   Outputs:
%       this - filtered labTimeSeries with NaN at edges
%
%   See also: medfilt1, lowPassFilter

if mod(N, 2) == 0
    error('labTS:medianFilter', 'Only odd filter orders are allowed');
    % This actually works with even orders, but then the data gets
    % shifted by half a sample, which is undesirable.
end

% altered 12/4/2015 "omitnan" is not a valid input to medfilt1 in 2015a,
% 'omitnan' allowed for the median to be taken among the non-NaN elements
% this.Data = medfilt1(this.Data, N, 1, 'omitnan');
% This back-compatible alternative works as if the last argument were
% 'includenan' (i.e. whenever there is NaN in the window, result is NaN)
this.Data = medfilt1(double(this.Data), double(N), double(1));
% Setting the samples outside the filter to NaN:
this.Data(1:floor(N / 2), :) = NaN;
this.Data(end - floor(N / 2) + 1:end, :) = NaN;
end


function newThis = resampleN(this, newN, method)
%RESAMPLEN Resamples to N samples (override).
%
%   newThis = resampleN(this, newN, method) resamples and preserves
% orientedLabTimeSeries type
%
% Inputs:
%   this   - orientedLabTimeSeries object
%   newN   - target number of samples
%   method - interpolation method (optional)
%
% Outputs:
%   newThis - resampled orientedLabTimeSeries
%
%   Note: Same as resample function, but directly fixing number of
%         samples instead of Ts
%
% Toolbox Dependencies: None
%
% See also RESAMPLE, LABTIMESERIES/RESAMPLEN.

if nargin < 3
    method = [];
end
auxThis = this.resampleN@labTimeSeries(newN, method);
newThis = orientedLabTimeSeries(auxThis.Data, auxThis.Time(1), ...
    auxThis.sampPeriod, auxThis.labels, this.orientation);
end


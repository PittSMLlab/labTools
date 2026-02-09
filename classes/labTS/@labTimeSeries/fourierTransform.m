function Fthis = fourierTransform(this, M)
%fourierTransform  Computes Fourier transform
%
%   Fthis = fourierTransform(this) computes discrete Fourier transform
%   of data
%
%   Fthis = fourierTransform(this, M) ignores M parameter (deprecated)
%
%   Inputs:
%       this - labTimeSeries object
%       M - ignored parameter (optional)
%
%   Outputs:
%       Fthis - labTimeSeries containing Fourier transform with
%               frequency as time axis
%
%   Note: Changed Apr 1st 2015 to return a timeseries. Now ignores 2nd arg
%
%   See also: DiscreteTimeFourierTransform, spectrogram

if nargin > 1
    warning('labTimeSeries:fourierTransform', 'Ignoring second argument');
end
[F, f] = DiscreteTimeFourierTransform(this.Data, this.sampFreq);
Fthis = labTimeSeries(F, f(1), f(2) - f(1), ...
    strcat(strcat('F(', this.labels), ')'));
Fthis.TimeInfo.Units = 'Hz';
end


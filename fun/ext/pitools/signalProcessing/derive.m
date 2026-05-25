function y = derive(x, fsample)
%DERIVE Compute the numerical derivative of a discrete signal.
%
%   Applies a 9-tap smoothing-derivative filter to estimate the first
% derivative of x. The signal is mirrored at both ends before filtering
% to reduce boundary artifacts, and the relevant central portion is
% returned.
%
% Inputs:
%   x       - (N×1) double, input signal
%   fsample - scalar double, sampling frequency (Hz)
%
% Outputs:
%   y - (N×1) double, estimated derivative (same units as x per second)
%
% Toolbox Dependencies: None
%
% See also IDEALLPF, LOWPASSFILTERING2.

arguments
    x       (:,1) double
    fsample (1,1) double {mustBePositive}
end

% 9-tap smoothing-derivative filter (antisymmetric, normalized by 1/128)
DERIV_SCALE      = 1 / 128;  % filter normalizer
derivativeFilter = fsample * DERIV_SCALE ...
    * [1, 6, 14, 14, 0, -14, -14, -6, -1];

% mirror x at both ends to reduce convolution boundary effects
xMirrored = [x(end:-1:1); x; x(end:-1:1)];
yMirrored = conv(xMirrored, derivativeFilter, 'same');
y         = yMirrored(length(x) + 1 : 2 * length(x));

end

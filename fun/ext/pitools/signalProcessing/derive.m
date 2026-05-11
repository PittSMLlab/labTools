derivativeFilter=fsample * 1/8 * [1,2,0,-2,-1]; %Order 5
derivativeFilter=fsample * 1/32 * [1,4,5,0,-5,-4,-1]; %Order 7
derivativeFilter=fsample * 1/128 * [1,6,14,14,0,-14,-14,-6,-1]; %Order 9
order=9;
%derivativeFilter=fsample * 1/512 * [1,8,.,.,.,0,-14,-14,-6,-1]; %Order 9
%Get vels:
y2=conv([x(end:-1:1);x;x(end:-1:1)],derivativeFilter,'same');
y=y2(length(x)+1:2*length(x));
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

end

function [newThis, lag] = derivative(this, diffOrder)
%derivative  Numerical differentiation
%
%   [newThis, lag] = derivative(this) computes numerical derivative
%   using 2nd order finite differences
%
%   [newThis, lag] = derivative(this, diffOrder) uses specified
%   difference order
%
%   Inputs:
%       this - labTimeSeries object
%       diffOrder - filter order: 1, 2, 4, 6, or 8 (optional, default:
%                   2)
%
%   Outputs:
%       newThis - differentiated labTimeSeries
%       lag - time lag in samples (diffOrder/2)
%
%   Note: diffOrder establishes order of FIR filter used for
%         estimation, NOT higher order derivatives. Approximates IIR
%         filter (true derivative) through FIR. For even orders, pads
%         with NaN to preserve time vector.
%
%   Reference:
%   https://en.wikipedia.org/wiki/Finite_difference_coefficient
%
%   See also: derivate, integrate

if nargin < 2 || isempty(diffOrder)
    diffOrder = 2; % Default
end
lag = diffOrder / 2;
switch diffOrder
    case 1
        w = [1 -1];
    case 2
        w = 0.5 * [1 0 -1];
    case 4
        w = [-1 8 0 -8 1] / 12;
    case 6
        w = [1 -9 45 0 -45 9 -1] / 60;
    case 8
        w = [-1/56 4/21 -1 4 0 -4 1 -4/21 1/56] / 5;
    otherwise
        error('labTS:derivative', 'Order not supported');
end
M = size(this.Data, 2);
newData = conv2(this.Data, w', 'valid') / this.sampPeriod;
% newData = [nan(order, M); .5 * (this.Data(3:end, :) -
%     this.Data(1:end - 2, :)); nan(order, M)] / this.sampPeriod;
%     % Centered differential
% For even order differences, we can preserve the sampling of the time
% series, padding with NaN on the edges
if mod(diffOrder, 2) == 0
    newT0 = this.Time(1);
    newData = cat(1, nan(lag, size(newData, 2)), newData, ...
        nan(lag, size(newData, 2)));
else
    newT0 = this.Time(1) + lag * this.sampPeriod;
end
newLabels = strcat('d/dt', {' '}, this.labels);
newThis = labTimeSeries(newData, newT0, this.sampPeriod, newLabels);
end


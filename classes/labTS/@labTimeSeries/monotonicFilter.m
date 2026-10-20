function newThis = monotonicFilter(this, Nderiv, Nreg)
%MONOTONICFILTER Applies monotonic least squares.
%
%   newThis = monotonicFilter(this) applies monotonic least squares filter
% with default parameters
%
%   newThis = monotonicFilter(this, Nderiv, Nreg) uses specified derivative
% and regularization orders
%
% Inputs:
%   this   - labTimeSeries object
%   Nderiv - derivative order (optional, default: 2)
%   Nreg   - regularization order (optional, default: 2)
%
% Outputs:
%   newThis - filtered labTimeSeries
%
% Toolbox Dependencies: None
%
% See also MONOLS, LOWPASSFILTER.

if nargin < 2 || isempty(Nderiv)
    Nderiv = 2;
end
if nargin < 3 || isempty(Nreg)
    Nreg = 2;
end
for ii = 1:size(this.Data, 2)
    this.Data(:, ii) = monoLS(this.Data(:, ii), [], Nderiv, Nreg);
end
newThis = this;
end


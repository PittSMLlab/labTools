function newThis = monotonicFilter(this, Nderiv, Nreg)
%monotonicFilter  Applies monotonic least squares
%
%   newThis = monotonicFilter(this) applies monotonic least squares
%   filter with default parameters
%
%   newThis = monotonicFilter(this, Nderiv, Nreg) uses specified
%   derivative and regularization orders
%
%   Inputs:
%       this - labTimeSeries object
%       Nderiv - derivative order (optional, default: 2)
%       Nreg - regularization order (optional, default: 2)
%
%   Outputs:
%       newThis - filtered labTimeSeries
%
%   See also: monoLS, lowPassFilter

if nargin < 2 || isempty(Nderiv)
    Nderiv = 2;
end
if nargin < 3 || isempty(Nreg)
    Nreg = 2;
end
for i = 1:size(this.Data, 2)
    this.Data(:, i) = monoLS(this.Data(:, i), [], Nderiv, Nreg);
end
newThis = this;
end


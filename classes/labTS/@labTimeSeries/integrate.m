function newThis = integrate(this, initValues)
%integrate  Numerical integration
%
%   newThis = integrate(this) integrates data using zero initial
%   conditions
%
%   newThis = integrate(this, initValues) uses specified initial values
%
%   Inputs:
%       this - labTimeSeries object
%       initValues - initial conditions for integration (optional,
%                    default: zeros)
%
%   Outputs:
%       newThis - integrated labTimeSeries
%
%   Note: This is inverse operator of derivative when used with
%         diffOrder = 1. Initial values represent the integrated data
%         values HALF A SAMPLE before the first sample of this.
%
%   See also: derivative

% This is the inverse operator of derivative when used with
% diffOrder = 1;
M = size(this.Data, 2);
if nargin < 2 || isempty(initValues)
    % Default initial condition = 0
    % Initial values represent the integrated data values HALF A SAMPLE
    % before the first sample of this.
    initValues = zeros(1, M);
end
if numel(initValues) ~= M
    error('labTS:integrate', ...
        'Initial values mismatch between Data and initValues');
end
newData = bsxfun(@plus, initValues(:)', ...
    cumsum([zeros(1, M); this.Data], 1) * this.sampPeriod);
lag = -0.5;
newLabels = strcat('\int', {' '}, this.labels, {' '}, 'dt');
newT0 = this.Time(1) + lag * this.sampPeriod;
newThis = labTimeSeries(newData, newT0, this.sampPeriod, newLabels);
end


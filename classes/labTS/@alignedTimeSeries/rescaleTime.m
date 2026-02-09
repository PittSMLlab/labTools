function newThis = rescaleTime(this, newTs, newT0)
%rescaleTime  Redefines time vector
%
%   newThis = rescaleTime(this) rescales time to [0, 1] range
%
%   newThis = rescaleTime(this, newTs, newT0) uses specified sampling
%   period and initial time
%
%   Inputs:
%       this - alignedTimeSeries object
%       newTs - new sampling period (optional, default: 1/numSamples)
%       newT0 - new initial time (optional, default: 0)
%
%   Outputs:
%       newThis - alignedTimeSeries with rescaled time
%
%   Note: Made for backwards compatibility of aligned series always
%         being defined with time in [0 1]
%
%   See also: alignedTimeSeries

% Re-defines the Time vector to force a new sampling time Made for
% backwards compatibility of aligned series always being defined with
% time in [0 1]
if nargin < 3 || isempty(newT0)
    newT0 = 0;
end
if nargin < 2 || isempty(newTs)
    % Re-scales such that total duration is 1 [time can be thought of
    % as % of some cycle]
    newTs = 1 / length(this.Time);
end
newThis = alignedTimeSeries(newT0, newTs, this.Data, this.labels, ...
    this.alignmentVector, this.alignmentLabels);
end


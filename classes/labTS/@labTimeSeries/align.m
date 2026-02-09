function [ATS, bad] = align(this, eventTS, eventLabel, N, ~)
%align  Aligns data to gait events
%
%   [ATS, bad] = align(this, eventTS, eventLabel, N) aligns data to
%   specified events with given sample counts between events
%
%   Inputs:
%       this - labTimeSeries object
%       eventTS - labTimeSeries with event markers
%       eventLabel - cell array of event labels (optional, default:
%                    first label)
%       N - vector of sample counts between events (optional, default:
%           256 for each interval)
%
%   Outputs:
%       ATS - alignedTimeSeries object
%       bad - logical vector indicating strides with issues
%
%   See also: align_v2, alignedTimeSeries, discretize

if nargin < 3 || isempty(eventLabel)
    eventLabel = eventTS.labels(1);
end
if nargin < 4 || isempty(N)
    N = 256 * ones(size(eventLabel));
end
[ATS, bad] = this.align_v2(eventTS.split(this.Time(1) - ...
    this.sampPeriod, this.Time(end) + this.sampPeriod), eventLabel, N);
end


function this = flushAndRecomputeParameters(this, eventClass, ...
    initEventSide)
%flushAndRecomputeParameters  Completely recalculates parameters
%
%   this = flushAndRecomputeParameters(this) discards existing parameters
%   and recomputes all from scratch
%
%   this = flushAndRecomputeParameters(this, eventClass, initEventSide)
%   recomputes with specified options
%
%   Inputs:
%       this - experimentData object
%       eventClass - event classification parameter (optional)
%       initEventSide - initial event side specification (optional)
%
%   Outputs:
%       this - experimentData object with new parameters
%
%   Note: Different from recomputeParameters() as it throws away previously
%         existing parameters. recomputeParameters only substitutes if
%         there are name collisions, so it allows for recomputing only
%         force or EMG params.
%
%   Example:
%       expData = expData.flushAndRecomputeParameters();
%
%   See also: recomputeParameters, calcParameters

if nargin < 2 || isempty(eventClass)
    eventClass = [];
end

if nargin < 3 || isempty(initEventSide)
    initEventSide = [];
end

trials = cell2mat(this.metaData.trialsInCondition);
for t = trials
    this.data{t}.adaptParams = calcParameters(this.data{t}, ...
        this.subData, eventClass, initEventSide, []);
end
end


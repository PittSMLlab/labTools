function this = recomputeParameters(this, eventClass, initEventSide, ...
    parameterClasses)
%recomputeParameters  Recalculates adaptation parameters
%
%   this = recomputeParameters(this) recomputes adaptParams for all
%   trials using default options
%
%   this = recomputeParameters(this, eventClass, initEventSide,
%   parameterClasses) recomputes parameters with specified options
%
%   Inputs:
%       this - experimentData object
%       eventClass - event classification parameter (optional)
%       initEventSide - initial event side specification (optional)
%       parameterClasses - specific parameter classes to compute (optional)
%
%   Outputs:
%       this - experimentData object with updated parameters
%
%   Example:
%       expData = expData.recomputeParameters();
%
%   See also: flushAndRecomputeParameters, recomputeEvents, calcParameters

if nargin < 2 || isempty(eventClass)
    eventClass = [];
end
if nargin < 3 || isempty(initEventSide)
    initEventSide = [];
end
if nargin < 4 || isempty(parameterClasses)
    parameterClasses = [];
end
trials = cell2mat(this.metaData.trialsInCondition);
for t = trials
    newParams = calcParameters(this.data{t}, this.subData, ...
        eventClass, initEventSide, parameterClasses);
    this.data{t}.adaptParams = ...
        this.data{t}.adaptParams.replaceParams(newParams);
end
end


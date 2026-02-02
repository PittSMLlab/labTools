function this = recomputeEvents(this, eventClass, initEventSide)
%recomputeEvents  Recalculates gait events and parameters
%
%   this = recomputeEvents(this) recomputes events and parameters for
%   all trials with default options
%
%   this = recomputeEvents(this, eventClass, initEventSide)
%   recomputes with specified options
%
%   Inputs:
%       this - experimentData object
%       eventClass - event classification parameter (optional)
%       initEventSide - initial event side specification (optional)
%
%   Outputs:
%       this - experimentData object with recomputed events and parameters
%
%   See also: processedLabData/recomputeEvents, recomputeParameters

trials = cell2mat(this.metaData.trialsInCondition);
for t = trials
    % This recomputes events AND recomputes parameters (otherwise
    % parameters will not correspond to the new events)
    this.data{t} = recomputeEvents(this.data{t});
end
end


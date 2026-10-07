function this = recomputeEvents(this, eventClass, initEventSide)
%RECOMPUTEEVENTS Recalculates gait events and parameters
%
%   this = recomputeEvents(this) recomputes events and parameters for all
% trials with default options
%
%   this = recomputeEvents(this, eventClass, initEventSide) recomputes with
% specified options
%
% NOTE: currently errors because PROCESSEDLABDATA.RECOMPUTEEVENTS does;
%   eventClass and initEventSide are ignored.
%
% Inputs:
%   this          - experimentData object
%   eventClass    - event classification parameter (optional)
%   initEventSide - initial event side specification (optional)
%
% Outputs:
%   this - experimentData object with recomputed events and parameters
%
% Toolbox Dependencies: None
%
% See also PROCESSEDLABDATA.RECOMPUTEEVENTS, RECOMPUTEPARAMETERS.

trials = cell2mat(this.metaData.trialsInCondition);
for t = trials
    % This recomputes events AND recomputes parameters (otherwise
    % parameters will not correspond to the new events)
    this.data{t} = recomputeEvents(this.data{t});
end
end


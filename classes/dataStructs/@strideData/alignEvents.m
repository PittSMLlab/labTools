function newThis = alignEvents(this, events, spacing)
%alignEvents  Aligns data to gait events (unimplemented)
%
%   newThis = alignEvents(this, events, spacing) would align all
%   time series data to the specified gait events with given
%   spacing
%
%   Inputs:
%       this - strideData object
%       events - cell array of event labels for alignment
%       spacing - vector specifying spacing between events
%
%   Outputs:
%       newThis - aligned strideData object
%
%   Note: Current problem - sampling needs to be uniform, but when we
%         alignEvents that can no longer be the case (because event times
%         have natural variability, its alignment implies that we'll have
%         non-uniform sampling)
%
%   See also: timeNormalize

newThis = [];
end


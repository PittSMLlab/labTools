function newThis = discardBadStrides(this)
%discardBadStrides  Removes bad strides (deprecated)
%
%   newThis = discardBadStrides(this) would remove strides marked as
%   bad
%
%   Inputs:
%       this - stridedExperimentData object
%
%   Outputs:
%       newThis - stridedExperimentData object with bad strides removed
%
%   Note: No need, the discarding happens when this structure is
%         created from a processed experiment
%
%   See also: strideData/isBad

% No need, the discarding happens when this structure is created from
% a processed experiment.
newThis = [];
end


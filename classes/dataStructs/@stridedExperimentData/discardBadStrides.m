function newThis = discardBadStrides(this)
%DISCARDBADSTRIDES Removes bad strides (deprecated).
%
%   newThis = discardBadStrides(this) would remove strides marked as
% bad
%
% Inputs:
%   this - stridedExperimentData object
%
% Outputs:
%   newThis - stridedExperimentData object with bad strides removed
%
% NOTE: No need, the discarding happens when this structure is created from
%       a processed experiment
%
% Toolbox Dependencies: None
%
% See also STRIDEDATA/ISBAD.

newThis = [];
end


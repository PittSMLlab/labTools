function [int, dur] = getSingleStanceR(this)
%getSingleStanceR  Extracts right single stance phase
%
%   [int, dur] = getSingleStanceR(this) extracts the phase from
%   left toe off to left heel strike (right single stance)
%
%   Inputs:
%       this - strideData object
%
%   Outputs:
%       int - strideData object containing single stance phase
%       dur - duration of phase in seconds
%
%   See also: getSingleStanceL, getSwingL, getIntervalBtwEvents

int = getIntervalBtwEvents(this, 'LTO', 'LHS');
dur = int.gaitEvents.timeRange;
end


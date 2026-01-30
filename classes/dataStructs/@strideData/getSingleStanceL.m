function [int, dur] = getSingleStanceL(this)
%getSingleStanceL  Extracts left single stance phase
%
%   [int, dur] = getSingleStanceL(this) extracts the phase from
%   right toe off to right heel strike (left single stance)
%
%   Inputs:
%       this - strideData object
%
%   Outputs:
%       int - strideData object containing single stance phase
%       dur - duration of phase in seconds
%
%   See also: getSingleStanceR, getSwingR, getIntervalBtwEvents

int = getIntervalBtwEvents(this, 'RTO', 'RHS');
dur = int.gaitEvents.timeRange;
end


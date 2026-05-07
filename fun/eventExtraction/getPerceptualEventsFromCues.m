function [LHSstartCue, LHSstopCue, RHSstartCue, RHSstopCue] = ...
    getPerceptualEventsFromCues(datlog, infoLHSevent, infoRHSevent)
%GETPERCEPTUALEVENTSFROMCUES Map auditory cue times to nearest gait events.
%
%   Extracts perceptual trial start/stop cue times from the datalog and
% finds the nearest left and right heel-strike event times to each cue.
% Assumes the datalog has already been synchronized with Nexus data.
%
% Inputs:
%   datlog        - struct, datalog with fields audioCues.start, .stop,
%                   and dataLogTimeOffsetBest
%   infoLHSevent  - M×1 double, times of left heel-strike events (s)
%   infoRHSevent  - K×1 double, times of right heel-strike events (s)
%
% Outputs:
%   LHSstartCue - M×1 double, LHS event times at perceptual trial start
%   LHSstopCue  - M×1 double, LHS event times at perceptual trial stop
%   RHSstartCue - K×1 double, RHS event times at perceptual trial start
%   RHSstopCue  - K×1 double, RHS event times at perceptual trial stop
%
% Toolbox Dependencies: None
%
% See also GETEVENTS.

% grab auditory cue times from the datalog, offset by synchronization
startCue = datlog.audioCues.start + datlog.dataLogTimeOffsetBest;
stopCue  = datlog.audioCues.stop  + datlog.dataLogTimeOffsetBest;

%% Match cue times to nearest gait events
LHSstartCue = zeros(length(infoLHSevent), 1);
RHSstartCue = zeros(length(infoRHSevent), 1);
LHSstopCue  = zeros(length(infoLHSevent), 1);
RHSstopCue  = zeros(length(infoRHSevent), 1);

for ii = 1:length(startCue)
    [~, LidxI] = min(abs(infoLHSevent - startCue(ii)));
    [~, LidxF] = min(abs(infoLHSevent - stopCue(ii)));
    LHSstartCue(LidxI) = infoLHSevent(LidxI);
    LHSstopCue(LidxF)  = infoLHSevent(LidxF);

    [~, RidxI] = min(abs(infoRHSevent - startCue(ii)));
    [~, RidxF] = min(abs(infoRHSevent - stopCue(ii)));
    RHSstartCue(RidxI) = infoRHSevent(RidxI);
    RHSstopCue(RidxF)  = infoRHSevent(RidxF);
end

end

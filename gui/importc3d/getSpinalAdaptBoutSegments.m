function segments = getSpinalAdaptBoutSegments(datlog)
%GETSPINALADAPTBOUTSEGMENTS Find bout ramp and steady-state time windows.
%
%   Parses the audio-cue rows that the ExperimentalGUI SpinalAdapt
% controller (NirsHreflexArduinoOpenLoopWithAudio) logs to
% datlog.audioCues into one ramp and one steady-state (SS) time window
% per walking bout. Rows are named '<Profile>_<Event><NN>' (e.g.,
% 'AdaptSplitFastR_Split03'); only three row types set boundaries:
%   - ramp start: '<P>_AccRamp##' (tied) or '<P>_DccRamp2Split##'
%     (split), logged with the "walk" cue while the belts are still
%     stopped. Bout 1 of a trial that starts walking begins instead at
%     the pre-loop '<P>_Mid01' row, since its ramp row is logged
%     mid-ramp.
%   - SS start: the '<P>_Mid##' or '<P>_Split##' row after the ramp row.
%   - bout end: '<P>_Rest##_CountForward', logged with the "silently
%     count forward" cue after the belts have stopped.
% The spoken "stop" cue has no row of its own. The '<P>_Rest##' fNIRS
% marker and the trial-end row serve only as fallback ends for an
% interrupted bout. Standing intervals between segments (pre-walk,
% inter-bout rests, trailing rest) belong to no segment.
%
% Inputs:
%   datlog - struct; one trial's data log as saved by the controller
%
% Outputs:
%   segments - table with one row per segment, in chronological order:
%                bout      - bout number from the cue names
%                segment   - "Ramp" or "SS"
%                startTime - s, datlog relative time (the time base of
%                            audioCues.startInRelativeTime)
%                endTime   - s, same time base; NaN = end of trial
%                startCue  - cue row that opens the segment
%                endCue    - cue row that closes it ("" if none)
%                endSource - "SS" or "CountForward" for a complete
%                            bout; "Rest", "TrialEnd", or "EndOfTrial"
%                            mark a fallback end (interrupted bout)
%              Zero rows if the datlog has no audioCues or no ramp cue
%              (e.g., calibration, 6MWT, and tied-fastest trials).
%
% Toolbox Dependencies:
%   None
%
% See also SPLITSPINALADAPTBOUTCONDS, SYNCDATALOG,
%   SEPCONDSINEXPBYAUDIOCUE.

arguments
    datlog (1,1) struct
end

%% Define the Cue Grammar
% <Profile>_<Event><2-digit bout>[_CountForward]; the lazy event match
% parses 'DccRamp2Split01' as event 'DccRamp2Split', bout 01
cuePattern      = ['^(?<prefix>[A-Za-z0-9]+)_(?<event>[A-Za-z0-9]+?)' ...
    '(?<bout>\d{2})(?<suffix>_CountForward)?$'];
trialEndPattern = '_Trial_?End$';   % '_Trial_End' before 2026-09-18
rampEvents      = {'AccRamp', 'DccRamp2Split'};
steadyEvents    = {'Mid', 'Split'};
restEvent       = 'Rest';

segments = makeSegmentTable(zeros(0, 1), strings(0, 1), zeros(0, 1), ...
    zeros(0, 1), strings(0, 1), strings(0, 1), strings(0, 1));
if ~isfield(datlog, 'audioCues') || ...
        ~isfield(datlog.audioCues, 'audio_instruction_message')
    return
end

%% Classify Every Cue Row
cueNames = cellstr(datlog.audioCues.audio_instruction_message(:));
numCues  = numel(cueNames);
tokens   = regexp(cueNames, cuePattern, 'names', 'once');

eventName      = repmat({''}, numCues, 1);
boutNum        = nan(numCues, 1);
isCountForward = false(numCues, 1);
for cue = find(~cellfun(@isempty, tokens))'
    eventName{cue}      = tokens{cue}.event;
    boutNum(cue)        = str2double(tokens{cue}.bout);
    isCountForward(cue) = ~isempty(tokens{cue}.suffix);
end
isRamp   = ismember(eventName, rampEvents) & ~isCountForward;
isSteady = ismember(eventName, steadyEvents) & ~isCountForward;
isRest   = strcmp(eventName, restEvent) & ~isCountForward;
if ~any(isRamp)
    return
end

if ~isfield(datlog.audioCues, 'startInRelativeTime') || ...
        numel(datlog.audioCues.startInRelativeTime) ~= numCues
    error('getSpinalAdaptBoutSegments:cueTimes', ...
        ['audioCues.startInRelativeTime is missing or does not ' ...
        'match the %d cue names.'], numCues);
end
cueTimes    = datlog.audioCues.startInRelativeTime(:);
cueIdx      = (1:numCues)';
trialEndCue = find(~cellfun(@isempty, ...
    regexp(cueNames, trialEndPattern, 'once')), 1, 'last');

rampCues = find(isRamp);
numBouts = numel(rampCues);
if numel(unique(boutNum(rampCues))) < numBouts
    error('getSpinalAdaptBoutSegments:malformedBout', ...
        'More than one ramp cue carries the same bout number.');
end

%% Build One Ramp and One SS Segment per Bout
numRows = 2 * numBouts;
[bout, startTime, endTime]             = deal(nan(numRows, 1));
[segment, startCue, endCue, endSource] = deal(strings(numRows, 1));
numSegments = 0;
for bb = 1:numBouts
    rampCue = rampCues(bb);
    isLast  = bb == numBouts;
    if isLast
        nextRampCue = numCues + 1;
    else
        nextRampCue = rampCues(bb + 1);
    end
    inBout = boutNum == boutNum(rampCue) & cueIdx < nextRampCue;

    % a pre-loop Mid row of the same bout opens bout 1 of a trial that
    % starts walking; otherwise the ramp cue opens the bout
    openCue = find(inBout & isSteady & cueIdx < rampCue, 1, 'first');
    if isempty(openCue)
        openCue = rampCue;
    end
    ssCue       = find(inBout & isSteady & cueIdx > rampCue, 1, 'first');
    lastWalkCue = max([rampCue; ssCue]);

    [closeCue, closeSource] = findBoutEnd(inBout & ...
        cueIdx > lastWalkCue, isCountForward, isRest, trialEndCue, ...
        lastWalkCue, isLast);
    if ~isLast && (isempty(ssCue) || isempty(closeCue))
        error('getSpinalAdaptBoutSegments:malformedBout', ...
            ['Bout %02d lacks a steady-state or end cue but later ' ...
            'bouts follow it.'], boutNum(rampCue));
    end
    if isempty(closeCue)
        boutEndTime = NaN;
        boutEndCue  = "";
    else
        boutEndTime = cueTimes(closeCue);
        boutEndCue  = string(cueNames{closeCue});
    end

    numSegments = numSegments + 1;
    bout(numSegments)      = boutNum(rampCue);
    segment(numSegments)   = "Ramp";
    startTime(numSegments) = cueTimes(openCue);
    startCue(numSegments)  = cueNames{openCue};
    if isempty(ssCue)       % interrupted during the ramp
        endTime(numSegments)   = boutEndTime;
        endCue(numSegments)    = boutEndCue;
        endSource(numSegments) = closeSource;
        continue
    end
    endTime(numSegments)   = cueTimes(ssCue);
    endCue(numSegments)    = cueNames{ssCue};
    endSource(numSegments) = "SS";

    numSegments = numSegments + 1;
    bout(numSegments)      = boutNum(rampCue);
    segment(numSegments)   = "SS";
    startTime(numSegments) = cueTimes(ssCue);
    startCue(numSegments)  = cueNames{ssCue};
    endTime(numSegments)   = boutEndTime;
    endCue(numSegments)    = boutEndCue;
    endSource(numSegments) = closeSource;
end

keep     = 1:numSegments;
segments = makeSegmentTable(bout(keep), segment(keep), ...
    startTime(keep), endTime(keep), startCue(keep), endCue(keep), ...
    endSource(keep));

%% Check That Segments Are Chronological
bounds = reshape([segments.startTime segments.endTime]', [], 1);
if any(isnan(bounds(1:end - 1))) || ...
        any(diff(bounds(~isnan(bounds))) < 0)
    error('getSpinalAdaptBoutSegments:malformedBout', ...
        'Bout cue times are out of chronological order.');
end

end

% ============================================================
% ==================== Local Functions =======================
% ============================================================

function [closeCue, closeSource] = findBoutEnd(isCandidate, ...
    isCountForward, isRest, trialEndCue, lastWalkCue, isLast)
%FINDBOUTEND Pick the cue row that closes a bout.
%
%   Prefers the bout's '_CountForward' row, then its 'Rest' row, then
% (last bout only) the trial-end row; returns empty when none exists,
% meaning the bout runs to the end of the trial.
%
% Inputs:
%   isCandidate    - logical column; rows of this bout after its last
%                    walking cue and before the next bout's ramp cue
%   isCountForward - logical column; '_CountForward' rows
%   isRest         - logical column; 'Rest' rows
%   trialEndCue    - row index of the trial-end cue, or []
%   lastWalkCue    - row index of the bout's last ramp/SS cue
%   isLast         - logical; true for the trial's last bout
%
% Outputs:
%   closeCue    - row index of the closing cue, or [] if none
%   closeSource - "CountForward", "Rest", "TrialEnd", or "EndOfTrial"
%
% Toolbox Dependencies:
%   None
%
% See also GETSPINALADAPTBOUTSEGMENTS.

closeSource = "CountForward";
closeCue    = find(isCandidate & isCountForward, 1, 'first');
if isempty(closeCue)
    closeSource = "Rest";
    closeCue    = find(isCandidate & isRest, 1, 'first');
end
if isempty(closeCue) && isLast && ~isempty(trialEndCue) && ...
        trialEndCue > lastWalkCue
    closeSource = "TrialEnd";
    closeCue    = trialEndCue;
end
if isempty(closeCue)
    closeSource = "EndOfTrial";
end

end

function segments = makeSegmentTable(bout, segment, startTime, ...
    endTime, startCue, endCue, endSource)
%MAKESEGMENTTABLE Assemble the bout-segment output table.
%
%   Keeps the output variable names and order in one place for both the
% empty and the populated result.
%
% Inputs:
%   bout      - column; bout numbers
%   segment   - string column; "Ramp" or "SS"
%   startTime - column; segment start times (s)
%   endTime   - column; segment end times (s), NaN = end of trial
%   startCue  - string column; opening cue rows
%   endCue    - string column; closing cue rows
%   endSource - string column; how each segment was closed
%
% Outputs:
%   segments - table with the variables above
%
% Toolbox Dependencies:
%   None
%
% See also GETSPINALADAPTBOUTSEGMENTS.

segments = table(bout, segment, startTime, endTime, startCue, ...
    endCue, endSource);

end

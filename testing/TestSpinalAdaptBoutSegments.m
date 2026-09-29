%TestSpinalAdaptBoutSegments Unit tests for the SpinalAdapt cue parser.
%
%   Exercises GETSPINALADAPTBOUTSEGMENTS against small synthetic data
% logs covering every cue grammar the SpinalAdapt controller has
% produced: the 2026-09-18 grammar ('<P>_Trial_End', as logged for
% SAYA90), the current one ('<P>_TrialEnd', per-leg split prefixes),
% a trial resumed mid-way, bouts interrupted by the STOP button,
% trials without bout cues, the unprefixed Pilot Study 2 grammar, and
% malformed logs that must raise an error.
%
% It also checks SPLITSPINALADAPTBOUTCONDS's input guards on minimal
% mock sessions (an already split session is refused; a session with no
% bout cues is returned unchanged).
%
%   Scope: this script validates the PARSER and the guards only. It is
% not a substitute for VALIDATESPINALADAPTBOUTSPLITONSERVER.M, which
% runs the parser and the stride partition against real SAYA90/SAYA91
% data.
%
%   Usage:
%     run('testing/TestSpinalAdaptBoutSegments.m')
%
% Toolbox Dependencies:
%   None
%
% See also GETSPINALADAPTBOUTSEGMENTS, SPLITSPINALADAPTBOUTCONDS,
%   VALIDATESPINALADAPTBOUTSPLITONSERVER.

%% 2026-09-18 Grammar (Tied): Two Complete Bouts
dl = makeDatlog({'PreAdaptFast_Mid01', 'PreAdaptFast_AccRamp01', ...
    'PreAdaptFast_Mid01', 'PreAdaptFast_Rest01', ...
    'PreAdaptFast_Rest01_CountForward', 'PreAdaptFast_AccRamp02', ...
    'PreAdaptFast_Mid02', 'PreAdaptFast_Rest02', ...
    'PreAdaptFast_Rest02_CountForward', 'PreAdaptFast_Trial_End'}, ...
    [0 0.6 2.8 13.8 14.5 26.8 31.4 42.6 43.3 56]);
segs = getSpinalAdaptBoutSegments(dl);
assert(height(segs) == 4, 'Two bouts should give four segments.');
assert(isequal(segs.segment', ["Ramp" "SS" "Ramp" "SS"]), ...
    'Segments should alternate Ramp, SS.');
assert(isequal(segs.bout', [1 1 2 2]), 'Bout numbers are wrong.');
assert(isequal(segs.startTime', [0 2.8 26.8 31.4]), ...
    ['Bout 1 must open at the pre-loop Mid row; later bouts at ' ...
    'their ramp cue; SS at the Mid row after the ramp.']);
assert(isequal(segs.endTime', [2.8 14.5 31.4 43.3]), ...
    'SS segments must close at the CountForward row, not Rest.');
assert(all(ismember(segs.endSource, ["SS" "CountForward"])), ...
    'Complete bouts should not use a fallback end.');

%% Current Grammar (Split): Per-Leg Prefix and '_TrialEnd'
dl = makeDatlog({'AdaptSplitFastR_Mid01', ...
    'AdaptSplitFastR_DccRamp2Split01', 'AdaptSplitFastR_Split01', ...
    'AdaptSplitFastR_Rest01', 'AdaptSplitFastR_Rest01_CountForward', ...
    'AdaptSplitFastR_DccRamp2Split02', 'AdaptSplitFastR_Split02', ...
    'AdaptSplitFastR_Rest02', 'AdaptSplitFastR_Rest02_CountForward', ...
    'AdaptSplitFastR_TrialEnd'}, [0 0.9 3.7 16.8 17.5 30.5 36.1 ...
    50.8 51.5 64]);
segs = getSpinalAdaptBoutSegments(dl);
assert(height(segs) == 4, 'Split bouts should give four segments.');
assert(segs.startCue(1) == "AdaptSplitFastR_Mid01" && ...
    segs.endCue(1) == "AdaptSplitFastR_Split01", ...
    '''DccRamp2Split'' must parse as a ramp event despite its digit.');
assert(isequal(segs.endTime([2 4])', [17.5 51.5]), ...
    'Split SS segments must close at CountForward.');

%% Resumed Trial: No Pre-Loop Marker, Bouts Start at 04
dl = makeDatlog({'PostAdaptSlow_Rest03', ...
    'PostAdaptSlow_Rest03_CountForward', 'PostAdaptSlow_AccRamp04', ...
    'PostAdaptSlow_Mid04', 'PostAdaptSlow_Rest04', ...
    'PostAdaptSlow_Rest04_CountForward', 'PostAdaptSlow_TrialEnd'}, ...
    [0 0.7 12.5 17.0 28.1 28.8 41]);
segs = getSpinalAdaptBoutSegments(dl);
assert(height(segs) == 2 && all(segs.bout == 4), ...
    'A resumed trial should give bout 04 only (Rest03 is standing).');
assert(segs.startTime(1) == 12.5, ...
    'Without a pre-loop marker the ramp cue opens the bout.');

%% STOP During the Last Steady State: Fallback Ends
names = {'X_Mid01', 'X_AccRamp01', 'X_Mid01', 'X_Rest01', ...
    'X_Rest01_CountForward', 'X_AccRamp02', 'X_Mid02', 'X_TrialEnd'};
segs = getSpinalAdaptBoutSegments(makeDatlog(names, ...
    [0 0.6 2.8 13.8 14.5 26.8 31.4 35.0]));
assert(segs.endSource(end) == "TrialEnd" && segs.endTime(end) == 35, ...
    'An interrupted last bout should close at the trial-end row.');
segs = getSpinalAdaptBoutSegments(makeDatlog(names(1:end - 1), ...
    [0 0.6 2.8 13.8 14.5 26.8 31.4]));
assert(segs.endSource(end) == "EndOfTrial" && isnan(segs.endTime(end)), ...
    'With no trial-end row the last bout should run to trial end.');

%% STOP During the Last Ramp: Ramp Without SS
segs = getSpinalAdaptBoutSegments(makeDatlog(names(1:6), ...
    [0 0.6 2.8 13.8 14.5 26.8]));
assert(height(segs) == 3 && segs.segment(end) == "Ramp" && ...
    isnan(segs.endTime(end)), ...
    'A last bout stopped mid-ramp should give only a Ramp segment.');

%% Missing CountForward in an Earlier Bout: Rest Fallback
segs = getSpinalAdaptBoutSegments(makeDatlog({'X_Mid01', ...
    'X_AccRamp01', 'X_Mid01', 'X_Rest01', 'X_AccRamp02', 'X_Mid02', ...
    'X_Rest02', 'X_Rest02_CountForward'}, ...
    [0 0.6 2.8 13.8 26.8 31.4 42.6 43.3]));
assert(segs.endSource(2) == "Rest" && segs.endTime(2) == 13.8, ...
    'A bout without CountForward should close at its Rest row.');

%% Trials Without Bout Cues Give Zero Rows
assert(height(getSpinalAdaptBoutSegments(struct('forces', 1))) == 0, ...
    'A datlog without audioCues (tied fastest) should give no rows.');
segs = getSpinalAdaptBoutSegments(makeDatlog({ ...
    'CalibrationSlow_Mid01', 'CalibrationSlow_TrialEnd'}, [0 300]));
assert(height(segs) == 0, 'A calibration trial should give no rows.');
segs = getSpinalAdaptBoutSegments(makeDatlog({'Rest1', 'AccRamp1', ...
    'Mid1', 'DccRamp2Split1', 'Split1', ...
    'TMStopAudioCountDown_Train1', 'Rest2', 'Trial_End'}, 1:8));
assert(height(segs) == 0, ...
    'The unprefixed Pilot Study 2 grammar must not be parsed.');

%% Malformed Logs Raise Errors
assertThrows(@() getSpinalAdaptBoutSegments(makeDatlog({'X_Mid01', ...
    'X_AccRamp01', 'X_Rest01_CountForward', 'X_AccRamp02', ...
    'X_Mid02', 'X_Rest02_CountForward'}, 1:6)), ...
    'getSpinalAdaptBoutSegments:malformedBout', ...
    'An earlier bout without an SS cue');
assertThrows(@() getSpinalAdaptBoutSegments(makeDatlog({'X_Mid01', ...
    'X_AccRamp01', 'X_Mid01', 'X_Rest01_CountForward'}, [0 1 5 3])), ...
    'getSpinalAdaptBoutSegments:malformedBout', 'Out-of-order cue times');
assertThrows(@() getSpinalAdaptBoutSegments(makeDatlog({ ...
    'X_AccRamp01', 'X_Mid01', 'X_AccRamp01', 'X_Mid01'}, 1:4)), ...
    'getSpinalAdaptBoutSegments:malformedBout', 'A repeated ramp bout');
dl = makeDatlog({'X_AccRamp01', 'X_Mid01'}, 1:2);
dl.audioCues.startInRelativeTime = 1;
assertThrows(@() getSpinalAdaptBoutSegments(dl), ...
    'getSpinalAdaptBoutSegments:cueTimes', 'Mismatched cue times');

%% splitSpinalAdaptBoutConds: Refuse an Already Split Session
splitSession = makeMockExpData('C:\Vicon\Trial09_SplitIdx009');
assertThrows(@() splitSpinalAdaptBoutConds(splitSession), ...
    'splitSpinalAdaptBoutConds:alreadySplit', ...
    'Splitting an already split session');

%% splitSpinalAdaptBoutConds: No Bout Cues -> Unchanged
plainSession = makeMockExpData('C:\Vicon\Trial04');
warnState = warning('off', 'splitSpinalAdaptBoutConds:noBoutTrials');
[sameSession, report] = splitSpinalAdaptBoutConds(plainSession);
warning(warnState);
assert(isequal(sameSession.metaData.conditionName, ...
    plainSession.metaData.conditionName) && ...
    isempty(report.segments), ...
    'A session without bout cues should be returned unchanged.');

fprintf('All TestSpinalAdaptBoutSegments checks passed.\n');

%% Local Functions

function datlog = makeDatlog(names, times)
%MAKEDATLOG Build a minimal synthetic datlog with audio-cue rows.
%
%   Mirrors the fields the controller saves: a column cell of cue names
% and their times in seconds relative to the first frame.
%
% Inputs:
%   names - cell array of cue-row names
%   times - vector of cue times (s), one per name
%
% Outputs:
%   datlog - struct with audioCues.audio_instruction_message and
%            audioCues.startInRelativeTime
%
% Toolbox Dependencies:
%   None
%
% See also GETSPINALADAPTBOUTSEGMENTS.

datlog = struct();
datlog.audioCues.audio_instruction_message = names(:);
datlog.audioCues.startInRelativeTime       = times(:);

end

function expData = makeMockExpData(rawDataFilename)
%MAKEMOCKEXPDATA Build a one-trial session with no data and no datlog.
%
%   Enough structure for SPLITSPINALADAPTBOUTCONDS's input guards, which
% run before any trial data or datlog is read.
%
% Inputs:
%   rawDataFilename - char; the single trial's rawDataFilename
%
% Outputs:
%   expData - experimentData with one empty processedTrialData
%
% Toolbox Dependencies:
%   None
%
% See also SPLITSPINALADAPTBOUTCONDS.

warnState = warning('off', 'all');  % silence metadata default notices
trialMeta = trialMetaData('Mock', 'mock trial', '', 'L', 1, ...
    rawDataFilename, 'TM');
meta = experimentMetaData('SpinalAdapt', labDate.default, 'tester', ...
    '', {'Mock'}, {'mock condition'}, {1}, 1, 0, 0, {[]});
sub  = subjectData([], 'male', 'R', 'R', 170, 70, 30, 'Mock01', 'R');
warning(warnState);
expData = experimentData(meta, sub, {processedTrialData(trialMeta)});

end

function assertThrows(fcn, expectedID, caseName)
%ASSERTTHROWS Assert that a call raises an error with a given identifier.
%
% Inputs:
%   fcn        - function handle to call
%   expectedID - expected error identifier
%   caseName   - short description used in the failure message
%
% Outputs:
%   None
%
% Toolbox Dependencies:
%   None
%
% See also GETSPINALADAPTBOUTSEGMENTS.

actualID = '';
try
    fcn();
catch err
    actualID = err.identifier;
end
assert(strcmp(actualID, expectedID), ...
    '%s should raise %s (got ''%s'').', caseName, expectedID, actualID);

end

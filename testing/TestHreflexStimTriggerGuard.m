%TestHreflexStimTriggerGuard Unit tests for the H-reflex trigger guard.
%
%   Exercises HREFLEX.HASSTIMTRIGGER in isolation (flat trigger, real
% pulse train, single- vs double-underscore channel names, empty/
% zero-column/all-NaN data) and COMPUTEHREFLEXPARAMETERS end-to-end
% against small synthetic labTimeSeries fixtures built in-memory, to
% confirm: (1) a session with the H-reflex Nexus configuration enabled
% but no stimulation (flat trigger channels, no TAP EMG collected)
% returns NaN parameters instead of erroring, and (2) a session with a
% real trigger pulse train still reaches the artifact detector (the
% guard does not silently swallow genuine H-reflex sessions).
%
%   Scope: this script validates the guard's decision logic and the two
% computeHreflexParameters code paths against synthetic data. It is not
% a substitute for running VALIDATEHREFLEXGUARDONSERVER.M against a real
% accidental (non-stimulation) session and a known-good H-reflex
% session -- that is the only check that confirms the feature works
% end-to-end on real data.
%
%   Usage:
%     run('testing/TestHreflexStimTriggerGuard.m')
%
% Toolbox Dependencies:
%   None
%
% See also HREFLEX.HASSTIMTRIGGER, COMPUTEHREFLEXPARAMETERS,
%   VALIDATEHREFLEXGUARDONSERVER.

%% Shared Fixture Constants
fs        = 100;                     % Hz, synthetic sampling frequency
dur       = 4;                       % s, synthetic trial duration
nSamples  = fs * dur;
t0        = 0;
Ts        = 1 / fs;
rLabel    = 'Stimulator_Trigger_Sync_Right_Stimulator';
lLabelDbl = 'Stimulator_Trigger_Sync_Left__Stimulator';  % double underscore
lLabelSgl = 'Stimulator_Trigger_Sync_Left_Stimulator';   % single underscore

%% hasStimTrigger: Flat (Near-Zero) Trigger -> False
flatData = 0.01 * ones(nSamples, 2);   % ~10 mV, far below 2.5 V threshold
flatTrig = labTimeSeries(flatData, t0, Ts, {rLabel, lLabelDbl});
assert(~Hreflex.hasStimTrigger(flatTrig), ...
    'A flat near-zero trigger channel should not be detected as active.');

%% hasStimTrigger: Real Pulse Train -> True
pulseData = zeros(nSamples, 2);
pulseData(10:15, :) = 5;               % 5 V pulse on both channels
realTrig = labTimeSeries(pulseData, t0, Ts, {rLabel, lLabelDbl});
assert(Hreflex.hasStimTrigger(realTrig), ...
    'A real 5 V pulse train should be detected as active.');

%% hasStimTrigger: Single- and Double-Underscore Labels -> Both True
pulseDataOneCh = zeros(nSamples, 1);
pulseDataOneCh(10:15) = 5;
trigDbl = labTimeSeries(pulseDataOneCh, t0, Ts, {lLabelDbl});
trigSgl = labTimeSeries(pulseDataOneCh, t0, Ts, {lLabelSgl});
assert(Hreflex.hasStimTrigger(trigDbl), ...
    'Double-underscore channel name should not affect detection.');
assert(Hreflex.hasStimTrigger(trigSgl), ...
    'Single-underscore channel name should not affect detection.');

%% hasStimTrigger: Empty Input -> False, No Error
assert(~Hreflex.hasStimTrigger([]), ...
    'Empty HreflexPin input should return false without erroring.');

%% hasStimTrigger: Zero-Column Data -> False, No Error
zeroColTrig = labTimeSeries(zeros(nSamples, 0), t0, Ts, {});
assert(~Hreflex.hasStimTrigger(zeroColTrig), ...
    'Zero-column trigger data should return false without erroring.');

%% hasStimTrigger: All-NaN Data -> False, No Error
nanTrig = labTimeSeries(nan(nSamples, 2), t0, Ts, {rLabel, lLabelDbl});
assert(~Hreflex.hasStimTrigger(nanTrig), ...
    'All-NaN trigger data should return false without erroring.');

%% Build Shared strideEvents Fixture
timeSHS  = [0.5; 1.5; 2.5];
timeFTO  = [0.7; 1.7; 2.7];
timeFHS  = [1.0; 2.0; 3.0];
timeSTO  = [1.2; 2.2; 3.2];
timeSHS2 = [1.5; 2.5; 3.5];
timeFTO2 = [1.7; 2.7; 3.7];
timeFHS2 = [2.0; 3.0; 3.9];
timeSTO2 = [2.2; 3.2; 3.95];
strideEvents = struct('tSHS', timeSHS, 'tFTO', timeFTO, ...
    'tFHS', timeFHS, 'tSTO', timeSTO, 'tSHS2', timeSHS2, ...
    'tFTO2', timeFTO2, 'tFHS2', timeFHS2, 'tSTO2', timeSTO2);
nExpectedParams = 66;   % see computeHreflexParameters aux label block
                         % (the function's own H1 comment says 68; the
                         % literal 'aux' cell array has 66 rows)

%% computeHreflexParameters: Flat Trigger, No TAP EMG -> NaN Parameters
% The H-reflex Nexus configuration was left enabled (trigger channels
% recorded) for a session that never stimulated (flat trigger) and
% never collected the TAP muscles. The guard must short-circuit before
% the RTAP/LTAP read, so this must not error even with EMGData = [].
out = computeHreflexParameters(strideEvents, flatTrig, [], 'R');
assert(numel(out.labels) == nExpectedParams, ...
    'Flat-trigger call should still return all H-reflex parameter labels.');
% isSingleStanceSlow/Fast are initialized as logical false (not NaN);
% every other parameter should be NaN with no stimulation.
isSingleStanceMask = contains(out.labels, 'isSingleStance');
assert(all(isnan(out.Data(:, ~isSingleStanceMask)), 'all'), ...
    'Flat-trigger call with no stimulation should return all-NaN data.');
assert(all(out.Data(:, isSingleStanceMask) == 0, 'all'), ...
    'isSingleStance parameters should default to false, not NaN.');

%% computeHreflexParameters: Real Trigger, No TAP EMG -> Still Errors
% A real pulse train must NOT be swallowed by the guard: with the TAP
% channels absent, this should still reach
% Hreflex.extractStimArtifactIndsFromTrigger and throw its "data
% missing" error, proving the guard passes real stimulation through.
noTAPEMG = labTimeSeries(zeros(nSamples, 1), t0, Ts, {'RSOL'});
threwExpectedError = false;
try
    computeHreflexParameters(strideEvents, realTrig, noTAPEMG, 'R');
catch ME
    threwExpectedError = contains(ME.message, ...
        'data missing that is crucial');
end
assert(threwExpectedError, ...
    ['A real trigger pulse train with missing TAP EMG should still ' ...
    'reach the artifact detector and throw its data-missing error ' ...
    '(i.e., the guard must not silently skip genuine stimulation).']);

disp('TestHreflexStimTriggerGuard: all assertions passed.');

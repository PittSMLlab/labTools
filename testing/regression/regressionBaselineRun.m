function regressionBaselineRun(refExpDataFile, eventClass, baselineDir)
%REGRESSIONBASELINERUN Save a flush-stage regression baseline.
%
%   Loads the reference experimentData (read-only; nothing is written
% next to it), runs flushAndRecomputeParameters(eventClass) and
% makeDataObj, and saves the result plus per-trial warnings to
% <baselineDir>/baselineParams.mat. Run ONLY on the reference tree.
% Then runs two sanity checks: baseline vs itself, and a second flush
% vs the baseline (determinism); both must report 0 Changed.
%
% Inputs:
%   refExpDataFile - char, path to the reference *expData.mat
%   eventClass     - char, '' | 'kin' | 'force' (must be identical in
%                    every later compare run)
%   baselineDir    - char, output folder (see README.md)
%
% Outputs:
%   none (writes baselineParams.mat; exits nonzero on a failed check
%   when run under matlab -batch)
%
% Toolbox Dependencies: None
%
% See also REGRESSIONCOMPARERUN, COMPAREADAPTATIONDATA,
%   FLUSHANDRECOMPUTEPARAMETERS.

arguments
    refExpDataFile (1,:) char
    eventClass     (1,:) char
    baselineDir    (1,:) char
end

[adaptData, trialWarnings] = regressionRunPipeline(refExpDataFile, ...
    eventClass);
meta = struct('refExpDataFile', refExpDataFile, 'eventClass', ...
    eventClass, 'created', char(datetime('now')), 'matlab', version);
save(fullfile(baselineDir, 'baselineParams.mat'), 'adaptData', ...
    'trialWarnings', 'meta', '-v7.3');
fprintf('BASELINE saved: %s\n', fullfile(baselineDir, ...
    'baselineParams.mat'));

%% Sanity checks
selfReport = compareAdaptationData(adaptData, adaptData, ...
    RefName='baseline', NewName='baseline', Verbose=false);
[againData, againWarnings] = regressionRunPipeline(refExpDataFile, ...
    eventClass);
detReport = compareAdaptationData(adaptData, againData, ...
    RefName='baseline', NewName='second flush');
warnSame = isequal(trialWarnings, againWarnings);
fprintf(['SANITY self-compare nChanged = %d | determinism nChanged ' ...
    '= %d | per-trial warnings identical = %d\n'], ...
    selfReport.nChanged, detReport.nChanged, warnSame);
if selfReport.nChanged > 0 || detReport.nChanged > 0 || ~warnSame
    error('regressionBaselineRun:sanityFailed', 'Sanity check failed.');
end
end

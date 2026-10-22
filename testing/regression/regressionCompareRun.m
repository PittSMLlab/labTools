function regressionCompareRun(refExpDataFile, eventClass, baselineDir)
%REGRESSIONCOMPARERUN Compare the current tree against the saved baseline.
%
%   Re-runs the same in-memory pipeline as REGRESSIONBASELINERUN on the
% current code and compares with <baselineDir>/baselineParams.mat
% (RefName 'baseline', NewName 'current'). Also diffs per-trial
% warning text. Errors (nonzero exit under matlab -batch) when any
% parameter changed or any trial's warnings differ.
%
% Inputs:
%   refExpDataFile - char, same file used for the baseline
%   eventClass     - char, same eventClass used for the baseline
%   baselineDir    - char, folder holding baselineParams.mat
%
% Outputs:
%   none (prints the compareAdaptationData report)
%
% Toolbox Dependencies: None
%
% See also REGRESSIONBASELINERUN, COMPAREADAPTATIONDATA.

arguments
    refExpDataFile (1,:) char
    eventClass     (1,:) char
    baselineDir    (1,:) char
end

base = load(fullfile(baselineDir, 'baselineParams.mat'));
if ~strcmp(base.meta.eventClass, eventClass)
    error('regressionCompareRun:eventClass', ...
        'Baseline used eventClass ''%s''.', base.meta.eventClass);
end
[newData, newWarnings] = regressionRunPipeline(refExpDataFile, eventClass);
report = compareAdaptationData(fullfile(baselineDir, ...
    'baselineParams.mat'), newData, RefName='baseline', ...
    NewName='current');

%% Per-trial warnings
nWarnDiff = 0;
for ii = 1:size(base.trialWarnings, 1)
    if ~isequal(base.trialWarnings(ii, :), newWarnings(ii, :))
        nWarnDiff = nWarnDiff + 1;
        fprintf('WARNINGS differ in trial %d\n', base.trialWarnings{ii, 1});
    end
end
fprintf('RESULT nChanged = %d | trials with different warnings = %d\n', ...
    report.nChanged, nWarnDiff);
if report.nChanged > 0 || nWarnDiff > 0
    error('regressionCompareRun:changed', 'Regression detected.');
end
regressionStrictCheck(report, 'flush');
end

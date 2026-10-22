function [adaptData, trialWarnings] = regressionRunPipeline( ...
    refExpDataFile, eventClass)
%REGRESSIONRUNPIPELINE Flush-recompute a reference session in memory.
%
%   Loads the first experimentData variable in refExpDataFile, runs
% flushAndRecomputeParameters(eventClass) one trial at a time under
% EVALC so warnings can be attributed per trial, then builds the
% adaptationData with makeDataObj() (no filename, so nothing is saved).
% recomputeEvents is deliberately not called: it currently errors.
%
% Inputs:
%   refExpDataFile - char, path to the reference *expData.mat
%   eventClass     - char, '' | 'kin' | 'force'
%
% Outputs:
%   adaptData     - adaptationData object
%   trialWarnings - cell array {trialIdx, warningText} per trial
%
% Toolbox Dependencies: None
%
% See also REGRESSIONBASELINERUN, REGRESSIONCOMPARERUN, CALCPARAMETERS.

arguments
    refExpDataFile (1,:) char
    eventClass     (1,:) char
end

info    = whos('-file', refExpDataFile);
isExp   = strcmp({info.class}, 'experimentData');
if ~any(isExp)
    error('regressionRunPipeline:noExpData', ...
        'No experimentData variable in %s (found: %s).', ...
        refExpDataFile, strjoin({info.class}, ', '));
end
varName = info(find(isExp, 1)).name;
loaded  = load(refExpDataFile, varName);
expData = loaded.(varName);

% NOTE: same per-trial call as flushAndRecomputeParameters with default
% initEventSide, so warnings can be captured trial by trial. Backtraces
% are off: their stack lines carry repo line numbers (which style edits
% shift) and the caller's name, so they would differ between runs.
trials        = cell2mat(expData.metaData.trialsInCondition);
trialWarnings = cell(numel(trials), 2);
btState       = warning('off', 'backtrace');
restoreBt     = onCleanup(@() warning(btState));
for ii = 1:numel(trials)
    tr  = trials(ii);
    txt = evalc(['expData.data{tr}.adaptParams = calcParameters(' ...
        'expData.data{tr}, expData.subData, eventClass, '''');']);
    trialWarnings(ii, :) = {tr, strtrim(txt)};
end
adaptData = expData.makeDataObj();
fprintf('PIPELINE done: %d trials, %d strides, %d parameters\n', ...
    numel(trials), size(adaptData.data.Data, 1), ...
    size(adaptData.data.Data, 2));
end

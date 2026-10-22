function regressionProcessRun(mode, rawFile, eventClass, baselineDir)
%REGRESSIONPROCESSRUN Process-stage regression: RAW -> process -> params.
%
%   Loads the raw experimentData in rawFile (read-only), processes every
% trial in memory exactly as experimentData.process does (labData.process:
% processEMG, calcLimbAngles, getEvents, belt speeds, torques/COP,
% calcParameters), then builds the adaptationData with makeDataObj() (no
% filename, so nothing is saved). Each raw trial is cleared once
% processed to bound peak memory. Per trial it records the printed
% output (warnings without backtraces) and the gait-event matrix, so
% event changes are caught even when the parameters happen to match.
%   'baseline' saves processParams.mat in baselineDir and repeats the run
% once to prove it is deterministic; 'compare' checks parameters with
% COMPAREADAPTATIONDATA (0 Changed) and events/warnings with ISEQUALN.
% Errors (nonzero exit under matlab -batch) on any difference.
%
% Inputs:
%   mode        - 'baseline' | 'compare'
%   rawFile     - char, path to the session *RAW.mat (experimentData)
%   eventClass  - char, '' | 'kin' | 'force' (same in every run)
%   baselineDir - char, folder for processParams.mat
%
% Outputs:
%   none
%
% Toolbox Dependencies: None
%
% See also REGRESSIONBASELINERUN, REGRESSIONCOMPARERUN,
%   REGRESSIONEVENTSCHECK.

arguments
    mode        (1,:) char {mustBeMember(mode, {'baseline', 'compare'})}
    rawFile     (1,:) char
    eventClass  (1,:) char
    baselineDir (1,:) char
end

file = fullfile(baselineDir, 'processParams.mat');
[adaptData, trialWarnings, trialEvents] = runProcess(rawFile, ...
    eventClass);
switch mode
    case 'baseline'
        meta = struct('rawFile', rawFile, 'eventClass', eventClass, ...
            'created', char(datetime('now')), 'matlab', version);
        save(file, 'adaptData', 'trialWarnings', 'trialEvents', ...
            'meta', '-v7.3');
        fprintf('PROCESS baseline saved: %s\n', file);
        [againData, againWarnings, againEvents] = runProcess( ...
            rawFile, eventClass);
        report = compareAdaptationData(adaptData, againData, ...
            RefName='baseline', NewName='second process');
        refWarnings = againWarnings;
        refEvents   = againEvents;
        label       = 'determinism';
    case 'compare'
        ref = load(file);
        if ~strcmp(ref.meta.eventClass, eventClass)
            error('regressionProcessRun:eventClass', ...
                'Baseline used eventClass ''%s''.', ref.meta.eventClass);
        end
        report = compareAdaptationData(file, adaptData, ...
            RefName='baseline', NewName='current');
        refWarnings = ref.trialWarnings;
        refEvents   = ref.trialEvents;
        label = 'compare';
end
warnSame   = isequal(refWarnings, trialWarnings);
eventsSame = isequaln(refEvents, trialEvents);
fprintf(['PROCESS %s nChanged = %d | per-trial warnings identical ' ...
    '= %d | per-trial events identical = %d\n'], label, ...
    report.nChanged, warnSame, eventsSame);
if report.nChanged > 0 || ~warnSame || ~eventsSame
    error('regressionProcessRun:changed', 'Process-stage %s failed.', ...
        label);
end
regressionStrictCheck(report, ['process ' label]);
end

function [adaptData, trialWarnings, trialEvents] = runProcess(rawFile, ...
    eventClass)
%RUNPROCESS Process all trials of the raw session in memory.
info    = whos('-file', rawFile);
isExp   = strcmp({info.class}, 'experimentData');
if ~any(isExp)
    error('regressionProcessRun:noExpData', ...
        'No experimentData variable in %s.', rawFile);
end
varName = info(find(isExp, 1)).name;
loaded  = load(rawFile, varName);
rawExp  = loaded.(varName);
clear loaded

% NOTE: backtraces off - their stack lines carry repo line numbers
% (which style edits shift), so they would differ between runs.
nTrials       = numel(rawExp.data);
procData      = cell(1, nTrials);
trialWarnings = cell(nTrials, 1);
trialEvents   = cell(nTrials, 1);
btState       = warning('off', 'backtrace');
restoreBt     = onCleanup(@() warning(btState));
for tr = 1:nTrials
    if isempty(rawExp.data{tr})
        continue
    end
    txt = evalc(['procData{tr} = rawExp.data{tr}.process(' ...
        'rawExp.subData, eventClass);']);
    rawExp.data{tr}    = [];
    trialWarnings{tr}  = strtrim(txt);
    events             = procData{tr}.gaitEvents;
    trialEvents{tr}    = struct('data', events.Data, ...
        'labels', {events.labels}, 'time', events.Time);
end
expData   = experimentData(rawExp.metaData, rawExp.subData, procData);
adaptData = expData.makeDataObj();
fprintf('PROCESS done: %d trials, %d strides, %d parameters\n', ...
    nnz(~cellfun(@isempty, procData)), size(adaptData.data.Data, 1), ...
    size(adaptData.data.Data, 2));
end

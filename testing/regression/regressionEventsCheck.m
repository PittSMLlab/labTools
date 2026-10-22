function regressionEventsCheck(mode, baselineDir, sessionFile)
%REGRESSIONEVENTSCHECK Gait-event regression check (fixture and session).
%
%   Substitute for expData.recomputeEvents(), which currently errors.
% Runs GETEVENTS on the single processedTrialData stored in
% example/data/LI16_Trial9_expData.mat and, if sessionFile is given, on
% every trial of that session's experimentData, with the same arguments
% as labData.process (stored angleData, metaData.perceptualTasks).
% 'baseline' saves the event matrices; 'compare' checks them with
% ISEQUALN and errors on any difference. A trial whose GETEVENTS call
% errors stores the error identifier and message instead, so a changed
% failure also counts as a difference.
%
% Inputs:
%   mode        - 'baseline' | 'compare'
%   baselineDir - char, folder for fixtureEvents.mat/sessionEvents.mat
%   sessionFile - char, optional path to a session *.mat holding an
%                 experimentData (default '': fixture only)
%
% Outputs:
%   none
%
% Toolbox Dependencies: None
%
% See also GETEVENTS, REGRESSIONCOMPARERUN.

arguments
    mode        (1,:) char {mustBeMember(mode, {'baseline', 'compare'})}
    baselineDir (1,:) char
    sessionFile (1,:) char = ''
end

%% Fixture trial
repo   = fileparts(fileparts(fileparts(mfilename('fullpath'))));
loaded = load(fullfile(repo, 'example', 'data', ...
    'LI16_Trial9_expData.mat'));
names  = fieldnames(loaded);
events = runEvents(loaded.(names{1}));
checkOrSave(mode, fullfile(baselineDir, 'fixtureEvents.mat'), ...
    events, 'fixture');

%% Session trials
if isempty(sessionFile)
    return
end
info    = whos('-file', sessionFile);
isExp   = strcmp({info.class}, 'experimentData');
varName = info(find(isExp, 1)).name;
loaded  = load(sessionFile, varName);
expData = loaded.(varName);
trials  = cell2mat(expData.metaData.trialsInCondition);
events  = cell(numel(trials), 1);
for ii = 1:numel(trials)
    events{ii} = runEvents(expData.data{trials(ii)});
end
events = struct('trials', trials, 'events', {events});
checkOrSave(mode, fullfile(baselineDir, 'sessionEvents.mat'), ...
    events, sprintf('session (%d trials)', numel(trials)));
end

function out = runEvents(trial)
%RUNEVENTS Call GETEVENTS as labData.process does; capture any error.
perc = trial.metaData.perceptualTasks;
if isempty(perc)
    perc = 0;
end
try
    ev  = getEvents(trial, trial.angleData, perc);
    out = struct('data', ev.Data, 'labels', {ev.labels}, ...
        'time', ev.Time, 'err', '');
catch err
    out = struct('data', [], 'labels', {{}}, 'time', [], ...
        'err', [err.identifier ': ' err.message]);
end
end

function checkOrSave(mode, file, events, what)
%CHECKORSAVE Save events (baseline) or compare them with ISEQUALN.
switch mode
    case 'baseline'
        save(file, 'events', '-v7.3');
        fprintf('EVENTS baseline saved (%s): %s\n', what, file);
    case 'compare'
        ref  = load(file);
        same = isequaln(ref.events, events);
        fprintf('EVENTS %s identical to baseline: %d\n', what, same);
        if ~same
            error('regressionEventsCheck:changed', ...
                'Events changed (%s).', what);
        end
end
end

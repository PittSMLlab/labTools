%ValidateHreflexGuardOnServer Validates the H-reflex stim-trigger guard
% on real sessions copied locally from the server.
%
%   Runs EXPERIMENTDATA.FLUSHANDRECOMPUTEPARAMETERS (the same
% recomputation path used by post-processing, which re-enters
% CALCPARAMETERS -> COMPUTEHREFLEXPARAMETERS) against local copies of:
%
%   1. 'AccidentalNonStim' -- a session where the H-reflex Nexus
%      configuration (Stimulator_Trigger_Sync_* channels) was left
%      enabled for a study that never stimulated. Before this fix, this
%      aborted recomputation entirely; this checks it now completes
%      without error and without needing the +Hreflex helper commented
%      out.
%   2. 'KnownGoodHreflex' -- a session with real H-reflex stimulation.
%      This checks that its H-reflex (and all other) parameters are
%      BYTE-IDENTICAL to a pre-fix baseline, not merely that recomputation
%      does not error -- that is the regression that matters, since the
%      guard must never affect a genuine stimulation session.
%
%   IMPORTANT -- SAFETY:
%     This script must be pointed at LOCAL COPIES of the session data,
%   never at the original server location. It only ever loads and
%   recomputes in memory; it never calls SAVE. You are still
%   responsible for ensuring 'sessionDirs' below points at a local
%   copy, not 'Z:\Nathan\C3\Data' or any other server path. Each
%   session folder must contain that session's '*expData.mat' (required
%   -- flushAndRecomputeParameters needs real per-trial processed data,
%   not just the saved 'params.mat').
%
%   Usage:
%     1. Edit 'sessionDirs' below to point at your local copies.
%     2. Run: run('testing/ValidateHreflexGuardOnServer.m')
%        This always checks 'AccidentalNonStim' completes without error.
%     3. For the 'KnownGoodHreflex' byte-identical regression check:
%        a. With this fix applied (current working tree), run this
%           script once with 'baselineMatFile' left as '' -- it saves a
%           baseline snapshot and prints the path.
%        b. git stash the fix (fun/+Hreflex/hasStimTrigger.m and the
%           edits to computeHreflexParameters.m/calcParameters.m),
%           restart MATLAB to clear the function cache, and rerun this
%           script with 'baselineMatFile' set to the path printed in
%           step (a) -- this compares the pre-fix run against that
%           baseline and reports PASS/FAIL.
%        c. git stash pop to restore the fix.
%
% Toolbox Dependencies:
%   None
%
% See also HREFLEX.HASSTIMTRIGGER, COMPUTEHREFLEXPARAMETERS,
%   TESTHREFLEXSTIMTRIGGERGUARD, EXPERIMENTDATA.FLUSHANDRECOMPUTEPARAMETERS.

%% Configuration -- Edit These Local (Not Server) Paths
% Each entry: sessionID -> local folder containing that session's
% '*expData.mat'. Leave a folder as '' to skip that session. NEVER
% point these at Z:\Nathan\C3\Data or any other server path -- copy the
% files locally first.
sessionDirs = struct( ...
    'AccidentalNonStim', '', ...  % H-reflex config enabled, no stim
    'KnownGoodHreflex',  '');     % real H-reflex stimulation session

% Optional: path to a baseline .mat snapshot of KnownGoodHreflex's
% recomputed parameters (see Usage step 3 above). Leave '' to save a
% new baseline from the current (fixed) code instead of comparing.
baselineMatFile = '';

%% Validate Configuration Before Touching Any Files
serverPathToken = 'Z:\Nathan\C3\Data'; % guard token; see safety note
sessionIDs = fieldnames(sessionDirs);
for ii = 1:length(sessionIDs)
    sessionDir = sessionDirs.(sessionIDs{ii});
    if isempty(sessionDir)
        continue
    end
    if contains(sessionDir, serverPathToken)
        error('ValidateHreflexGuardOnServer:serverPath', ...
            ['sessionDirs.%s points at the server path (%s). ' ...
            'Copy the session files to a local folder first and ' ...
            'point this script at the copy.'], sessionIDs{ii}, ...
            serverPathToken);
    end
end

%% Check 1: Accidental Non-Stimulation Session Recomputes Without Error
sessionDir = sessionDirs.AccidentalNonStim;
if isempty(sessionDir)
    fprintf(['AccidentalNonStim: (skipped -- no local path ' ...
        'configured)\n']);
else
    checkAccidentalSession(sessionDir);
end

%% Check 2: Known-Good H-Reflex Session Parameters Are Unaffected
sessionDir = sessionDirs.KnownGoodHreflex;
if isempty(sessionDir)
    fprintf(['KnownGoodHreflex: (skipped -- no local path ' ...
        'configured)\n']);
else
    checkKnownGoodSession(sessionDir, baselineMatFile);
end

% ============================================================
% ==================== Local Functions ======================
% ============================================================

function checkAccidentalSession(sessionDir)
%checkAccidentalSession  Confirms recomputation no longer aborts.
%
%   Inputs:
%     sessionDir - char, LOCAL folder containing the session's saved
%                  '*expData.mat'
%
%   See also: ValidateHreflexGuardOnServer

expFiles = dir(fullfile(sessionDir, '*expData.mat'));
if isempty(expFiles)
    warning('ValidateHreflexGuardOnServer:noData', ...
        ['AccidentalNonStim: no ''*expData.mat'' found in %s. ' ...
        'Skipping.'], sessionDir);
    return
end

try
    loaded  = load(fullfile(sessionDir, expFiles(1).name));
    expData = loaded.expData.flushAndRecomputeParameters();
    fprintf(['AccidentalNonStim: PASS -- ' ...
        'flushAndRecomputeParameters completed without error.\n']);
catch recomputeErr
    warning('ValidateHreflexGuardOnServer:accidentalSessionFailed', ...
        ['AccidentalNonStim: flushAndRecomputeParameters still ' ...
        'errors (%s). The guard did not resolve this session.'], ...
        recomputeErr.message);
    return
end

adaptData = expData.makeDataObj([]);
hreflexMask = contains(adaptData.data.labels, ...
    {'Hwave', 'Mwave', 'HreflexNoise', 'H2M', 'HreflexBEMG', ...
    'NoStimBEMG', 'stimTimeFrom', 'isSingleStance'});
if any(hreflexMask)
    allNaN = all(isnan(adaptData.data.Data(:, hreflexMask)), 'all');
    fprintf(['AccidentalNonStim: H-reflex parameters present and ' ...
        '%s all NaN, as expected for a non-stimulation session.\n'], ...
        ternary(allNaN, 'are', 'are NOT'));
    if ~allNaN
        warning('ValidateHreflexGuardOnServer:unexpectedHreflexData', ...
            ['AccidentalNonStim: some H-reflex parameters are not ' ...
            'NaN. Review manually -- this session was expected to ' ...
            'have no stimulation.']);
    end
end

end

function checkKnownGoodSession(sessionDir, baselineMatFile)
%checkKnownGoodSession  Compares recomputed parameters to a baseline.
%
%   Inputs:
%     sessionDir      - char, LOCAL folder containing the session's
%                        saved '*expData.mat'
%     baselineMatFile - char, path to a previously saved baseline
%                        snapshot, or '' to save a new one
%
%   See also: ValidateHreflexGuardOnServer

expFiles = dir(fullfile(sessionDir, '*expData.mat'));
if isempty(expFiles)
    warning('ValidateHreflexGuardOnServer:noData', ...
        ['KnownGoodHreflex: no ''*expData.mat'' found in %s. ' ...
        'Skipping.'], sessionDir);
    return
end

try
    loaded    = load(fullfile(sessionDir, expFiles(1).name));
    expData   = loaded.expData.flushAndRecomputeParameters();
    adaptData = expData.makeDataObj([]);
catch recomputeErr
    warning('ValidateHreflexGuardOnServer:knownGoodSessionFailed', ...
        ['KnownGoodHreflex: flushAndRecomputeParameters errored ' ...
        '(%s). Investigate before trusting the guard on genuine ' ...
        'H-reflex sessions.'], recomputeErr.message);
    return
end

paramData   = adaptData.data.Data;
paramLabels = adaptData.data.labels;

if isempty(baselineMatFile)
    outFile = fullfile(sessionDir, ...
        sprintf('hreflexGuardBaseline_%s.mat', ...
        datestr(now, 'yyyymmdd_HHMMSS'))); %#ok<TNOW1,DATST>
    save(outFile, 'paramData', 'paramLabels');
    fprintf(['KnownGoodHreflex: saved baseline snapshot to %s. ' ...
        'Rerun with baselineMatFile set to this path after ' ...
        'stashing the fix (see Usage step 3).\n'], outFile);
    return
end

baseline = load(baselineMatFile, 'paramData', 'paramLabels');
if ~isequal(sort(paramLabels(:)), sort(baseline.paramLabels(:)))
    warning('ValidateHreflexGuardOnServer:labelMismatch', ...
        ['KnownGoodHreflex: parameter label sets differ between ' ...
        'this run and the baseline. Cannot compare directly -- ' ...
        'review manually.']);
    return
end

% Reorder this run's columns to match the baseline label order before
% comparing, in case label order is not guaranteed to be stable.
[~, reorderIdx] = ismember(baseline.paramLabels, paramLabels);
paramDataAligned = paramData(:, reorderIdx);

if isequaln(paramDataAligned, baseline.paramData)
    fprintf(['KnownGoodHreflex: PASS -- recomputed parameters are ' ...
        'byte-identical to the baseline.\n']);
else
    warning('ValidateHreflexGuardOnServer:regressionDetected', ...
        ['KnownGoodHreflex: recomputed parameters DIFFER from the ' ...
        'baseline. The guard may be affecting a genuine H-reflex ' ...
        'session -- investigate before trusting it.']);
end

end

function out = ternary(cond, trueVal, falseVal)
%ternary  Small inline conditional helper for a single fprintf call.
%
%   See also: ValidateHreflexGuardOnServer

if cond
    out = trueVal;
else
    out = falseVal;
end

end

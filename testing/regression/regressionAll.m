function regressionAll(baseDir, sessionID, eventClass)
%REGRESSIONALL Run every regression compare in one go.
%
%   Runs, against the baselines in baseDir, the flush compare
% (REGRESSIONCOMPARERUN), the event check (REGRESSIONEVENTSCHECK, fixture
% and session) and the process-stage compare (REGRESSIONPROCESSRUN) on
% the session copy in <baseDir>/session. Every check runs even if an
% earlier one fails; errors at the end if any failed (nonzero exit under
% matlab -batch). Prints which calcParameters ran, so the log shows
% which tree was tested. A two-trial session takes ~10 min.
%
% Inputs:
%   baseDir    - char, folder holding baselineParams.mat,
%                processParams.mat, fixtureEvents.mat, sessionEvents.mat
%                and session/<sessionID>.mat, session/<sessionID>RAW.mat
%   sessionID  - char, session ID (file name stem), e.g. 'C3S36_S1'
%   eventClass - char, '' | 'kin' | 'force' (same as the baseline)
%
% Outputs:
%   none (prints one GATE line per check and a GATE SUMMARY line)
%
% Toolbox Dependencies: None
%
% See also REGRESSIONCOMPARERUN, REGRESSIONEVENTSCHECK,
%   REGRESSIONPROCESSRUN.

arguments
    baseDir    (1,:) char
    sessionID  (1,:) char
    eventClass (1,:) char
end

fprintf('TREE calcParameters: %s\n', which('calcParameters'));
expFile = fullfile(baseDir, 'session', [sessionID '.mat']);
rawFile = fullfile(baseDir, 'session', [sessionID 'RAW.mat']);
checks  = { ...
    'flush',   @() regressionCompareRun(expFile, eventClass, baseDir); ...
    'events',  @() regressionEventsCheck('compare', baseDir, expFile); ...
    'process', @() regressionProcessRun('compare', rawFile, ...
    eventClass, baseDir)};
failed = {};
for ii = 1:size(checks, 1)
    t0 = tic;
    try
        checks{ii, 2}();
        fprintf('GATE %-8s PASS (%.0f s)\n', checks{ii, 1}, toc(t0));
    catch err
        failed{end + 1} = checks{ii, 1}; %#ok<AGROW>
        fprintf('GATE %-8s FAIL (%.0f s): %s\n', checks{ii, 1}, ...
            toc(t0), err.message);
    end
end
if isempty(failed)
    fprintf('GATE SUMMARY: all %d checks passed\n', size(checks, 1));
else
    fprintf('GATE SUMMARY: FAILED %s\n', strjoin(failed, ', '));
    error('regressionAll:failed', 'Regression gate failed.');
end
end

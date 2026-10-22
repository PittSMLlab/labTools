function regressionLineCoverage(outFile, baseDir, sessionID, eventClass)
%REGRESSIONLINECOVERAGE Executed line numbers of the regression checks.
%
%   Runs the flush compare, the event check and the process-stage
% compare (as REGRESSIONALL) under the MATLAB profiler and writes, per
% executed repo file, the sorted executed line numbers to a text file
% (one line per file: path TAB comma-separated line numbers). Intersect
% it with the files a change touches to find code the checks never run.
% A failing check is reported but does not stop the run.
%
% Inputs:
%   outFile    - char, text file to write
%   baseDir    - char, folder with the baselines (see REGRESSIONALL)
%   sessionID  - char, session ID (file name stem)
%   eventClass - char, '' | 'kin' | 'force' (same as the baseline)
%
% Outputs:
%   none
%
% Toolbox Dependencies: None
%
% See also REGRESSIONALL.

arguments
    outFile    (1,:) char
    baseDir    (1,:) char
    sessionID  (1,:) char
    eventClass (1,:) char
end

warning('off', 'backtrace');
expFile = fullfile(baseDir, 'session', [sessionID '.mat']);
rawFile = fullfile(baseDir, 'session', [sessionID 'RAW.mat']);

%% Profile the three checks
profile('clear');
profile('on');
checks = {'flush', 'events', 'process'};
for ii = 1:numel(checks)
    try
        switch checks{ii}
            case 'flush'
                regressionCompareRun(expFile, eventClass, baseDir);
            case 'events'
                regressionEventsCheck('compare', baseDir, expFile);
            case 'process'
                regressionProcessRun('compare', rawFile, eventClass, ...
                    baseDir);
        end
        fprintf('LINECOV %s ran\n', checks{ii});
    catch err
        fprintf('LINECOV %s FAILED: %s\n', checks{ii}, err.message);
    end
end
profile('off');
ft = profile('info').FunctionTable;

%% Executed lines per file
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
fid = fopen(outFile, 'w');
files = unique({ft.FileName});
for ii = 1:numel(files)
    if ~startsWith(files{ii}, repo)
        continue
    end
    rows = strcmp({ft.FileName}, files{ii});
    lines = [];
    for kk = find(rows)
        el = ft(kk).ExecutedLines;
        if ~isempty(el)
            lines = [lines; el(:, 1)]; %#ok<AGROW>
        end
    end
    lines = unique(lines)';
    fprintf(fid, '%s\t%s\n', files{ii}, strjoin(string(lines), ','));
end
fclose(fid);
fprintf('LINECOV done\n');
end

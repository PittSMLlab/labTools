function report = validateC3DReaders(fileList, tolerance)
%VALIDATEC3DREADERS Check that ezc3d output matches BTK output exactly.
%
%   Reads each C3D file with BTK and with the ezc3d path of
% GETC3DANALOGS / GETC3DMARKERS and compares everything loadTrials and
% other callers can see: field names and their order, every sample of
% every analog channel and marker, and every field of the info structs.
% Run it on a computer where BTK works (any lab Windows PC) with the
% ezc3d MATLAB binaries for that platform on the path.
%
%   Inputs:
%     fileList  - cell array of .c3d file paths (with extension)
%     tolerance - largest allowed absolute difference between samples
%                 (default 0, i.e. identical; BTK and ezc3d both compute
%                 in double, so differences should be exactly zero)
%
%   Outputs:
%     report - table with one row per file and check, the largest
%              absolute difference, and pass/fail
%
%   Toolbox Dependencies:
%     BTK and ezc3d (both must run on this computer)
%
%   See also GETC3DREADER, GETC3DANALOGS, GETC3DMARKERS.

arguments
    fileList  cell
    tolerance (1,1) double {mustBeNonnegative} = 0
end

%% Require Both Readers
if ~endsWith(which('btkReadAcquisition'), ['.' mexext()])
    error('validateC3DReaders:noBtk', ['BTK cannot run on this ' ...
        'computer; run the validation where BTK works.']);
end
originalPref = getpref('labTools', 'c3dReader', 'auto');
restorePref  = onCleanup(@() setpref('labTools', 'c3dReader', ...
    originalPref));

rows = {};
for ff = 1:numel(fileList)
    fileName = fileList{ff};

    %% Read With Each Reader
    setpref('labTools', 'c3dReader', 'btk');
    acqBtk = readC3DAcquisition(fileName);
    [anBtk, anInfoBtk] = getC3DAnalogs(acqBtk);
    [mkBtk, mkInfoBtk] = getC3DMarkers(acqBtk);
    closeC3DAcquisition(acqBtk);

    setpref('labTools', 'c3dReader', 'ezc3d');
    acqEz = readC3DAcquisition(fileName);
    [anEz, anInfoEz] = getC3DAnalogs(acqEz);
    [mkEz, mkInfoEz] = getC3DMarkers(acqEz);

    %% Compare Analogs
    rows = [rows; compareData(fileName, 'analog values', anBtk, anEz, ...
        tolerance)]; %#ok<AGROW>
    infoFields = fieldnames(anInfoBtk);
    rows = [rows; {fileName, 'analog info field order', NaN, ...
        isequal(infoFields, fieldnames(anInfoEz)), ''}]; %#ok<AGROW>
    for ii = 1:numel(infoFields)
        fld = infoFields{ii};
        same = isfield(anInfoEz, fld) && ...
            isequaln(anInfoBtk.(fld), anInfoEz.(fld));
        rows = [rows; {fileName, ['analog info.' fld], NaN, same, ...
            firstMismatch(anInfoBtk.(fld), anInfoEz, fld)}]; %#ok<AGROW>
    end

    %% Compare Markers
    rows = [rows; compareData(fileName, 'marker values', mkBtk, mkEz, ...
        tolerance)]; %#ok<AGROW>
    rows = [rows; {fileName, 'marker info', NaN, ...
        isequaln(mkInfoBtk, mkInfoEz), ''}]; %#ok<AGROW>
end

report = cell2table(rows, 'VariableNames', ...
    {'file', 'check', 'maxAbsDiff', 'pass', 'detail'});
nFail = sum(~report.pass);
if nFail == 0
    fprintf('All %d checks passed: ezc3d output matches BTK.\n', ...
        height(report));
else
    fprintf(2, '%d of %d checks FAILED; see report.detail.\n', nFail, ...
        height(report));
end

end

function rows = compareData(fileName, what, ref, test, tolerance)
%COMPAREDATA Compare two btk-style data structs field by field.
%
%   Inputs:
%     fileName  - file being checked (for the report)
%     what      - label for the report row
%     ref       - BTK struct
%     test      - ezc3d struct
%     tolerance - largest allowed absolute difference
%
%   Outputs:
%     rows - 2-by-5 cell of report rows (names, values)

refNames  = fieldnames(ref);
testNames = fieldnames(test);
namesOk   = isequal(refNames, testNames);
detail    = '';
if ~namesOk
    detail = sprintf('only BTK: %s | only ezc3d: %s', ...
        strjoin(setdiff(refNames, testNames, 'stable'), ', '), ...
        strjoin(setdiff(testNames, refNames, 'stable'), ', '));
end
rows = {fileName, [what ' (field names/order)'], NaN, namesOk, detail};

maxDiff = 0;
bad     = {};
for ii = 1:numel(refNames)
    nm = refNames{ii};
    if ~isfield(test, nm) || ~isequal(size(ref.(nm)), size(test.(nm)))
        bad{end+1} = [nm ' (size)']; %#ok<AGROW>
        continue
    end
    diffs = abs(ref.(nm) - test.(nm));
    diffs(isnan(ref.(nm)) & isnan(test.(nm))) = 0;
    maxDiff = max([maxDiff; diffs(:)], [], 'omitnan');
    if any(diffs(:) > tolerance | isnan(diffs(:)))
        bad{end+1} = nm; %#ok<AGROW>
    end
end
rows(2, :) = {fileName, what, maxDiff, isempty(bad), ...
    strjoin(bad(1:min(end, 10)), ', ')};
end

function detail = firstMismatch(refValue, testInfo, fld)
%FIRSTMISMATCH Describe the first differing channel of an info field.
%
%   Inputs:
%     refValue - BTK value of info.(fld)
%     testInfo - ezc3d info struct
%     fld      - info field name
%
%   Outputs:
%     detail - text naming the first mismatch, or ''

detail = '';
if ~isfield(testInfo, fld)
    detail = 'missing in ezc3d output';
    return
end
testValue = testInfo.(fld);
if ~isstruct(refValue) || ~isstruct(testValue)
    if ~isequaln(refValue, testValue)
        detail = sprintf('BTK %s vs ezc3d %s', mat2str(refValue), ...
            mat2str(testValue));
    end
    return
end
names = fieldnames(refValue);
for ii = 1:numel(names)
    nm = names{ii};
    if ~isfield(testValue, nm) || ...
            ~isequaln(refValue.(nm), testValue.(nm))
        refStr  = toText(refValue.(nm));
        testStr = '<missing>';
        if isfield(testValue, nm)
            testStr = toText(testValue.(nm));
        end
        detail = sprintf('%s: BTK %s vs ezc3d %s', nm, refStr, testStr);
        return
    end
end
end

function txt = toText(value)
%TOTEXT Short printable form of a scalar or string.
%
%   Inputs:
%     value - char vector or numeric scalar
%
%   Outputs:
%     txt - quoted text or number

if ischar(value)
    txt = ['''' value ''''];
else
    txt = mat2str(value);
end
end

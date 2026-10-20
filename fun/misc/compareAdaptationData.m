function report = compareAdaptationData(refInput, newInput, options)
%COMPAREADAPTATIONDATA Compare two adaptationData objects or files.
%
%   Loads two adaptationData objects and reports differences in computed
% stride-by-stride parameters. Comparisons are restricted to trials
% present in both objects and strides matched by initiation time, so an
% object with only a subset of trials does not generate spurious
% differences for the missing trials.
%
%   Parameters differing only by floating-point noise (below RelTol and
% AbsTol) are classified as roundoff-only and not counted as changes.
%
% Inputs:
%   refInput - char path to a *params.mat file, or an adaptationData
%              object, to use as the reference
%   newInput - char path to a *params.mat file, or an adaptationData
%              object, to compare against the reference
%
% Outputs:
%   report - struct with fields: refName, newName, refFile, newFile,
%            refTrials, newTrials, commonTrials, refOnlyTrials,
%            newOnlyTrials, refOnlyLabels, newOnlyLabels, commonLabels,
%            nStridesCompared, nUnmatchedRef, nUnmatchedNew, params
%            (struct array with fields label, maxAbsDiff, maxRelDiff,
%            nNanMismatches, isChanged), nChanged, nRoundoffOnly
%
% Toolbox Dependencies: None
%
% See also ADAPTATIONDATA, PARAMETERSERIES.

arguments
    refInput
    newInput
    options.RelTol  (1,1) double  = 1e-9
    options.AbsTol  (1,1) double  = 1e-12
    options.RefName (1,:) char    = 'reference'
    options.NewName (1,:) char    = 'new'
    options.Verbose (1,1) logical = true
end

%% Validate inputs
if ~ischar(refInput) && ~isa(refInput, 'adaptationData')
    error('compareAdaptationData:invalidInput', ...
        'refInput must be a char file path or adaptationData object.');
end
if ~ischar(newInput) && ~isa(newInput, 'adaptationData')
    error('compareAdaptationData:invalidInput', ...
        'newInput must be a char file path or adaptationData object.');
end

%% Load inputs
[refData, refFile] = loadAdaptData(refInput);
[newData, newFile]  = loadAdaptData(newInput);

%% Compare trial sets
refTrials = unique(refData.data.stridesTrial);
newTrials  = unique(newData.data.stridesTrial);
refTrials  = refTrials(~isnan(refTrials));
newTrials  = newTrials(~isnan(newTrials));
commonTrials  = intersect(refTrials, newTrials);
refOnlyTrials = setdiff(refTrials, newTrials);
newOnlyTrials  = setdiff(newTrials, refTrials);

%% Compare parameter labels
% Structural columns are used only for alignment; exclude from diffs
structuralLabels = {'initTime', 'finalTime', 'trial'};
refAllLabels   = refData.data.labels;
newAllLabels   = newData.data.labels;
refCompLabels  = setdiff(refAllLabels, structuralLabels, 'stable');
newCompLabels  = setdiff(newAllLabels, structuralLabels, 'stable');
commonLabels   = intersect(refCompLabels, newCompLabels, 'stable');
refOnlyLabels  = setdiff(refCompLabels, newCompLabels, 'stable');
newOnlyLabels  = setdiff(newCompLabels, refCompLabels, 'stable');

%% Pre-compute column indices for aligned comparisons
nCommon    = length(commonLabels);
refColIdx  = zeros(1, nCommon);
newColIdx  = zeros(1, nCommon);
for lbl = 1:nCommon
    refColIdx(lbl) = find( ...
        strcmp(refAllLabels, commonLabels{lbl}), 1);
    newColIdx(lbl) = find( ...
        strcmp(newAllLabels, commonLabels{lbl}), 1);
end
refInitCol = find(strcmp(refAllLabels, 'initTime'), 1);
newInitCol  = find(strcmp(newAllLabels, 'initTime'), 1);

%% Align strides per trial and accumulate differences
maxAbsDiffAcc   = zeros(1, nCommon);
maxRelDiffAcc   = zeros(1, nCommon);
nNanMismatchAcc = zeros(1, nCommon);
isChangedAcc    = false(1, nCommon);
nStridesCompared = 0;
nUnmatchedRef   = 0;
nUnmatchedNew   = 0;

% Absolute tolerance for stride initTime matching (s); well below
% any real stride-to-stride interval (typically 0.8–1.5 s)
initTimeTol = 0.01;

for tr = 1:length(commonTrials)
    t = commonTrials(tr);
    refIdxCell = refData.data.indsInTrial(t);
    newIdxCell  = newData.data.indsInTrial(t);
    refInds = refIdxCell{1};
    newInds  = newIdxCell{1};

    if isempty(refInds) || isempty(newInds)
        nUnmatchedRef = nUnmatchedRef + length(refInds);
        nUnmatchedNew  = nUnmatchedNew + length(newInds);
        continue
    end

    refTimes = refData.data.Data(refInds, refInitCol);
    newTimes  = newData.data.Data(newInds, newInitCol);

    % Match ref strides to new strides by initTime; DataScale=1 makes
    % ismembertol use an absolute (not relative) tolerance
    [tfRef, locRef] = ismembertol(refTimes, newTimes, ...
        initTimeTol, 'DataScale', 1);

    matchedNewIdx = locRef(tfRef);
    nUnmatchedRef = nUnmatchedRef + sum(~tfRef);
    nUnmatchedNew  = nUnmatchedNew ...
        + sum(~ismember(1:length(newTimes), matchedNewIdx));

    nMatched = sum(tfRef);
    if nMatched == 0
        continue
    end
    nStridesCompared = nStridesCompared + nMatched;

    refMatchedGlobal = refInds(tfRef);
    newMatchedGlobal  = newInds(matchedNewIdx);

    % Compare each common parameter across matched strides
    for lbl = 1:nCommon
        refVals = refData.data.Data( ...
            refMatchedGlobal, refColIdx(lbl));
        newVals  = newData.data.Data( ...
            newMatchedGlobal, newColIdx(lbl));

        oneNaN      = isnan(refVals) ~= isnan(newVals);
        bothNumeric = ~isnan(refVals) & ~isnan(newVals);

        nNanMismatchAcc(lbl) = nNanMismatchAcc(lbl) ...
            + sum(oneNaN);
        if any(oneNaN)
            isChangedAcc(lbl) = true;
        end

        if any(bothNumeric)
            rV    = refVals(bothNumeric);
            nV    = newVals(bothNumeric);
            diffs = abs(nV - rV);
            maxAbsDiffAcc(lbl) = max( ...
                maxAbsDiffAcc(lbl), max(diffs));
            relDiffs = diffs ./ (abs(rV) + options.AbsTol);
            maxRelDiffAcc(lbl) = max( ...
                maxRelDiffAcc(lbl), max(relDiffs));
            if any(diffs > options.AbsTol + options.RelTol * abs(rV))
                isChangedAcc(lbl) = true;
            end
        end
    end
end

%% Build params struct array and compute summary counts
if nCommon > 0
    paramResults(nCommon, 1).label          = '';
    paramResults(nCommon, 1).maxAbsDiff     = 0;
    paramResults(nCommon, 1).maxRelDiff     = 0;
    paramResults(nCommon, 1).nNanMismatches = 0;
    paramResults(nCommon, 1).isChanged      = false;
    for lbl = 1:nCommon
        paramResults(lbl).label          = commonLabels{lbl};
        paramResults(lbl).maxAbsDiff     = maxAbsDiffAcc(lbl);
        paramResults(lbl).maxRelDiff     = maxRelDiffAcc(lbl);
        paramResults(lbl).nNanMismatches = nNanMismatchAcc(lbl);
        paramResults(lbl).isChanged      = isChangedAcc(lbl);
    end
else
    paramResults = struct( ...
        'label', {}, 'maxAbsDiff', {}, 'maxRelDiff', {}, ...
        'nNanMismatches', {}, 'isChanged', {});
end

nChanged     = sum(isChangedAcc);
nRoundoffOnly = sum(maxAbsDiffAcc > 0 & ~isChangedAcc);

%% Assemble report struct
report.refName          = options.RefName;
report.newName          = options.NewName;
report.refFile          = refFile;
report.newFile          = newFile;
report.refTrials        = refTrials;
report.newTrials        = newTrials;
report.commonTrials     = commonTrials;
report.refOnlyTrials    = refOnlyTrials;
report.newOnlyTrials    = newOnlyTrials;
report.refOnlyLabels    = refOnlyLabels;
report.newOnlyLabels    = newOnlyLabels;
report.commonLabels     = commonLabels;
report.nStridesCompared = nStridesCompared;
report.nUnmatchedRef    = nUnmatchedRef;
report.nUnmatchedNew    = nUnmatchedNew;
report.params           = paramResults;
report.nChanged         = nChanged;
report.nRoundoffOnly    = nRoundoffOnly;

%% Print report
if options.Verbose
    printComparisonReport(report, options.RelTol, options.AbsTol);
end

end

% =========================================================================

function [adaptData, filePath] = loadAdaptData(input)
%LOADADAPTDATA Load adaptationData from file path or return object as-is.

arguments
    input
end

if ischar(input)
    filePath  = input;
    loaded    = load(input, 'adaptData');
    adaptData = loaded.adaptData;
else
    filePath  = '';
    adaptData = input;
end
end

% =========================================================================

function printComparisonReport(report, relTol, absTol)
%PRINTCOMPARISONREPORT Print the comparison report to the command window.

arguments
    report struct
    relTol (1,1) double
    absTol (1,1) double
end

useCprintf = exist('cprintf', 'file') == 2;

fprintf('\n=== ADAPTATIONDATA COMPARISON ===\n');
fprintf('Reference : %s', report.refName);
if ~isempty(report.refFile)
    fprintf(' (%s)', report.refFile);
end
fprintf('\nNew       : %s', report.newName);
if ~isempty(report.newFile)
    fprintf(' (%s)', report.newFile);
end
fprintf('\n\n');

%% Trials
fprintf('TRIALS\n');
fprintf('  Reference : [%s]\n', num2str(report.refTrials(:)', '%d '));
fprintf('  New       : [%s]\n', num2str(report.newTrials(:)', '%d '));
fprintf('  Common: %d  |  Ref-only: %d  |  New-only: %d\n', ...
    length(report.commonTrials), ...
    length(report.refOnlyTrials), ...
    length(report.newOnlyTrials));
if ~isempty(report.refOnlyTrials)
    fprintf('  *** Reference-only trials: [%s]\n', ...
        num2str(report.refOnlyTrials(:)', '%d '));
end
if ~isempty(report.newOnlyTrials)
    fprintf('  *** New-only trials: [%s]\n', ...
        num2str(report.newOnlyTrials(:)', '%d '));
end
fprintf('\n');

%% Parameter labels
fprintf('PARAMETER LABELS\n');
fprintf('  Common: %d  |  Ref-only: %d  |  New-only: %d\n', ...
    length(report.commonLabels), ...
    length(report.refOnlyLabels), ...
    length(report.newOnlyLabels));
if ~isempty(report.refOnlyLabels)
    fprintf('  Reference-only labels: %s\n', ...
        strjoin(report.refOnlyLabels, ', '));
end
if ~isempty(report.newOnlyLabels)
    fprintf('  New-only labels: %s\n', ...
        strjoin(report.newOnlyLabels, ', '));
end
fprintf('\n');

%% Stride alignment
fprintf('STRIDE ALIGNMENT\n');
fprintf('  Matched pairs   : %d\n', report.nStridesCompared);
fprintf('  Unmatched (ref) : %d  |  Unmatched (new): %d\n', ...
    report.nUnmatchedRef, report.nUnmatchedNew);
fprintf('\n');

%% Parameter differences
nTotal     = length(report.params);
nUnchanged = nTotal - report.nChanged - report.nRoundoffOnly;
fprintf('PARAMETER DIFFERENCES  (RelTol=%.0e, AbsTol=%.0e)\n', ...
    relTol, absTol);
fprintf('  Unchanged  : %d\n', nUnchanged);
fprintf('  Roundoff   : %d\n', report.nRoundoffOnly);

if report.nChanged > 0
    if useCprintf
        cprintf('Errors', '  Changed    : %d\n', report.nChanged);
    else
        fprintf('  Changed    : %d\n', report.nChanged);
    end
else
    fprintf('  Changed    : 0\n');
end

if report.nChanged > 0 || report.nRoundoffOnly > 0
    fprintf('  ---\n');
    for ii = 1:nTotal
        p = report.params(ii);
        if p.isChanged
            line = sprintf( ...
                '  %-28s relDiff=%8.2e  absDiff=%8.2e  NaN=%d\n', ...
                p.label, p.maxRelDiff, p.maxAbsDiff, ...
                p.nNanMismatches);
            if useCprintf
                cprintf('Errors', '%s', line);
            else
                fprintf('%s', line);
            end
        elseif p.maxAbsDiff > 0
            line = sprintf( ...
                '  %-28s relDiff=%8.2e  absDiff=%8.2e  (roundoff)\n', ...
                p.label, p.maxRelDiff, p.maxAbsDiff);
            if useCprintf
                cprintf('SystemCommands', '%s', line);
            else
                fprintf('%s', line);
            end
        end
    end
end
fprintf('\n');

%% Summary line
fprintf('SUMMARY: ');
if report.nChanged == 0
    summaryMsg = sprintf( ...
        '0 of %d common parameters changed beyond tolerance.\n', ...
        nTotal);
    if useCprintf
        cprintf('Comments', '%s', summaryMsg);
    else
        fprintf('%s', summaryMsg);
    end
else
    summaryMsg = sprintf( ...
        '%d of %d common parameters changed beyond tolerance.\n', ...
        report.nChanged, nTotal);
    if useCprintf
        cprintf('Errors', '%s', summaryMsg);
    else
        fprintf('%s', summaryMsg);
    end
end
fprintf('\n');
end

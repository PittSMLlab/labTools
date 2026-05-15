function report = compareExperimentData(refInput, newInput, options)
%COMPAREEXPERIMENTDATA Compare structure of two experimentData objects.
%
%   Compares structural properties — data type, field presence, data
% dimensions, and channel labels — of two experimentData objects or
% saved MAT files. Unlike COMPAREADAPTATIONDATA, no numerical values
% are compared; only the layout and composition of each trial's data
% fields are checked.
%
%   Useful for verifying that a code change did not add, remove, or
% reorder data channels in rawTrialData or processedTrialData.
%
%   Label comparisons are order-sensitive: a channel list with the same
% labels in a different order is flagged as a structural difference.
%
% Inputs:
%   refInput - char path to a *expData.mat or *RAW.mat file, or an
%              experimentData object, to use as the reference
%   newInput - char path to a *expData.mat or *RAW.mat file, or an
%              experimentData object, to compare against the reference
%
% Outputs:
%   report - struct with fields: refName, newName, refFile, newFile,
%            nRefTrials, nNewTrials, commonTrials, refOnlyTrials,
%            newOnlyTrials, trials (struct array per common trial with
%            fields trial, dataTypesMatch, refType, newType, fields,
%            nFieldsChanged), nTrialsChanged, nFieldDiffs
%
% Toolbox Dependencies: None
%
% See also COMPAREADAPTATIONDATA, EXPERIMENTDATA, LABDATA.

arguments
    refInput
    newInput
    options.RefName (1,:) char    = 'reference'
    options.NewName (1,:) char    = 'new'
    options.Verbose (1,1) logical = true
end

%% Validate inputs
if ~ischar(refInput) && ~isa(refInput, 'experimentData')
    error('compareExperimentData:invalidInput', ...
        ['refInput must be a char file path or ' ...
        'experimentData object.']);
end
if ~ischar(newInput) && ~isa(newInput, 'experimentData')
    error('compareExperimentData:invalidInput', ...
        ['newInput must be a char file path or ' ...
        'experimentData object.']);
end

%% Load inputs
[refData, refFile] = loadExpData(refInput);
[newData, newFile] = loadExpData(newInput);

%% Compare trial sets
refTrials     = cell2mat(refData.metaData.trialsInCondition);
newTrials     = cell2mat(newData.metaData.trialsInCondition);
commonTrials  = intersect(refTrials, newTrials);
refOnlyTrials = setdiff(refTrials, newTrials);
newOnlyTrials = setdiff(newTrials, refTrials);

%% Fields to compare
% Base fields present in all labData subclasses
baseFields = { ...
    'markerData', 'EMGData', 'GRFData', ...
    'beltSpeedSetData', 'beltSpeedReadData', ...
    'accData', 'EEGData', 'footSwitches', 'HreflexPin'};
% Additional fields present only in processedLabData
procFields = { ...
    'gaitEvents', 'procEMGData', 'angleData', ...
    'adaptParams', 'COPData', 'COMData', 'jointMomentsData'};

%% Compare per trial
nCommon        = length(commonTrials);
nTrialsChanged = 0;
nFieldDiffs    = 0;

if nCommon > 0
    trialResult(nCommon, 1).trial          = 0;
    trialResult(nCommon, 1).dataTypesMatch = true;
    trialResult(nCommon, 1).refType        = '';
    trialResult(nCommon, 1).newType        = '';
    trialResult(nCommon, 1).fields         = [];
    trialResult(nCommon, 1).nFieldsChanged = 0;
else
    trialResult = struct( ...
        'trial', {}, 'dataTypesMatch', {}, ...
        'refType', {}, 'newType', {}, ...
        'fields', {}, 'nFieldsChanged', {});
end

for ii = 1:nCommon
    tr     = commonTrials(ii);
    refObj = refData.data{tr};
    newObj = newData.data{tr};

    refType = class(refObj);
    newType = class(newObj);
    trialResult(ii).trial          = tr;
    trialResult(ii).refType        = refType;
    trialResult(ii).newType        = newType;
    trialResult(ii).dataTypesMatch = strcmp(refType, newType);

    % Include processedLabData fields if either object is processed
    isProc    = isa(refObj, 'processedLabData') || ...
                isa(newObj, 'processedLabData');
    allFields = baseFields;
    if isProc
        allFields = [baseFields, procFields];
    end
    nFields = length(allFields);

    trialChanged = ~trialResult(ii).dataTypesMatch;

    % Reset fieldResult for this trial (clears any prior-iteration data)
    clear fieldResult
    for jj = 1:nFields
        fn      = allFields{jj};
        refDesc = describeField(refObj, fn);
        newDesc = describeField(newObj, fn);

        inRef = refDesc.present;
        inNew = newDesc.present;

        if inRef && inNew
            sizeMatch   = isequal(refDesc.sz, newDesc.sz);
            labelsMatch = isequal(refDesc.labels, newDesc.labels);
            refOnlyLbl  = setdiff( ...
                refDesc.labels, newDesc.labels, 'stable');
            newOnlyLbl  = setdiff( ...
                newDesc.labels, refDesc.labels, 'stable');
        else
            sizeMatch   = true;
            labelsMatch = true;
            refOnlyLbl  = {};
            newOnlyLbl  = {};
        end

        changed = (inRef ~= inNew) || ~sizeMatch || ~labelsMatch;

        fieldResult(jj).name          = fn;
        fieldResult(jj).inRef         = inRef;
        fieldResult(jj).inNew         = inNew;
        fieldResult(jj).sizeMatch     = sizeMatch;
        fieldResult(jj).refSize       = refDesc.sz;
        fieldResult(jj).newSize       = newDesc.sz;
        fieldResult(jj).labelsMatch   = labelsMatch;
        fieldResult(jj).refOnlyLabels = refOnlyLbl;
        fieldResult(jj).newOnlyLabels = newOnlyLbl;
        fieldResult(jj).changed       = changed;

        if changed
            trialChanged = true;
            nFieldDiffs  = nFieldDiffs + 1;
        end
    end

    trialResult(ii).fields         = fieldResult;
    trialResult(ii).nFieldsChanged = sum([fieldResult.changed]);

    if trialChanged
        nTrialsChanged = nTrialsChanged + 1;
    end
end

%% Assemble report
report.refName        = options.RefName;
report.newName        = options.NewName;
report.refFile        = refFile;
report.newFile        = newFile;
report.nRefTrials     = length(refTrials);
report.nNewTrials     = length(newTrials);
report.commonTrials   = commonTrials;
report.refOnlyTrials  = refOnlyTrials;
report.newOnlyTrials  = newOnlyTrials;
report.trials         = trialResult;
report.nTrialsChanged = nTrialsChanged;
report.nFieldDiffs    = nFieldDiffs;

%% Print report
if options.Verbose
    printStructureReport(report);
end

end

% =========================================================================

function [expData, filePath] = loadExpData(input)
%LOADEXPDATA Load experimentData from file path or return object as-is.
%
%   Tries variable names 'expData' and 'rawExpData' first, then searches
% for the first variable of class experimentData in the file.

arguments
    input
end

if ischar(input)
    filePath = input;
    loaded   = load(input);
    if isfield(loaded, 'expData') && ...
            isa(loaded.expData, 'experimentData')
        expData = loaded.expData;
    elseif isfield(loaded, 'rawExpData') && ...
            isa(loaded.rawExpData, 'experimentData')
        expData = loaded.rawExpData;
    else
        flds    = fieldnames(loaded);
        expData = [];
        for ii = 1:length(flds)
            if isa(loaded.(flds{ii}), 'experimentData')
                expData = loaded.(flds{ii});
                break
            end
        end
        if isempty(expData)
            error('compareExperimentData:noExpData', ...
                'No experimentData variable found in: %s', input);
        end
    end
else
    filePath = '';
    expData  = input;
end
end

% =========================================================================

function desc = describeField(trialObj, fieldName)
%DESCRIBEFIELD Safely extract presence, size, and labels from a field.
%
%   Returns a struct with fields present (logical), sz (size of .Data
% or of the value itself), and labels (cell of strings). Uses try/catch
% to handle missing properties across labData subclasses.

arguments
    trialObj
    fieldName (1,:) char
end

desc.present = false;
desc.sz      = [];
desc.labels  = {};

try
    val = trialObj.(fieldName);
    if isempty(val)
        return
    end
    desc.present = true;
    try
        desc.sz = size(val.Data);
    catch
        desc.sz = size(val);
    end
    try
        desc.labels = val.labels;
    catch
        % Field object has no labels property — treated as unlabeled.
    end
catch
    % Property does not exist on this labData subclass.
end
end

% =========================================================================

function printStructureReport(report)
%PRINTSTRUCTUREREPORT Print formatted structure comparison.

arguments
    report struct
end

useCprintf = exist('cprintf', 'file') == 2;

fprintf('\n=== EXPERIMENTDATA STRUCTURE COMPARISON ===\n');
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
fprintf('  Reference : %d trials\n', report.nRefTrials);
fprintf('  New       : %d trials\n', report.nNewTrials);
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

%% Per-trial field structure
fprintf('FIELD STRUCTURE  (%d common trials)\n', ...
    length(report.commonTrials));

if report.nTrialsChanged == 0
    fprintf('  All trials: no structural differences.\n');
else
    for ii = 1:length(report.trials)
        tr = report.trials(ii);
        if tr.nFieldsChanged == 0 && tr.dataTypesMatch
            continue
        end
        fprintf('  Trial %d:\n', tr.trial);
        if ~tr.dataTypesMatch
            line = sprintf('    [data type]  ref=%s  new=%s\n', ...
                tr.refType, tr.newType);
            if useCprintf; cprintf('Errors', '%s', line);
            else;          fprintf('%s', line); end
        end
        for jj = 1:length(tr.fields)
            f = tr.fields(jj);
            if ~f.changed; continue; end
            if ~f.inRef
                line = sprintf( ...
                    '    %-22s  absent in reference\n', f.name);
            elseif ~f.inNew
                line = sprintf( ...
                    '    %-22s  absent in new\n', f.name);
            elseif ~f.sizeMatch
                line = sprintf( ...
                    '    %-22s  size: ref=%s  new=%s\n', ...
                    f.name, ...
                    mat2str(f.refSize), mat2str(f.newSize));
            else
                % Size matches but labels differ
                if isempty(f.refOnlyLabels) && ...
                        isempty(f.newOnlyLabels)
                    detail = '(same set, different order)';
                else
                    seg = '';
                    if ~isempty(f.refOnlyLabels)
                        seg = [seg '  ref-only: ' ...
                            strjoin(f.refOnlyLabels, ',')];
                    end
                    if ~isempty(f.newOnlyLabels)
                        seg = [seg '  new-only: ' ...
                            strjoin(f.newOnlyLabels, ',')];
                    end
                    detail = seg;
                end
                line = sprintf( ...
                    '    %-22s  labels differ  %s\n', ...
                    f.name, detail);
            end
            if useCprintf; cprintf('Errors', '%s', line);
            else;          fprintf('%s', line); end
        end
    end
end
fprintf('\n');

%% Summary
fprintf('SUMMARY: ');
if report.nTrialsChanged == 0
    msg = sprintf( ...
        '0 of %d common trials have structural differences.\n', ...
        length(report.commonTrials));
    if useCprintf; cprintf('Comments', '%s', msg);
    else;          fprintf('%s', msg); end
else
    msg = sprintf( ...
        ['%d of %d common trials have structural differences ' ...
        '(%d field diffs total).\n'], ...
        report.nTrialsChanged, length(report.commonTrials), ...
        report.nFieldDiffs);
    if useCprintf; cprintf('Errors', '%s', msg);
    else;          fprintf('%s', msg); end
end
fprintf('\n');
end

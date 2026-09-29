%ValidateSpinalAdaptBoutSplitOnServer Validates SpinalAdapt bout splitting
% on real sessions without running the import pipeline.
%
%   Read-only and headless: it only loads files (never SAVEs), opens no
% dialog, and needs neither GETINFOGUI nor a full C3D2MAT import. Three
% independent parts, each skipped when its path is empty or missing:
%
%   A. Data logs only (e.g., SAYA91 before import). Per datlog: the cue
%      inventory, the GETSPINALADAPTBOUTSEGMENTS windows (datlog time),
%      and APPROXIMATE strides per segment, counted from the
%      controller's own online slow-leg heel strikes (stepdata times;
%      Step# is never used, since it includes the simulated strides the
%      controller skips over at each rest).
%   B. A session's '<ID>params.mat' (e.g., SAYA90). Cue windows are
%      shifted onto the Vicon clock with the embedded
%      dataLogTimeOffsetBest, and the offline strides are assigned by
%      initTime exactly as SPLITSPINALADAPTBOUTCONDS assigns them.
%   C. (Optional, ~3.6 GB for SAYA90) a session's processed
%      '<ID>.mat' (expData). Runs the real SPLITSPINALADAPTBOUTCONDS and
%      MAKEDATAOBJ in memory, and checks stride preservation and the
%      condition -> stride mapping.
%
%   Flagged: any zero- or one-stride segment, any GOOD stride left
% outside every segment, and any trial with ramp cues that did not
% parse into segments. Expected per bout: ~3 ramp strides (2-3 after
% gait initiation) and ~10 SS strides (plus the bad stop strides).
%
%   NOTE: after an import with the split, '<ID>.mat' and
% '<ID>params.mat' ARE the split files; point Parts B and C at
% '<ID>OriginalCondNameparams.mat' / '<ID>OriginalCondName.mat'.
%
%   Usage:
%     1. Edit the paths below (defaults point at the server, read only).
%     2. Run: run('testing/ValidateSpinalAdaptBoutSplitOnServer.m')
%
% Toolbox Dependencies:
%   None
%
% See also GETSPINALADAPTBOUTSEGMENTS, SPLITSPINALADAPTBOUTCONDS,
%   TESTSPINALADAPTBOUTSEGMENTS.

%% Configuration -- Edit These Paths (Read Only; Nothing Is Saved)
dataRoot      = 'Z:\Chase\SpinalAdapt\Data';
datlogDir     = fullfile(dataRoot, 'SAYA91', 'Visit01', 'DataLogs');
paramsFile    = fullfile(dataRoot, 'SAYA90', 'Visit01', ...
    'SAYA90params.mat');
expDataFile   = '';  % optional (Part C), e.g., fullfile(dataRoot,
                     % 'SAYA90', 'Visit01', 'SAYA90.mat')
probeCondName = 'Adapt 1 SS03';     % Part C condition -> stride check

expectedRampStrides  = 3;  % strides; rampStrides in
                           % generateProfiles_SpinalAdaptBouts
expectedSSStrides    = 10; % strides; ssStrides, same file
minStridesPerSegment = 2;  % strides; fewer = zero/one-stride segment
rampCueTokens = {'AccRamp', 'DccRamp2Split'}; % raw ramp-cue substrings
numFlags = 0;
fprintf('Expected per bout: %d ramp + %d SS strides.\n', ...
    expectedRampStrides, expectedSSStrides);

%% Part A: Data Logs Only (Online Heel Strikes, Datlog Time)
datlogFiles = [];
if ~isempty(datlogDir) && isfolder(datlogDir)
    datlogFiles = dir(fullfile(datlogDir, '*.mat'));
    datlogFiles = datlogFiles(~strcmp({datlogFiles.name}, ...
        'lastDatlog.mat'));
end
if isempty(datlogFiles)
    fprintf('\nPart A skipped: no datlog files in ''%s''.\n', datlogDir);
end
for ff = 1:numel(datlogFiles)
    fileName = datlogFiles(ff).name;
    loaded   = load(fullfile(datlogDir, fileName), 'datlog');
    if ~isfield(loaded, 'datlog')
        continue
    end
    datlog = loaded.datlog;
    fprintf('\n=== Part A: %s\n', fileName);
    if ~isfield(datlog, 'audioCues')
        fprintf('  no audioCues field (e.g., tied fastest): unsplit\n');
        continue
    end
    cueNames = cellstr(datlog.audioCues.audio_instruction_message(:));
    fprintf('  %d cue rows; inventory: %s\n', numel(cueNames), ...
        strjoin(unique(regexprep(cueNames, '\d{2}', '##')), ', '));

    segs = getSpinalAdaptBoutSegments(datlog);
    if height(segs) == 0
        if any(contains(cueNames, rampCueTokens))
            fprintf('  FLAG: ramp cues present but no segments parsed\n');
            numFlags = numFlags + 1;
        else
            fprintf('  no ramp cues: unsplit trial\n');
        end
        continue
    end

    % slow leg = the slower belt of a split profile; tied: left, which
    % stands in for the reference leg (either leg's strides count)
    profile = datlog.speedprofile;
    if mean(profile.velL, 'omitnan') > mean(profile.velR, 'omitnan')
        slowLeg = 'R';
    else
        slowLeg = 'L';
    end
    hsData = datlog.stepdata.([slowLeg 'HSdata']);
    hsTime = hsData(hsData(:, 2) > 0, 4);   % trim preallocated rows
    [numFlags, isAssigned] = reportSegments(segs, hsTime, 0, [], ...
        minStridesPerSegment, numFlags, sprintf('%sHS', slowLeg));
    fprintf('  heel strikes outside every segment: %d of %d\n', ...
        nnz(~isAssigned), numel(hsTime));
end

%% Part B: params.mat (Offline Strides, Vicon Time)
if ~isempty(paramsFile) && isfile(paramsFile)
    loaded    = load(paramsFile, 'adaptData');
    adaptData = loaded.adaptData;
    meta      = adaptData.metaData;
    trialCol  = adaptData.data.getDataAsVector('trial');
    initTime  = adaptData.data.getDataAsVector('initTime');
    isGood    = adaptData.data.getDataAsVector('bad') == 0;
    fprintf('\n=== Part B: %s\n', paramsFile);
    trialsToCheck = 1:numel(meta.datlog);
    if any(~cellfun(@isempty, regexp(meta.conditionName, ...
            ' (Ramp|SS)\d{2}$', 'once')))
        fprintf(['  already split: point paramsFile at ' ...
            '<ID>OriginalCondNameparams.mat instead\n']);
        numFlags      = numFlags + 1;
        trialsToCheck = [];
    end
    for tr = trialsToCheck
        datlog = meta.datlog{tr};
        if ~isstruct(datlog)
            continue
        end
        segs = getSpinalAdaptBoutSegments(datlog);
        if height(segs) == 0
            hasRampCue = isfield(datlog, 'audioCues') && ...
                any(contains(datlog.audioCues.audio_instruction_message, ...
                rampCueTokens));
            if hasRampCue
                fprintf('Trial%02d FLAG: ramp cues but no segments\n', tr);
                numFlags = numFlags + 1;
            else
                fprintf('Trial%02d: no bout cues (unsplit)\n', tr);
            end
            continue
        end
        if ~isfield(datlog, 'dataLogTimeOffsetBest')
            fprintf('Trial%02d FLAG: bout cues but no sync offset\n', tr);
            numFlags = numFlags + 1;
            continue
        end
        inTrial = trialCol == tr;
        fprintf('Trial%02d (%s), %d strides:\n', tr, ...
            segs.startCue(1), nnz(inTrial));
        [numFlags, isAssigned] = reportSegments(segs, ...
            initTime(inTrial), datlog.dataLogTimeOffsetBest, ...
            isGood(inTrial), minStridesPerSegment, numFlags, 'strides');
        numUnassignedGood = nnz(~isAssigned & isGood(inTrial));
        fprintf('  unassigned strides: %d (%d good)\n', ...
            nnz(~isAssigned), numUnassignedGood);
        if numUnassignedGood > 0
            fprintf('  FLAG: good strides fall outside every segment\n');
            numFlags = numFlags + 1;
        end
    end
else
    fprintf('\nPart B skipped: ''%s'' not found.\n', paramsFile);
end

%% Part C (Optional): Real Splitter on a Processed expData
if ~isempty(expDataFile) && isfile(expDataFile)
    fprintf('\n=== Part C: %s (loading...)\n', expDataFile);
    loaded  = load(expDataFile, 'expData');
    expData = loaded.expData;
    [expSplit, splitReport] = splitSpinalAdaptBoutConds(expData);
    disp(splitReport.trials);

    % every stride of a split trial lands in exactly one segment or in a
    % standing interval (partition, no recompute)
    for row = 1:height(splitReport.trials)
        tr = splitReport.trials.origTrial(row);
        numBefore   = size(expData.data{tr}.adaptParams.Data, 1);
        numAfter    = sum(splitReport.segments.nStrides( ...
            splitReport.segments.origTrial == tr));
        numStanding = splitReport.trials.nUnassigned(row);
        if numAfter + numStanding ~= numBefore
            fprintf('  FLAG: trial %d strides %d ~= %d + %d\n', tr, ...
                numBefore, numAfter, numStanding);
            numFlags = numFlags + 1;
        end
    end

    adaptSplit = expSplit.makeDataObj([]);
    fprintf('  %d conditions, %d trials, %d strides after split\n', ...
        numel(expSplit.metaData.conditionName), ...
        numel(expSplit.data), size(adaptSplit.data.Data, 1));
    probeRow = splitReport.segments.condition == probeCondName;
    if any(probeRow)
        probeInit = adaptSplit.getParamInCond('initTime', probeCondName);
        if numel(probeInit) ~= splitReport.segments.nStrides(probeRow)
            fprintf('  FLAG: ''%s'' maps to %d strides, expected %d\n', ...
                probeCondName, numel(probeInit), ...
                splitReport.segments.nStrides(probeRow));
            numFlags = numFlags + 1;
        else
            fprintf('  ''%s'' maps to its %d strides\n', probeCondName, ...
                numel(probeInit));
        end
    end
end

%% Summary
fprintf('\nValidateSpinalAdaptBoutSplitOnServer: %d flag(s).\n', numFlags);

%% Local Functions

function [numFlags, isAssigned] = reportSegments(segs, strideTime, ...
    timeOffset, isGood, minStrides, numFlags, countLabel)
%REPORTSEGMENTS Print strides per bout segment and flag short segments.
%
%   Assigns each stride (or heel strike) to the segment containing its
% time, exactly as SPLITSPINALADAPTBOUTCONDS assigns strides by initTime,
% and prints one compact line per bout.
%
% Inputs:
%   segs       - table from GETSPINALADAPTBOUTSEGMENTS
%   strideTime - column; stride start (or heel-strike) times (s)
%   timeOffset - s; added to the segment times (0 for datlog time,
%                dataLogTimeOffsetBest for Vicon time)
%   isGood     - logical column of good strides, or [] if unknown
%   minStrides - fewest strides a segment may hold without a flag
%   numFlags   - running flag count
%   countLabel - char; what is being counted (for the printout)
%
% Outputs:
%   numFlags   - updated flag count
%   isAssigned - logical column; strides inside some segment
%
% Toolbox Dependencies:
%   None
%
% See also SPLITSPINALADAPTBOUTCONDS.

isAssigned = false(size(strideTime));
for sg = 1:height(segs)
    t0 = segs.startTime(sg) + timeOffset;
    t1 = segs.endTime(sg) + timeOffset;
    inSeg = strideTime >= t0 & (isnan(t1) | strideTime < t1);
    isAssigned = isAssigned | inSeg;
    numStrides = nnz(inSeg);
    goodText = '';
    if ~isempty(isGood)
        goodText = sprintf(' (%d good)', nnz(inSeg & isGood));
    end
    fprintf('  bout %02d %-4s [%8.2f, %8.2f) s: %2d %s%s, end %s\n', ...
        segs.bout(sg), segs.segment(sg), t0, t1, numStrides, ...
        countLabel, goodText, segs.endSource(sg));
    if numStrides < minStrides
        fprintf('  FLAG: bout %02d %s holds %d %s\n', segs.bout(sg), ...
            segs.segment(sg), numStrides, countLabel);
        numFlags = numFlags + 1;
    end
end

end

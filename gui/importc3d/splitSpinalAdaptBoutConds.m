function [expData, splitReport] = splitSpinalAdaptBoutConds(expData)
%SPLITSPINALADAPTBOUTCONDS Split SpinalAdapt bout trials into conditions.
%
%   Replaces every bout-based trial of a processed SpinalAdapt session
% with one trial and condition per bout segment -- '<Parent> Ramp01',
% '<Parent> SS01', ..., e.g., 'Adapt 1 SS03' -- using the datlog cue
% windows from GETSPINALADAPTBOUTSEGMENTS, shifted onto the Vicon clock
% by each datlog's dataLogTimeOffsetBest (SYNCDATALOG). Trials without
% bout cues (6MWT, H-reflex calibration, tied fastest) are kept as they
% are. Standing intervals between segments are left out.
%
%   Strides are partitioned, not recomputed: each segment keeps the rows
% of its parent trial's adaptParams whose initTime (slow heel strike)
% falls inside the segment, so every stride keeps its original
% parameters (EMG-norm and H-reflex ones included) and none is lost at
% a boundary. Recomputing on the short pieces would instead drop the
% stride straddling each cut and flag each piece's last stride
% badMissingEvent, leaving ramps with about 0-1 good strides. For the
% same reason, never pass a split experimentData to
% RECOMPUTEPARAMETERS, FLUSHANDRECOMPUTEPARAMETERS, or
% CORRECTLEGASSIGNMENT: recompute the unsplit session, then split again
% (this function refuses an already split session).
%
%   Trials before the first bout trial keep their indices. Later trials
% are renumbered contiguously in chronological order, and every trial
% whose index changes has its 'trial' parameter rewritten and
% '_SplitIdx###' appended to its rawDataFilename, whose trailing digits
% CALCPARAMETERS reads as the trial number.
%
% Inputs:
%   expData - processed experimentData whose datlogs were synchronized
%             by SYNCDATALOG (dataLogTimeOffsetBest)
%
% Outputs:
%   expData     - experimentData with its bout trials split into
%                 per-segment conditions (unchanged if no trial has
%                 bout cues)
%   splitReport - struct with two tables:
%                   segments - one row per new segment: origTrial,
%                              newTrial, condition, bout, segment,
%                              startTime and endTime (s, Vicon trial
%                              time; NaN = trial end), nStrides,
%                              nGoodStrides, endSource
%                   trials   - one row per split trial: origTrial,
%                              condition, nStrides, nUnassigned,
%                              nUnassignedGood (strides that start in a
%                              standing interval, outside all segments)
%
% Toolbox Dependencies:
%   None
%
% See also GETSPINALADAPTBOUTSEGMENTS, SYNCDATALOG, LOADSUBJECT,
%   SEPCONDSINEXPBYAUDIOCUE.

arguments
    expData (1,1) experimentData
end

minStridesPerSegment = 2; % strides; SAYA90 ramps held 2-3 and SS bouts
                          % 9-13, so fewer flags a cue or sync fault
splitIdxMarker = '_SplitIdx';              % rawDataFilename suffix,
splitIdxFormat = [splitIdxMarker '%03d'];  % followed by the new index

meta    = expData.metaData;
oldData = expData.data;
numOld  = numel(oldData);
trials  = find(~cellfun(@isempty, oldData(:)'));

%% Refuse an Already Split Session
% every piece keeps its parent trial's full datlog, so splitting again
% would re-split each piece by the whole trial's cues
isSplitPiece = cellfun(@(trialData) contains( ...
    string(trialData.metaData.rawDataFilename), splitIdxMarker), ...
    oldData(trials));
if any(isSplitPiece)
    error('splitSpinalAdaptBoutConds:alreadySplit', ...
        ['Trial %d is already a split piece; split the unsplit ' ...
        '<ID>OriginalCondName.mat instead.'], ...
        trials(find(isSplitPiece, 1)));
end

%% Find the Bout Segments of Every Trial
boutSegments = cell(1, numOld);
for tr = trials
    trialDatlog = getTrialDatlog(meta, oldData{tr}, tr);
    if isstruct(trialDatlog)
        boutSegments{tr} = getSpinalAdaptBoutSegments(trialDatlog);
    end
end
isBoutTrial = ~cellfun(@(seg) isempty(seg) || height(seg) == 0, ...
    boutSegments);

splitReport = struct('segments', table(), 'trials', table());
if ~any(isBoutTrial)
    warning('splitSpinalAdaptBoutConds:noBoutTrials', ...
        'No trial has SpinalAdapt bout cues; nothing was split.');
    return
end

condOfTrial = zeros(1, numOld);
for con = 1:numel(meta.trialsInCondition)
    condOfTrial(meta.trialsInCondition{con}) = con;
end

%% Keep the Trials Before the First Bout Trial Unchanged
firstBoutTrial = find(isBoutTrial, 1);
newData        = oldData(1:firstBoutTrial - 1);
newDatlog      = cell(size(newData));
newIdxOfTrial  = cell(1, numOld);   % new trial index(es) per old trial
for tr = trials(trials < firstBoutTrial)
    newIdxOfTrial{tr} = tr;
    newDatlog{tr}     = getTrialDatlog(meta, oldData{tr}, tr);
end
segCondName = {};                   % condition name per new bout trial
segCondDesc = {};

%% Split Each Bout Trial into Segment Trials
segRows   = {};
trialRows = {};
for tr = trials(trials >= firstBoutTrial)
    trialData   = oldData{tr};
    trialDatlog = getTrialDatlog(meta, trialData, tr);
    params      = trialData.adaptParams;
    if ~isBoutTrial(tr)
        newIdx = numel(newData) + 1;
        if newIdx ~= tr
            trialData = reindexTrial(trialData, params, ...
                true(size(params.Data, 1), 1), newIdx, splitIdxFormat);
        end
        newData{newIdx}   = trialData;
        newDatlog{newIdx} = trialDatlog;
        newIdxOfTrial{tr} = newIdx;
        continue
    end

    if ~isfield(trialDatlog, 'dataLogTimeOffsetBest')
        error('splitSpinalAdaptBoutConds:notSynced', ...
            ['Trial %d has bout cues but its datlog has no ' ...
            'dataLogTimeOffsetBest; run SYNCDATALOG first.'], tr);
    end
    timeOffset = trialDatlog.dataLogTimeOffsetBest;  % s, datlog -> Vicon
    segs       = boutSegments{tr};
    parentName = meta.conditionName{condOfTrial(tr)};
    parentDesc = meta.conditionDescription{condOfTrial(tr)};
    initTime   = params.getDataAsVector('initTime');
    isGood     = params.getDataAsVector('bad') == 0;
    trialStart = trialData.gaitEvents.Time(1);
    trialEnd   = trialData.gaitEvents.Time(end);

    isAssigned = false(size(initTime));
    for sg = 1:height(segs)
        t0 = segs.startTime(sg) + timeOffset;
        t1 = segs.endTime(sg) + timeOffset; % NaN = runs to trial end
        inSeg = initTime >= t0 & (isnan(t1) | initTime < t1);
        isAssigned = isAssigned | inSeg;

        % clamp to the recorded range (NaN = trial start/end) so that
        % LABTIMESERIES.SPLIT does not pad the piece with NaNs
        splitStart = t0;
        if t0 <= trialStart
            splitStart = NaN;
        end
        splitEnd = t1;
        if t1 >= trialEnd
            splitEnd = NaN;
        end

        segName = char(segs.segment(sg));   % 'Ramp' or 'SS'
        if strcmp(segName, 'Ramp')
            segLabel = 'ramp';
        else
            segLabel = 'steady state';
        end
        newIdx   = numel(newData) + 1;
        condName = sprintf('%s %s%02d', parentName, segName, ...
            segs.bout(sg));
        piece = trialData.split(splitStart, splitEnd);
        piece.metaData.name         = condName;
        piece.metaData.description  = sprintf('%s; bout %02d %s', ...
            parentDesc, segs.bout(sg), segLabel);
        piece.metaData.observations = trialData.metaData.observations;
        piece = reindexTrial(piece, params, inSeg, newIdx, ...
            splitIdxFormat);

        newData{newIdx}     = piece;
        newDatlog{newIdx}   = trialDatlog;
        newIdxOfTrial{tr}   = [newIdxOfTrial{tr} newIdx];
        segCondName{newIdx} = condName;                       %#ok<AGROW>
        segCondDesc{newIdx} = piece.metaData.description;     %#ok<AGROW>

        numStrides = nnz(inSeg);
        if numStrides < minStridesPerSegment
            warning('splitSpinalAdaptBoutConds:fewStrides', ...
                ['%s (trial %d) holds %d stride(s); check its cues ' ...
                'and datlog sync.'], condName, tr, numStrides);
        end
        segRows(end + 1, :) = {tr, newIdx, string(condName), ...
            segs.bout(sg), segs.segment(sg), t0, t1, numStrides, ...
            nnz(inSeg & isGood), segs.endSource(sg)}; %#ok<AGROW>
    end
    trialRows(end + 1, :) = {tr, string(parentName), numel(initTime), ...
        nnz(~isAssigned), nnz(~isAssigned & isGood)}; %#ok<AGROW>
end

%% Rebuild the Condition List in Chronological Order
condNames  = {};
condDescs  = {};
condTrials = {};
for con = 1:numel(meta.conditionName)
    oldTrials   = meta.trialsInCondition{con};
    isSplitCond = isBoutTrial(oldTrials);
    if ~any(isSplitCond)
        condNames{end + 1}  = meta.conditionName{con};        %#ok<AGROW>
        condDescs{end + 1}  = meta.conditionDescription{con}; %#ok<AGROW>
        condTrials{end + 1} = [newIdxOfTrial{oldTrials}];     %#ok<AGROW>
    elseif all(isSplitCond)
        for newIdx = [newIdxOfTrial{oldTrials}]
            condNames{end + 1}  = segCondName{newIdx};        %#ok<AGROW>
            condDescs{end + 1}  = segCondDesc{newIdx};        %#ok<AGROW>
            condTrials{end + 1} = newIdx;                     %#ok<AGROW>
        end
    else
        error('splitSpinalAdaptBoutConds:mixedCondition', ...
            ['Condition ''%s'' mixes bout and non-bout trials; ' ...
            'split it manually.'], meta.conditionName{con});
    end
end
[~, firstOfName] = unique(condNames, 'stable');
if numel(firstOfName) < numel(condNames)
    dupName = condNames{setdiff(1:numel(condNames), firstOfName)};
    error('splitSpinalAdaptBoutConds:duplicateBout', ...
        ['Bout condition ''%s'' occurs in more than one trial of the ' ...
        'same condition; split it manually.'], dupName);
end

%% Assemble the Split experimentData
% the constructor revalidates unique names and non-interleaved trials
newMeta = experimentMetaData(meta.ID, meta.date, meta.experimenter, ...
    meta.observations, condNames, condDescs, condTrials, ...
    numel(newData), meta.SchenleyPlace, meta.PerceptualTasks, newDatlog);
for con = 1:numel(newMeta.trialsInCondition)
    for tr = newMeta.trialsInCondition{con}
        newData{tr}.metaData.condition = con;
    end
end
expData.metaData = newMeta;
expData.data     = newData;

splitReport.segments = cell2table(segRows, 'VariableNames', ...
    {'origTrial', 'newTrial', 'condition', 'bout', 'segment', ...
    'startTime', 'endTime', 'nStrides', 'nGoodStrides', 'endSource'});
splitReport.trials = cell2table(trialRows, 'VariableNames', ...
    {'origTrial', 'condition', 'nStrides', 'nUnassigned', ...
    'nUnassignedGood'});

end

% ============================================================
% ==================== Local Functions =======================
% ============================================================

function trialDatlog = getTrialDatlog(meta, trialData, tr)
%GETTRIALDATLOG Return a trial's datlog, preferring the session copy.
%
%   SYNCDATALOG writes dataLogTimeOffsetBest into both
% expData.metaData.datlog{tr} and the trial's own metaData.datlog; the
% session copy is used when present.
%
% Inputs:
%   meta      - experimentMetaData of the session
%   trialData - labData object of trial tr
%   tr        - trial index
%
% Outputs:
%   trialDatlog - datlog struct, or [] if the trial has none
%
% Toolbox Dependencies:
%   None
%
% See also SPLITSPINALADAPTBOUTCONDS.

trialDatlog = [];
if iscell(meta.datlog) && numel(meta.datlog) >= tr && ...
        isstruct(meta.datlog{tr})
    trialDatlog = meta.datlog{tr};
elseif isstruct(trialData.metaData.datlog)
    trialDatlog = trialData.metaData.datlog;
end

end

function trialData = reindexTrial(trialData, params, rows, newIdx, ...
    splitIdxFormat)
%REINDEXTRIAL Give a trial a subset of strides and a new trial index.
%
%   Keeps the selected rows of the parent trial's adaptParams (with its
% UserData, where EMG-norm state lives), writes newIdx into their
% 'trial' column, and appends the new index to rawDataFilename.
%
% Inputs:
%   trialData      - labData object to update (a split piece, or a whole
%                    trial whose index changed)
%   params         - parent trial's adaptParams (parameterSeries)
%   rows           - logical column; strides of params to keep
%   newIdx         - new trial index in expData.data
%   splitIdxFormat - sprintf format of the rawDataFilename suffix
%
% Outputs:
%   trialData - updated labData object
%
% Toolbox Dependencies:
%   None
%
% See also SPLITSPINALADAPTBOUTCONDS, CALCPARAMETERS.

subset = parameterSeries(params.Data(rows, :), params.labels, ...
    params.hiddenTime(rows), params.description, params.trialTypes);
subset.DataInfo.UserData = params.DataInfo.UserData;
subset.Data(:, strcmp(subset.labels, 'trial')) = newIdx;
trialData.adaptParams = subset;
trialData.metaData.rawDataFilename = ...
    [char(trialData.metaData.rawDataFilename) ...
    sprintf(splitIdxFormat, newIdx)];

end

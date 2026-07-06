%% Determine the Optimal Reconstruct & Label Pipeline Parameters
% author: NWB (with assistance from ChatGPT)
% date (created): 18 May 2025
% purpose: Iterate through various Vicon Nexus 'Reconstruct & Label'
%   pipeline parameters to determine the optimal configuration based
%   on metrics such as percentage of frames missing, average number of
%   gaps per marker, maximum gap length, and median gap length — both
%   across all markers and a subset.

% TODO:
%   1. Loop through exemplar trials from all SML Lab studies or
%       study types
%   2. Save RGT, LGT, RANK, LANK marker trajectories in MAT file
%       for later analysis just in case
%   3. Generate and save trajectory figures for GT and ANK markers

%% 1) Define Paths
pathData   = 'Z:\Nathan\ViconNexusReconstructAndLabel\Vicon\';
pathOutCSV = fullfile('Z:\Nathan\ViconNexusReconstructAndLabel\', ...
    'Results_C3S_S1_OGPost_2.csv');

% get all session folders (exclude '.' and '..')
dirsSess = dir(pathData);
dirsSess = dirsSess([dirsSess.isdir] & ...
    ~ismember({dirsSess.name}, {'.','..'}));
numSess = numel(dirsSess);              % number of sessions to process
if numSess == 0
    error('No session folders found in %s', pathData);
end

%% 2) Initialize Vicon Nexus SDK & Prepare Results Container
vicon = ViconNexus();   % assumes ViconNexus() is on the MATLAB path

% preallocate a struct array to hold per-trial results:
%   • ParticipantName, TrialID, Use3DPredictions,
%     EnvironmentalDriftTolerance, MinCamerasToStartTraj,
%     MinCamerasToContTraj, MinSeparation, PercentMissing_All,
%     NumGapsPerMarker_All, MaxGapLength_All, MedianGapLength_All,
%     PercentMissing_Subset, NumGapsPerMarker_Subset,
%     MaxGapLength_Subset, MedianGapLength_Subset
results = struct( ...
    'ParticipantName',            {}, ...
    'TrialID',                    {}, ...
    'Use3DPredictions',           {}, ...
    'EnvironmentalDriftTolerance',{}, ...
    'MinCamerasToStartTraj',      {}, ...
    'MinCamerasToContTraj',       {}, ...
    'MinSeparation',              {}, ...
    'PercentMissing_All',         {}, ...
    'NumGapsPerMarker_All',       {}, ...
    'MaxGapLength_All',           {}, ...
    'MedianGapLength_All',        {}, ...
    'PercentMissing_Subset',      {}, ...
    'NumGapsPerMarker_Subset',    {}, ...
    'MaxGapLength_Subset',        {}, ...
    'MedianGapLength_Subset',     {} ...
    );

%% 3) Locate & Read the 'Reconstruct And Label Test.Pipeline' File
pathPipeline = fullfile( ...
    'C:\Users\Public\Documents\Vicon\Nexus2.x\', ...
    'Configurations\Pipelines\', ...
    'Reconstruct And Label Test.Pipeline');

params = readlines(pathPipeline);

% find exactly one line index for each parameter
ind3DPredict          = find(contains( ...
    params, 'Reconstructor.3DPredictions'));
indEnvDriftTol        = find(contains( ...
    params, 'EnvironmentalDriftTolerance'));
indMinCamsToStartTraj = find(contains(params, '"MinCams"'));
indMinCamsToContTraj  = find(contains( ...
    params, 'MinCamsWithPrediction'));
indMinSeparation      = find(contains(params, 'MinSeparation'));

% sanity check: each parameter must appear exactly once in the XML
if any([numel(ind3DPredict), numel(indEnvDriftTol), ...
        numel(indMinCamsToStartTraj), numel(indMinCamsToContTraj), ...
        numel(indMinSeparation)] ~= 1)
    error(['Each pipeline parameter must appear exactly once ' ...
        'in the XML file.']);
end

%% 4) Define the Subset of Critical Markers
markersSubset = {'RGT','LGT','RANK','LANK'};

%% 5) Specify Set of Reconstruct & Label Parameters to Loop Through
predict3D          = [true, false];
envDriftTol        = 2.00:0.25:4.50;   % e.g., [2.00, 2.25, ..., 4.50]
minCamsToStartTraj = 2:3;              % [2, 3]
minCamsToContTraj  = 1:2;              % [1, 2]
minSeparation      = 14:5:34;          % [14, 19, 24, 29, 34]

% build full-factorial combinations of all parameter values
paramSets    = allcomb(predict3D, envDriftTol, ...
    minCamsToStartTraj, minCamsToContTraj, minSeparation);
numParamSets = size(paramSets, 1);

% preallocate arrays to store per-parameter-set summary means
meanMissingAllArr = nan(numParamSets, 1);
meanMissingSubArr = nan(numParamSets, 1);

%% 6) Loop Over Parameter Sets & Trials & Compute Outcome Measures
for setIdx = 1:numParamSets

    % extract current parameter values
    shouldPredict3D = paramSets(setIdx, 1);
    currEnvDriftTol = paramSets(setIdx, 2);
    currMinStart    = paramSets(setIdx, 3);
    currMinCont     = paramSets(setIdx, 4);
    currMinSep      = paramSets(setIdx, 5);

    fprintf('\n---\nAssessing parameter set %d of %d:\n', ...
        setIdx, numParamSets);
    fprintf('  • 3D Predictions          = %d\n',   shouldPredict3D);
    fprintf('  • Environmental Drift Tol = %.2f\n', currEnvDriftTol);
    fprintf('  • MinCamsToStartTraj      = %d\n',   currMinStart);
    fprintf('  • MinCamsToContTraj       = %d\n',   currMinCont);
    fprintf('  • MinSeparation           = %d\n',   currMinSep);

    % 6a) overwrite the pertinent lines in the pipeline XML file
    if shouldPredict3D
        params(ind3DPredict) = ['      <Param name=' ...
            '"Reconstructor.3DPredictions" value="true"/>'];
    else
        params(ind3DPredict) = ['      <Param name=' ...
            '"Reconstructor.3DPredictions" value="false"/>'];
    end
    params(indEnvDriftTol) = sprintf(['      <Param name=' ...
        '"EnvironmentalDriftTolerance" value="%.2f"/>'], ...
        currEnvDriftTol);
    params(indMinCamsToStartTraj) = sprintf(['      <Param ' ...
        'name="MinCams" value="%d"/>'], currMinStart);
    params(indMinCamsToContTraj) = sprintf(['      <Param name=' ...
        '"MinCamsWithPrediction" value="%d"/>'], currMinCont);
    params(indMinSeparation) = sprintf(['      <Param name=' ...
        '"MinSeparation" value="%d"/>'], currMinSep);

    % 6b) write all lines back into the pipeline XML file
    fidW = fopen(pathPipeline, 'w');
    if fidW < 0
        error('Could not open pipeline file for writing: %s', ...
            pathPipeline);
    end
    fprintf(fidW, '%s\n', params);
    fclose(fidW);

    % 6c) initialize per-parameter-set lists for PercentMissing
    missingAllList = [];
    missingSubList = [];

    for sessIdx = 1:numSess             % for each session, ...
        nameSess = dirsSess(sessIdx).name;
        pathSess = fullfile(pathData, nameSess);
        fprintf('\nProcessing session: %s\n', nameSess);

        % find all trials in this session folder
        trialFiles = dir(fullfile(pathSess, 'Trial*.x1d'));
        if isempty(trialFiles)
            warning(['  • No trials found in folder: %s. ' ...
                'Skipping session.'], pathSess);
            continue;
        end

        % extract trial numbers from filenames ('TrialXX.x1d')
        [~, namesFiles] = cellfun(@fileparts, {trialFiles.name}, ...
            'UniformOutput', false);
        indsTrials = cellfun( ...
            @(s) str2double(s(end-1:end)), namesFiles);

        for tr = 1:numel(indsTrials)    % for each trial, ...
            trialID   = indsTrials(tr);
            trialName = sprintf('Trial%02d', trialID);
            pathTrial = fullfile(pathSess, [trialName '.x1d']);

            fprintf('  • Trial %s ...\n', trialName);

            % 6d) open the trial in Nexus (if not already open)
            if ~dataMotion.openTrialIfNeeded(pathTrial, vicon)
                warning(['    – Could not open trial %s. ' ...
                    'Skipping.'], trialName);
                continue;
            end

            % 6e) run the "Reconstruct And Label Test" pipeline
            try
                vicon.RunPipeline( ...
                    'Reconstruct And Label Test', '', 200);
            catch ME
                warning(['    – Nexus.RunPipeline failed on ' ...
                    '%s: %s'], trialName, ME.message);
                continue;
            end

            % 6f) retrieve the (single) subject name
            subs = vicon.GetSubjectNames();
            if isempty(subs)
                warning(['    – No subject found in %s. ' ...
                    'Skipping.'], trialName);
                continue;
            end
            subject = subs{1};

            % 6g) retrieve all marker names for this subject
            markersAll = vicon.GetMarkerNames(subject);
            nMarkers   = numel(markersAll);
            if nMarkers == 0
                warning(['    – No markers found for subject ' ...
                    '%s. Skipping.'], subject);
                continue;
            end

            % 6h) preallocate per-marker arrays
            percentMissing = nan(nMarkers, 1);
            numGaps        = nan(nMarkers, 1);
            allGapLens     = cell(nMarkers, 1);
            isInSubset     = false(nMarkers, 1);

            % 6i) for each marker: retrieve trajectory, compute
            %     missing frames and gaps
            totalFrames = vicon.GetFrameCount();

            for mrkr = 1:nMarkers       % for each marker, ...
                nameMarker = markersAll{mrkr};
                isInSubset(mrkr) = ...
                    any(strcmp(nameMarker, markersSubset));

                try
                    [~, ~, ~, existsTraj] = ...
                        vicon.GetTrajectory(subject, nameMarker);
                    % existsTraj: true = visible, false = occluded
                catch
                    warning(['    – Failed to get trajectory ' ...
                        'for %s. Marking all as missing.'], ...
                        nameMarker);
                    existsTraj = false(totalFrames, 1);
                end

                % compute percentage of missing frames
                nMissing             = sum(~existsTraj);
                percentMissing(mrkr) = ...
                    (nMissing / totalFrames) * 100;

                % identify gap runs (contiguous occluded segments)
                missingFlags  = ~existsTraj;
                dv            = diff([0; missingFlags; 0]);
                runBoundaries = find(dv ~= 0);
                runLengths    = diff(runBoundaries);
                runValues     = dv(runBoundaries);
                gapRuns       = runLengths(runValues == 1);
                numGaps(mrkr)     = numel(gapRuns);
                allGapLens{mrkr}  = gapRuns;
            end

            % 6j) compute aggregate metrics for ALL markers
            PercentMissing_All   = mean(percentMissing);
            NumGapsPerMarker_All = sum(numGaps) / nMarkers;
            MaxGapLength_All     = max(cellfun( ...
                @(x) max([x; 0]), allGapLens));
            allGapsCombined_All  = vertcat(allGapLens{:});
            if isempty(allGapsCombined_All)
                MedianGapLength_All = 0;
            else
                MedianGapLength_All = median(allGapsCombined_All);
            end

            % 6k) compute aggregate metrics for SUBSET markers
            subsetInds = find(isInSubset);
            if isempty(subsetInds)
                PercentMissing_Subset   = NaN;
                NumGapsPerMarker_Subset = NaN;
                MaxGapLength_Subset     = NaN;
                MedianGapLength_Subset  = NaN;
            else
                pctMiss_Sub  = percentMissing(subsetInds);
                nGaps_Sub    = numGaps(subsetInds);
                gapLens_Sub  = allGapLens(subsetInds);

                PercentMissing_Subset   = mean(pctMiss_Sub);
                NumGapsPerMarker_Subset = ...
                    sum(nGaps_Sub) / numel(subsetInds);
                MaxGapLength_Subset     = max(cellfun( ...
                    @(x) max([x; 0]), gapLens_Sub));
                gapsCombined_Sub = vertcat(gapLens_Sub{:});
                if isempty(gapsCombined_Sub)
                    MedianGapLength_Subset = 0;
                else
                    MedianGapLength_Subset = ...
                        median(gapsCombined_Sub);
                end
            end

            % 6l) append a single row to the results structure
            results(end+1) = struct( ...          %#ok<AGROW>
                'ParticipantName',            subject, ...
                'TrialID',                    trialID, ...
                'Use3DPredictions',           shouldPredict3D, ...
                'EnvironmentalDriftTolerance',currEnvDriftTol, ...
                'MinCamerasToStartTraj',      currMinStart, ...
                'MinCamerasToContTraj',       currMinCont, ...
                'MinSeparation',              currMinSep, ...
                'PercentMissing_All',         PercentMissing_All, ...
                'NumGapsPerMarker_All',       NumGapsPerMarker_All,...
                'MaxGapLength_All',           MaxGapLength_All, ...
                'MedianGapLength_All',        MedianGapLength_All,...
                'PercentMissing_Subset',      PercentMissing_Subset,...
                'NumGapsPerMarker_Subset',    NumGapsPerMarker_Subset,...
                'MaxGapLength_Subset',        MaxGapLength_Subset, ...
                'MedianGapLength_Subset',     MedianGapLength_Subset ...
                );

            % store this trial's PercentMissing in the summary lists
            missingAllList(end+1) = PercentMissing_All;  %#ok<AGROW>
            missingSubList(end+1) = PercentMissing_Subset; %#ok<AGROW>

            fprintf(['    • AllMarkers → %%Missing=%.2f%%, ' ...
                'Gaps/Marker=%.2f, MaxGap=%d, ' ...
                'MedianGap=%.2f\n'], ...
                PercentMissing_All, NumGapsPerMarker_All, ...
                MaxGapLength_All, MedianGapLength_All);
            fprintf(['      Subset    → %%Missing=%.2f%%, ' ...
                'Gaps/Marker=%.2f, MaxGap=%d, ' ...
                'MedianGap=%.2f\n\n'], ...
                PercentMissing_Subset, NumGapsPerMarker_Subset, ...
                MaxGapLength_Subset, MedianGapLength_Subset);
        end
    end

    % 6m) compute and store mean PercentMissing across all trials
    meanMissingAllArr(setIdx) = mean(missingAllList, 'omitnan');
    meanMissingSubArr(setIdx) = mean(missingSubList, 'omitnan');

    fprintf(['Summary for parameter set %d ' ...
        '(means across all trials):\n'], setIdx);
    fprintf('  • AllMarkers → %%Missing=%.2f%%\n', ...
        meanMissingAllArr(setIdx));
    fprintf('  • Subset     → %%Missing=%.2f%%\n', ...
        meanMissingSubArr(setIdx));
end

%% 7) Identify & Display Best Parameter Sets
[~, bestAllIdx] = min(meanMissingAllArr);
[~, bestSubIdx] = min(meanMissingSubArr);

bestAllParams = paramSets(bestAllIdx, :);
bestSubParams = paramSets(bestSubIdx, :);

fprintf('\n=== Optimal Parameter Sets ===\n');
fprintf('All Markers best @ set %d:\n', bestAllIdx);
fprintf('  • 3D Predictions          = %d\n',   bestAllParams(1));
fprintf('  • Environmental Drift Tol = %.2f\n', bestAllParams(2));
fprintf('  • MinCamsToStartTraj      = %d\n',   bestAllParams(3));
fprintf('  • MinCamsToContTraj       = %d\n',   bestAllParams(4));
fprintf('  • MinSeparation           = %d\n',   bestAllParams(5));
fprintf('  → Mean %%Missing_All = %.2f%%\n\n', ...
    meanMissingAllArr(bestAllIdx));

fprintf('Subset Markers best @ set %d:\n', bestSubIdx);
fprintf('  • 3D Predictions          = %d\n',   bestSubParams(1));
fprintf('  • Environmental Drift Tol = %.2f\n', bestSubParams(2));
fprintf('  • MinCamsToStartTraj      = %d\n',   bestSubParams(3));
fprintf('  • MinCamsToContTraj       = %d\n',   bestSubParams(4));
fprintf('  • MinSeparation           = %d\n',   bestSubParams(5));
fprintf('  → Mean %%Missing_Subset = %.2f%%\n\n', ...
    meanMissingSubArr(bestSubIdx));

%% 8) Save All Trial-Level Results to CSV
T = struct2table(results);
writetable(T, pathOutCSV);
fprintf('All per-trial results saved to:\n   %s\n\n', pathOutCSV);

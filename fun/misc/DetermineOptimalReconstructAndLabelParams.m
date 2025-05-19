%% Determine the Optimal Reconstruct & Label Pipeline Parameters
% author: NWB (with assistance from ChatGPT)
% date (created): 18 May 2025
% purpose: to iterate through various Vicon Nexus 'Reconstruct & Label'
% pipeline parameters to determine the optimal configuration based on
% various metrics.

% TODO:
%   1. Loop through exemplar trials from all SML Lab studies or study types
%   2. Save RGT, LGT, RANK, LANK marker trajectories in MAT file for later
%       analysis just in case
%   3. Generate and save trajectory figures for GT and ANK markers

%% 1) Define Paths & Trial List
pathSess   = 'Z:\Nathan\ViconNexusReconstructAndLabel\Vicon\';
pathOutCSV = 'Z:\Nathan\ViconNexusReconstructAndLabel\Results.csv';

% get all trial files that start with 'Trial' and end in '.x1d'
trialFiles = dir(fullfile(pathSess,'Trial*.x1d'));
if isempty(trialFiles)                      % if no trial files found, ...
    error('No trials found in session folder: %s\n',pathSess);
end

% extract numeric trial indices from filenames (assumes 'TrialXX.x1d')
[~,namesFiles] = cellfun(@fileparts,{trialFiles.name}, ...
    'UniformOutput',false);
indsTrials = cellfun(@(s) str2double(s(end-1:end)),namesFiles);

%% 2) Initialize Vicon Nexus SDK & Prepare Results Container
vicon = ViconNexus();   % assumes ViconNexus() is on the MATLAB path

% preallocate a struct array to hold summary results:
%   • TrialID           (e.g. 1, 2, …)
%   • SubjectName       (string)
%   • Use3DPredictions  (logical)
%   • DropPct_All       (numeric)
%   • NumGapsPerMarker_All
%   • MaxGapLength_All
%   • DropPct_Subset    (numeric)
%   • NumGapsPerMarker_Subset
%   • MaxGapLength_Subset
results = struct( ...
    'TrialID',                {}, ...
    'SubjectName',            {}, ...
    'Use3DPredictions',       {}, ...
    'DropPct_All',            {}, ...
    'NumGapsPerMarker_All',   {}, ...
    'MaxGapLength_All',       {}, ...
    'DropPct_Subset',         {}, ...
    'NumGapsPerMarker_Subset',{}, ...
    'MaxGapLength_Subset',    {} ...
    );

%% 3) Locate & Read the “Reconstruct And Label Test.Pipeline” File
pipelineFile = ['C:\Users\Public\Documents\Vicon\Nexus2.x\' ...
    'Configurations\Pipelines\Reconstruct And Label Test.Pipeline'];

% read in all lines once and search for the 3DPredictions line index
params         = readlines(pipelineFile);
ind3DPredict   = contains(params,'Reconstructor.3DPredictions');
if nnz(ind3DPredict) ~= 1
    error(['Could not find exactly one line containing ' ...
        '"Reconstructor.3DPredictions" in pipeline file.']);
end

%% 4) Define the Subset of Markers to Compute Separately
subsetMarkers = {'RGT','LGT','RANK','LANK'};

%% Specify Set of Reconstruct & Label Parameters to Loop Through
predict3D = [true false];
envDriftTolerance = 1.5; % 0.5:1.0:2.5;
minCamerasToStartTraj = 3; % 2:3;
minCamerasToContTraj = 2; % 1:2;
minSeparation = 14; % 14:5:34;
minCentroidRadius = 0; % 0:2:4;
maxCentroidRadius = 50; % 30:10:50;
% create set of parameter combinations
% paramSets = allcomb(predict3D,envDriftTolerance, ...
%     minCamerasToStartTraj,minCamerasToContTraj,minSeparation, ...
%     minCentroidRadius,maxCentroidRadius);

%% 5) Loop Over All Trials & Parameter Sets
paramSets = [true; false];  % only two rows: true (row 1), false (row 2)
numParamSets = size(paramSets,1);           % number of parameter sets

for set = 1:numParamSets                    % for each parameter set, ...
    use3D = paramSets(set);

    % 5a) overwrite just the '3DPredictions' line in pipeline XML file
    if use3D                                % if 3D predictions on, ...
        params(ind3DPredict) = '      <Param name="Reconstructor.3DPredictions" value="true"/>';
    else
        params(ind3DPredict) = '      <Param name="Reconstructor.3DPredictions" value="false"/>';
    end

    % 5b) overwrite ALL 209 lines back into the pipeline file
    % if MATLAB R2022a or later
    % writelines(params,pipelineFile);
    fidW = fopen(pipelineFile,'w');     % open the file to overwrite
    if fidW < 0                         % if file did not open, ...
        error('Could not open pipeline file for writing: %s',pipelineFile);
    end
    for line = 1:numel(params)          % for each line in file, ...
        fprintf(fidW,'%s\n',params(line));  % overwrite it
    end
    fclose(fidW);                       % close file

    % process all trials
    for tr = 1:numel(indsTrials)     % for each trial specified, ...
        trialID = indsTrials(tr);
        trialName = sprintf('Trial%02d',trialID);
        pathTrial = fullfile(pathSess,trialName);
        fprintf('---\nProcessing %s (Trial %d)\n',trialName,trialID);

        % 5c) open the trial in Nexus (if not already open)
        if ~dataMotion.openTrialIfNeeded(pathTrial,vicon)
            warning('  • Could not open %s. Skipping.\n',trialName);
            continue;   % skip trial if coule not be opened
        end

        % 5d) run the "Reconstruct And Label Test" pipeline (batch mode)
        fprintf('  • Running pipeline with 3D Predictions = %d...\n',use3D);
        try                 % try running reconstruct and label pipeline
            vicon.RunPipeline('Reconstruct And Label Test','',200);
        catch ME
            warning(ME.identifier,'  • Nexus.RunPipeline failed: %s\n', ...
                ME.message);
            continue;
        end

        % 5e) get subject name (assuming only one subject in the trial)
        subject = vicon.GetSubjectNames();
        if isempty(subject)
            warning('  • No subject found in %s. Skipping.\n',trialName);
            continue;
        end
        subject = subject{1};

        % 5f) retrieve all marker names for this subject
        allMarkers = vicon.GetMarkerNames(subject);
        numMarkers   = numel(allMarkers);
        if numMarkers == 0
            warning('  • No markers found for subject %s. Skipping.\n',subject);
            continue;
        end

        % 5g) preallocate temporary arrays to store per-marker metrics
        dropPctArr       = zeros(nMarkers,1);  % percentage of missing frames
        numGapsArr       = zeros(nMarkers,1);  % number of gap events
        maxGapLenArr     = zeros(nMarkers,1);  % largest gap length for each marker
        isInSubsetMask   = false(nMarkers,1);

        % 5h) For each marker: grab trajectory, compute missing‐frames & gaps
        for mrkr = 1:numMarkers         % for each marker, ...
            nameMarker = allMarkers{mrkr};
            isInSubsetMask(mrkr) = any(strcmp(nameMarker,subsetMarkers));

            try
                [~,~,~,existsTraj] = ...
                    vicon.GetTrajectory(subject,nameMarker);
                % existsTraj is logical vector: true=visible, false=occluded
            catch
                warning('    • Could not retrieve trajectory for %s. Treating as fully missing.\n',nameMarker);
                existsTraj = false(vicon.GetFrameCount(),1);
            end

            totalFrames = numel(existsTraj);
            numMissing    = sum(~existsTraj);
            dropPctArr(mrkr) = (numMissing / totalFrames) * 100;

            % find runs of consecutive missing frames:
            missingFlags = ~existsTraj;          % true = a missing frame
            dv = diff([0; missingFlags; 0]);
            runBoundaries = find(dv~=0);         % changes
            runLengths    = diff(runBoundaries); % lengths of each run (present and missing)
            runValues     = dv(runBoundaries);   % +1=run of missing starts, -1=ends
            gapRuns       = runLengths(runValues==1);  % only lengths where runValues==+1
            numGapsArr(mrkr)   = numel(gapRuns);
            if isempty(gapRuns)
                maxGapLenArr(mrkr) = 0;
            else
                maxGapLenArr(mrkr) = max(gapRuns);
            end

            % 5i) compute aggregate measures over ALL markers
            DropPct_All          = mean(dropPctArr);
            NumGapsPerMarker_All = sum(numGapsArr) / nMarkers;
            MaxGapLength_All     = max(maxGapLenArr);

            % 5j) compute aggregate measures over SUBSET markers
            subsetIdx = find(isInSubsetMask);
            if isempty(subsetIdx)
                % if subset markers not found, set NaN:
                DropPct_Subset          = NaN;
                NumGapsPerMarker_Subset = NaN;
                MaxGapLength_Subset     = NaN;
            else
                DropPct_Subset          = mean(dropPctArr(subsetIdx));
                NumGapsPerMarker_Subset = sum(numGapsArr(subsetIdx)) / numel(subsetIdx);
                MaxGapLength_Subset     = max(maxGapLenArr(subsetIdx));
            end

            % 5k) Append a single row to "results"
            results(end+1) = struct( ...
                'TrialID',                trialID, ...
                'SubjectName',            subject, ...
                'Use3DPredictions',       use3D, ...
                'DropPct_All',            DropPct_All, ...
                'NumGapsPerMarker_All',   NumGapsPerMarker_All, ...
                'MaxGapLength_All',       MaxGapLength_All, ...
                'DropPct_Subset',         DropPct_Subset, ...
                'NumGapsPerMarker_Subset',NumGapsPerMarker_Subset, ...
                'MaxGapLength_Subset',    MaxGapLength_Subset ...
                );

            fprintf('    • 3D=%d → DropPct_All=%.2f%%, Gaps/Marker_All=%.2f, MaxGap_All=%d frames\n', ...
                use3D, DropPct_All, NumGapsPerMarker_All, MaxGapLength_All);
            fprintf('      Subset → DropPct=%.2f%%, Gaps/Marker=%.2f, MaxGap=%d frames\n', ...
                DropPct_Subset, NumGapsPerMarker_Subset, MaxGapLength_Subset);
        end
    end
end

%% 6) Save Summary Results to a CSV File
T = struct2table(results);
writetable(T,pathOutCSV);
fprintf('\nQC complete. Summary written to:\n   %s\n',pathOutCSV);


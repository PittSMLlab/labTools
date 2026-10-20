%% Optimizing Reconstruct & Label Pipeline
% Script. Runs, for every Trial*.x1d under pathSess: the pre-pattern
% Nexus pipeline (RLPrePatternFill), a custom MATLAB pattern fill
% (runCustomPatternFill with getPatternFillReferenceMap), and the
% post-pattern Nexus pipeline (RLPostPatternFill).
%
% Inputs:
%   none - edit pathSess and pathOutCSV below
%
% Outputs:
%   none - results is preallocated for per-trial gap summaries but is
%          not filled or written (pathOutCSV is currently unused)
%
% Side effects: needs a running Vicon Nexus; opens, processes, and saves
%   every trial found under pathSess (the saved trials are overwritten).
%
% Toolbox Dependencies: None (Vicon Nexus SDK, ViconNexus class)
%
% See also GETPATTERNFILLREFERENCEMAP, RUNCUSTOMPATTERNFILL, PART1RL,
% DATAMOTION.OPENTRIALIFNEEDED.

%% 1) Define Paths & Trial List

pathSess   = 'Z:\Nathan\ViconNexusReconstructAndLabel\Vicon\';
pathOutCSV = ...
    'Z:\Nathan\ViconNexusReconstructAndLabel\ShanthiTry_Results.csv';

trialFiles = dir(fullfile(pathSess, '**', 'Trial*.x1d'));
if isempty(trialFiles)
    error('No trials found in session folder: %s\n', pathSess);
end

[~, namesFiles] = cellfun(@fileparts, {trialFiles.name}, ...
    'UniformOutput', false);
indsTrials = cellfun(@(s) str2double(s(end-1:end)), namesFiles);

%% 2) Initialize Vicon Nexus SDK & Prepare the Results Container Structure

try
    vicon = ViconNexus();   % assumes ViconNexus() is on the MATLAB path
catch ME
    error('Could not initialize Vicon Nexus SDK. \n%s', ME.message);
end
% preallocate a struct array to hold summary results:
%   • ParticipantName               (string)
%   • TrialID                       (e.g., 1, 2, …)
%   • Use3DPredictions              (logical)
%   • EnvironmentalDriftTolerance	(numeric)
%   • MinCamerasToStartTraj         (unsigned integer)
%   • MinCamerasToContTraj          (unsigned integer)
%   • PercentMissing_All            (numeric)
%   • NumGapsPerMarker_All          (numeric)
%   • MaxGapLength_All              (numeric)
%   • MedianGapLength_All           (numeric)
%   • PercentMissing_Subset         (numeric)
%   • NumGapsPerMarker_Subset       (numeric)
%   • MaxGapLength_Subset           (numeric)
%   • MedianGapLength_Subset        (numeric)
results = struct( ...
    'ParticipantName',              {}, ...
    'TrialID',                      {}, ...
    'Use3DPredictions',             {}, ...
    'EnvironmentalDriftTolerance',  {}, ...
    'MinCamerasToStartTraj',        {}, ...
    'MinCamerasToContTraj',         {}, ...
    'PercentMissing_All',           {}, ...
    'NumGapsPerMarker_All',         {}, ...
    'MaxGapLength_All',             {}, ...
    'MedianGapLength_All',          {}, ...
    'PercentMissing_Subset',        {}, ...
    'NumGapsPerMarker_Subset',      {}, ...
    'MaxGapLength_Subset',          {}, ...
    'MedianGapLength_Subset',       {} ...
    );

%% 3) Loop through Trials and Apply Pre-Pattern Nexus Pipeline

for ii = 1:numel(trialFiles)
    trialName = trialFiles(ii).name;
    trialPath = fullfile(trialFiles(ii).folder, trialFiles(ii).name);

    fprintf('---Running RLPrePatternFill on %s ---\n', trialName);
    try
        if ~dataMotion.openTrialIfNeeded(trialPath, vicon)
            warning('  • Could not open %s. Skipping.\n', trialName);
            continue;
        end
        %vicon.OpenTrial(trialPath);
        %pause(2);

        pipelinePath = fullfile('C:', 'Users', 'Public', 'Documents', ...
            'Vicon', 'Nexus2.x', 'Configurations', 'Pipelines', ...
            'RLPrePatternFill.Pipeline');
        vicon.RunPipeline(pipelinePath, '', 200);
        pause(1);

        vicon.SaveTrial();
        vicon.CloseTrial();
        fprintf('Trial %s processed and saved successfully.\n', trialName);

    catch ME
        warning('Error processing trial %s: %s', trialName, ME.message);
        continue
    end
end

%% 4) Custom Pattern Fill via MATLAB

refMap = getPatternFillReferenceMap();

for ii = 1:numel(trialFiles)
    trialName = trialFiles(ii).name;
    trialPath = fullfile(trialFiles(ii).folder, trialFiles(ii).name);

    fprintf('---Running custom Pattern Fill on %s ---\n', trialName);
    try
        vicon.OpenTrial(trialPath);
        pause(1);

        runCustomPatternFill(vicon, refMap);
        pause(1);

        vicon.SaveTrial(200);
        vicon.CloseTrial();
        fprintf('Pattern fill completed and trial saved: %s\n', trialName);
    catch ME
        warning('Error during pattern fill for trial %s: %s', ...
            trialName, ME.message);
        continue;
    end
end

%% 5) Post-Pattern Processing

for ii = 1:numel(trialFiles)
    trialName = trialFiles(ii).name;
    trialPath = fullfile(trialFiles(ii).folder, trialFiles(ii).name);

    fprintf('---Running post-pattern pipeline on %s ---\n', trialName);
    try
        vicon.OpenTrial(trialPath);
        pause(1);

        vicon.RunPipeline('RLPostPatternFill', '', 200);
        pause(1);

        vicon.SaveTrial();
        vicon.CloseTrial();
        fprintf('Post-pattern pipeline complete %s\n', trialName);
    catch ME
        warning('Error during post pattern processing for %s: %s', ...
            trialName, ME.message);
        continue;
    end
end

%% Take 1 at Optimizing Reconstruct & Label Pipeline
% author: SB
% date (created): 13 May 2025

%% 1) Define Paths & Trial List
pathSess   = 'Z:\Nathan\ViconNexusReconstructAndLabel\Vicon\';
pathOutCSV = 'Z:\Nathan\ViconNexusReconstructAndLabel\ShanthiTry_Results.csv';

% get all trial files that start with 'Trial' and end in '.x1d'
trialFiles = dir(fullfile(pathSess,'**', 'Trial*.x1d'));
if isempty(trialFiles)                      % if no trial files found, ...
    error('No trials found in session folder: %s\n',pathSess);
end

% extract numeric trial indices from filenames (assumes 'TrialXX.x1d')
[~,namesFiles] = cellfun(@fileparts,{trialFiles.name}, ...
    'UniformOutput',false);
indsTrials = cellfun(@(s) str2double(s(end-1:end)),namesFiles);

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
    'EnvironmentalDriftTolerance',	{}, ...
    'MinCamerasToStartTraj',        {}, ...
    'MinCamerasToContTraj',         {}, ...
    'PercentMissing_All',           {}, ...
    'NumGapsPerMarker_All',         {}, ...
    'MaxGapLength_All',             {}, ...
    'MedianGapLength_All',          {}, ...
    'PercentMissing_Subset',        {}, ...
    'NumGapsPerMarker_Subset',      {}, ...
    'MaxGapLength_Subset',          {}, ...
    'MedianGapLength_Subset',          {} ...
    );

%% 3) Loop through Trials and Apply Pre-Pattern Nexus Pipeline

for i = 1:numel(trialFiles)
    trialName = trialFiles(i).name;
    trialPath = fullfile(trialFiles(i).folder, trialFiles(i).name);
    
    fprintf('---Running RLPrePatternFill on %s ---\n', trialName);
    try 
        %Open Trial
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

        vicon.SaveTrial;
        vicon.CloseTrial;
        fprintf('Trial %s processed and saved successfully.\n', trialName);
    
    catch ME
        warning('Error processing trial %s: %s', trialName, ME.message);
        continue
    end
end

%% 4) Custom Pattern Fill via MATLAB

refMap = getPatternFillReferenceMap();

for i = 1:numel(trialFiles)
    trialName = trialFiles(i).name;
    trialPath = fullfile(trialFiles(i).folder, trialFiles(i).name);
    
    fprintf('---Running custom Pattern Fill on %s ---\n', trialName);
    try
        %Open trial again if not already open
        vicon.OpenTrial(trialPath);
        pause(1);
        
        runCustomPatternFill(vicon, refMap);
        pause(1)
        
        vicon.SaveTrial(200);
        vicon.CloseTrial;
        fprintf('Pattern fill completed and trial saved: %s\n', trialName);
    catch ME
        warning('Error during pattern fill for trial %s: %s', trialName, ME.message);
        continue;
    end
end

%% 5) Post-Pattern Processing 

for i = 1:numel(trialFiles)
    trialName = trialFiles(i).name;
    trialPath = fullfile(trialFiles(i).folder, trialFiles(i).name);
    
    fprintf('---Running post-pattern pipeline on %s ---\n', trialName);
    try
        vicon.OpenTrial(trialPath);
        pause(1);
        
        vicon.RunPipeline('RLPostPatternFill', '', 200);
        pause(1);
        
        vicon.SaveTrial;
        vicon.CloseTrial;
        fprintf('Post-pattern pipeline complete %s\n', trialName);
    catch ME
        warning('Error during post pattern processing for %s: %s', trialName, ME.message);
        continue;
    end
end    
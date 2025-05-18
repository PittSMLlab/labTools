%% Determine the Optimal Reconstruct & Label Pipeline Parameters
% author: NWB
% date (created): 18 May 2025
% purpose: to iterate through various Vicon Nexus 'Reconstruct & Label'
% pipeline parameters to determine the optimal configuration based on
% various metrics.

% TODO:
%   1. Loop through exemplar trials from all SML Lab studies or study types
%   2. Save RGT, LGT, RANK, LANK marker trajectories in MAT file for later
%       analysis just in case
%   3. Generate and save trajectory figures for GT and ANK markers

%% Define Data Path, Identify Trials to Process, & Initialize SDK
pathSess = 'Z:\Nathan\ViconNexusReconstructAndLabel';
% get all trial files that start with 'Trial'
trialFiles = dir(fullfile(pathSess,'Trial*.x1d'));
if isempty(trialFiles)      % if no trial files found, ...
    fprintf('No trials found in session folder: %s\n',pathSess);
    return;
end

% extract trial indices from filenames
[~,namesFiles] = cellfun(@fileparts,{trialFiles.name}, ...
    'UniformOutput',false);
indsTrials = cellfun(@(s) str2double(s(end-1:end)),namesFiles);

% initialize the Vicon Nexus object
vicon = ViconNexus();

%% Process All Trials
% define reference and target markers for pattern-based gap filling
markersRef = {'GT','KNEE','GT','ANK'};

for tr = indsTrials     % for each trial specified, ...
    pathTrial = fullfile(pathSess,sprintf('Trial%02d',tr));
    fprintf('Processing trial %d: %s\n',tr,pathTrial);

    % open the trial if needed
    if ~dataMotion.openTrialIfNeeded(pathTrial,vicon)
        return;     % exit if the trial could not be opened
    end

    % The reconstruct and label step will process the raw camera data and
    % reconstruct 3D marker positions. The labeling step assigns names to
    % the reconstructed markers based on the Vicon Nexus labeling scheme.
    fprintf('Running reconstruction and labeling pipeline...\n');
    try                     % try running reconstruct and label pipeline
        vicon.RunPipeline('Reconstruct And Label','',200);
        fprintf('Reconstruction and labeling complete.\n');
    catch ME
        warning(ME.identifier,'%s',ME.message);
    end

    % extract marker gaps to be filled
    markerGaps = dataMotion.extractMarkerGapsTrial(pathTrial,vicon);

    fprintf('Saving trial %d: %s\n',tr,pathTrial);
    try
        vicon.SaveTrial(200);
        fprintf('Trial saved successfully.\n');
    catch ME
        warning(ME.identifier,'%s',ME.message);
    end
end


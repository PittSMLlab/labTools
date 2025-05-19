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
pathSess = 'Z:\Nathan\ViconNexusReconstructAndLabel\Vicon\';
pathOutCSV = 'Z:\Nathan\ViconNexusReconstructAndLabel\';
% get all trial files that start with 'Trial'
trialFiles = dir(fullfile(pathSess,'Trial*.x1d'));
if isempty(trialFiles)                      % if no trial files found, ...
    fprintf('No trials found in session folder: %s\n',pathSess);
    return;
end

results = struct('Trial',{},'Subject',{},'Marker',{}, ...
    'DropPct',{},'NumGaps',{},'MaxGapLength',{});

% extract trial indices from filenames
[~,namesFiles] = cellfun(@fileparts,{trialFiles.name}, ...
    'UniformOutput',false);
indsTrials = cellfun(@(s) str2double(s(end-1:end)),namesFiles);

% initialize the Vicon Nexus object
vicon = ViconNexus();

%% Specify Set of Reconstruct & Label Parameters to Loop Through
predict3D = [true false];
envDriftTolerance = 1.5; % 0.5:1.0:2.5;
minCamerasToStartTraj = 3; % 2:3;
minCamerasToContTraj = 2; % 1:2;
minSeparation = 14; % 14:5:34;
minCentroidRadius = 0; % 0:2:4;
maxCentroidRadius = 50; % 30:10:50;
% create set of parameter combinations
paramSets = allcomb(predict3D,envDriftTolerance, ...
    minCamerasToStartTraj,minCamerasToContTraj,minSeparation, ...
    minCentroidRadius,maxCentroidRadius);
numParamSets = size(paramSets,1);           % number of parameter sets

%%
pipelineFile = ['C:\Users\Public\Documents\Vicon\Nexus2.x\' ...
    'Configurations\Pipelines\Reconstruct And Label Test.Pipeline'];
% load the test 'Reconstruct And Label' pipeline text file for editing
params = readlines(pipelineFile);
ind3DPredict = contains(params,'3DPredictions');

for set = 1:numParamSets                    % for each parameter set, ...
    % update parameter strings in pipeline XML file
    if paramSets(set,1)                     % if 3D predictions on, ...
        params(ind3DPredict) = "      <Param name=""Reconstructor.3DPredictions"" value=""true""/>";
    else
        params(ind3DPredict) = "      <Param name=""Reconstructor.3DPredictions"" value=""false""/>";
    end

    % overwrite pipeline XML file with current parameter set
    % if MATLAB R2022a or later
    % writelines(params,pipelineFile);
    fid = fopen(pipelineFile,'w');          % open the file to overwrite
    for line = 1:numel(params)              % for each line in file, ...
        fprintf(fid,'%s\n',params(line));   % overwrite it
    end
    fclose(fid);                            % close file

    % process all trials
    for tr = indsTrials     % for each trial specified, ...
        pathTrial = fullfile(pathSess,sprintf('Trial%02d',tr));
        fprintf('Processing trial %d: %s\n',tr,pathTrial);

        % open the trial if needed
        if ~dataMotion.openTrialIfNeeded(pathTrial,vicon)
            return;     % exit if the trial could not be opened
        end

        % The reconstruct and label step processes raw camera data and
        % reconstructs 3D marker positions. The labeling step assigns names
        % to reconstructed markers based on Vicon Nexus labeling scheme.
        fprintf('Running reconstruction and labeling pipeline...\n');
        try                 % try running reconstruct and label pipeline
            vicon.RunPipeline('Reconstruct And Label Test','',200);
            fprintf('Reconstruction and labeling complete.\n');
        catch ME
            warning(ME.identifier,'%s',ME.message);
        end

        % get subject name (assuming only one subject in the trial)
        subject = vicon.GetSubjectNames();
        if isempty(subject)
            error('No subject found in the trial.');
        end
        subject = subject{1};

        markers = vicon.GetMarkerNames(subject);    % retrieve all markers
        if isempty(markers)             % if empty array of markers, ...
            warning('No markers found for the subject in the trial.');
            return;
        end

        for mrkr = 1:numel(markers)         % for each marker, ...
            nameMarker = markers{mrkr};     % get marker name
            try
                [xTraj,yTraj,zTraj,existsTraj] = ...
                    vicon.GetTrajectory(subject,nameMarker);
            catch
                warning(['Failed to retrieve trajectory for marker %s.' ...
                    ' Skipping...'],nameMarker);
                continue;
            end

            % identify gaps as sequences where trajExists is false
            indsGap = find(~existsTraj);
            if isempty(indsGap)             % if no gaps for a marker, ...
                continue;
            end

            % identify start and end indices of each trajectory gap
            gapsStarts = indsGap([true diff(indsGap) > 1])';
            gapsEnds = indsGap([diff(indsGap) > 1 true])';

            % compute metrics
            dropPct = (sum(~existsTraj) / numel(existsTraj)) * 100;
            numGaps = numel(gapsStarts);
            gapMax = max(diff([gapsStarts gapsEnds]));

            % append to results
            results(end+1) = struct(...
                'Trial',       trialName, ...
                'Subject',     subject, ...
                'Marker',      marker, ...
                'DropPct',     dropPct, ...
                'NumGaps',     numGaps, ...
                'MaxGapLength',maxG);
        end
    end
end

%% Save Results to a CSV File
T = struct2table(results);
writetable(T,pathOutCSV);
fprintf('QC complete. Results written to %s.\n',pathOutCSV);


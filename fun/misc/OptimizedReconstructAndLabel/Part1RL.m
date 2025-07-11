function mrkrTrajs = Part1RL(trialPath)

    % pathTrial = 'Z:\Nathan\ViconNexusReconstructAndLabel\Vicon\C3S24_S1\Trial16';

    fprintf('Connecting to Vicon Nexus...\n');
    newVicon = ViconNexus();

    % --- Open Trial ---
    fprintf('Opening trial: %s\n', trialPath);
    if ~dataMotion.openTrialIfNeeded(trialPath, newVicon)
        warning('Could not open trial. Exiting. \n');
        mrkrTrajs = struct(); return;
    end

    pause(5);
    
    mrkrTrajs = struct();

    [~, trialName] = fileparts(trialPath);
    fprintf('\n--- Processing trial: %s ---\n', trialName);

    % ---Step 1a: Run Pre-Pattern Pipeline (R&L)---
    fprintf('Running RLPrePatternFill1 pipeline...\n');
    %pipelinePath = 'C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\Pipelines\RLPrePatternFill1';
    try
        %newVicon.RunPipeline(pipelinePath, '', 200);
        newVicon.RunPipeline('RLPrePatternFill1','',200);
        pause(1);
        mrkrTrajs.Step1RandL = getRelevantMrkrTrajs(newVicon);
        fprintf('Pre-pattern fill 1 complete.\n');
    catch ME
        warning('Failed to run RLPrePatternFill: %s', ME.message);
    end
    
        % ---Step 1b: Run Pre-Pattern Pipeline (Woltring)---
    fprintf('Running RLPrePatternFill2 pipeline...\n');
    %pipelinePath = 'C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\Pipelines\RLPrePatternFill1';
    try
        %newVicon.RunPipeline(pipelinePath, '', 200);
        newVicon.RunPipeline('RLPrePatternFill2','',200);
        pause(1);
        mrkrTrajs.Step2Woltring = getRelevantMrkrTrajs(newVicon);
        fprintf('Pre-pattern fill 2 complete.\n');
    catch ME
        warning('Failed to run RLPrePatternFill: %s', ME.message);
    end

    % ---Step 2: Custom Pattern Fill

    % define reference and target markers for pattern-based gap filling
    markersRef = {'GT','KNEE','GT','ANK'};
    markersTarg = {
        {'ASIS','PSIS','THI','KNEE'}, ...
        {'GT','ANK'}, ...
        {'ASIS','PSIS','THI','KNEE'}, ...
        {'SHANK','HEEL','TOE'}
        };

    % extract marker gaps to be filled
    markerGaps = dataMotion.extractMarkerGapsTrial(trialPath,newVicon);

    % fill small marker gaps using spline interpolation
%     markerGaps = dataMotion.fillSmallMarkerGapsSpline(markerGaps, trialPath,newVicon,false);

    % fill gaps using pattern fill for each reference marker
    for ref = 1:numel(markersRef)       % for each reference marker, ...
        refMarker = markersRef{ref};    % retrieve reference marker name
        targetMarkers = markersTarg{ref};

        % Call the helper function to process each ref marker group
        markerGaps = fillMarkerGapsPatternSpecifiedTargets( ...
            markerGaps,targetMarkers,refMarker,trialPath,newVicon);
    end
    
    pause(1);
    mrkrTrajs.Step3Pattern = getRelevantMrkrTrajs(newVicon);

%     fprintf('Saving trial %d: %s\n',trialName,trialPath);
%     try
%         newVicon.SaveTrial(200);
%         fprintf('Trial saved successfully.\n');
%     catch ME
%         warning(ME.identifier,'%s',ME.message);
%     end

    % ---Step 3: Run Post-Pattern Pipeline ---
    fprintf('Running RLPostPatternFill pipeline...\n');
    %pipelinePath = 'C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\Pipelines\RLPostPatternFill';
    try
        %vicon.RunPipeline(pipelinePath, '', 200);
        newVicon.RunPipeline('RLPostPatternFill','',200);
        pause(1);
        mrkrTrajs.Step4Butterworth = getRelevantMrkrTrajs(newVicon);
        fprintf('Post-pattern fill complete.\n');
    catch ME
        warning('Failed to run RLPostPatternFill: %s', ME.message);
    end

    fprintf('Saving trial %d: %s\n',trialName,trialPath);
     try
         newVicon.SaveTrial(200);
         fprintf('Trial saved successfully.\n');
     catch ME
         warning(ME.identifier,'%s',ME.message);
     end
    
end

%% Helper function
function markerGaps = fillMarkerGapsPatternSpecifiedTargets( ...
    markerGaps,targetMarkers,refMarker,trialPath,newVicon)
%PROCESSREFERENCEMARKERGAPS Process marker gaps for a reference marker
%   Helper function to perform a pattern-based fill of marker gaps for
% specified target markers and a referencefor right and left markers.

sides = {'R','L'};
for i = 1:numel(sides)
    sidePrefix = sides{i};
    gaps = struct();

    % collect gaps for the target markers
    for j = 1:numel(targetMarkers)
        markerName = [sidePrefix targetMarkers{j}];
        if isfield(markerGaps,markerName)
            gaps.(markerName) = markerGaps.(markerName);
        end
    end

    % skip if no gaps to process
    if isempty(fieldnames(gaps))
        continue;
    end

    % fill gaps using pattern-based method
    remainingGaps = dataMotion.fillMarkerGapsPattern( ...
        gaps,trialPath,[sidePrefix refMarker],newVicon,false);

    % update the marker gaps structure with the remaining gaps
    markerNames = fieldnames(remainingGaps);
    for k = 1:numel(markerNames)
        markerGaps.(markerNames{k}) = remainingGaps.(markerNames{k});
    end
end
end
%% Get the trajectories
function mrkrTrajs = getRelevantMrkrTrajs(newVicon)

mrkrsRelevant = {'RGT','LGT','RANK','LANK'};
mrkrTrajs = struct();

subjects = newVicon.GetSubjectNames();
if isempty(subjects)
    warning('No subject found in trial.'); mrkrTrajs = struct(); return;
end
subject = subjects{1};

for i = 1:numel(mrkrsRelevant)
    marker = mrkrsRelevant{i};
    [trajX, trajY, trajZ, existsTraj] = newVicon.GetTrajectory(subject, marker);
    
    trajX(~existsTraj) = NaN;
    trajY(~existsTraj) = NaN;
    trajZ(~existsTraj) = NaN;
    
    mrkrTrajs.(marker) = [trajX(:), trajY(:), trajZ(:)];%, double(exists(:))];
end
% for mrkr = mrkrsRelevant
%     [trajX,trajY,trajZ,exists] = newVicon.getTrajectory(mrkrsRelevant{mrkr});
%     mrkrTrajs.(mrkrsRelevant{mrkr}) = [trajX; trajY; trajZ; double(exists)];
% end
end
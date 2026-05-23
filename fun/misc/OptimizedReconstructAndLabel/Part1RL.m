function mrkrTrajs = Part1RL(trialPath)
%PART1RL Run full reconstruct, label, and pattern-fill pipeline on a trial.
%
%   Connects to Vicon Nexus, opens the specified trial, runs the
% pre-pattern pipelines (R&L and Woltring), applies custom pattern-based
% gap filling, then runs the post-pattern pipeline and saves the result.
% Returns marker trajectories captured at each processing stage.
%
% Inputs:
%   trialPath - Full path to the trial folder (string)
%
% Outputs:
%   mrkrTrajs - Struct with fields Step1RandL, Step2Woltring,
%               Step3Pattern, and Step4Butterworth; each contains
%               lower-limb marker trajectories at that stage
%
% Toolbox Dependencies: None
%
% See also PROCESSANDFILLMARKERGAPSTRIAL, RECONSTRUCTANDLABELTRIAL.

% pathTrial = 'Z:\Nathan\ViconNexusReconstructAndLabel\Vicon\C3S24_S1\Trial16';

fprintf('Connecting to Vicon Nexus...\n');
newVicon = ViconNexus();

fprintf('Opening trial: %s\n', trialPath);
if ~dataMotion.openTrialIfNeeded(trialPath, newVicon)
    warning('Could not open trial. Exiting. \n');
    mrkrTrajs = struct();
    return;
end

pause(5);

mrkrTrajs = struct();

[~, trialName] = fileparts(trialPath);
fprintf('\n--- Processing trial: %s ---\n', trialName);

%% Step 1a — Pre-pattern pipeline (Reconstruct & Label)

fprintf('Running RLPrePatternFill1 pipeline...\n');
%pipelinePath = 'C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\Pipelines\RLPrePatternFill1';
try
    %newVicon.RunPipeline(pipelinePath, '', 200);
    newVicon.RunPipeline('RLPrePatternFill1', '', 200);
    pause(1);
    mrkrTrajs.Step1RandL = getRelevantMrkrTrajs(newVicon);
    fprintf('Pre-pattern fill 1 complete.\n');
catch ME
    warning('Failed to run RLPrePatternFill: %s', ME.message);
end

%% Step 1b — Pre-pattern pipeline (Woltring)

fprintf('Running RLPrePatternFill2 pipeline...\n');
%pipelinePath = 'C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\Pipelines\RLPrePatternFill1';
try
    %newVicon.RunPipeline(pipelinePath, '', 200);
    newVicon.RunPipeline('RLPrePatternFill2', '', 200);
    pause(1);
    mrkrTrajs.Step2Woltring = getRelevantMrkrTrajs(newVicon);
    fprintf('Pre-pattern fill 2 complete.\n');
catch ME
    warning('Failed to run RLPrePatternFill: %s', ME.message);
end

%% Step 2 — Custom pattern fill

markersRef  = {'GT', 'KNEE', 'GT', 'ANK'};
markersTarg = { ...
    {'ASIS', 'PSIS', 'THI', 'KNEE'}, ...
    {'GT', 'ANK'}, ...
    {'ASIS', 'PSIS', 'THI', 'KNEE'}, ...
    {'SHANK', 'HEEL', 'TOE'} ...
};

markerGaps = dataMotion.extractMarkerGapsTrial(trialPath, newVicon);

%     markerGaps = dataMotion.fillSmallMarkerGapsSpline(markerGaps, trialPath,newVicon,false);

for ref = 1:numel(markersRef)
    refMarker     = markersRef{ref};
    targetMarkers = markersTarg{ref};
    markerGaps    = fillMarkerGapsPatternSpecifiedTargets( ...
        markerGaps, targetMarkers, refMarker, trialPath, newVicon);
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

%% Step 3 — Post-pattern pipeline

fprintf('Running RLPostPatternFill pipeline...\n');
%pipelinePath = 'C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\Pipelines\RLPostPatternFill';
try
    %vicon.RunPipeline(pipelinePath, '', 200);
    newVicon.RunPipeline('RLPostPatternFill', '', 200);
    pause(1);
    mrkrTrajs.Step4Butterworth = getRelevantMrkrTrajs(newVicon);
    fprintf('Post-pattern fill complete.\n');
catch ME
    warning('Failed to run RLPostPatternFill: %s', ME.message);
end

fprintf('Saving trial %s: %s\n', trialName, trialPath);
try
    newVicon.SaveTrial(200);
    fprintf('Trial saved successfully.\n');
catch ME
    warning(ME.identifier, '%s', ME.message);
end

end

function markerGaps = fillMarkerGapsPatternSpecifiedTargets( ...
        markerGaps, targetMarkers, refMarker, trialPath, newVicon)
%FILLMARKERGAPSPATTERNSPECIFIEDTARGETS Pattern-fill gaps for a marker group.
%
%   For each side (R/L), collects gaps for the specified target markers
% and fills them using the given reference marker via pattern-based gap
% filling. Updates markerGaps with any remaining unfilled gaps.
%
% Inputs:
%   markerGaps    - Struct mapping marker names to gap arrays
%   targetMarkers - Cell array of marker name suffixes to fill
%   refMarker     - Reference marker name suffix
%   trialPath     - Full path to the trial folder
%   newVicon      - Vicon Nexus SDK object
%
% Outputs:
%   markerGaps - Updated struct with remaining gaps after filling

sides = {'R', 'L'};
for ii = 1:numel(sides)
    sidePrefix = sides{ii};
    gaps = struct();

    for jj = 1:numel(targetMarkers)
        markerName = [sidePrefix targetMarkers{jj}];
        if isfield(markerGaps, markerName)
            gaps.(markerName) = markerGaps.(markerName);
        end
    end

    if isempty(fieldnames(gaps))
        continue;
    end

    remainingGaps = dataMotion.fillMarkerGapsPattern( ...
        gaps, trialPath, [sidePrefix refMarker], newVicon, false);

    markerNames = fieldnames(remainingGaps);
    for kk = 1:numel(markerNames)
        markerGaps.(markerNames{kk}) = remainingGaps.(markerNames{kk});
    end
end

end

function mrkrTrajs = getRelevantMrkrTrajs(newVicon)
%GETRELEVANTMRKRTRAJS Retrieve key lower-limb marker trajectories.
%
%   Queries the Vicon Nexus SDK for RGT, LGT, RANK, and LANK marker
% trajectories and returns them as an N×3 matrix per marker with NaN
% for missing frames.
%
% Inputs:
%   newVicon  - Vicon Nexus SDK object
%
% Outputs:
%   mrkrTrajs - Struct with one N×3 field per relevant marker

mrkrsRelevant = {'RGT', 'LGT', 'RANK', 'LANK'};
mrkrTrajs     = struct();

subjects = newVicon.GetSubjectNames();
if isempty(subjects)
    warning('No subject found in trial.');
    mrkrTrajs = struct();
    return;
end
subject = subjects{1};

for mrkr = 1:numel(mrkrsRelevant)
    marker = mrkrsRelevant{mrkr};
    [trajX, trajY, trajZ, existsTraj] = ...
        newVicon.GetTrajectory(subject, marker);
    trajX(~existsTraj) = NaN;
    trajY(~existsTraj) = NaN;
    trajZ(~existsTraj) = NaN;
    mrkrTrajs.(marker) = [trajX(:), trajY(:), trajZ(:)];
end
% for mrkr = mrkrsRelevant
%     [trajX,trajY,trajZ,exists] = newVicon.getTrajectory(mrkrsRelevant{mrkr});
%     mrkrTrajs.(mrkrsRelevant{mrkr}) = [trajX; trajY; trajZ; double(exists)];
% end

end

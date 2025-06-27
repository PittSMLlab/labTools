function Part1RL(trialPath)

    pathTrial = 'Z:\Nathan\ViconNexusReconstructAndLabel\Vicon\C3S26_S1\Trial15';

    fprintf('Connecting to Vicon Nexus...\n');
    vicon = ViconNexus();

    % --- Open Trial ---
    fprintf('Opening trial: %s\n', trialPath);
    if ~dataMotion.openTrialIfNeeded(trialPath, vicon)
        warning('Could not open trial. Exiting. \n');
        return;
    end

    pause(5);

    [~, trialName] = fileparts(trialPath);
    fprintf('\n--- Processing trial: %s ---\n', trialName);

    % ---Step 1: Run Pre-Pattern Pipeline ---
    fprintf('Running RLPrePatternFill pipeline...\n');
    %pipelinePath = 'C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\Pipelines\RLPrePatternFill1';
    try
        %vicon.RunPipeline(pipelinePath, '', 200);
        vicon.RunPipeline('RLPrePatternFill1','',200);
        pause(1);
        fprintf('Pre-pattern fill complete.\n');
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
    markerGaps = dataMotion.extractMarkerGapsTrial(trialPath,vicon);

    % fill small marker gaps using spline interpolation
    markerGaps = dataMotion.fillSmallMarkerGapsSpline(markerGaps, trialPath,vicon,false);

    % fill gaps using pattern fill for each reference marker
    for ref = 1:numel(markersRef)       % for each reference marker, ...
        refMarker = markersRef{ref};    % retrieve reference marker name
        targetMarkers = markersTarg{ref};

        % Call the helper function to process each ref marker group
        markerGaps = fillMarkerGapsPatternSpecifiedTargets( ...
            markerGaps,targetMarkers,refMarker,trialPath,vicon);
    end

    fprintf('Saving trial %d: %s\n',trialName,trialPath);
    try
        vicon.SaveTrial(200);
        fprintf('Trial saved successfully.\n');
    catch ME
        warning(ME.identifier,'%s',ME.message);
    end

    % ---Step 3: Run Post-Pattern Pipeline ---
    fprintf('Running RLPostPatternFill pipeline...\n');
    %pipelinePath = 'C:\Users\Public\Documents\Vicon\Nexus2.x\Configurations\Pipelines\RLPostPatternFill';
    try
        %vicon.RunPipeline(pipelinePath, '', 200);
        vicon.RunPipeline('RLPostPatternFill','',200);
        pause(1);
        fprintf('Post-pattern fill complete.\n');
    catch ME
        warning('Failed to run RLPostPatternFill: %s', ME.message);
    end

    % Helper function
    function markerGaps = fillMarkerGapsPatternSpecifiedTargets( ...
        markerGaps,targetMarkers,refMarker,trialPath,vicon)
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
            gaps,trialPath,[sidePrefix refMarker],vicon,false);

        % update the marker gaps structure with the remaining gaps
        markerNames = fieldnames(remainingGaps);
        for k = 1:numel(markerNames)
            markerGaps.(markerNames{k}) = remainingGaps.(markerNames{k});
        end
    end
    end
end
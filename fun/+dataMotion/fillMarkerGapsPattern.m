function markerGapsUpdated = ...
    fillMarkerGapsPattern(markerGaps,pathTrial,refMarker,vicon,shouldSave)
%FILLMARKERGAPSPATTERN Fills marker gaps using reference marker pattern
%   This function fills gaps in all marker trajectories identified in
% markerGaps by applying a transformed pattern from a specified reference
% marker's trajectory over the gap range.
%
% input(s):
%   markerGaps: struct with start and end frame indices of gaps in each
%       marker's trajectory, as obtained from extractMarkerGapsTrial
%   pathTrial: string or character array of the full path to the trial
%   refMarker: name of the reference marker to use for gap filling pattern
%   vicon: (optional) Vicon Nexus SDK object; connects if not supplied
%   shouldSave: (optional) logical, whether to save changes (default: true)
% output(s):
%   updatedMarkerGaps: struct with only remaining gaps after processing

narginchk(3,5);                 % verify correct number of input arguments

if nargin < 5 || isempty(shouldSave)        % if no 'shouldSave' input
    shouldSave = true;                      % default to saving changes
end

% validate 'markerGaps' structure format
markers = fieldnames(markerGaps);
for mrkr = 1:numel(markers)                 % for each marker, ...
    gaps = markerGaps.(markers{mrkr});      % retrieve the 'gaps' array
    if isempty(gaps) || size(gaps,2) ~= 2   % if empty or bad size, ...
        error(['Invalid format in markerGaps for marker %s. Expecting ' ...
            'a non-empty Nx2 matrix.'],markers{mrkr});
    end
end

% initialize the Vicon Nexus object if not provided
if nargin < 4 || isempty(vicon)
    fprintf(['No Vicon SDK object provided. Connecting to Vicon ' ...
        'Nexus...\n']);
    vicon = ViconNexus();
end

% open the trial if not already open
if ~dataMotion.openTrialIfNeeded(pathTrial,vicon)
    return;  % exit if the trial could not be opened
end

% get subject name (assuming only one subject in the trial)
subject = vicon.GetSubjectNames();
if isempty(subject)
    error('No subject found in the trial.');
end
subject = subject{1};

try                                 % get reference marker trajectory data
    [refX,refY,refZ,refExists] = vicon.GetTrajectory(subject,refMarker);
catch
    warning(['Failed to retrieve reference marker (%s) trajectory. ' ...
        'Exiting...'],refMarker);
    markerGapsUpdated = markerGaps;
    return;
end

% process each marker gap in the 'markerGaps' struct
fprintf(['Filling marker gaps using reference marker %s pattern ' ...
    'fill...\n'],refMarker);
wasChanged = false;                     % track whether changes were made

for mrkr = 1:numel(markers)
    nameMarker = markers{mrkr};         % get marker name
    gaps = markerGaps.(nameMarker);     % retrieve gap indices for marker

    try                                 % get marker trajectory data
        [trajX,trajY,trajZ,existsTraj] = ...
            vicon.GetTrajectory(subject,nameMarker);
    catch
        warning(['Failed to retrieve trajectory for marker %s. ' ...
            'Skipping...'],nameMarker);
        continue;
    end

    gapsRemaining = gaps;               % preallocate remaining gaps array
    indNextGap = 1;

    for indGap = 1:size(gaps,1)         % for each target marker gap, ...
        gapStart = gaps(indGap,1);
        gapEnd = gaps(indGap,2);
        indPreGap = gapStart - 1;       % frame before gap
        indPostGap = gapEnd + 1;        % frame after gap

        % skip gap if 'indPreGap' or 'indPostGap' is invalid
        if (indPreGap <= 1) || (indPostGap >= length(refExists))
            fprintf(['Skipping gap from frame %d to %d as pre- or ' ...
                'post-gap index is invalid.\n'],gapStart,gapEnd);
            % keep gaps that can't be filled with reference pattern
            gapsRemaining(indNextGap,:) = gaps(indGap,:);
            indNextGap = indNextGap + 1;
            continue;
        end

        % check if reference trajectory exists over the entire gap range
        if ~all(refExists(indPreGap:indPostGap))
            fprintf(['Skipping gap from frame %d to %d as reference ' ...
                'marker data does not exist for this range.\n'], ...
                gapStart,gapEnd);
            gapsRemaining(indNextGap,:) = gaps(indGap,:);
            indNextGap = indNextGap + 1;
            continue;
        end

        % get reference trajectory values at pre- and post-gap indices
        refPreGapX = refX(indPreGap); refPostGapX = refX(indPostGap);
        refPreGapY = refY(indPreGap); refPostGapY = refY(indPostGap);
        refPreGapZ = refZ(indPreGap); refPostGapZ = refZ(indPostGap);

        % get scaling and offset based on target pre- & post-gap data
        preGapX = trajX(indPreGap); postGapX = trajX(indPostGap);
        preGapY = trajY(indPreGap); postGapY = trajY(indPostGap);
        preGapZ = trajZ(indPreGap); postGapZ = trajZ(indPostGap);

        % calculate scale and offset for pattern adjustment
        scaleX = (postGapX - preGapX) / (refPostGapX - refPreGapX);
        scaleY = (postGapY - preGapY) / (refPostGapY - refPreGapY);
        scaleZ = (postGapZ - preGapZ) / (refPostGapZ - refPreGapZ);

        offsetX = preGapX - refPreGapX * scaleX;
        offsetY = preGapY - refPreGapY * scaleY;
        offsetZ = preGapZ - refPreGapZ * scaleZ;

        % fill gap with adjusted pattern from the reference marker
        refPatternX = refX(gapStart:gapEnd);
        refPatternY = refY(gapStart:gapEnd);
        refPatternZ = refZ(gapStart:gapEnd);

        trajX(gapStart:gapEnd) = refPatternX * scaleX + offsetX;
        trajY(gapStart:gapEnd) = refPatternY * scaleY + offsetY;
        trajZ(gapStart:gapEnd) = refPatternZ * scaleZ + offsetZ;
        existsTraj(gapStart:gapEnd) = true;     % update existence
        wasChanged = true;                      % mark changes made
    end

    % remove any excess preallocated rows in 'gapsRemaining'
    gapsRemaining(indNextGap:end,:) = [];
    if ~isempty(gapsRemaining)          % if there are gaps remaining, ...
        % update 'markerGaps' with only the remaining gaps
        markerGaps.(nameMarker) = gapsRemaining;
    else                                % otherwise, remove marker field
        markerGaps = rmfield(markerGaps,nameMarker);
    end

    % update trajectory in Vicon Nexus
    vicon.SetTrajectory(subject,nameMarker,trajX,trajY,trajZ,existsTraj);
end
fprintf('%s reference pattern-based marker gap filling complete.\n', ...
    refMarker);

% save the trial if changes were made and 'shouldSave' is true
if wasChanged && shouldSave
    fprintf('Saving the trial with changes...\n');
    try
        vicon.SaveTrial(200);
        fprintf('Trial saved successfully.\n');
    catch ME
        warning(ME.identifier,'%s',ME.message);
    end
elseif ~wasChanged
    fprintf('No changes made; trial not saved.\n');
elseif ~shouldSave
    fprintf('Save option is disabled; trial not saved.\n');
end

% output the updated markerGaps with only remaining gaps
markerGapsUpdated = markerGaps;

end


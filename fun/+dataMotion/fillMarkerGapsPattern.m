function markerGapsUpdated = ...
    fillMarkerGapsPattern(markerGaps,pathTrial,refMarker,vicon)
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
% output(s):
%   updatedMarkerGaps: struct with only remaining gaps after processing

narginchk(3,4);         % verify correct number of input arguments

% validate markerGaps structure format
markers = fieldnames(markerGaps);
for i = 1:numel(markers)
    gaps = markerGaps.(markers{i});
    if isempty(gaps) || size(gaps,2) ~= 2
        error(['Invalid format in markerGaps for marker %s. Expecting ' ...
            'a non-empty Nx2 matrix.'],markers{i});
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

try     % get reference marker trajectory data
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
for mrkr = 1:numel(markers)
    nameMarker = markers{mrkr};      % get marker name
    gaps = markerGaps.(nameMarker);  % retrieve gap indices for marker

    try     % get marker trajectory data
        [trajX,trajY,trajZ,existsTraj] = ...
            vicon.GetTrajectory(subject,nameMarker);
    catch
        warning(['Failed to retrieve trajectory for marker %s. ' ...
            'Skipping...'],nameMarker);
        continue;
    end

    % preallocate remaining gaps array
    gapsRemaining = gaps;
    indNextGap = 1;

    for indGap = 1:size(gaps,1)
        gapStart = gaps(indGap,1);
        gapEnd = gaps(indGap,2);

        % check if reference trajectory exists over the gap range
        if all(refExists(gapStart:gapEnd))
            % calculate the pattern from the reference marker
            refPatternX = refX(gapStart:gapEnd);
            refPatternY = refY(gapStart:gapEnd);
            refPatternZ = refZ(gapStart:gapEnd);

            % align reference pattern to target marker’s trajectory
            indPreGap = max(find(existsTraj(1:gapStart-1),1,'last'),1);
            indPostGap = min(find( ...
                existsTraj(gapEnd+1:end),1,'first')+gapEnd,length(trajX));

            % Skip gap if preGapIdx or postGapIdx is empty
            if isempty(indPreGap) || isempty(indPostGap)
                fprintf(['Skipping gap from frame %d to %d as no valid' ...
                    ' pre-gap or post-gap indices exist.\n'], ...
                    gapStart,gapEnd);
                gapsRemaining(indNextGap,:) = gaps(indGap,:);
                indNextGap = indNextGap + 1;
                continue;
            end

            % get scaling and offset based on target pre- & post-gap data
            preGapX = trajX(indPreGap); postGapX = trajX(indPostGap);
            preGapY = trajY(indPreGap); postGapY = trajY(indPostGap);
            preGapZ = trajZ(indPreGap); postGapZ = trajZ(indPostGap);

            % calculate scale and offset for pattern adjustment
            scaleX = (postGapX - preGapX) / ...
                (refPatternX(end) - refPatternX(1));
            scaleY = (postGapY - preGapY) / ...
                (refPatternY(end) - refPatternY(1));
            scaleZ = (postGapZ - preGapZ) / ...
                (refPatternZ(end) - refPatternZ(1));

            offsetX = preGapX - refPatternX(1) * scaleX;
            offsetY = preGapY - refPatternY(1) * scaleY;
            offsetZ = preGapZ - refPatternZ(1) * scaleZ;

            % fill gap with adjusted reference pattern
            trajX(gapStart:gapEnd) = refPatternX * scaleX + offsetX;
            trajY(gapStart:gapEnd) = refPatternY * scaleY + offsetY;
            trajZ(gapStart:gapEnd) = refPatternZ * scaleZ + offsetZ;
            existsTraj(gapStart:gapEnd) = true;     % update existence
        else
            % keep gaps that can't be filled with reference pattern
            gapsRemaining(indNextGap,:) = gaps(indGap,:);
            indNextGap = indNextGap + 1;
        end
    end
    
    % remove any unused preallocated rows in 'gapsRemaining'
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

% saves the changes made back to the trial file
fprintf('Saving the trial...\n');
try
    vicon.SaveTrial(200);
    fprintf('Trial saved successfully.\n');
catch ME
    warning(ME.identifier,'%s',ME.message);
end

% output the updated markerGaps with only remaining gaps
markerGapsUpdated = markerGaps;

end

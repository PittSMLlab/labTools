function markerGapsUpdated = fillSmallMarkerGapsSpline( ...
    markerGaps,pathTrial,vicon,shouldSave,maxGapSize)
%FILLSMALLMARKERGAPSSPLINE Fills small marker trajectory gaps via spline
%   This function fills gaps in all marker trajectories identified in
% markerGaps using spline interpolation for gaps smaller than the specified
% maxGapSize variable. It optionally accepts a Vicon Nexus SDK object.
%
% input(s):
%   markerGaps: struct with start and end frame indices of gaps in each
%       marker's trajectory, as obtained from extractMarkerGapsTrial
%   pathTrial: string or character array of the full path to the trial
%   vicon: (optional) Vicon Nexus SDK object; connects if not supplied
%   shouldSave: (optional) logical, whether to save changes (default: true)
%   maxGapSize: (optional) integer specifying maximum gap size to fill,
%       (default: 10 frames)
% output(s):
%   updatedMarkerGaps: struct with only remaining gaps after processing

% TODO: add a GUI input option if helpful
narginchk(2,5);         % verify correct number of input arguments

% set default value for maxGapSize if not provided
if nargin < 5 || isempty(maxGapSize)
    maxGapSize = 10;
end

if nargin < 4 || isempty(shouldSave)       % if no 'shouldSave' input
    shouldSave = true;                     % default to saving changes
end

% validate 'markerGaps' structure format
markers = fieldnames(markerGaps);
for i = 1:numel(markers)
    gaps = markerGaps.(markers{i});
    if isempty(gaps) || size(gaps,2) ~= 2
        error(['Invalid format in markerGaps for marker %s. Expecting ' ...
            'a non-empty Nx2 matrix.'],markers{i});
    end
end

% initialize the Vicon Nexus object if not provided
if nargin < 3 || isempty(vicon)
    fprintf(['No Vicon SDK object provided. Connecting to Vicon ' ...
        'Nexus...\n']);
    vicon = ViconNexus();
end

% open the trial if not already open
if ~dataMotion.openTrialIfNeeded(pathTrial,vicon)
    return;                         % exit if the trial could not be opened
end

% get subject name (assuming only one subject in the trial)
subject = vicon.GetSubjectNames();
if isempty(subject)
    error('No subject found in the trial.');
end
subject = subject{1};

% process each marker gap in the 'markerGaps' struct
fprintf('Filling small marker gaps with spline interpolation...\n');
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

    % preallocate remaining gaps array based on initial size
    gapsRemaining = gaps;   % store indices of gaps that were not filled
    indNextGap = 1;         % track the index for remaining gaps

    % process and fill gaps smaller than 'maxGapSize'
    for indGap = 1:size(gaps,1)
        gapStart = gaps(indGap,1);
        gapEnd = gaps(indGap,2);
        gapLength = gapEnd - gapStart + 1;

        % fill gap if it is within the allowed 'maxGapSize'
        if gapLength <= maxGapSize && any(existsTraj)
            [trajX,trajY,trajZ,existsTraj] = ...
                fillGap(trajX,trajY,trajZ,existsTraj,gaps(indGap,:));
            wasChanged = true;              % mark changes made
        else
            % retain the gap in 'gapsRemaining' if it exceeds 'maxGapSize'
            % that is, if gap was not filled, add it to 'gapsRemaining'
            gapsRemaining(indNextGap,:) = gaps(indGap,:);
            indNextGap = indNextGap + 1;    % increment gap index
        end
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
fprintf('Small marker gap spline filling complete.\n');

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

function [trajX,trajY,trajZ,existsTraj] = fillGap( ...
    trajX,trajY,trajZ,existsTraj,gapRange)
% FILLGAP Interpolates a gap in a marker trajectory using spline
% input:
%   trajX, trajY, trajZ: trajectories for x, y, and z coordinates
%   existsTraj: logical array indicating frame existence
%   gapRange: 1x2 array with start and end indices of the gap to fill

% frames to process for filling the gap
framesToFill = gapRange(1):gapRange(2);
existingFrames = find(existsTraj);      % get frames with data

% interpolate missing frames
% TODO: consider switching to 'spline' with 'ppval' or 'griddedInterpolant'
% instead of 'interp1' to reduce computation time if duration becomes an
% issue (although results should be identical)
% TODO: consider other interpolation methods ('pchip','cubic','v5cubic',
% 'makima') to see if they have better trajectories (especially for longer
% gaps) in addition to possibly reducing computation time.
trajX(framesToFill) = interp1(existingFrames,trajX(existingFrames), ...
    framesToFill,'spline');
trajY(framesToFill) = interp1(existingFrames,trajY(existingFrames), ...
    framesToFill,'spline');
trajZ(framesToFill) = interp1(existingFrames,trajZ(existingFrames), ...
    framesToFill,'spline');
existsTraj(framesToFill) = true;        % update existence array

end


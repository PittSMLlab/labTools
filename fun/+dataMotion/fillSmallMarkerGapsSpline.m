function markerGapsUpdated = fillSmallMarkerGaps(markerGaps, pathTrial, ...
    vicon, shouldSave, maxGapSize, interpMethod)
%FILLSMALLMARKERGAPSSPLINE Fill small marker gaps by interpolation.
%
%   Fills the gaps listed in markerGaps that are not longer than
% maxGapSize frames, interpolating each trajectory axis with interpMethod.
% Longer gaps are left and returned.
%
% Side effects: needs a running Vicon Nexus (a connection is opened when
%   no vicon object is passed); opens the trial, writes the filled
%   trajectories back to Nexus and, when shouldSave is true and something
%   changed, saves the trial. Errors on a malformed markerGaps struct or
%   a trial without a subject.
%
% Inputs:
%   markerGaps   - struct with one field per marker, each an Nx2 array of
%                  [start end] gap frames (see extractMarkerGapsTrial)
%   pathTrial    - full path to the trial
%   vicon        - (optional) Vicon Nexus SDK object
%   shouldSave   - (optional) logical, save the trial after filling
%                  (default: true)
%   maxGapSize   - (optional) largest gap to fill, in frames (default: 10)
%   interpMethod - (optional) method passed to interp1 (default:
%                  'spline')
%
% Outputs:
%   markerGapsUpdated - struct with only the gaps that remain unfilled
%
% Toolbox Dependencies: None
%
% See also DATAMOTION.EXTRACTMARKERGAPSTRIAL,
%   DATAMOTION.FILLMARKERGAPSPATTERN.

% TODO: add a GUI input option if helpful
narginchk(2,6);         % verify correct number of input arguments

% set default value for maxGapSize if not provided
if nargin < 6 || isempty(interpMethod)
    interpMethod = 'spline';
end

if nargin < 5 || isempty(maxGapSize)
    maxGapSize = 10;
end

if nargin < 4 || isempty(shouldSave)       % if no 'shouldSave' input
    shouldSave = true;                     % default to saving changes
end

%% Validate inputs and open the trial
markers = fieldnames(markerGaps);
for mrkr = 1:numel(markers)
    gaps = markerGaps.(markers{mrkr});
    if isempty(gaps) || size(gaps,2) ~= 2
        error(['Invalid format in markerGaps for marker %s. Expecting ' ...
            'a non-empty Nx2 matrix.'],markers{mrkr});
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

%% Fill the gaps
fprintf('Filling small marker gaps with %s interpolation...\n', ...
    interpMethod);
wasChanged = false;                     % track whether changes were made

for mrkr = 1:numel(markers)
    nameMarker = markers{mrkr};         % get marker name
    gaps       = markerGaps.(nameMarker); % retrieve gap indices for marker

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
    indNextGap    = 1;         % track the index for remaining gaps

    % process and fill gaps smaller than 'maxGapSize'
    for indGap = 1:size(gaps,1)
        gapStart  = gaps(indGap,1);
        gapEnd    = gaps(indGap,2);
        gapLength = gapEnd - gapStart + 1;

        % fill gap if it is within the allowed 'maxGapSize'
        if gapLength <= maxGapSize && any(existsTraj)
            [trajX,trajY,trajZ,existsTraj] = ...
                fillGap(trajX,trajY,trajZ,existsTraj,gaps(indGap,:), ...
                interpMethod);
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

%% Save the trial
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
    trajX,trajY,trajZ,existsTraj,gapRange, interpMethod)
%FILLGAP Interpolate one gap of a marker trajectory.
%
%   Fills the frames in gapRange of the X, Y, and Z trajectories with
% interp1 over the frames where the marker exists.
%
% Inputs:
%   trajX        - X trajectory
%   trajY        - Y trajectory
%   trajZ        - Z trajectory
%   existsTraj   - logical array, true where the marker exists
%   gapRange     - 1x2 [start end] frame indices of the gap to fill
%   interpMethod - interpolation method passed to interp1
%
% Outputs:
%   trajX, trajY, trajZ - trajectories with the gap filled
%   existsTraj          - existence array with the gap frames set true
%
% Toolbox Dependencies: None

% frames to process for filling the gap
framesToFill   = gapRange(1):gapRange(2);
existingFrames = find(existsTraj);      % get frames with data

trajX(framesToFill) = interp1(existingFrames, trajX(existingFrames), ...
    framesToFill, interpMethod);
trajY(framesToFill) = interp1(existingFrames, trajY(existingFrames), ...
    framesToFill, interpMethod);
trajZ(framesToFill) = interp1(existingFrames, trajZ(existingFrames), ...
    framesToFill, interpMethod);
existsTraj(framesToFill) = true;        % update existence array

end

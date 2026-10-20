function processAndFillMarkerGapsSession(pathSess,indsTrials,vicon)
%PROCESSANDFILLMARKERGAPSSESSION Reconstruct, label, and fill gaps.
%
%   For each selected trial in a session folder, runs the Nexus
% reconstruct-and-label pipelines (RLPrePatternFill1 and 2), fills gaps by
% reference-marker pattern, fills the remaining small gaps with 'makima'
% interpolation, runs the post-fill pipeline (Butterworth smoothing),
% saves the trial, and saves trajectory figures of the hip and ankle
% markers. A failed pipeline stage only warns; a trial whose first two
% pipelines fail is skipped.
%
% Side effects: needs a running Vicon Nexus (a connection is opened when
%   no vicon object is passed); opens, edits, and saves each trial.
%   Writes <fig|png>/<marker>_Trial##.fig/.png under a TrajectoryFigures
%   folder next to the session folder. Errors if the session folder does
%   not exist.
%
% Inputs:
%   pathSess   - path to the session folder holding the Trial*.x1d files
%   indsTrials - (optional) trial numbers to process; numbers without a
%                trial file are ignored (default: all trials)
%   vicon      - (optional) Vicon Nexus SDK object
%
% Outputs:
%   none
%
% Toolbox Dependencies: None
%
% See also DATAMOTION.EXTRACTMARKERGAPSTRIAL,
%   DATAMOTION.FILLMARKERGAPSPATTERN,
%   DATAMOTION.FILLSMALLMARKERGAPSSPLINE.

% TODO: add optional input for maximum marker gap size to pass along
% TODO: add a GUI input option if helpful
narginchk(1,3);                 % verify correct number of input arguments

%% Validate the session folder
if ~isfolder(pathSess)
    error('The session folder path specified does not exist: %s',pathSess);
end

% get all trial files that start with 'Trial'
trialFiles = dir(fullfile(pathSess,'Trial*.x1d'));
if isempty(trialFiles)      % if no trial files found, ...
    fprintf('No trials found in session folder: %s\n',pathSess);
    return;
end

%% Select trials
[~,namesFiles] = cellfun(@fileparts,{trialFiles.name}, ...
    'UniformOutput',false);
indsTrialsAll = cellfun(@(s) str2double(s(end-1:end)),namesFiles);

% select trials to process
if nargin < 2 || isempty(indsTrials)    % if 'indsTrials' not provided, ...
    indsTrials = indsTrialsAll;         % process all trials
else    % otherwise, ensure no values provided as input do not exist
    indsTrials = indsTrials(ismember(indsTrials,indsTrialsAll));
end

% initialize the Vicon Nexus object if not provided
if nargin < 3 || isempty(vicon)
    fprintf(['No Vicon SDK object provided. Connecting to Vicon ' ...
        'Nexus...\n']);
    vicon = ViconNexus();
end

%% Process each trial
markersRef  = {'GT','KNEE','GT','ANK'};
markersTarg = {
    {'ASIS','PSIS','THI','KNEE'}, ...
    {'GT','ANK'}, ...
    {'ASIS','PSIS','THI','KNEE'}, ...
    {'SHANK','HEEL','TOE'}
    };

for tr = indsTrials     % for each trial specified, ...
    pathTrial = fullfile(pathSess,sprintf('Trial%02d',tr));
    fprintf('Processing trial %d: %s\n',tr,pathTrial);

    % open the trial if needed
    if ~dataMotion.openTrialIfNeeded(pathTrial,vicon)
        return;     % exit if the trial could not be opened
    end

    % run reconstruct and label pipeline on the trial
    disp('Running RLPrePatternFill1...');
    try
        vicon.RunPipeline('RLPrePatternFill1','',1200);
    catch ME
        warning('Failed to run RLPrePatternFill1 for trial %d: %s', tr, ...
            ME.message);
        fprintf('Skipping to next trial...\n');
        continue;
    end

    % run woltring gap filling pipeline on the trial
    disp('Running RLPrePatternFill2...');
    try
        vicon.RunPipeline('RLPrePatternFill2','',1200);
    catch ME
        warning('Failed to run RLPrePatternFill2 for trial %d: %s', tr, ...
            ME.message);
        fprintf('Skipping to next trial...\n');
        continue;
    end

    % extract marker gaps to be filled
    try
        markerGaps = dataMotion.extractMarkerGapsTrial(pathTrial,vicon);
    catch ME
        warning('Failed to extract marker gaps for trial %d: %s', tr, ...
            ME.message);
        markerGaps = struct();
    end

    % fill gaps using pattern fill for each reference marker
    disp('Running Pattern Fill...');
    for ref = 1:numel(markersRef)       % for each reference marker, ...
        refMarker     = markersRef{ref};    % retrieve reference marker name
        targetMarkers = markersTarg{ref};

        try
            % Process gaps for the current reference marker
            markerGaps = fillMarkerGapsPatternSpecifiedTargets( ...
                markerGaps,targetMarkers,refMarker,pathTrial,vicon);
        catch ME
            warning(['Failed to fill gaps for reference marker %s for ' ...
                'trial %d: %s'], refMarker, tr, ME.message)
        end
    end

    % fill remaining small gaps with makima
    maxGapFrames = 250;     % TODO: source?
    if ~isempty(fieldnames(markerGaps))
        disp('Filling remaining small marker gaps with makima...');
        try
            dataMotion.fillSmallMarkerGapsSpline(markerGaps, pathTrial, ...
                vicon, false, maxGapFrames, 'makima');
        catch ME
            warning('Failed to fill small marker gaps for trial %d: %s', ...
                tr, ME.message);
        end
    end


    % smooth trajectories using Butterworth filter
    disp('Running RLPostPatternFill...');
    try
        vicon.RunPipeline('RLPostPatternFill','',1200);
    catch ME
        warning('Failed to run RLPostPatternFill for trial %d: %s', tr, ...
            ME.message);
    end

    fprintf('Saving trial %d: %s\n',tr,pathTrial);
    try
        vicon.SaveTrial(900);
        fprintf('Vicon trial saved. Now creating trajectory figures...\n');

        % Save trajectory figures
        try
            % saveTrajectoryFigures(pathSess, pathTrial, tr, vicon);
            if contains(pathSess, 'C3', 'IgnoreCase', true)
                % pass flag
                saveTrajectoryFigures(pathSess, tr, vicon, true);
            else
                saveTrajectoryFigures(pathSess, tr, vicon, false);
            end
            fprintf(['Trajectory figures saved successfully for trial ' ...
                '%d.\n'], tr);
        catch ME
            warning(['Failed to save trajectory figures for trial ' ...
                '%d: %s'], tr, ME.message);
            fprintf('Error details: %s\n', getReport(ME));
        end

        fprintf('Trial %d processing completed.\n', tr);

    catch ME
        warning(ME.identifier,'Failed to save trial %d: %s', tr, ...
            ME.message);
    end
end

fprintf('All specified trials have been processed.\n');
end

function markerGaps = fillMarkerGapsPatternSpecifiedTargets( ...
    markerGaps,targetMarkers,refMarker,pathTrial,vicon)
%FILLMARKERGAPSPATTERNSPECIFIEDTARGETS Pattern-fill gaps for one reference.
%
%   For the right and left side, fills the gaps of the target markers
% (side prefix plus each target name) from the side's reference marker
% with fillMarkerGapsPattern, without saving the trial.
%
% Inputs:
%   markerGaps    - struct of [start end] gap frames per marker
%   targetMarkers - cell array of target marker names without side prefix
%   refMarker     - reference marker name without side prefix
%   pathTrial     - full path to the trial
%   vicon         - Vicon Nexus SDK object
%
% Outputs:
%   markerGaps - the input struct with the entries of the target markers
%                replaced by their remaining gaps
%
% Toolbox Dependencies: None
%
% See also DATAMOTION.FILLMARKERGAPSPATTERN.

sides = {'R','L'};
for side = sides
    sidePrefix = side{1};
    gaps       = struct();

    % collect gaps for the target markers
    for targ = 1:numel(targetMarkers)
        markerName = [sidePrefix targetMarkers{targ}];
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
        gaps,pathTrial,[sidePrefix refMarker],vicon,false);

    % update the marker gaps structure with the remaining gaps
    markerNames = fieldnames(remainingGaps);
    for mrkr = 1:numel(markerNames)
        markerGaps.(markerNames{mrkr}) = remainingGaps.(markerNames{mrkr});
    end
end

end

function mrkrTrajs = getRelevantMrkrTrajs(newVicon)
%GETRELEVANTMRKRTRAJS Read the hip and ankle trajectories from Nexus.
%
%   Returns the RGT, LGT, RANK, and LANK trajectories of the first subject
% in the open trial, with frames where the marker does not exist set to
% NaN. A marker that cannot be read is returned as an empty array.
%
% Inputs:
%   newVicon - Vicon Nexus SDK object with a trial open
%
% Outputs:
%   mrkrTrajs - struct with one Nx3 [X Y Z] array per marker (mm)
%
% Toolbox Dependencies: None

mrkrsRelevant = {'RGT','LGT','RANK','LANK'};
mrkrTrajs     = struct();

subjects = newVicon.GetSubjectNames();
if isempty(subjects)
    warning('No subject found in trial.');
    mrkrTrajs = struct();
    return;
end
subject = subjects{1};
fprintf('Getting trajectories for subject: %s\n', subject);

for mrkr = 1:numel(mrkrsRelevant)
    marker = mrkrsRelevant{mrkr};
    try
        [trajX, trajY, trajZ, existsTraj] = ...
            newVicon.GetTrajectory(subject, marker);

        trajX(~existsTraj) = NaN;
        trajY(~existsTraj) = NaN;
        trajZ(~existsTraj) = NaN;

        %, double(exists(:))];
        mrkrTrajs.(marker) = [trajX(:), trajY(:), trajZ(:)];
        fprintf('Successfully retrieved trajectory for marker: %s\n', ...
            marker);
    catch ME
        warning('Failed to get trajectory for marker %s: %s', marker, ...
            ME.message);
        mrkrTrajs.(marker) = [];  % Empty array for failed markers
    end
end

end

function saveTrajectoryFigures(pathSess, trialNum, vicon, ...
    highlightTurningPoints)
%SAVETRAJECTORYFIGURES Save X/Y/Z trajectory figures of the hip and ankle.
%
%   Plots the X, Y, and Z trajectories of RGT, LGT, RANK, and LANK of the
% open trial in a stacked layout and saves each marker as .fig and .png.
% With highlightTurningPoints, frames whose Y value is outside the walkway
% bounds are shaded and the bounds drawn on the Y panel.
%
% Side effects: creates TrajectoryFigures/fig and TrajectoryFigures/png
%   next to the session folder if missing and writes
%   <marker>_Trial##.fig and .png there; each figure is opened and then
%   closed.
%
% Inputs:
%   pathSess               - path to the session folder
%   trialNum               - trial number used in titles and file names
%   vicon                  - Vicon Nexus SDK object with the trial open
%   highlightTurningPoints - (optional) logical, shade out-of-bounds Y
%                            frames (default: false)
%
% Outputs:
%   none
%
% Toolbox Dependencies: None
%
% See also GETRELEVANTMRKRTRAJS.

if nargin < 4
    highlightTurningPoints = false;
end

markers   = {'RGT','LGT','RANK','LANK'};
mrkrTrajs = getRelevantMrkrTrajs(vicon);

outParent = fileparts(pathSess);
outDir    = fullfile(outParent, 'TrajectoryFigures');
figDir    = fullfile(outDir, 'fig');
pngDir    = fullfile(outDir, 'png');

if ~exist(figDir, 'dir')
    mkdir(figDir);
end

if ~exist(pngDir, 'dir')
    mkdir(pngDir);
end

lowerBound = -2500;     % TODO: source?
upperBound = 4500;      % TODO: source?

for mrkr = 1:numel(markers)
    markerName = markers{mrkr};

    if ~isfield(mrkrTrajs, markerName)
        warning('Marker %s not found in trial.', markerName);
        continue;
    end

    traj = mrkrTrajs.(markerName);
    if isempty(traj) || all(isnan(traj(:)))
        warning('No valid data for marker %s in trial %d.', markerName, ...
            trialNum);
        continue;
    end

    frames  = 1:size(traj, 1);
    yValues = traj(:,2);

    if highlightTurningPoints % only for C3 trajectories
        outOfBounds = (yValues < lowerBound) | (yValues > upperBound) | ...
            isnan(yValues);
        outOfBounds = [false; outOfBounds(:); false];
        d           = diff(outOfBounds);
        startIdxs   = find(d == 1);
        endIdxs     = find(d == -1) - 1;
    end

    % Create stacked plot
    % visible so the figure opens automatically
    fig = figure('Visible','on', 'Name', ...
        ['Trajectories for ' markerName], 'NumberTitle', 'off');
    tl  = tiledlayout(3,1, 'TileSpacing', 'Compact');
    title(tl, sprintf('%s Trajectory - Trial %02d', markerName, ...
        trialNum), 'Interpreter', 'none');

    componentLabels = {'X','Y','Z'};
    for dim = 1:3
        ax = nexttile;
        hold(ax,'on');
        plot(ax, frames, traj(:,dim), 'b-', 'LineWidth',1.2);
        ylabel(ax, [componentLabels{dim} ' (mm)']);
        if dim == 3
            xlabel(ax,'Frame');
        end
        grid(ax,'on');

        dataMin = min(traj(:,dim),[],'omitnan');
        dataMax = max(traj(:,dim),[],'omitnan');
        padding = 0.1 * (dataMax - dataMin);
        ylim(ax, [dataMin - padding, dataMax + padding]);

        if highlightTurningPoints
            % vertical shading based on Y out-of-bounds, drawn on all
            % subplots
            dataMin = min(traj(:,dim),[],'omitnan');
            dataMax = max(traj(:,dim),[],'omitnan');
            yMin    = dataMin - 100;
            yMax    = dataMax + 100;

            for ii = 1:numel(startIdxs)
                fill(ax, [startIdxs(ii) endIdxs(ii) endIdxs(ii) ...
                    startIdxs(ii)], ...
                    [yMin yMin yMax yMax], ...
                    [1 0 0], 'FaceAlpha',0.2, 'EdgeColor','none');
            end

            % only add Y threshold lines on Y subplot
            if dim == 2
                yline(ax, lowerBound, 'r--','LineWidth',1);
                yline(ax, upperBound, 'r--','LineWidth',1);
            end
        end
    end

    % Save .fig and .png
    baseName = sprintf('%s_Trial%02d', markerName, trialNum);
    savefig(fig, fullfile(figDir, [baseName '.fig']));
    saveas(fig, fullfile(pngDir, [baseName '.png']));
    close(fig);
end

end


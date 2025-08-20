function processAndFillMarkerGapsSession(pathSess,indsTrials,vicon)
%PROCESSANDFILLMARKERGAPSSESSION Process trial and fill marker gaps
%   This function finds all trials in the session folder with filenames
% starting with 'Trial', filters them based on the specified indices, and
% runs the reconstruct and label pipelines. Then, the small marker gaps are
% filled using spline interpolation. Make sure the Vicon Nexus SDK is
% installed and added to the MATLAB path.
%
% input(s):
%   pathSess: path to the session folder where all trial data is stored.
%   indsTrials: (optional) array of indices indicating which trials to
%       process. By default, all files starting with 'Trial' are processed.
%   vicon: (optional) Vicon Nexus SDK object. If not supplied, a new Vicon
%       object will be created and connected.

% TODO: add optional input for maximum marker gap size to pass along
% TODO: add a GUI input option if helpful
narginchk(1,3);                 % verify correct number of input arguments

% ensure session folder path exists
if ~isfolder(pathSess)
    error('The session folder path specified does not exist: %s',pathSess);
end

% get all trial files that start with 'Trial'
trialFiles = dir(fullfile(pathSess,'Trial*.x1d'));
if isempty(trialFiles)      % if no trial files found, ...
    fprintf('No trials found in session folder: %s\n',pathSess);
    return;
end

% extract trial indices from filenames
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

% define reference and target markers for pattern-based gap filling
markersRef = {'GT','KNEE','GT','ANK'};
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
        vicon.RunPipeline('RLPrePatternFill1','',800);
        pause(30);
    catch ME
        warning('Failed to run RLPrePatternFill1 for trial %d: %s', tr, ME.message);
        fprintf('Skipping to next trial...\n');
        continue;
    end
    
    % run woltring gap filling pipeline on the trial
    disp('Running RLPrePatternFill2...');
    try
        vicon.RunPipeline('RLPrePatternFill2','',800);
        pause(30);
    catch ME
        warning('Failed to run RLPrePatternFill2 for trial %d: %s', tr, ME.message);
        fprintf('Skipping to next trial...\n');
        continue;
    end
    
    % extract marker gaps to be filled
    try
        markerGaps = dataMotion.extractMarkerGapsTrial(pathTrial,vicon);
    catch ME
        warning('Failed to extract marker gaps for trial %d: %s', tr, ME.message);
        markerGaps = struct();
    end
    
    disp('Running Pattern Fill...');
    % fill gaps using pattern fill for each reference marker
    for ref = 1:numel(markersRef)       % for each reference marker, ...
        refMarker = markersRef{ref};    % retrieve reference marker name
        targetMarkers = markersTarg{ref};
        
        try
            % Process gaps for the current reference marker
            markerGaps = fillMarkerGapsPatternSpecifiedTargets( ...
                markerGaps,targetMarkers,refMarker,pathTrial,vicon);
        catch ME
            warning('Failed to fill gaps for reference marker %s for trial %d: %s', refMarker, tr, ME.message)
        end
    end
    pause(5);
    
    disp('Running RLPostPatternFill...');
    try
        vicon.RunPipeline('RLPostPatternFill','',200);
        pause(5);
    catch ME
        warning('Failed to run RLPostPatternFill for trial %d: %s', tr, ME.message); 
    end
    
    fprintf('Saving trial %d: %s\n',tr,pathTrial);
    try
        vicon.SaveTrial(200);
        fprintf('Vicon trial saved. Now creating trajectory figures...\n');        
        
        % Save trajectory figures
        try
            saveTrajectoryFigures(pathSess, pathTrial, tr, vicon);
            fprintf('Trajectory figures saved successfully for trial %d.\n', tr);
        catch ME
            warning('Failed to save trajectory figures for trial %d: %s', tr, ME.message);
            fprintf('Error details: %s\n', getReport(ME));
        end
        
        fprintf('Trial %d processing completed.\n', tr);

    catch ME
        warning(ME.identifier,'Failed to save trial %d: %s', tr, ME.message);
    end
end

fprintf('All specified trials have been processed.\n');
end

function markerGaps = fillMarkerGapsPatternSpecifiedTargets( ...
    markerGaps,targetMarkers,refMarker,pathTrial,vicon)
%PROCESSREFERENCEMARKERGAPS Process marker gaps for a reference marker
%   Helper function to perform a pattern-based fill of marker gaps for
% specified target markers and a referencefor right and left markers.

sides = {'R','L'};
for side = sides
    sidePrefix = side{1};
    gaps = struct();

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

mrkrsRelevant = {'RGT','LGT','RANK','LANK'};
mrkrTrajs = struct();

subjects = newVicon.GetSubjectNames();
if isempty(subjects)
    warning('No subject found in trial.'); mrkrTrajs = struct(); return;
    return;
end
subject = subjects{1};
fprintf('Getting trajectories for subject: %s\n', subject);

for i = 1:numel(mrkrsRelevant)
    marker = mrkrsRelevant{i};
    try
        [trajX, trajY, trajZ, existsTraj] = newVicon.GetTrajectory(subject, marker);

        trajX(~existsTraj) = NaN;
        trajY(~existsTraj) = NaN;
        trajZ(~existsTraj) = NaN;

        mrkrTrajs.(marker) = [trajX(:), trajY(:), trajZ(:)];%, double(exists(:))];
        fprintf('Successfully retrieved trajectory for marker: %s\n', marker);
    catch ME
        warning('Failed to get trajectory for marker %s: %s', marker, ME.message);
        mrkrTrajs.(marker) = [];  % Empty array for failed markers
    end
end
% for mrkr = mrkrsRelevant
%     [trajX,trajY,trajZ,exists] = newVicon.getTrajectory(mrkrsRelevant{mrkr});
%     mrkrTrajs.(mrkrsRelevant{mrkr}) = [trajX; trajY; trajZ; double(exists)];
% end
end

function saveTrajectoryFigures(pathSess, pathTrial, trialNum, vicon)

markers = {'RGT', 'LGT', 'RANK', 'LANK'};
mrkrTrajs = getRelevantMrkrTrajs(vicon);

[outParent, ~] = fileparts(pathSess);      
outDir = fullfile(outParent, 'TrajectoryFigures');
figDir = fullfile(outDir, 'fig');
pngDir = fullfile(outDir, 'png');

if ~exist(figDir, 'dir'), mkdir(figDir); end
if ~exist(pngDir, 'dir'), mkdir(pngDir); end

for i = 1:numel(markers)
    markerName = markers{i};
    
    if ~isfield(mrkrTrajs, markerName)
        warning('Marker %s not found in trial.', markerName);
        continue;
    end

    traj = mrkrTrajs.(markerName);
    if isempty(traj) || all(isnan(traj(:)))
        warning('No valid data for marker %s in trial %d.', markerName, trialNum);
        continue;
    end

    frames = 1:size(traj, 1);

    % Create stacked plot
    fig = figure('Visible','off', 'Name', ['Trajectories for ' markerName], 'NumberTitle', 'off');
    tl = tiledlayout(3,1, 'TileSpacing', 'Compact');
    title(tl, sprintf('%s Trajectory - Trial %02d', markerName, trialNum), 'Interpreter', 'none');

    % X Component
    nexttile;
    plot(frames, traj(:,1));
    ylabel('X (mm)');
    title('X');

    % Y Component
    nexttile;
    plot(frames, traj(:,2));
    ylabel('Y (mm)');
    title('Y');

    % Z Component
    nexttile;
    plot(frames, traj(:,3));
    ylabel('Z (mm)');
    xlabel('Frame');
    title('Z');

    % Save .fig and .png
    baseName = sprintf('%s_Trial%02d', markerName, trialNum);
    savefig(fig, fullfile(figDir, [baseName '.fig']));
    saveas(fig, fullfile(pngDir, [baseName '.png']));

    close(fig);
end
end
    


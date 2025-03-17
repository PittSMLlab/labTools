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

    % run reconstruct and label pipeline on the trial
    dataMotion.reconstructAndLabelTrial(pathTrial,vicon,false);

    % extract marker gaps to be filled
    markerGaps = dataMotion.extractMarkerGapsTrial(pathTrial,vicon);

    % fill small marker gaps using spline interpolation
    markerGaps = dataMotion.fillSmallMarkerGapsSpline(markerGaps, ...
        pathTrial,vicon,false);

    % fill gaps using pattern fill for each reference marker
    for ref = 1:numel(markersRef)       % for each reference marker, ...
        refMarker = markersRef{ref};    % retrieve reference marker name
        targetMarkers = markersTarg{ref};

        % Process gaps for the current reference marker
        markerGaps = fillMarkerGapsPatternSpecifiedTargets( ...
            markerGaps,targetMarkers,refMarker,pathTrial,vicon);
    end

    fprintf('Saving trial %d: %s\n',tr,pathTrial);
    try
        vicon.SaveTrial(200);
        fprintf('Trial saved successfully.\n');
    catch ME
        warning(ME.identifier,'%s',ME.message);
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


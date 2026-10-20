function exportSessionToC3D(pathSess,indsTrials,vicon)
%EXPORTSESSIONTOC3D Save selected session trials as C3D files.
%
%   Finds the Trial*.x1d files in a session folder, keeps the requested
% trial numbers, and exports each one as a C3D file through Vicon Nexus
% with no further processing.
%
% Side effects: needs a running Vicon Nexus (a connection is opened when
%   no vicon object is passed); opens each trial and writes its C3D file.
%   Errors if the session folder does not exist.
%
% Inputs:
%   pathSess   - path to the session folder holding the trial files
%   indsTrials - (optional) trial numbers to export; numbers without a
%                trial file are ignored (default: all trials)
%   vicon      - (optional) Vicon Nexus SDK object
%
% Outputs:
%   none
%
% Toolbox Dependencies: None
%
% See also DATAMOTION.EXPORTTRIALTOC3D, DATAMOTION.OPENTRIALIFNEEDED.

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
[~,namesFiles] = cellfun(@(s) fileparts(s),{trialFiles.name}, ...
    'UniformOutput',false);
indsTrialsAll = cellfun(@(s) str2double(s(end-1:end)),namesFiles);

% select trials to process
if nargin < 2 || isempty(indsTrials)    % if 'indsTrials' not provided, ...
    indsTrials = indsTrialsAll;         % process all trials
else    % otherwise, ensure no values provided as input do not exist
    indsTrials = indsTrials(ismember(indsTrials,indsTrialsAll));
end

%% Connect to Nexus and export
if nargin < 3 || isempty(vicon)
    fprintf(['No Vicon SDK object provided. Connecting to Vicon ' ...
        'Nexus...\n']);
    vicon = ViconNexus();
end

for tr = indsTrials     % for each trial specified, ...
    pathTrial = fullfile(pathSess,sprintf('Trial%02d',tr));
    fprintf('Processing trial %d: %s\n',tr,pathTrial);

    % export trial to C3D using previously implemented function
    dataMotion.exportTrialToC3D(pathTrial,vicon);
end

end


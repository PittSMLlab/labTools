function reconstructAndLabelSession(pathSess, indsTrials, vicon)
%RECONSTRUCTANDLABELSESSION Run reconstruct and label pipeline on a session.
%
%   Finds all trials in the session folder whose filenames start with
% 'Trial', filters them by the specified indices, and runs the
% reconstruct and label pipeline on each. Requires the Vicon Nexus SDK
% on the MATLAB path.
%
% Inputs:
%   pathSess   - Path to the session folder where trial data is stored
%   indsTrials - (optional) Array of numeric trial indices to process;
%                defaults to all trials when empty
%   vicon      - (optional) Vicon Nexus SDK object; connects if not
%                supplied
%
% Outputs:
%   None
%
% Toolbox Dependencies: None
%
% See also RECONSTRUCTANDLABELTRIAL.

% TODO: add a GUI input option if helpful
narginchk(1, 3);

if ~isfolder(pathSess)
    error('The session folder path specified does not exist: %s', ...
        pathSess);
end

trialFiles = dir(fullfile(pathSess, 'Trial*.x1d'));
if isempty(trialFiles)
    fprintf('No trials found in session folder: %s\n', pathSess);
    return;
end

[~, namesFiles] = cellfun(@(s) fileparts(s), {trialFiles.name}, ...
    'UniformOutput', false);
indsTrialsAll = cellfun(@(s) str2double(s(end-1:end)), namesFiles);

if nargin < 2 || isempty(indsTrials)
    indsTrials = indsTrialsAll;
else
    indsTrials = indsTrials(ismember(indsTrials, indsTrialsAll));
end

if nargin < 3 || isempty(vicon)
    fprintf(['No Vicon SDK object provided. Connecting to Vicon ' ...
        'Nexus...\n']);
    vicon = ViconNexus();
end

for tr = indsTrials
    pathTrial = fullfile(pathSess, sprintf('Trial%02d', tr));
    fprintf('Processing trial %d: %s\n', tr, pathTrial);
    dataMotion.reconstructAndLabelTrial(pathTrial, vicon);
end

end

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
[~,namesFiles] = cellfun(@(s) fileparts(s),{trialFiles.name}, ...
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

for tr = indsTrials     % for each trial specified, ...
    pathTrial = fullfile(pathSess,sprintf('Trial%02d',tr));
    fprintf('Processing trial %d: %s\n',tr,pathTrial);
    
    % run reconstruct and label pipeline on the trial
    %     dataMotion.reconstructAndLabelTrial(pathTrial,vicon);
    
    % extract marker gaps to be filled
    markerGaps = dataMotion.extractMarkerGapsTrial(pathTrial,vicon);
    
    % fill small marker gaps using spline interpolation
    markerGaps = dataMotion.fillSmallMarkerGapsSpline(markerGaps, ...
        pathTrial,vicon);
    markers = fieldnames(markerGaps);
    
    % fill remaining gaps using pattern fill
    markersRef = {'GT','KNEE','GT','ANK'};
    numMarkersRef = length(markersRef);
    markersTargGT = {'ASIS','PSIS','THI','KNEE'};
    markersTargKNEE = {'GT','ANK'};
    markersTargANK = {'SHANK','HEEL','TOE'};
    markersTarg = {markersTargGT,markersTargKNEE, ...
        markersTargGT,markersTargANK};
    
    % TODO: better to pass entire 'markerGaps' as input with optional
    % target markers list as input?
    for ref = 1:numMarkersRef       % for each reference marker, ...
        numMarkersTarg = length(markersTarg{ref});
        mrkrsTargR = cellfun(@(s) ['R' s],markersTarg{ref}, ...
            'UniformOutput',false);
        tmpGapsR = struct();
        for targ = 1:numMarkersTarg
            if any(strcmp(markers,mrkrsTargR{targ}))
                tmpGapsR.(mrkrsTargR{targ}) = markerGaps.(mrkrsTargR{targ});
            end
        end
        
        if ~isempty(fieldnames(tmpGapsR))
            dataMotion.fillMarkerGapsPattern(tmpGapsR,pathTrial,['R' markersRef{ref}],vicon);
        end
        
        mrkrsTargL = cellfun(@(s) ['L' s],markersTarg{ref}, ...
            'UniformOutput',false);
        tmpGapsL = struct();
        for targ = 1:numMarkersTarg
            if any(strcmp(markers,mrkrsTargL{targ}))
                tmpGapsL.(mrkrsTargL{targ}) = markerGaps.(mrkrsTargL{targ});
            end
        end
        
        if ~isempty(fieldnames(tmpGapsL))
            dataMotion.fillMarkerGapsPattern(tmpGapsL,pathTrial,['L' markersRef{ref}],vicon);
        end
    end
end

end


function markerGaps = extractMarkerGapsTrial(pathTrial,vicon)
%EXTRACTMARKERGAPSTRIAL Find the frame ranges of all marker gaps in a trial.
%
%   Opens the trial in Vicon Nexus if needed and, for every marker of the
% first subject, finds the runs of frames where the trajectory does not
% exist. The Vicon Nexus SDK must be installed and on the MATLAB path.
%
% Side effects: needs a running Vicon Nexus (a connection is opened when
%   no vicon object is passed); opens the trial. Errors if the SDK cannot
%   be initialized or the trial has no subject.
%
% Inputs:
%   pathTrial - full path to the trial
%   vicon     - (optional) Vicon Nexus SDK object
%
% Outputs:
%   markerGaps - struct with one field per marker that has gaps, each an
%                Nx2 array of [start end] frame indices, one row per gap
%
% Toolbox Dependencies: None
%
% See also DATAMOTION.FILLMARKERGAPSPATTERN,
%   DATAMOTION.FILLSMALLMARKERGAPSSPLINE.

% TODO: add a GUI input option if helpful
narginchk(1,2);         % verify correct number of input arguments

%% Connect to Nexus and open the trial
if nargin < 2 || isempty(vicon)
    fprintf(['No Vicon SDK object provided. Connecting to Vicon ' ...
        'Nexus...\n']);
    try
        vicon = ViconNexus();
    catch
        error(['Failed to initialize Vicon Nexus SDK. Ensure SDK is ' ...
            'properly installed.']);
    end
end

% open the trial if needed
if ~dataMotion.openTrialIfNeeded(pathTrial,vicon)
    return;     % exit if the trial could not be opened
end

% get subject name (assuming only one subject in the trial)
subject = vicon.GetSubjectNames();
if isempty(subject)
    error('No subject found in the trial.');
end
subject = subject{1};

%% Find the gaps of each marker
markerGaps = struct();
markers    = vicon.GetMarkerNames(subject);
if isempty(markers)     % if empty array of markers, ...
    warning('No markers found for the subject in the trial.');
    return;
end

for mrkr = 1:length(markers)        % for each marker, ...
    nameMarker = markers{mrkr};     % get marker name
    try                             % get marker trajectory existence flags
        [~,~,~,existsTraj] = vicon.GetTrajectory(subject,nameMarker);
    catch
        warning(['Failed to retrieve trajectory for marker %s. ' ...
            'Skipping...'],nameMarker);
        continue;
    end

    % identify gaps as sequences where trajExists is false
    indsGap = find(~existsTraj);
    if isempty(indsGap)             % if no gaps for a marker, ...
        continue;
    end

    % identify start and end indices of each trajectory gap
    gapsStarts = indsGap([true diff(indsGap) > 1])';    % start of gaps
    gapsEnds   = indsGap([diff(indsGap) > 1 true])';      % end of gaps

    % store gap data for this marker in the output structure
    markerGaps.(nameMarker) = [gapsStarts gapsEnds];
end

end


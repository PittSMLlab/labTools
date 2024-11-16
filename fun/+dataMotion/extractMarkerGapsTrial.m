function markerGaps = extractMarkerGapsTrial(pathTrial,vicon)
%EXTRACTMARKERGAPSTRIAL Extract indices of all marker gaps to be filled
%   This function accepts as input the full path to the trial and
% identifies gaps in all markers' trajectories. Make sure the Vicon Nexus
% SDK is installed and added to the MATLAB path.
%
% input(s):
%   pathTrial: string or character array of the full path of the trial on
%       which to run the reconstruct and label processing pipeline
%   vicon: (optional) Vicon Nexus SDK object; connects if not supplied.
% output:
%   markerGaps: struct of arrays with start and end frame indices of the
%       gaps in each marker's trajectory, ...
%       formatted as [startsGaps endsGaps]

% TODO: add a GUI input option if helpful
narginchk(1,2);         % verify correct number of input arguments

% initialize the Vicon Nexus object if not provided
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

% initialize structure to store marker trajectory gaps
markerGaps = struct();
markers = vicon.GetMarkerNames(subject);
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
    gapsEnds = indsGap([diff(indsGap) > 1 true])';      % end of gaps

    % store gap data for this marker in the output structure
    markerGaps.(nameMarker) = [gapsStarts gapsEnds];
end

end


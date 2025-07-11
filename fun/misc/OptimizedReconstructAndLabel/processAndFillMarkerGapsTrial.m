function mrkrTrajs = processAndFillMarkerGapsTrial(pathTrial, vicon)
%PROCESSANDFILLMARKERGAPSTRIAL Process a single trial and fill marker gaps
%   This function runs reconstruct and label pipelines, fills small marker
%   gaps using spline interpolation, and then attempts pattern-based filling.
%
% input(s):
%   pathTrial: full path to the trial folder
%   vicon: (optional) Vicon Nexus SDK object. If not supplied, a new Vicon
%       object will be created and connected.

% verify input
narginchk(1, 2);

% initialize Vicon Nexus object if not provided
if nargin < 2 || isempty(vicon)
    fprintf('No Vicon SDK object provided. Connecting to Vicon Nexus...\n');
    vicon = ViconNexus();
end

% define reference and target markers
markersRef = {'GT','KNEE','GT','ANK'};
markersTarg = {
    {'ASIS','PSIS','THI','KNEE'}, ...
    {'GT','ANK'}, ...
    {'ASIS','PSIS','THI','KNEE'}, ...
    {'SHANK','HEEL','TOE'}
};

mrkrTrajs = struct();

% run reconstruct and label pipeline
fprintf('Running reconstruct and label on: %s\n', pathTrial);
dataMotion.reconstructAndLabelTrial(pathTrial, vicon, false);
pause(3);
mrkrTrajs.Step1RandL = getRelevantMrkrTrajs(vicon);

% extract marker gaps
markerGaps = dataMotion.extractMarkerGapsTrial(pathTrial, vicon);

% fill small gaps with spline interpolation
markerGaps = dataMotion.fillSmallMarkerGapsSpline(markerGaps, pathTrial, vicon, false);

mrkrTrajs.Step2Spline = getRelevantMrkrTrajs(vicon);

% fill gaps using pattern fill for each reference marker
for ref = 1:numel(markersRef)
    refMarker = markersRef{ref};
    targetMarkers = markersTarg{ref};

    % fill for both sides
    markerGaps = fillMarkerGapsPatternSpecifiedTargets( ...
        markerGaps, targetMarkers, refMarker, pathTrial, vicon);
end

mrkrTrajs.Step3Pattern = getRelevantMrkrTrajs(vicon);

% save trial
fprintf('Saving trial: %s\n', pathTrial);
try
    vicon.SaveTrial(200);
    fprintf('Trial saved successfully.\n');
catch ME
    warning(ME.identifier, '%s', ME.message);
end

end

function markerGaps = fillMarkerGapsPatternSpecifiedTargets( ...
    markerGaps, targetMarkers, refMarker, pathTrial, vicon)

sides = {'R','L'};
for side = sides
    sidePrefix = side{1};
    gaps = struct();

    % collect gaps for the target markers
    for targ = 1:numel(targetMarkers)
        markerName = [sidePrefix targetMarkers{targ}];
        if isfield(markerGaps, markerName)
            gaps.(markerName) = markerGaps.(markerName);
        end
    end

    % skip if no gaps to process
    if isempty(fieldnames(gaps))
        continue;
    end

    % fill gaps using pattern-based method
    remainingGaps = dataMotion.fillMarkerGapsPattern( ...
        gaps, pathTrial, [sidePrefix refMarker], vicon, false);

    % update the marker gaps structure with the remaining gaps
    markerNames = fieldnames(remainingGaps);
    for mrkr = 1:numel(markerNames)
        markerGaps.(markerNames{mrkr}) = remainingGaps.(markerNames{mrkr});
    end
end
end

function mrkrTrajs = getRelevantMrkrTrajs(vicon)

mrkrsRelevant = {'RGT','LGT','RANK','LANK'};
mrkrTrajs = struct();

subjects = vicon.GetSubjectNames();
if isempty(subjects)
    error('No subject found in trial.');
end
subject = subjects{1};

for i = 1:numel(mrkrsRelevant)
    marker = mrkrsRelevant{i};
    [trajX, trajY, trajZ, existsTraj] = vicon.GetTrajectory(subject, marker);
    
    trajX(~existsTraj) = NaN;
    trajY(~existsTraj) = NaN;
    trajZ(~existsTraj) = NaN;
    
    mrkrTrajs.(marker) = [trajX(:), trajY(:), trajZ(:)];%, double(exists(:))];
end
% for mrkr = mrkrsRelevant
%     [trajX,trajY,trajZ,exists] = vicon.getTrajectory(mrkrsRelevant{mrkr});
%     mrkrTrajs.(mrkrsRelevant{mrkr}) = [trajX; trajY; trajZ; double(exists)];
% end
end

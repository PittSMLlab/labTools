function mrkrTrajs = processAndFillMarkerGapsTrial(pathTrial, vicon)
%PROCESSANDFILLMARKERGAPSTRIAL Process a single trial and fill marker gaps.
%
%   Runs the reconstruct and label pipeline, fills small marker gaps
% via spline interpolation, then applies pattern-based filling for each
% reference/target group. Returns marker trajectories at each stage.
%
% Inputs:
%   pathTrial - Full path to the trial folder
%   vicon     - (optional) Vicon Nexus SDK object; connects if not
%               supplied
%
% Outputs:
%   mrkrTrajs - Struct with fields Step1RandL, Step2Spline, and
%               Step3Pattern; each contains marker trajectories at
%               that processing stage
%
% Toolbox Dependencies: None
%
% See also RECONSTRUCTANDLABELTRIAL, RUNCUSTOMPATTERNFILL.

narginchk(1, 2);

if nargin < 2 || isempty(vicon)
    fprintf('No Vicon SDK object provided. Connecting to Vicon Nexus...\n');
    vicon = ViconNexus();
end

markersRef  = {'GT', 'KNEE', 'GT', 'ANK'};
markersTarg = { ...
    {'ASIS', 'PSIS', 'THI', 'KNEE'}, ...
    {'GT', 'ANK'}, ...
    {'ASIS', 'PSIS', 'THI', 'KNEE'}, ...
    {'SHANK', 'HEEL', 'TOE'} ...
};

mrkrTrajs = struct();

fprintf('Running reconstruct and label on: %s\n', pathTrial);
dataMotion.reconstructAndLabelTrial(pathTrial, vicon, false);
pause(3);
mrkrTrajs.Step1RandL = getRelevantMrkrTrajs(vicon);

markerGaps = dataMotion.extractMarkerGapsTrial(pathTrial, vicon);

markerGaps = dataMotion.fillSmallMarkerGapsSpline( ...
    markerGaps, pathTrial, vicon, false);

mrkrTrajs.Step2Spline = getRelevantMrkrTrajs(vicon);

for ref = 1:numel(markersRef)
    refMarker     = markersRef{ref};
    targetMarkers = markersTarg{ref};
    markerGaps    = fillMarkerGapsPatternSpecifiedTargets( ...
        markerGaps, targetMarkers, refMarker, pathTrial, vicon);
end

mrkrTrajs.Step3Pattern = getRelevantMrkrTrajs(vicon);

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
%FILLMARKERGAPSPATTERNSPECIFIEDTARGETS Pattern-fill gaps for a marker group.
%
%   For each side (R/L), collects gaps for the specified target markers
% and fills them using the given reference marker via pattern-based gap
% filling. Updates markerGaps with any remaining unfilled gaps.
%
% Inputs:
%   markerGaps    - Struct mapping marker names to gap arrays
%   targetMarkers - Cell array of marker name suffixes to fill
%   refMarker     - Reference marker name suffix
%   pathTrial     - Full path to the trial folder
%   vicon         - Vicon Nexus SDK object
%
% Outputs:
%   markerGaps - Updated struct with remaining gaps after filling

sides = {'R', 'L'};
for side = sides
    sidePrefix = side{1};
    gaps = struct();

    for targ = 1:numel(targetMarkers)
        markerName = [sidePrefix targetMarkers{targ}];
        if isfield(markerGaps, markerName)
            gaps.(markerName) = markerGaps.(markerName);
        end
    end

    if isempty(fieldnames(gaps))
        continue;
    end

    remainingGaps = dataMotion.fillMarkerGapsPattern( ...
        gaps, pathTrial, [sidePrefix refMarker], vicon, false);

    markerNames = fieldnames(remainingGaps);
    for mrkr = 1:numel(markerNames)
        markerGaps.(markerNames{mrkr}) = remainingGaps.(markerNames{mrkr});
    end
end

end

function mrkrTrajs = getRelevantMrkrTrajs(vicon)
%GETRELEVANTMRKRTRAJS Retrieve key lower-limb marker trajectories.
%
%   Queries the Vicon Nexus SDK for RGT, LGT, RANK, and LANK marker
% trajectories and returns them as an N×3 matrix per marker with NaN
% for missing frames.
%
% Inputs:
%   vicon - Vicon Nexus SDK object
%
% Outputs:
%   mrkrTrajs - Struct with one N×3 field per relevant marker

mrkrsRelevant = {'RGT', 'LGT', 'RANK', 'LANK'};
mrkrTrajs     = struct();

subjects = vicon.GetSubjectNames();
if isempty(subjects)
    error('No subject found in trial.');
end
subject = subjects{1};

for mrkr = 1:numel(mrkrsRelevant)
    marker = mrkrsRelevant{mrkr};
    [trajX, trajY, trajZ, existsTraj] = ...
        vicon.GetTrajectory(subject, marker);
    trajX(~existsTraj) = NaN;
    trajY(~existsTraj) = NaN;
    trajZ(~existsTraj) = NaN;
    mrkrTrajs.(marker) = [trajX(:), trajY(:), trajZ(:)];
end
% for mrkr = mrkrsRelevant
%     [trajX,trajY,trajZ,exists] = vicon.getTrajectory(mrkrsRelevant{mrkr});
%     mrkrTrajs.(mrkrsRelevant{mrkr}) = [trajX; trajY; trajZ; double(exists)];
% end

end

function out = computeAngleParameters(angleData, gaitEvents, slowLeg, ...
    eventTypes)
% computeAngleParameters  Compute joint angle parameters per stride.
%
%   Computes stride-by-stride joint angle parameters and returns a
% parameterSeries object that can be concatenated with other parameter
% series objects (e.g., from computeTemporalParameters).
%
%   Inputs:
%     angleData  - labTimeSeries containing limb angle data, with
%                  channel labels prefixed by leg side ('L' or 'R')
%     gaitEvents - labTimeSeries of gait events for the trial
%     slowLeg    - Char specifying the slow-belt leg ('L' or 'R')
%     eventTypes - Cell array of gait event type strings as constructed
%                  in calcParameters (e.g., {'LHS','RTO','RHS','LTO'})
%
%   Outputs:
%     out - parameterSeries object containing all angle parameters,
%           including discrete stride-level measures and heel strike
%           angle parameters
%
%   Toolbox Dependencies:
%     None
%
%   See also: computeTemporalParameters, computeSpatialParameters,
%     computeForceParameters, computeTSdiscreteParameters,
%     computeHSparameters, parameterSeries, calcParameters

arguments
    angleData  (1,1)
    gaitEvents (1,1)
    slowLeg    (1,:) char
    eventTypes (1,:) cell
end

%% Pre-Process Angle Labels
% Rename channel labels from L/R convention to s/f convention so that
% downstream parameter names are leg-agnostic
fastLeg = getOtherLeg(slowLeg);
lS = angleData.getLabelsThatMatch(['^' slowLeg]);
lF = angleData.getLabelsThatMatch(['^' fastLeg]);

% Silence renameLabels warning temporarily during relabeling
warning('off', 'labTS:renameLabels:dont');
angleData = angleData.renameLabels(lS, regexprep(lS, ['^' slowLeg], 's'));
angleData = angleData.renameLabels(lF, regexprep(lF, ['^' fastLeg], 'f'));
angleData = angleData.renameLabels( ...
    angleData.labels, strcat(angleData.labels, {'Angle'}));
warning('on', 'labTS:renameLabels:dont');

%% Compute and Output Angle Parameters
Angles_alt = computeTSdiscreteParameters( ...
    angleData, gaitEvents, eventTypes);
Angles_HS  = computeHSparameters(angleData, gaitEvents, eventTypes);
out = cat(Angles_alt, Angles_HS);

end


function out = computeEMGParameters( ...
    EMGData, gaitEvents, slowLeg, eventTypes)
% computeEMGParameters  Compute EMG parameters per stride.
%
%   Syntax:
%     out = computeEMGParameters(EMGData, gaitEvents, slowLeg, eventTypes)
%
%   Computes stride-by-stride EMG parameters and returns a
% parameterSeries object that can be concatenated with other parameter
% series objects (e.g., from computeTemporalParameters).
%
%   Inputs:
%     EMGData    - labTimeSeries containing rectified or raw EMG data,
%                  with channel labels prefixed by leg side ('L' or 'R')
%     gaitEvents - labTimeSeries of gait events for the trial
%     slowLeg    - Char specifying the slow-belt leg ('L' or 'R')
%     eventTypes - Cell array of gait event type strings as constructed
%                  in calcParameters (e.g., {'LHS','RTO','RHS','LTO'})
%
%   Outputs:
%     out - parameterSeries object containing all EMG parameters,
%           including statistical and discrete stride-level measures
%           for both mean and median aggregations
%
%   Toolbox Dependencies:
%     None
%
%   See also: computeTemporalParameters, computeSpatialParameters,
%     computeForceParameters, computeTSstatParameters,
%     computeTSdiscreteParameters, parameterSeries, calcParameters

arguments
    EMGData    (1,1)
    gaitEvents (1,1)
    slowLeg    (1,:) char
    eventTypes (1,:) cell
end

%% Pre-Process EMG Labels
% Rename channel labels from L/R convention to s/f convention so that
% downstream parameter names are leg-agnostic
fastLeg = getOtherLeg(slowLeg);
lS = EMGData.getLabelsThatMatch(['^' slowLeg]);
lF = EMGData.getLabelsThatMatch(['^' fastLeg]);

% Silence renameLabels warning temporarily during relabeling
warning('off', 'labTS:renameLabels:dont');
EMGData = EMGData.renameLabels(lS, regexprep(lS, ['^' slowLeg], 's'));
EMGData = EMGData.renameLabels(lF, regexprep(lF, ['^' fastLeg], 'f'));

% Get rectified EMG and strip the 'abs' suffix added by rectify()
newEMG = EMGData.rectify.renameLabels([], EMGData.labels);
warning('on', 'labTS:renameLabels:dont');

%% Compute EMG Parameters
% Select the appropriate heel strike event label based on event class
if strcmp(eventTypes{1}, 'kinLHS') || strcmp(eventTypes{1}, 'kinRHS')
    arrayedEvents = labTimeSeries.getArrayedEvents( ...
        gaitEvents, ['kin' slowLeg 'HS']);
else
    arrayedEvents = labTimeSeries.getArrayedEvents( ...
        gaitEvents, [slowLeg 'HS']);
end

% Statistical parameters for raw EMG (mean-aggregated)
statEMG = computeTSstatParameters(EMGData, arrayedEvents);

% Discrete stride-level parameters for rectified EMG (mean and median)
EMG_alt  = computeTSdiscreteParameters(newEMG, gaitEvents, ...
    eventTypes, []);
EMG_alt2 = computeTSdiscreteParameters(newEMG, gaitEvents, ...
    eventTypes, [], 'nanmedian');

% Prefix median-aggregated parameter labels with 'med' to distinguish
% them from the mean-aggregated parameters in EMG_alt
warning('off', 'labTS:renameLabels:dont');
EMG_alt2 = EMG_alt2.renameLabels( ...
    EMG_alt2.labels, strcat('med', EMG_alt2.labels));
warning('on', 'labTS:renameLabels:dont');

%% Concatenate and Output Computed Parameters
out = cat(statEMG, EMG_alt);
out = cat(out, EMG_alt2);

end


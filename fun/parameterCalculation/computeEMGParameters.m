%% Some pre-process:
%do naming as s/f not L/R:
lS=EMGData.getLabelsThatMatch(['^' slowLeg]);
fastLeg=getOtherLeg(slowLeg);
lF=EMGData.getLabelsThatMatch(['^' fastLeg]);
warning('off','labTS:renameLabels:dont') %Silencing renameLabels warning temporarily
EMGData=EMGData.renameLabels(lS,regexprep(lS,['^' slowLeg],'s'));
EMGData=EMGData.renameLabels(lF,regexprep(lF,['^' fastLeg],'f'));
%Get rectified EMG, remove 'abs' suffix:
newEMG=EMGData.rectify.renameLabels([],EMGData.labels);
warning('on','labTS:renameLabels:dont')

%% Do:
if strcmp(eventTypes{1},'kinLHS') || strcmp(eventTypes{1},'kinRHS')
    arrayedEvents=labTimeSeries.getArrayedEvents(gaitEvents,['kin',slowLeg 'HS']);
    
function out = computeEMGParameters( ...
    EMGData, gaitEvents, slowLeg, eventTypes)
% computeEMGParameters  Compute EMG parameters per stride.
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

else
    arrayedEvents=labTimeSeries.getArrayedEvents(gaitEvents,[slowLeg 'HS']);
end
[statEMG] = computeTSstatParameters(EMGData,arrayedEvents); %Stat parameters for raw EMG
[EMG_alt] = computeTSdiscreteParameters(newEMG,gaitEvents,eventTypes,[]);
[EMG_alt2] = computeTSdiscreteParameters(newEMG,gaitEvents,eventTypes,[],'nanmedian');
warning('off','labTS:renameLabels:dont')
EMG_alt2=EMG_alt2.renameLabels(EMG_alt2.labels,strcat('med',EMG_alt2.labels));
warning('on','labTS:renameLabels:dont')
out=cat(statEMG,EMG_alt);   
out=cat(out,EMG_alt2);
end


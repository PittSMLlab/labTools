function [out] = computeEMGParameters(EMGData,gaitEvents,slowLeg)
%This function computes summary parameters per stride based on EMG data.
%The output is a parameterSeries object, which can be concatenated with
%other parameterSeries objects, for example with those from
%computeTemporalParameters. While this is used for EMG parameters strictly,
%it should work for any labTS.
%See also computeSpatialParameters, computeTemporalParameters,
%computeForceParameters, parameterSeries

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
arrayedEvents=labTimeSeries.getArrayedEvents(gaitEvents,[slowLeg 'HS']);
[statEMG] = computeTSstatParameters(EMGData,arrayedEvents); %Stat parameters for raw EMG
[EMG_alt] = computeTSdiscreteParameters(newEMG,gaitEvents,slowLeg);
[EMG_alt2] = computeTSdiscreteParameters(newEMG,gaitEvents,slowLeg,[],'nanmedian');
EMG_alt2=EMG_alt2.renameLabels(EMG_alt2.labels,strcat('med',EMG_alt2.labels));
out=cat(statEMG,EMG_alt);   
out=cat(out,EMG_alt2);
end


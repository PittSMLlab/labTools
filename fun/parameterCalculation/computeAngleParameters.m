function [out] = computeAngleParameters(angleData,gaitEvents,slowLeg,eventTypes)
%This function computes summary parameters per stride based on Angle data.
%The output is a parameterSeries object, which can be concatenated with
%other parameterSeries objects, for example with those from
%computeTemporalParameters. While this is used for EMG parameters strictly,
%it should work for any labTS.
%See also computeSpatialParameters, computeTemporalParameters,
%computeForceParameters, parameterSeries

%% Some pre-process:
%do naming as s/f not L/R:
lS=angleData.getLabelsThatMatch(['^' slowLeg]);
fastLeg=getOtherLeg(slowLeg);
lF=angleData.getLabelsThatMatch(['^' fastLeg]);
warning('off','labTS:renameLabels:dont') %Silencing renameLabels warning temporarily
angleData=angleData.renameLabels(lS,regexprep(lS,['^' slowLeg],'s'));
angleData=angleData.renameLabels(lF,regexprep(lF,['^' fastLeg],'f'));
angleData=angleData.renameLabels(angleData.labels,strcat(angleData.labels,{'Angle'}));


warning('on','labTS:renameLabels:dont')
%keyboard

%% Do:
[Angles_alt] = computeTSdiscreteParameters(angleData,gaitEvents,eventTypes);
[Angles_HS] = computeHSparameters(angleData,gaitEvents,eventTypes);
out=cat(Angles_alt,Angles_HS);
   
end

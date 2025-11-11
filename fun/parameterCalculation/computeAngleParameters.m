function out = computeAngleParameters(angleData,gaitEvents,slowLeg, ...
    eventTypes)
%This function computes summary parameters per stride for the angle data
%   This function outputs a 'parameterSeries' object, which can be
% concatenated with other 'parameterSeries' objects, for example, with
% those from 'computeTemporalParameters'. While this function is used for
% angle parameters exclusively, it should work for any 'labTS' object.
%
% See also computeSpatialParameters, computeTemporalParameters,
% computeForceParameters, parameterSeries

%% Preprocess Data
% update labeling as slow vs. fast rather than left vs. right
lS = angleData.getLabelsThatMatch(['^' slowLeg]);
fastLeg = getOtherLeg(slowLeg);
lF = angleData.getLabelsThatMatch(['^' fastLeg]);
% temporarily silence 'renameLabels' warning message
warning('off','labTS:renameLabels:dont');
angleData = angleData.renameLabels(lS,regexprep(lS,['^' slowLeg],'s'));
angleData = angleData.renameLabels(lF,regexprep(lF,['^' fastLeg],'f'));
angleData = angleData.renameLabels( ...
    angleData.labels,strcat(angleData.labels,{'Angle'}));
warning('on','labTS:renameLabels:dont');    % resume warning messages

%% Compute & Output Angle Parameters
Angles_alt = computeTSdiscreteParameters(angleData,gaitEvents,eventTypes);
Angles_HS = computeHSparameters(angleData,gaitEvents,eventTypes);
out = cat(Angles_alt,Angles_HS);

end


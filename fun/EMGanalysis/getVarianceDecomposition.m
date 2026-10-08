function [decomposition,meanValue,avgStride,trial2trialVariability] = ...
    getVarianceDecomposition(alignedData)
%GETVARIANCEDECOMPOSITION Split EMG energy into mean, shape, and noise.
%
%   Decomposes the energy of aligned strides into the mean level, the
% variation of the average stride around that mean, and the stride-to-
% stride variability, and returns each as an RMS value. Warns if the
% three parts do not add up to the signal energy within 0.1%.
%
% Inputs:
%   alignedData - aligned strides; time x channels x strides
%
% Outputs:
%   decomposition          - 3 x channels RMS of the mean value, the
%                            average stride shape, and the trial-to-trial
%                            variability
%   meanValue              - mean of the average stride per channel
%   avgStride              - average stride with the mean removed
%   trial2trialVariability - alignedData minus the average stride
%
% Toolbox Dependencies: None

avgStride = mean(alignedData,3);
meanValue = mean(avgStride,1);
trial2trialVariability = bsxfun(@minus,alignedData,avgStride);
avgStride = bsxfun(@minus,avgStride,meanValue);


decomposition(1,:) = meanValue.^2 * size(alignedData,3) * ...
    size(alignedData,1);
decomposition(2,:) = sum(avgStride.^2,1) * size(alignedData,3);
decomposition(3,:) = sum(sum(trial2trialVariability.^2,3),1);


maxEnergyMismatch = 0.001;      % 0.1% of total energy
%Check: difference btw decomposition and actual energy is not more than .1%
%of total energy
if any(sum(decomposition,1)-sum(sum(alignedData.^2,3),1) > ...
        maxEnergyMismatch*sum(sum(alignedData.^2,3),1))
    warning('Decomposition does not add up to actual signal energy')
end


%Normalize decomposition so we get RMS values of each component:
decomposition = ...
    sqrt(decomposition/(size(alignedData,3)*size(alignedData,1)));
end


function alignedData = getAlignedData(this, spacing, trial, ...
    fieldName, labelList)
%getAlignedData  Extracts phase-aligned data
%
%   alignedData = getAlignedData(this, spacing, trial, fieldName,
%   labelList) extracts data aligned to gait phases with specified
%   sample counts per phase
%
%   Inputs:
%       this - stridedExperimentData object
%       spacing - vector specifying number of samples for each of 4
%                 phases [DS_LR, SS_L, DS_RL, SS_R]
%       trial - trial number to extract from
%       fieldName - name of field to extract (e.g., 'procEMGData')
%       labelList - cell array of data labels to extract
%
%   Outputs:
%       alignedData - 3D array (samples x labels x strides) with
%                     phase-aligned data
%
%   See also: strideData/getDoubleSupportLR,
%             strideData/getSingleStanceL

data = this;
M = spacing;
aux = [0 cumsum(M)];
strides = data.stridedTrials{trial};
alignedData = zeros(sum(M), length(labelList), length(strides));
Nphases = 4;
for phase = 1:Nphases
    samples = zeros(length(strides), length(labelList));
    for stride = 1:length(strides)
        switch phase
            case 1
                thisPhase = strides{stride}.getDoubleSupportLR;
            case 2
                thisPhase = strides{stride}.getSingleStanceL;
            case 3
                thisPhase = strides{stride}.getDoubleSupportRL;
            case 4
                thisPhase = strides{stride}.getSingleStanceR;
        end
        alignedData(aux(phase) + 1:aux(phase) + M(phase), :, ...
            stride) = thisPhase.(fieldName).resampleN(M(phase))...
            .getDataAsVector(labelList);
    end
end
end


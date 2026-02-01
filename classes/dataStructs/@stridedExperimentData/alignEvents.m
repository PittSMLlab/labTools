function alignedData = alignEvents(this, spacing, trial, fieldName, ...
    labelList)
%alignEvents  Aligns data to gait events (deprecated)
%
%   alignedData = alignEvents(this, spacing, trial, fieldName,
%   labelList) aligns data to gait events with specified spacing
%
%   Inputs:
%       this - stridedExperimentData object
%       spacing - vector specifying samples per phase
%       trial - trial number
%       fieldName - name of field to align
%       labelList - cell array of labels to extract
%
%   Outputs:
%       alignedData - aligned data array
%
%   Note: This function will be deprecated, use getAlignedData instead
%
%   See also: getAlignedData

% This function will be deprecated, use getAlignedData instead.
alignedData = [];
end


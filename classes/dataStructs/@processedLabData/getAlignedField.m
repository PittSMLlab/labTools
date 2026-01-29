function [alignedField,bad]=getAlignedField(this,field,events,...
    alignmentLengths)
%getAlignedField  Time-aligns field data to gait events
%
%   [alignedField,bad] = getAlignedField(this,field,events,
%   alignmentLengths) aligns the specified field data to the
%   provided gait events with specified resampling lengths
%
%   Inputs:
%       field - name of the data field to align
%       events - cell array of event labels for alignment
%       alignmentLengths - vector specifying the number of
%                          samples between each pair of events
%
%   Outputs:
%       alignedField - time-normalized and resampled data
%       bad - logical vector indicating strides with incomplete
%             or missing events
%
%   See also: labTimeSeries/align, reduce

[alignedField,bad]=this.(field).align(this.gaitEvents,...
    events,alignmentLengths);
end


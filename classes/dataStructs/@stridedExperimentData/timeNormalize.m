function newThis = timeNormalize(this, N)
%timeNormalize  Resamples all strides to uniform length
%
%   newThis = timeNormalize(this, N) resamples all stride data to N
%   samples, creating time-normalized strides
%
%   Inputs:
%       this - stridedExperimentData object
%       N - target number of samples for each stride
%
%   Outputs:
%       newThis - stridedExperimentData object with time-normalized
%                 strides
%
%   See also: strideData/timeNormalize

% Lstrides
newStrides = cell(1, length(this.stridedTrials));
for trial = 1:length(this.stridedTrials)
    thisTrial = this.stridedTrials{trial};
    newTrial = cell(1, length(thisTrial));
    for stride = 1:length(thisTrial)
        thisStride = thisTrial{stride};
        newTrial{stride} = timeNormalize(thisStride, N);
    end
    newStrides{trial} = newTrial;
end

% Construct newTrial
newThis = stridedExperimentData(this.metaData, this.subData, ...
    newStrides);
newThis.isTimeNormalized = true;
end


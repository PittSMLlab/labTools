function [numStrides, trials, initTimes, endTimes] = ...
    getStrideInfo(this, eventClass)
%getStrideInfo  Returns stride timing information
%
%   [numStrides, trials, initTimes, endTimes] = getStrideInfo(this)
%   returns stride count and timing for all trials
%
%   [numStrides, trials, initTimes, endTimes] = getStrideInfo(this,
%   eventClass) uses specified event class
%
%   Inputs:
%       this - experimentData object
%       eventClass - event classification parameter (optional)
%
%   Outputs:
%       numStrides - total number of strides across all trials
%       trials - vector indicating source trial for each stride
%       initTimes - vector of stride start times
%       endTimes - vector of stride end times
%
%   See also: processedLabData/getStrideInfo

numStrides = 0;
initTimes = [];
endTimes = [];
trials = [];
for t = 1:length(this.data)
    if ~isempty(this.data{t})
        [numStrides_, initTimes_, endTimes_] = ...
            getStrideInfo(this.data{t}, eventClass);
        numStrides = numStrides + numStrides_;
        initTimes = [initTimes; initTimes_];
        endTimes = [endTimes; endTimes_];
        trials = [trials; t * ones(numStrides_, 1)];
    end
end
end


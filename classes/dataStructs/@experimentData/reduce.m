function reducedThis = reduce(this, eventLabels, N)
%reduce  Creates reducedLabData for all trials
%
%   reducedThis = reduce(this) reduces all trials using default event
%   labels and resampling
%
%   reducedThis = reduce(this, eventLabels, N) reduces all trials
%   using specified events and sample counts
%
%   Inputs:
%       this - experimentData object
%       eventLabels - cell array of event labels for alignment
%                     (optional, default: based on ref/non-ref legs)
%       N - vector of sample counts between events (optional)
%
%   Outputs:
%       reducedThis - experimentData object with reduced data
%
%   See also: labData/reduce, processedLabData/reduce

if nargin < 2 || isempty(eventLabels)
    s = this.getRefLeg;
    f = this.getNonRefLeg;
    eventLabels = {[s, 'HS'], [f, 'TO'], [f, 'HS'], [s, 'TO']};
end
if nargin < 3
    N = [];
end
redData = cell(size(this.data));
for i = 1:length(this.data)
    redData{i} = this.data{i}.reduce(eventLabels, N);
end
reducedThis = experimentData(this.metaData, this.subData, redData);
end


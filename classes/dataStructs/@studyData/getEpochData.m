function data = getEpochData(this, epochs, labels, summaryFlag)
%GETEPOCHDATA Returns data from all subjects in all groups for each epoch.
%
%   data = getEpochData(this, epochs, labels) extracts specified
% parameter data from all groups for the given epochs
%
%   data = getEpochData(this, epochs, labels, summaryFlag) optionally
% specifies how to summarize the data
%
% Inputs:
%   this        - studyData object
%   epochs      - epoch specification (e.g., 'Early Adaptation', 'Late
%                 Adaptation')
%   labels      - cell array or string of parameter labels to extract
%   summaryFlag - flag controlling data summarization (optional, respects
%                 default in adaptationData.getEpochData)
%
% Outputs:
%   data - extracted data, organized as cell array or matrix depending on
%          whether all groups have same size. If all groups same size:
%          matrix of size [labels x epochs x groups x subjects]. Otherwise:
%          cell array with one cell per group
%
% Toolbox Dependencies: None
%
% See also ADAPTATIONDATA.GETEPOCHDATA, GROUPADAPTATIONDATA.

% Manage inputs:
if nargin < 4
    % Respect default in adaptationData.getEpochData
    summaryFlag = [];
end

if isa(labels, 'char')
    labels = {labels};
end

data        = cell(size(this.groupData));
allSameSize = true;
N           = length(this.groupData{1}.ID);
for ii = 1:length(this.groupData)
    data{ii} = this.groupData{ii}.getEpochData(epochs, labels, summaryFlag);
    allSameSize = allSameSize && N == size(data{ii}, 3);
end
% If all groups are same size, catting into a matrix for easier
% manipulation (this is probably a bad idea)
if allSameSize
    % Cats along dim 2 by default
    data = reshape(cell2mat(data), length(labels), length(epochs), ...
        length(this.groupData), N);
end
end


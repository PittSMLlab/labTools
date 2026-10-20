function epochs = defineEpochs(epochNames,condition,strideNo, ...
    exemptFirst,exemptLast,summaryMethod,shortName)
%DEFINEEPOCHS Create the dataset that defines analysis epochs.
%
%   Builds the dataset used by adaptationData, groupAdaptationData, and
% studyData to describe epochs: condition, stride count, strides to
% exempt, and the function used to summarize the strides. Scalar inputs
% are expanded to all epochs.
%
% Inputs:
%   epochNames    - Nx1 cell array of epoch names
%   condition     - Nx1 cell array of condition names, or one name
%   strideNo      - Nx1 nonzero integers or a scalar; negative values mean
%                   the last M strides, positive the first M strides
%   exemptFirst   - positive number of initial strides to skip
%   exemptLast    - positive number of final strides to skip
%   summaryMethod - (optional) cell array of summary function names,
%                   resolved with str2func (default: 'nanmean')
%   shortName     - (optional) short epoch names
%
% Outputs:
%   epochs - dataset with one row per epoch
%
% Example:
%   epochs = defineEpochs({'Initial_A1','Last_A1','Initial_A2', ...
%       'Last_A2'}, ...
%       {'Adaptation 1','Adaptation 1','Adaptation 1(2nd time)', ...
%       'Adaptation 1(2nd time)'},[5 -40 5 -40],5,5,{'nanmean'});
%
% NOTE: summary names are looked up by name (str2func) in
%   adaptationData.getEpochData, so 'nanmean' must stay a function name.
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox

%% Expand scalar inputs
N = length(epochNames);         % number of epoch names
if isa(condition,'char')        % if character array, ...
    condition = {condition};    % create cell array string
end

if nargin < 6 || isempty(summaryMethod)
    summaryMethod = 'nanmean';
end

%To allow for summaryMethod to be given as string directly
if isa(summaryMethod,'char')
    summaryMethod = {summaryMethod};
end

if numel(condition) == 1
    condition = repmat(condition,N,1);
end

if numel(strideNo) == 1
    strideNo = repmat(strideNo,N,1);
end

if numel(exemptFirst) == 1
    exemptFirst = repmat(exemptFirst,N,1);
end

if numel(exemptLast) == 1
    exemptLast = repmat(exemptLast,N,1);
end

if numel(summaryMethod) == 1
    summaryMethod = repmat(summaryMethod,N,1);
end

earlyOrLate = sign(strideNo) == 1;
if nargin < 7 || isempty(shortName)
    shortName = cell(size(epochNames));
elseif numel(shortName) == 1
    shortName = repmat(shortName,N,1);
end

%% Describe the epochs

%add a description string that can be included when we want a description
%of the epoch, this is helpful string to use when we want to include the
%refEpoch info in any new parameters or any display string to remind us
%what was done.
description = cell(N,1);
for ii = 1:N
    description{ii} = ...
        sprintf(['condition: %s, stride no: %d, exemptfirst: %d, ' ...
        'exceptLast: %d, earlyOrLate: %d, summaryMethod: %s, short ' ...
        'name: %s'],...
        condition{ii},strideNo(ii),exemptFirst(ii), ...
        exemptLast(ii),earlyOrLate(ii),summaryMethod{ii},shortName{ii});
end

%% Build the dataset

epochs = dataset(condition(:),abs(strideNo(:)),exemptFirst(:), ...
    exemptLast(:),earlyOrLate(:),summaryMethod(:),shortName(:), ...
    description(:), ...
    'VarNames',{'Condition','Stride_No','ExemptFirst','ExemptLast', ...
    'EarlyOrLate','summaryMethod','shortName','Description'},'ObsNames', ...
    epochNames);

end


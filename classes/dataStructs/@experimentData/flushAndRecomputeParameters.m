function this = flushAndRecomputeParameters(this, eventClass, ...
    initEventSide, shouldComputeEMGNorm, muscleLabels, ...
    normalizationRefCond, biasRemovalCond)
%flushAndRecomputeParameters  Completely recalculates parameters
%
%   this = flushAndRecomputeParameters(this) discards existing parameters
%   and recomputes all from scratch
%
%   this = flushAndRecomputeParameters(this, eventClass, initEventSide)
%   recomputes with specified options
%
%   Inputs:
%       this - experimentData object
%       eventClass - event classification parameter (optional)
%       initEventSide - initial event side specification (optional)
%       shouldComputeEMGNorm - boolean, indicating if EMG norm parameters
%           should be computed (optional), default false.
%       muscleLabels: cell array of strings that represent the
%           muscleLabels, contains unique muscle names only. e.g., 
%           {'BF'	'GLU'	'LG'	'MG'	'PER'	'SEMT'	'SOL'	'TA'	'VL'
%          'VM'}. If shouldComputeEMGNorm, this arg needs to be provided.
%           If not provided. will throw a warning and make no norm calculations.
%           note only the muscles provided in the list will have norm per
%           muscle calculated and the whole leg norm assumes these are all
%         the muscles available
%       normalizationRefCond: string representing the conditon name that will
%           be used to normalize the EMG data, i.e., all EMG data will be stretched
%           in reference to the last 40 stirdes (excluding the last 5) of this refcondition such that 100%
%           = max of the ref condition, 0 = min of the ref condition.
%       biasRemovalCond: OPTIONAL. string representing the condition name to
%           use to compute bias removed EMG norm. if provided, will remove bias using the providec condition and
%           ignore the trial type (e.g., if provided 'OGBase' will remove
%           OGBase for all types of trials including TM, etc.)
%           If not provided, will use default bias removal behavior which looks
%           for trial type specific baseline (see
%           labTools\classes\dataStructs\@adaptationData\removeBiasV4.m)
%   Outputs:
%       this - experimentData object with new parameters
%
%   Note: Different from recomputeParameters() as it throws away previously
%         existing parameters. recomputeParameters only substitutes if
%         there are name collisions, so it allows for recomputing only
%         force or EMG params.
%
%   Example:
%       expData = expData.flushAndRecomputeParameters();
%
%   See also: recomputeParameters, calcParameters
%   labTools\fun\parameterCalculation\appendEMGNormParameters.m

if nargin < 2 || isempty(eventClass)
    eventClass = [];
end

if nargin < 3 || isempty(initEventSide)
    initEventSide = [];
end
if nargin < 4 || isempty(shouldComputeEMGNorm)
    shouldComputeEMGNorm = false;
end

trials = cell2mat(this.metaData.trialsInCondition);
for t = trials
    this.data{t}.adaptParams = calcParameters(this.data{t}, ...
        this.subData, eventClass, initEventSide);
end

%now add back the norm parameters
if shouldComputeEMGNorm
    if nargin < 5 || isempty(muscleLabels)
        warning('muscleLabels was not provided. Here won not have it in the adaptData freshly created. EMGNorm calculation was not possible. Returning with no change made in params.')
        return
    end
    
    adaptData = this.makeDataObj([]); %make one without saving it.
    if nargin < 6 || isempty(normalizationRefCond) %not provided use default search in order of OG, TM etc
        normalizationRefCond = [];
    end
    if nargin < 7 || isempty(biasRemovalCond) %not provided use default (type specific removal)
        biasRemovalCond = [];
    end
    adaptData = appendEMGNormParameters(adaptData, muscleLabels, normalizationRefCond, biasRemovalCond);
    this = populateNewParamBackToExpData(this,adaptData);
end
end


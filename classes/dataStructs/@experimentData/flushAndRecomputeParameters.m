function this = flushAndRecomputeParameters(this, eventClass, ...
    initEventSide, shouldComputeEMGNorm, muscleLabels, ...
    normalizationRefCond, biasRemovalCond)
%FLUSHANDRECOMPUTEPARAMETERS Discard existing parameters and recompute all.
%
%   Discards all existing adaptation parameters and recomputes from
% scratch. Unlike RECOMPUTEPARAMETERS, no previously computed parameters
% are preserved — this is equivalent to re-running the full parameter
% calculation pipeline from existing processed trial data.
%
% Inputs:
%   this                 - experimentData object
%   eventClass           - (optional) gait event source: '' (default,
%                          auto-select), 'kin', or 'force'
%   initEventSide        - (optional) 'L' or 'R'; defaults to trial
%                          metadata when empty
%   shouldComputeEMGNorm - (optional) logical; compute EMG norm
%                          parameters (default false)
%   muscleLabels         - (optional) cell array of unique muscle label
%                          strings; required when shouldComputeEMGNorm
%                          is true
%   normalizationRefCond - (optional) condition name used to normalize
%                          EMG; uses type-specific search if empty
%   biasRemovalCond      - (optional) condition name for bias removal;
%                          uses type-specific default if empty
%
% Outputs:
%   this - experimentData object with freshly computed parameters
%
% Toolbox Dependencies: None
%
if nargin < 2 || isempty(eventClass)
    eventClass = [];
end
% See also RECOMPUTEPARAMETERS, RECOMPUTEEVENTS,
%   CALCPARAMETERS, APPENDEMGNORMPARAMETERS.

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


function this = recomputeParameters(this, eventClass, initEventSide, ...
    parameterClasses, shouldComputeEMGNorm, muscleLabels, ...
    normalizationRefCond, biasRemovalCond)
%RECOMPUTEPARAMETERS Recalculate stride-by-stride adaptation parameters.
%
%   Recalculates adaptation parameters for all trials in the
% experimental session from existing processed trial data. Unlike
% FLUSHANDRECOMPUTEPARAMETERS, this merges newly computed parameters
% into the existing set, replacing name collisions but preserving
% parameters with different names — enabling partial recomputation
% (e.g., one class only) without discarding other parameters.
%
%   The eventClass must match the one used in the original processing
% run. A different eventClass may produce a different stride count,
% which is incompatible with the merge-in-place behavior of this
% function. Use FLUSHANDRECOMPUTEPARAMETERS when changing eventClass.
%
% Inputs:
%   this                 - experimentData object
%   eventClass           - (optional) gait event source: '' (default,
%                          auto-select), 'kin', or 'force'
%   initEventSide        - (optional) 'L' or 'R'; defaults to trial
%                          metadata when empty
%   parameterClasses     - (optional) string or cell array of parameter
%                          class names to compute; defaults to all
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
%   this - experimentData object with updated parameters
%
% Toolbox Dependencies: None
%
% See also FLUSHANDRECOMPUTEPARAMETERS, RECOMPUTEEVENTS,
%   CALCPARAMETERS, APPENDEMGNORMPARAMETERS.

arguments
    this
    eventClass           (1,:) char    = ''
    initEventSide        (1,:) char    = ''
    parameterClasses                   = []
    shouldComputeEMGNorm (1,1) logical = false
    muscleLabels                       = {}
    normalizationRefCond               = []
    biasRemovalCond                    = []
end

trials = cell2mat(this.metaData.trialsInCondition);
for t = trials
    newParams = calcParameters(this.data{t}, this.subData, ...
        eventClass, initEventSide, parameterClasses);
    this.data{t}.adaptParams = ...
        this.data{t}.adaptParams.replaceParams(newParams);
end

%now add back the norm parameters
if shouldComputeEMGNorm
    if nargin < 6 || isempty(muscleLabels)
        warning('muscleLabels was not provided. Here won not have it in the adaptData freshly created. EMGNorm calculation was not possible. Returning with no change made in params.')
        return
    end
    adaptData = this.makeDataObj([]); %make one without saving it.
    if nargin < 7 || isempty(normalizationRefCond)
        normalizationRefCond = [];
    end
    if nargin < 8 || isempty(biasRemovalCond)
        biasRemovalCond = [];
    end
    adaptData = appendEMGNormParameters(adaptData, muscleLabels, normalizationRefCond, biasRemovalCond);
    this = populateNewParamBackToExpData(this,adaptData);
end
end


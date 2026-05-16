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
for tr = trials
    newParams = calcParameters(this.data{tr}, this.subData, ...
        eventClass, initEventSide, parameterClasses);
    nNew      = size(newParams.Data, 1);
    nExisting = size(this.data{tr}.adaptParams.Data, 1);
    if nNew ~= nExisting
        error('recomputeParameters:strideMismatch', ...
            ['Trial %d: new stride count (%d) differs from ' ...
            'existing (%d). A different eventClass produces ' ...
            'different stride boundaries — use ' ...
            'flushAndRecomputeParameters instead.'], ...
            tr, nNew, nExisting);
    end
    this.data{tr}.adaptParams = ...
        this.data{tr}.adaptParams.replaceParams(newParams);
end

if shouldComputeEMGNorm
    if isempty(muscleLabels)
        warning('recomputeParameters:noMuscleLabels', ...
            ['muscleLabels not provided — EMG norm parameters ' ...
            'were not computed.']);
        return
    end
    adaptData = this.makeDataObj([]);
    adaptData = appendEMGNormParameters( ...
        adaptData, muscleLabels, normalizationRefCond, biasRemovalCond);
    this = populateNewParamBackToExpData(this, adaptData);
end
end

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
% See also RECOMPUTEPARAMETERS, RECOMPUTEEVENTS,
%   CALCPARAMETERS, APPENDEMGNORMPARAMETERS.

arguments
    this
    eventClass           (1,:) char    = ''
    initEventSide        (1,:) char    = ''
    shouldComputeEMGNorm (1,1) logical = false
    muscleLabels                       = {}
    normalizationRefCond               = []
    biasRemovalCond                    = []
end

trials = cell2mat(this.metaData.trialsInCondition);
for tr = trials
    this.data{tr}.adaptParams = calcParameters(this.data{tr}, ...
        this.subData, eventClass, initEventSide);
end

if shouldComputeEMGNorm
    if isempty(muscleLabels)
        warning('flushAndRecomputeParameters:noMuscleLabels', ...
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

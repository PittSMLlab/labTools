%TESTPIPELINERECOMPUTE Template script for regression-testing recompute pipelines.
%
%   Loads a reference experimentData object, runs three recompute
% pipeline variants, and compares each result against the reference
% params.mat. Fill in the file paths and eventClass in the
% Configuration section before running.
%
%   Requires compareAdaptationData (fun/misc/) and the labTools
% directory on the MATLAB path.
%
% See also COMPAREADAPTATIONDATA, TESTING.md.

%% Configuration — fill in before running
% Path to the reference *params.mat saved from known-good code
refParamsFile = '';

% Path to the session MAT file containing the experimentData object
expDataFile = '';

% Event class for Variant B (flushAndRecomputeParameters).
% Use '' for the session default, 'kin' for kinematics, 'force' for GRF.
eventClass = '';

if isempty(refParamsFile) || isempty(expDataFile)
    error('TestPipelineRecompute:missingConfig', ...
        'Set refParamsFile and expDataFile before running.');
end

%% Variant A: recomputeParameters
% Use after changes to fun/parameterCalculation/ or fun/eventExtraction/.
% Recalculates stride-by-stride parameters from existing processed data.
load(expDataFile, 'expData');
expData = expData.recomputeParameters();
newAdaptDataA = expData.makeDataObj();

compareAdaptationData(refParamsFile, newAdaptDataA, ...
    RefName='reference', NewName='recomputeParameters');

%% Variant B: flushAndRecomputeParameters
% Use after changes to raw-processing code (filters, torques, EMG) or
% any step in labData.process. Fully reprocesses from the loaded data.
load(expDataFile, 'expData');
expData = expData.flushAndRecomputeParameters(eventClass);
newAdaptDataB = expData.makeDataObj();

compareAdaptationData(refParamsFile, newAdaptDataB, ...
    RefName='reference', NewName='flushAndRecomputeParameters');

%% Variant C: recomputeParameters with a single parameter class
% Use to scope a test to one parameter class (e.g., 'force', 'temporal',
% 'spatial', 'EMG'). Faster than a full recompute. To test multiple
% classes at once, pass a cell array as the third argument with []
% placeholders for the first two, e.g.:
%   expData.recomputeParameters([], [], {'force', 'spatial'})
load(expDataFile, 'expData');
expData = expData.recomputeParameters('force');
newAdaptDataC = expData.makeDataObj();

compareAdaptationData(refParamsFile, newAdaptDataC, ...
    RefName='reference', NewName='recomputeParameters(force)');

function out = computeForceParameters(strideEvents, GRFData, slowleg, ...
    fastleg, BW, trialData, markerData, subData, FyPSat)
% computeForceParameters  Compute kinetic treadmill parameters per stride.
%
%   Syntax:
%     out = computeForceParameters(strideEvents, GRFData, slowleg, ...
%         fastleg, BW, trialData, markerData, subData)
%     out = computeForceParameters(strideEvents, GRFData, slowleg, ...
%         fastleg, BW, trialData, markerData, subData, FyPSat)
%
%   Analyzes anterior-posterior ground reaction force (GRF) data on a
% stride-by-stride basis, focused on braking and propulsion forces as
% described in Sombric et al. (2019, 2020). Returns a parameterSeries
% object that can be concatenated with other parameter series objects
% (e.g., from computeTemporalParameters).
%
%   Inputs:
%     strideEvents - Struct of stride-level gait event times generated
%                    by calcParameters, with fields tSHS, tFTO, tFHS,
%                    tSTO, tSHS2, and tFTO2 (N-by-1 vectors, in seconds)
%     GRFData      - orientedLabTimeSeries containing ground reaction
%                    force data for the trial
%     slowleg      - Char specifying the slow-belt leg ('L' or 'R')
%     fastleg      - Char specifying the fast-belt leg ('L' or 'R')
%     BW           - Body weight of the subject (in kg)
%     trialData    - processedTrialData object; used for trial type,
%                    description, and inclination angle
%     markerData   - orientedLabTimeSeries containing kinematic marker
%                    data (used for optional COM/COP computations)
%     subData      - subjectData object containing subject information,
%                    including the ID used to detect decline trials
%     FyPSat       - (optional) Saturation value for the slow-leg
%                    propulsion force; passed to the commented-out
%                    computeCOM call. Defaults to [] if omitted.
%
%   Outputs:
%     out - parameterSeries object containing all kinetic parameters
%
%   Toolbox Dependencies:
%     None
%
%   See also: computeTemporalParameters, computeSpatialParameters,
%     ComputeLegForceParameters, DetermineTMAngle, parameterSeries,
%     calcParameters

arguments
    strideEvents (1,1) struct
    GRFData
    slowleg      (1,:) char
    fastleg      (1,:) char
    BW           (1,1) double
    trialData    (1,1)
    markerData
    subData      (1,1)
    FyPSat              = []
end

%% Labels and Descriptions
aux = { ...
    'TMAngle',              'Angle I think the study was run at';...
    'WalkingDirection',     'Identified as a decline trial with subjects walking backwards';...
    'FyBS',                 'GRF-FYs average signed braking';...
    'FyPS',                 'GRF-FYs average signed propulsion';...
    'FyBF',                 'GRF-FYf average signed braking';...
    'FyPF',                 'GRF-FYf average signed propulsion';...
    'FyBSym',               'GRF-FYs average signed Symmetry braking';...
    'FyPSym',               'GRF-FYs average signed Symmetry propulsion';...
    'FxS',                  'GRF-Fxs average force';...
    'FzS',                  'GRF-Fzs average force';...
    'FxF',                  'GRF-Fxf average force';...
    'FzF',                  'GRF-Fzf average force';...
    'HandrailHolding',      'Handrail was being held onto';...
    'ImpactMagS',           'Max anterior-posterior impact force of the slow leg';...
    'ImpactMagF',           'Max anterior-posterior impact force of the fast leg';...
    'FyBSmax',              'GRF-FYs max signed braking';...
    'FyPSmax',              'GRF-FYs max signed propulsion';...
    'FyBFmax',              'GRF-FYf max signed braking';...
    'FyPFmax',              'GRF-FYf max signed propulsion';...
    'FyBmaxSym',            'GRF-FYs max signed Symmetry braking (fast-slow)';...
    'FyPmaxSym',            'GRF-FYs max signed Symmetry propulsion (fast-slow)';...
    'FyBmaxRatio',          'GRF-FYs max signed Ratio braking (s/f)';...
    'FyPmaxRatio',          'GRF-FYs max signed Ratio propulsion (s/f)';...
    'FyBmaxSymNorm',        'GRF-FYs max signed Normalized Ratio braking (abs(fast)-abs(slow))/(abs(fast)+abs(slow))';...
    'FyPmaxSymNorm',        'GRF-FYs max signed Normalized Ratio propulsion (abs(fast)-abs(slow))/(abs(fast)+abs(slow))';...
    'FyBFmaxPer',           'Fast max Braking Percent';...
    'FyBSmaxPer',           'Slow max Braking Percent';...
    'FyPFmaxPer',           'Fast max Propulsion Percent';...
    'FyPSmaxPer',           'Slow max Propulsion Percent';...
    'Slow_Ipsi_FySym',      '[FyBSmax+FyPSmax]';...
    'Fast_Ipsi_FySym',      '[FyBFmax+FyPFmax]';...
    'SlowB_Contra_FySym',   '[FyBSmax+FyPFmax]';...
    'FastB_Contra_FySym',   '[FyBFmax+FyPSmax]';...
    'FyPSsum',              'Summed time normalized slow propulsion force';...
    'FyPFsum',              'Summed time normalized fast propulsion force';...
    'FyBSsum',              'Summed slow braking';...
    'FyBFsum',              'Summed Fast braking';...
    'FxSmax',               'GRF-Fxs max force';...
    'FzSmax',               'GRF-Fzs max force';...
    'FxFmax',               'GRF-Fxf max force';...
    'FzFmax',               'GRF-Fzf max force';...
    'FyBFmax_ABS',          'FyBFmax_ABS';...
    'FyBSmax_ABS',          'FyBSmax_ABS'};

paramLabels = aux(:, 1);
description = aux(:, 2);

%% Retrieve Trial Information and Filter Data
% Retrieve trial description, which contains TM inclination information
% (currently unused directly; retained as reference for the
% commented-out computeCOM call below)
trialDesc   = trialData.description; %#ok<NASGU>
tmAngle     = DetermineTMAngle(trialData);
numStrides  = length(strideEvents.tSHS);

% Normalize forces to body weight (add Nimbus shoe mass for those trials)
if strcmpi(trialData.type, 'NIM')   % if Nimbus shoe trial, ...
    % TODO: update this block to account for weight of new Moonwalkers
    normalizer = 9.81 * (BW + 3.4);    % two Nimbus shoes weigh 3.4 kg
else                                % otherwise, ...
    normalizer = 9.81 * BW;
end
% NOTE: may want to change if desire braking magnitudes
flipB = 1;

if iscell(trialDesc)        % if 'trialDesc' is a cell array, ...
    trialDesc = trialDesc{1};   % retrieve only first element
end

% Determine walking direction sign for force flipping in decline trials
if contains(lower(subData.ID), 'decline')
    flipSign = -1;
else
    flipSign = 1;
end

% Low-pass filter forces prior to all further processing (cutoff: 20 Hz)
filteredGRF = GRFData.lowPassFilter(20);

%% Remove Anterior-Posterior Force Offsets
% CJS (8/5/2016): One decline subject (LD30) had a force plate that was not
% properly zeroed. The Fy offsets are estimated here from the swing phase
% of each leg (when that leg is airborne, Fy should be ~0). Vertical forces
% are assumed to be correctly zeroed during c3d2mat; if they are not, gait
% events will be incorrect and this correction will not help.

% figure; plot(filteredGRF.getDataAsTS([s 'Fy']).Data, 'b');
% hold on; plot(filteredGRF.getDataAsTS([f 'Fy']).Data, 'r');

fastLegOffsetData = nan(1, numStrides - 1);
slowLegOffsetData = nan(1, numStrides - 1);
for st = 1:numStrides - 1
    SHS  = strideEvents.tSHS(st);
    FTO  = strideEvents.tFTO(st);
    FHS  = strideEvents.tFHS(st);
    STO  = strideEvents.tSTO(st);
    FTO2 = strideEvents.tFTO2(st);
    SHS2 = strideEvents.tSHS2(st);

    if isnan(FTO) || isnan(FHS) || FTO > FHS
        fastLegOffsetData(st) = NaN;
    else
        fastLegOffsetData(st) = median(filteredGRF.split(FTO, FHS) ...
            .getDataAsTS([fastleg 'Fy']).Data, 'omitnan');
    end
    if isnan(STO) || isnan(SHS2)
        slowLegOffsetData(st) = NaN;
    else
        slowLegOffsetData(st) = median(filteredGRF.split(STO, SHS2) ...
            .getDataAsTS([slowleg 'Fy']).Data, 'omitnan');
    end
end
fastLegOffset = round(median(fastLegOffsetData, 'omitnan'), 3);
slowLegOffset = round(median(slowLegOffsetData, 'omitnan'), 3);
disp(['Fast Leg Offset: ' num2str(fastLegOffset) ...
    ', Slow Leg Offset: ' num2str(slowLegOffset)]);

% Apply the estimated offsets to the filtered Fy channels
fastFyIdx = find(strcmp(filteredGRF.getLabels(), [fastleg 'Fy']));
filteredGRF.Data(:, fastFyIdx) = ...
    filteredGRF.getDataAsVector([fastleg 'Fy']) - fastLegOffset;
slowFyIdx = find(strcmp(filteredGRF.getLabels(), [slowleg 'Fy']));
filteredGRF.Data(:, slowFyIdx) = ...
    filteredGRF.getDataAsVector([slowleg 'Fy']) - slowLegOffset;

% figure; plot(filteredGRF.getDataAsTS([slowleg 'Fy']).Data, 'b');
% hold on; plot(filteredGRF.getDataAsTS([fastleg 'Fy']).Data, 'r');
% line([0 5*10^5], [0, 0]);

% Incline-specific gravity component along the walking direction (mm/s^2)
levelOfInterest = 0.5 .* flipSign .* cosd(90 - abs(tmAngle));

%% Initialize Output Arrays
TMAngle          = repmat(tmAngle,   1, numStrides);
WalkingDirection = repmat(flipSign,  1, numStrides);
FyBS          = nan(1, numStrides);
FyPS          = nan(1, numStrides);
FzS           = nan(1, numStrides);
FxS           = nan(1, numStrides);
FyBF          = nan(1, numStrides);
FyPF          = nan(1, numStrides);
FzF           = nan(1, numStrides);
FxF           = nan(1, numStrides);
HandrailHolding = nan(1, numStrides);
FyBSmax       = nan(1, numStrides);
FyPSmax       = nan(1, numStrides);
FzSmax        = nan(1, numStrides);
FxSmax        = nan(1, numStrides);
FyBFmax       = nan(1, numStrides);
FyPFmax       = nan(1, numStrides);
FzFmax        = nan(1, numStrides);
FxFmax        = nan(1, numStrides);
FyPSsum       = nan(1, numStrides);
FyPFsum       = nan(1, numStrides);
FyBSsum       = nan(1, numStrides);
FyBFsum       = nan(1, numStrides);
FyBSmax_ABS   = nan(1, numStrides);
FyBFmax_ABS   = nan(1, numStrides);
ImpactMagS    = nan(1, numStrides);
ImpactMagF    = nan(1, numStrides);

%% Compute Stride-by-Stride Force Parameters
% Only compute force parameters for treadmill (TM) trials; overground
% (OG) trials do not have reliable belt force plate data.
if ~isempty(regexp(trialData.type, 'TM')) %#ok<RGXP1>
    for st = 1:numStrides - 1
        SHS  = strideEvents.tSHS(st);
        FTO  = strideEvents.tFTO(st);
        FHS  = strideEvents.tFHS(st);
        STO  = strideEvents.tSTO(st);
        FTO2 = strideEvents.tFTO2(st);
        SHS2 = strideEvents.tSHS2(st);

        % Slow-leg stance phase Fy (SHS to STO), normalized to BW
        if isnan(SHS) || isnan(STO)
            striderS = [];
        else
            striderS = flipSign .* filteredGRF.split(SHS, STO) ...
                .getDataAsTS([slowleg 'Fy']).Data / normalizer;
        end

        % Fast-leg stance phase Fy (FHS to FTO2), normalized to BW
        if isnan(FHS) || isnan(FTO2)
            striderF = [];
        else
            striderF = flipSign .* filteredGRF.split(FHS, FTO2) ...
                .getDataAsTS([fastleg 'Fy']).Data / normalizer;
        end

        % Currently, handrail holding is not computed because data
        % integrity is poor unless it was explicitly collected.
        % HandrailHolding(i) = NaN;

        % Slow leg: compute anterior-posterior force measures
        if ~isempty(striderS) && ~all(striderS == striderS(1)) && ...
                ~isempty(FTO)  && ~isempty(STO)
            % Skip strides where signal is only noise or near-zero
            if std(striderS, 'omitnan') > 0.01 && ...
                    mean(striderS, 'omitnan') > 0.01
                [FyBS(st), FyBSsum(st), FyPS(st), FyPSsum(st), ...
                    FyBSmax(st), FyBSmax_ABS(st), ~, FyPSmax(st), ~, ...
                    ImpactMagS(st)] = ComputeLegForceParameters( ...
                    striderS, levelOfInterest, flipB, ['Epoch: ' ...
                    trialData.name ', Stride#: ' num2str(st) '; SlowLeg']);
            end

            % Vertical and medial-lateral force measures
            FzS(st) = -1 * mean(filteredGRF.split(SHS, STO) ...
                .getDataAsTS([slowleg 'Fz']).Data, 'omitnan') / normalizer;
            FxS(st) = mean(filteredGRF.split(SHS, STO) ...
                .getDataAsTS([slowleg 'Fx']).Data, 'omitnan') / normalizer;
            FzSmax(st) = -1 * min(filteredGRF.split(SHS, STO) ...
                .getDataAsTS([slowleg 'Fz']).Data, [], 'omitnan') ...
                / normalizer;
            FxSmax(st) = min(filteredGRF.split(SHS, STO) ...
                .getDataAsTS([slowleg 'Fx']).Data, [], 'omitnan') ...
                / normalizer;
        end

        % Fast leg: compute anterior-posterior force measures
        if ~isempty(striderF) && ~all(striderF == striderF(1)) && ...
                ~isempty(FTO)  && ~isempty(STO)
            % Skip strides where signal is only noise or near-zero
            if std(striderF, 'omitnan') > 0.01 || ...
                    mean(striderF, 'omitnan') > 0.01
                [FyBF(st), FyBFsum(st), FyPF(st), FyPFsum(st), ...
                    FyBFmax(st), FyBFmax_ABS(st), ~, FyPFmax(st), ...
                    ~, ImpactMagF(st)] = ComputeLegForceParameters( ...
                    striderF, levelOfInterest, flipB, ['Epoch: ' ...
                    trialData.name ', Stride#: ' num2str(st) '; FastLeg']);
            end

            % Vertical and medial-lateral force measures
            % TODO: why min & max here compared to min & min above?
            FzF(st) = -1 * mean(filteredGRF.split(FHS, FTO2) ...
                .getDataAsTS([fastleg 'Fz']).Data, 'omitnan') / normalizer;
            FxF(st) = mean(filteredGRF.split(FHS, FTO2) ...
                .getDataAsTS([fastleg 'Fx']).Data, 'omitnan') / normalizer;
            FzFmax(st) = -1 * min(filteredGRF.split(FHS, FTO2) ...
                .getDataAsTS([fastleg 'Fz']).Data, [], 'omitnan') ...
                / normalizer;
            FxFmax(st) = max(filteredGRF.split(FHS, FTO2) ...
                .getDataAsTS([fastleg 'Fx']).Data, [], 'omitnan') ...
                / normalizer;
        end
    end
end

%% Kinetic Symmetry Measures
FyBSym       = FyBF   - FyBS;
FyPSym       = FyPF   - FyPS;
FyBmaxSym    = FyBFmax - FyBSmax;
FyPmaxSym    = FyPFmax - FyPSmax;
FyBmaxRatio  = FyBSmax ./ FyBFmax;
FyPmaxRatio  = FyPSmax ./ FyPFmax;
FyBmaxSymNorm = (abs(FyBFmax) - abs(FyBSmax)) ./ ...
    (abs(FyBFmax) + abs(FyBSmax));
FyPmaxSymNorm = (abs(FyPFmax) - abs(FyPSmax)) ./ ...
    (abs(FyPFmax) + abs(FyPSmax));
FyBFmaxPer   = abs(FyBFmax) ./ (abs(FyBFmax) + abs(FyBSmax));
FyBSmaxPer   = abs(FyBSmax) ./ (abs(FyBFmax) + abs(FyBSmax));
FyPFmaxPer   = abs(FyPFmax) ./ (abs(FyPFmax) + abs(FyPSmax));
FyPSmaxPer   = abs(FyPSmax) ./ (abs(FyPFmax) + abs(FyPSmax));
Slow_Ipsi_FySym    = FyBSmax + FyPSmax;
Fast_Ipsi_FySym    = FyBFmax + FyPFmax;
SlowB_Contra_FySym = FyBSmax + FyPFmax;
FastB_Contra_FySym = FyBFmax + FyPSmax;

%% Center of Mass (COM): Not Robust Enough for General Code
% if ~isempty(markerData.getLabelsThatMatch('HAT'))
%     outCOM = computeCOM(strideEvents, markerData, BW, slowleg, ...
%         fastleg, impactS, expData, gaitEvents, flipSign, FyPSat);
% else
outCOM.Data        = [];
outCOM.labels      = [];
outCOM.description = [];
% end

%% Center of Pressure (COP): Not Ready to Be Used
% if ~isempty(markerData.getLabelsThatMatch('LCOP'))
%     outCOP = computeCOPParams(strideEvents, markerData, BW, ...
%         slowleg, fastleg, impactS, expData, gaitEvents);
% else
outCOP.Data        = [];
outCOP.labels      = [];
outCOP.description = [];
% end

% if isempty(markerData.getLabelsThatMatch('Hat'))
%     labels = [labels outCOM.labels outCOP.labels];
%     description = [description outCOM.description outCOP.description];
% end

%% Assign Parameters to Data Matrix
data = nan(numStrides, length(paramLabels));
for ii = 1:length(paramLabels)
    eval(['data(:, ii) = ' paramLabels{ii} ';']);
end

%% Output Computed Parameters
out = parameterSeries(data, paramLabels, [], description);

end


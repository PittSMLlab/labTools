function cfg = getStrideQualityConfig()
%GETSTRIDEQUALITYCONFIG Return default stride-quality labeling config.
%
%   Single source of truth for the thresholds and reason-column schema
% used by ADJUDICATESTRIDEQUALITY and FLAGTRIAGEOUTLIERS. Centralizing
% these values here keeps stride-quality labeling identical across
% marker-based and marker-less pipelines: both should call this
% function (or construct an equivalent struct) rather than
% hardcoding thresholds independently.
%
% Outputs:
%   cfg - struct with fields:
%           minStrideDur         - (s) stride shorter than this is bad
%           maxStrideDur         - (s) stride longer than this is bad
%           durationMedianFactor - stride longer than this factor
%                                  times the trial's median duration
%                                  is bad
%           startStopSpeedMmS    - (mm/s) TM single-stance speed below
%                                  this on both legs marks start/stop
%           reasonLabels         - 1xN cell array of all bad-stride
%                                  reason column names, in the order
%                                  they are added to 'basic' parameters
%           reasonDescriptions   - 1xN cell array of descriptions,
%                                  aligned with reasonLabels
%           defaultBadReasons    - subset of reasonLabels folded into
%                                  the aggregate 'bad' flag by default
%           triageParams         - parameter labels checked for triage
%                                  outliers
%           triageWindowStrides  - moving-median window length
%                                  (strides) used by FLAGTRIAGEOUTLIERS
%           triageMadFactor      - multiple of the (MAD-based) robust
%                                  residual scale beyond which a
%                                  stride is flagged for triage
%
% Toolbox Dependencies:
%   None
%
% See also ADJUDICATESTRIDEQUALITY, FLAGTRIAGEOUTLIERS, CALCPARAMETERS,
%   REMOVESTRIDESBYREASON.

% Duration/event thresholds (unchanged from the pre-refactor criteria
% in CALCPARAMETERS; see git history for prior inline location).
minStrideDur         = 0.4;  % TODO: confirm physiological bound rationale
maxStrideDur         = 2.5;  % TODO: confirm physiological bound rationale
durationMedianFactor = 1.5;  % TODO: NWB found 2.5s may be too stringent
                             % for slower older adult walkers, and this
                             % factor alone may suffice to exclude
                             % outliers (especially in overground
                             % trials); consider removing maxStrideDur
startStopSpeedMmS    = 50;   % mm/s; treadmill starting/stopping bound

% Reason schema: one row per stride-quality reason column. Columns not
% yet backed by a stride-level detector are documented STUBs (always
% false) so the reason set stays identical across marker-based and
% marker-less pipelines while detectors are implemented incrementally.
aux = { ...
    'badMissingEvent',    'True if any gait event time (SHS/FTO/FHS/STO/SHS2/FTO2) is missing (NaN) for this stride.'; ...
    'badDisordered',      'True if consecutive gait event times for this stride are out of order (negative time difference).'; ...
    'badDurationOutlier', 'True if stride duration exceeds durationMedianFactor times the trial''s median stride duration.'; ...
    'badDurationShort',   'True if stride duration is shorter than minStrideDur.'; ...
    'badDurationLong',    'True if stride duration is longer than maxStrideDur.'; ...
    'badStartStop',       'True if both legs'' single-stance speed is below startStopSpeedMmS (treadmill starting/stopping); TM trials only, false otherwise.'; ...
    'badTurning',         'STUB: always false. Intended to flag substantial within-stride heading change. TODO: wire to the ''direction'' spatial parameter (computeSpatialParameters) once a turning detector is implemented.'; ...
    'badWalkwayBounds',   'STUB: always false. Intended to flag strides that ended outside the walkway extent (OG trials). TODO: wire to validateMarkerModel''s ''outOfBoundsOutlier'' output (or an equivalent per-stride walkway-extent check).'; ...
    'badMarkerDropout',   'STUB: always false. Intended to flag marker dropout affecting this stride. TODO: wire to markerData.assessMissing / findOutliers per-stride dropout fraction.'; ...
    };
reasonLabels       = aux(:, 1)';
reasonDescriptions = aux(:, 2)';

% Reasons folded into the aggregate 'bad' flag by default. This
% reproduces the pre-refactor aggregate exactly: event/duration
% criteria plus treadmill start/stop. Handrail holding, triage, and
% the stub reasons above are intentionally excluded (opt-in only; see
% REMOVESTRIDESBYREASON and REMOVEHANDRAILSTRIDES).
defaultBadReasons = { ...
    'badMissingEvent', 'badDisordered', 'badDurationOutlier', ...
    'badDurationShort', 'badDurationLong', 'badStartStop'};

% Triage config: non-destructive outlier candidate flagging, not part
% of 'bad'. Parameter set matches the historical (now-removed; see
% CALCPARAMETERS revision history) outlier-detection block.
triageParams = {'stepLengthSlow', 'stepLengthFast', 'alphaSlow', ...
    'alphaFast', 'alphaTemp', 'betaSlow', 'betaFast'};
triageWindowStrides = 3;    % strides; moving-median window for triage
triageMadFactor     = 3.5;  % matches historical 3.5x IQR outlier cutoff

cfg = struct();
cfg.minStrideDur         = minStrideDur;
cfg.maxStrideDur         = maxStrideDur;
cfg.durationMedianFactor = durationMedianFactor;
cfg.startStopSpeedMmS    = startStopSpeedMmS;
cfg.reasonLabels         = reasonLabels;
cfg.reasonDescriptions   = reasonDescriptions;
cfg.defaultBadReasons    = defaultBadReasons;
cfg.triageParams         = triageParams;
cfg.triageWindowStrides  = triageWindowStrides;
cfg.triageMadFactor      = triageMadFactor;

end

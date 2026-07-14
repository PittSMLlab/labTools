function [bad, reasons] = adjudicateStrideQuality( ...
    extendedEventTimes, strideDuration, singleStanceSpeed, ...
    trialType, cfg)
%ADJUDICATESTRIDEQUALITY Label per-reason and aggregate stride quality.
%
%   Central, pure (no parameterSeries dependency) stride-quality
% adjudication used by CALCPARAMETERS. Splitting the historical
% aggregate 'bad' criteria into named reason columns lets the
% aggregate flag stay backward compatible while exposing WHY a stride
% failed, so marker-based and marker-less pipelines can apply an
% identical reason schema and threshold set (see
% GETSTRIDEQUALITYCONFIG) and callers can censor a chosen subset of
% reasons (see REMOVESTRIDESBYREASON).
%
%   CALCPARAMETERS calls this function twice: once early, with
% 'singleStanceSpeed' empty (before force parameters exist), to
% populate the event/duration reasons and a provisional 'bad'; and
% once more at the end of the pipeline, with the actual single-stance
% speed data, to refresh 'badStartStop' and the final aggregate. The
% event/duration reasons are identical between the two calls given the
% same inputs.
%
% Inputs:
%   extendedEventTimes - (numStrides x 6) SHS, FTO, FHS, STO, SHS2,
%                        FTO2 event times (seconds) for each stride
%   strideDuration     - (numStrides x 1) SHS2 - SHS duration (s)
%   singleStanceSpeed  - (numStrides x 2) [fastAbs, slowAbs] single-
%                        stance speed (mm/s), or [] if force
%                        parameters have not yet been computed
%   trialType          - char, trialData.metaData.type (e.g., 'TM',
%                        'OG', 'IN', 'NIM'); badStartStop only applies
%                        to 'TM' trials
%   cfg                - config struct from GETSTRIDEQUALITYCONFIG (or
%                        an equivalent struct with the same fields)
%
% Outputs:
%   bad     - (numStrides x 1) logical, OR of cfg.defaultBadReasons;
%             identical to the pre-refactor aggregate criterion
%   reasons - struct with one (numStrides x 1) logical field per name
%             in cfg.reasonLabels
%
% Toolbox Dependencies:
%   None
%
% See also GETSTRIDEQUALITYCONFIG, FLAGTRIAGEOUTLIERS, CALCPARAMETERS,
%   REMOVESTRIDESBYREASON.

arguments
    extendedEventTimes (:,6) double
    strideDuration      (:,1) double
    singleStanceSpeed          double
    trialType     (1,:) char
    cfg                  struct
end

numStrides = size(extendedEventTimes, 1);

%% Event- and Duration-Based Reasons
% Criterion 1: any event time missing (NaN)
reasons.badMissingEvent = any(isnan(extendedEventTimes), 2);
% Criterion 2: consecutive event times out of order (negative diff)
reasons.badDisordered = any(diff(extendedEventTimes, 1, 2) < 0, 2);
% Criterion 3: stride duration much longer than the trial's median
reasons.badDurationOutlier = strideDuration > ...
    cfg.durationMedianFactor * median(strideDuration, 'omitnan');
% Criterion 4: stride duration too short
reasons.badDurationShort = strideDuration < cfg.minStrideDur;
% Criterion 5: stride duration too long
reasons.badDurationLong = strideDuration > cfg.maxStrideDur;

%% Start/Stop Reason (Treadmill Only)
% Criterion 6: both legs' single-stance speed below threshold marks
% treadmill starting/stopping strides. Requires force parameters, so
% this reason is all-false until the caller's second (end-of-pipeline)
% call, when 'singleStanceSpeed' is available.
if strcmpi(trialType, 'TM') && ~isempty(singleStanceSpeed)
    reasons.badStartStop = ...
        abs(singleStanceSpeed(:, 1)) < cfg.startStopSpeedMmS & ...
        abs(singleStanceSpeed(:, 2)) < cfg.startStopSpeedMmS;
else
    reasons.badStartStop = false(numStrides, 1);
end

%% Stub Reasons (No Stride-Level Detector Yet)
% See GETSTRIDEQUALITYCONFIG.reasonDescriptions for TODO wiring notes.
reasons.badTurning       = false(numStrides, 1);
reasons.badWalkwayBounds = false(numStrides, 1);
reasons.badMarkerDropout = false(numStrides, 1);

%% Aggregate 'bad' Flag
bad = false(numStrides, 1);
for ii = 1:length(cfg.defaultBadReasons)  % for each folded reason, ...
    bad = bad | reasons.(cfg.defaultBadReasons{ii});
end

end

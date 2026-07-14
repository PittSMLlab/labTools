function newThis = removeStridesByReason(this, reasonLabels, markAsNaNflag)
%REMOVESTRIDESBYREASON Remove/NaN strides flagged by chosen reasons.
%
%   General-purpose stride-censoring method: any stride where at least
% one column in 'reasonLabels' is true (1) is flagged for removal (or
% NaN'ing). REMOVEBADSTRIDES and REMOVEHANDRAILSTRIDES both delegate to
% this method with a fixed reason list; call it directly to censor a
% chosen SUBSET of stride-quality reasons (see GETSTRIDEQUALITYCONFIG
% for the reason schema), e.g.:
%   adaptData.removeStridesByReason({'badMissingEvent', 'badDisordered'})
%
%   NOTE: manual 'Label Bad'/'Label Good' edits made in REVIEWEVENTSGUI
% are recorded only in the aggregate 'bad'/'good' columns, not in any
% individual reason column. Include 'bad' in 'reasonLabels' (or call
% REMOVEBADSTRIDES) to also honor those manual edits.
%
%   DESIGN NOTE: the returned object's 'bad'/'good' columns are
% overwritten to reflect exactly the OR of 'reasonLabels' used in THIS
% call (needed for MARKBADSTRIDESASNAN, which reads 'bad' internally,
% and kept for both code paths so 'bad'/'good' mean the same thing
% regardless of 'markAsNaNflag'). This is deliberate, not incidental:
% a stride surviving a narrow reason subset (e.g. only
% 'badMissingEvent') will read 'good' even if it is still bad for a
% different, non-selected reason (e.g. 'badDurationOutlier'). Chaining
% multiple censoring calls should not assume 'bad' still reflects the
% full original aggregate after a subset call; pass the full reason
% list (or use REMOVEBADSTRIDES) if that is what you need.
%
% Inputs:
%   this          - adaptationData object
%   reasonLabels  - string or cell array of parameterSeries column
%                  name(s) to OR together as the censoring criterion
%   markAsNaNflag - (optional) if true, NaN flagged strides instead of
%                  removing rows entirely. Defaults to false.
%
% Outputs:
%   newThis - adaptationData object with flagged strides removed (or
%             NaN'd); unchanged (with a warning) if none of
%             'reasonLabels' are present, or all are entirely NaN
%
% See also REMOVEBADSTRIDES, REMOVEHANDRAILSTRIDES,
%   GETSTRIDEQUALITYCONFIG, MARKBADSTRIDESASNAN.
if nargin < 3 || isempty(markAsNaNflag)
    markAsNaNflag = false;
end
if ischar(reasonLabels)
    reasonLabels = {reasonLabels};
end

if isa(this.data, 'paramData')
    % Legacy paramData-backed objects: pass through unchanged,
    % mirroring REMOVEBADSTRIDES and REMOVEHANDRAILSTRIDES.
    newThis = this;
    return;
end

aux = this.data;
[hasReason, reasonIdxs] = aux.isaLabel(reasonLabels);
validIdxs = reasonIdxs(hasReason);
if isempty(validIdxs) || all(all(isnan(aux.Data(:, validIdxs))))
    warning('adaptationData:noStrideQualityReason', ...
        ['None of the requested stride-quality reason column(s) are ' ...
        'present (or all are entirely NaN) for this subject; ' ...
        'returning object unchanged.']);
    newThis = this;
    return;
end

flagged = any(aux.Data(:, validIdxs) == 1, 2);
[~, badGoodIdxs] = aux.isaParameter({'bad', 'good'});
aux.Data(:, badGoodIdxs) = [flagged, ~flagged];

inds = ~flagged;
if ~markAsNaNflag
    newParamData = parameterSeries(aux.Data(inds, :), ...
        aux.labels, aux.hiddenTime(inds), aux.description);
    newParamData = newParamData.setTrialTypes(aux.trialTypes);
else
    newParamData = aux.markBadStridesAsNan;
end
newThis = adaptationData(this.metaData, this.subData, newParamData);

end

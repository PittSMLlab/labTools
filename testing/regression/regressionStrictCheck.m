function regressionStrictCheck(report, label)
%REGRESSIONSTRICTCHECK Phase-C gate: unmatched strides and NaN mismatches.
%
%   REGRESSIONSTRICTCHECK(report, label) errors unless the
% compareAdaptationData report has 0 unmatched strides on either side,
% 0 NaN mismatches in every compared parameter, no reference-only or
% new-only trials or labels. nChanged alone does not test any of these.
%
% Inputs:
%   report - struct returned by COMPAREADAPTATIONDATA
%   label  - char, name of the check (used in the message)
%
% Outputs:
%   none (prints one STRICT line; errors on failure)
%
% Toolbox Dependencies: None
%
% See also REGRESSIONCOMPARERUN, REGRESSIONPROCESSRUN.

nUnmatched = report.nUnmatchedRef + report.nUnmatchedNew;
nNan       = sum([report.params.nNanMismatches]);
nOnly      = numel(report.refOnlyTrials) + numel(report.newOnlyTrials) ...
    + numel(report.refOnlyLabels) + numel(report.newOnlyLabels);
fprintf(['STRICT %s unmatched strides = %d | NaN mismatches = %d | ' ...
    'ref/new-only trials+labels = %d | strides compared = %d\n'], ...
    label, nUnmatched, nNan, nOnly, report.nStridesCompared);
if nUnmatched > 0 || nNan > 0 || nOnly > 0
    error('regressionStrictCheck:failed', 'Strict check %s failed.', label);
end
end

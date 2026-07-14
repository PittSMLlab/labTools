function triageOutlier = flagTriageOutliers(paramValues, cfg)
%FLAGTRIAGEOUTLIERS Non-destructive stride outlier triage flag.
%
%   Flags candidate outlier strides for human review WITHOUT censoring
% them: the result is never OR'd into the 'bad' aggregate. For each
% column of 'paramValues', computes a moving-median residual and flags
% strides whose residual magnitude exceeds a robust (MAD-based)
% multiple of the residual scale. A stride is flagged if ANY input
% parameter column trips the threshold.
%
%   This is the non-destructive successor to the historical (now
% removed; see CALCPARAMETERS revision history) outlier-detection
% block, which used a 50-sample running average and a 3.5x IQR cutoff
% to directly set the 'bad' flag. This version uses a shorter,
% stride-scaled window and only labels a 'triageOutlier' column for
% review, leaving 'bad' untouched.
%
% Inputs:
%   paramValues - (numStrides x numParams) matrix of parameter values
%                (e.g., stepLengthSlow, alphaFast, ...; NaN allowed)
%   cfg         - config struct from GETSTRIDEQUALITYCONFIG; uses the
%                'triageWindowStrides' and 'triageMadFactor' fields
%
% Outputs:
%   triageOutlier - (numStrides x 1) logical; true if any parameter's
%                  residual exceeds the robust threshold for that
%                  stride
%
% Toolbox Dependencies:
%   None
%
% See also GETSTRIDEQUALITYCONFIG, ADJUDICATESTRIDEQUALITY,
%   CALCPARAMETERS.

arguments
    paramValues (:,:) double
    cfg          struct
end

numStrides = size(paramValues, 1);
triageOutlier = false(numStrides, 1);
madToSigmaFactor = 1.4826;  % MAD-to-std consistency factor (normality)

for jj = 1:size(paramValues, 2)     % for each triage parameter, ...
    paramCol = paramValues(:, jj);
    if all(isnan(paramCol))
        continue
    end
    residual = paramCol - ...
        movmedian(paramCol, cfg.triageWindowStrides, 'omitnan');
    robustSigma = madToSigmaFactor * median( ...
        abs(residual - median(residual, 'omitnan')), 'omitnan');
    if robustSigma == 0 || isnan(robustSigma)
        continue  % degenerate (constant or all-NaN) residual: skip
    end
    triageOutlier = triageOutlier | ...
        (abs(residual) > cfg.triageMadFactor * robustSigma);
end

end

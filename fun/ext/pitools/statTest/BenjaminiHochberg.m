function [h, pThreshold, i1, pAdjusted] = BenjaminiHochberg(p, fdr, twoStageFlag)
%BENJAMINIHOCHBERG Benjamini-Hochberg FDR correction for multiple comparisons.
%
%   Determines significance across multiple comparisons while controlling
%   the False Discovery Rate (expected fraction of false positives among
%   all rejections). Less conservative than Bonferroni correction; FDR
%   control holds in expectation over many realizations.
%
%   Validated Oct 2017 against fdr_bh() (MATLAB File Exchange) and
%   Nov 2018 against the Bioinformatics Toolbox mafdr().
%
%   References:
%     Benjamini & Hochberg 1995
%     Yekuteli & Benjamini 1999 (adjusted p-values)
%     Benjamini, Krieger & Yekuteli 2006 (two-stage procedure)
%
% Inputs:
%   p            - vector of p-values from multiple comparisons
%   fdr          - scalar in [0,1]; tolerated False Discovery Rate
%   twoStageFlag - (optional) logical; if true, applies the BKY two-stage
%                  procedure (more power, same FDR guarantees under
%                  independent tests); default false
%
% Outputs:
%   h          - binary vector; 1 where p-value is significant, 0 elsewhere
%   pThreshold - p-value cut-off; satisfies h = (p <= pThreshold)
%   i1         - number of significant results; equals sum(h)
%   pAdjusted  - adjusted p-values; significant where pAdjusted < fdr
%
% Toolbox Dependencies: None
%
% See also MAFDR.

arguments
    p            {mustBeVector, mustBeNumeric}
    fdr    (1,1) double {mustBeInRange(fdr, 0, 1)}
    twoStageFlag (1,1) logical = false
end

if twoStageFlag
    % BKY procedure uses fdr/(1+fdr) in both passes for FDR guarantee,
    % though authors later suggest using fdr itself in the first pass.
    fdr = fdr / (1 + fdr);
end

M = numel(p);  % total number of comparisons

%% Sort and Apply BH Threshold
[p1, idx] = sort(p(:), 'ascend');
h1        = zeros(size(p1));
lastSig   = find(p1 < fdr * (1:M)' / M, 1, 'last');
if isempty(lastSig)
    i1 = 0;
else
    i1 = lastSig;
end

h1(1:i1) = 1;  % significant results
h         = nan(size(p));
h(idx)    = h1;  % restore original ordering

pThreshold = p1(lastSig);

%% Compute Adjusted P-Values
if nargout > 3
    pAdjusted = nan(size(p));
    newP      = p1 * M ./ (1:M)';
    for ii = (length(newP) - 1):-1:1
        if newP(ii) > newP(ii + 1)
            newP(ii) = newP(ii + 1);
        end
    end
    pAdjusted(idx) = newP;
end

%% Two-Stage Recursive Call
if twoStageFlag
    [h, pThreshold, i1] = BenjaminiHochberg(p, fdr * M / (M - i1), false);
end

end

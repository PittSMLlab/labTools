function [h,pThreshold,i1,pAdjusted] = BenjaminiHochberg(p,fdr,twoStageFlag)
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

if nargin<3 || isempty(twoStageFlag)
    twoStageFlag=false;
end
if twoStageFlag
    fdr=fdr/(1+fdr); %BKY procedure requires using this value
    %in the first and second pass for FDR guarantee, although authors later use fdr
    %itself for the first pass and claim that it is ok in practice.
end

M=numel(p); %No. of total comparisons

[p1,idx]=sort(p(:),'ascend');
h1=zeros(size(p1));
ii=find(p1 < fdr*[1:M]'/M,1,'last');
if isempty(ii)
    i1=0;
else
    i1=ii;
end

h1(1:i1)=1; %Significant results
h=nan(size(p));
h(idx)=h1; %Re-sorting

pThreshold=p1(ii);

if nargout>3 %Computing adjusted p-values
    %Adjusted p-values are the thing that is compared to fdr
    pAdjusted=nan(size(p));
    newP=p1*M./[1:M]';
    for i=(length(newP)-1):-1:1
        if newP(i)>newP(i+1)
            newP(i)=newP(i+1);
        end
    end
    pAdjusted(idx)=newP;
end

if twoStageFlag
    [h,pThreshold,i1] = BenjaminiHochberg(p,fdr*M/(M-i1),false);
end

end

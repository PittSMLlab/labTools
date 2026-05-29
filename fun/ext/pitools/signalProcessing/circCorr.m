function lag=circCorr(trace1,trace2)
%CIRCCORR Estimate the phase shift between two sinusoidal traces.
%
%   Performs a circular (cyclic) correlation by iteratively shifting
% trace2 and computing the normalized inner product with trace1 at each
% lag. The peak-lag index is returned as a fraction of the cycle length.
% NOTE: the formula is equivalent to Pearson r only when both inputs are
% zero-mean; callers must center traces before calling if needed.
%
% Inputs:
%   trace1 - (n x 1) reference sinusoidal trace (zero-mean assumed)
%   trace2 - (n x 1) sinusoidal trace to shift (zero-mean assumed);
%            both vectors must have the same length n
%
% Outputs:
%   phaseShift - phase shift as a fraction of cycle length (0 to 1),
%                or NaN if peak correlation falls below quality
%                threshold (0.5) or inputs have zero variance
%
% Toolbox Dependencies:
%   None
%
% See also COMPUTESPATIALPARAMETERS.

s1=std(trace1);
s2=std(trace2);

c=[];
n=length(trace1);
for t=1:n
    c(t)=(trace1'*trace2)./((n-1)*s1*s2);
    trace2=circshift(trace2,1);
end

[cmax,lag]=max(c);
lag=lag/n;

if cmax<0.5 || isnan(cmax)
    lag=NaN;
end

end

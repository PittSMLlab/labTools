function[T,P,df] = BPtest(z,studentize)

% INPUTS:
% z:            an object of class 'LinearModel' or a (n x p) matrix with the last
%               column corresponding to the dependent (response) variable and the first p-1 columns
%               corresponding to the regressors. Do not include a column of ones for the
%               intercept, this is automatically accounted for.

% studentize:   optional flag (logical). if True the studentized Koenker's statistic is
%               used. If false the statistics from the original Breusch-Pagan test is
%               used.

% OUTPUTS: 
% BP:    test statistics.
% P:     P-value. 
% df:    degrees of freedom of the asymptotic Chi-squared distribution of BP



if nargin == 1
    studentize = true;
end

if isa(z, 'LinearModel')
    n  = height(z.Variables);
    df = z.NumPredictors;    
    x = z.Variables{:,z.PredictorNames};
    %tODO: this won't work if some variables are categorical, should add a
    %fix to auto-detect categorical and change code accordingly
    r = z.Residuals.Raw;
else   
    
    x = z(:,1:end-1);
    y = z(:,end);    
    n = numel(y);
    df = size(x,2);    
    lm = fitlm(x,y);
    r = lm.Residuals.Raw;    
    
end


aux = fitlm(x,r.^2);
T = aux.Rsquared.Ordinary*n;

if ~studentize
    lam = (n-1)/n*var(r.^2)/(2*((n-1)/n*var(r)).^2);
    T  = T*lam;
end

P = 1-chi2cdf(abs(T),df);

end

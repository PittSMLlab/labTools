function coefs = coefExtrFromSyn(data,syn)
%COEFEXTRFROMSYN Activation coefficients that fit data from synergies.
%
%   Solves the least squares problem data = syn * act for each row of data
% with non-negative activations (lsqnonneg), in parallel over rows.
%
% NOTE: opens and closes a pool with matlabpool, which no longer exists in
%   current MATLAB releases, so the call fails there.
%
% Inputs:
%   data - samples x channels matrix to reconstruct
%   syn  - synergy matrix, channels x synergies
%
% Outputs:
%   coefs - activations, synergies x samples
%
% Toolbox Dependencies: Parallel Computing Toolbox (parfor)


opts = optimset('display','off','TolFun',0.0001/size(data,2)^2,'TolX', ...
    0.0001);
x0   = ones(size(syn,2),size(data,1));

poolFlag = 0;
matlabpool size;
if (ans == 0)
    matlabpool open
    poolFlag = 1;
end

coefs = [];
parfor ii = 1:size(data,1)
    x0 = ones(size(syn,2),1);
    coefs(:,ii) = lsqnonneg(syn,data(ii,:)',opts);
end

if poolFlag == 1
    matlabpool close
end
end


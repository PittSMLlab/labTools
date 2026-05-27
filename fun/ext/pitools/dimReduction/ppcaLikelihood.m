function [logL] = ppcaLikelihood(data,coeff,latents,mu)
%PPCALIKELIHOOD Log-likelihood under probabilistic PCA.
%
%   Returns the log-likelihood of observing data given a PCA result,
%   under a probabilistic PCA (PPCA) model. coeff and latents should be
%   obtained from pca(). Useful for estimating the intrinsic dimensionality
%   of a dataset.
%
%   Model: data' = repmat(mu, N, 1) + coeff' * scores + noise
%
% Inputs:
%   data    - N-by-D observation matrix
%   coeff   - k-by-D matrix of PCA coefficients (one row per component)
%   latents - D-by-1 vector of eigenvalues from pca()
%   mu      - (optional) 1-by-D mean vector; defaults to zero if omitted
%
% Outputs:
%   logL - scalar log-likelihood; NaN when k >= D (model undefined)
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
%
% See also PCA.

%Parameters are such that data'=repmat(mu,N,1)+coeff'*scores + e;

if nargin<4 %In this case, assuming either the data had exactly zero mean or the analysis performed was on uncentered data and hence the mean parameter is by definition useless.
    mu=zeros(1,size(data,2));
end


N=size(data,1); %Sample size
D=size(data,2); %Sample dimensionality
k=size(coeff,1); %Number of components in reduced dimensionality space (reduced dim)


%Just in case: normalize so that the coeffs have norm=1
for i=1:k
   coeff(i,:)=coeff(i,:)/norm(coeff(i,:)); 
end

centData=data-repmat(mu,N,1);
S=centData'*centData/N;
if k<D %If k==D there is no need to do anything, the model makes no sense anyway. Returning NaN.
    sigma=sqrt(sum(latents(k+1:D))/(D-k));


    W=(coeff'*diag(sqrt(latents(1:k)-sigma^2)))'; %Eigen vectors are scaled by the sqrt(\lambda-sigma^2), which roughly means they are scaled by the standard deviation along that direction, discounting the portion of the variance that is attributed to noise.


    M=W*W' + sigma^2*eye(k);
    bb=svd(W');
    eigM=bb.^2 + sigma^2; %This should be exactly latents(1:k)

    Cinv=(eye(D)- W'*(M\W))/sigma^2;

    C=W'*W+sigma^2*eye(D); %If I understand this properly, C has the same first k eigenvectors and eigenvalues as S (when the coeff are extracted from the matrix S), and has the same trace (sum of all eigenvalues). If this is true, I expect trace(Cinv*S)= D (unless any of the eigenvalues of C is exactly 0, in which case this is undetermined), and then the only term of the likelihood that changes with k is det(C)
    aux=bb.^2;
    if length(aux)<D
        aux(end+1:D)=0;
    end
    detC=prod(aux + sigma^2); %Alt. calculation of det(C) to avoid numerical issues

    logL=-.5*N * (D*log(2*pi) + log(det(C)) + trace(Cinv*S)); 
    logL=-.5*N * (D*log(2*pi) + log(detC) + trace(pinv(C)*S)); %Alt. calc to avoid numerical errors
else
    logL=NaN;
end
end


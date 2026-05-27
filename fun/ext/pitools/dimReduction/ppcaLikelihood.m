function logL = ppcaLikelihood(data, coeff, latents, mu)
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

arguments
    data
    coeff
    latents
    mu = []
end

if isempty(mu)
    mu = zeros(1, size(data, 2));
end

N = size(data, 1);  % sample size
D = size(data, 2);  % sample dimensionality
k = size(coeff, 1); % number of retained components

%% Normalize Coefficients
for ii = 1:k
    coeff(ii, :) = coeff(ii, :) / norm(coeff(ii, :));
end

centData = data - repmat(mu, N, 1);
S        = centData' * centData / N;

%% Compute Log-Likelihood
% If k == D the noise-free model is undefined; return NaN.
if k < D
    sigma = sqrt(sum(latents(k+1:D)) / (D - k));

    % Eigenvectors scaled by sqrt(lambda - sigma^2): each direction is
    % scaled by the std beyond the noise floor.
    W = (coeff' * diag(sqrt(latents(1:k) - sigma^2)))';

    M    = W * W' + sigma^2 * eye(k);
    bb   = svd(W');
    eigM = bb.^2 + sigma^2;  % should equal latents(1:k)

    Cinv = (eye(D) - W' * (M \ W)) / sigma^2;

    % C shares the first k eigenvectors/eigenvalues with S and has the
    % same trace. Consequently trace(Cinv*S) = D when no eigenvalue of
    % C is zero, so the only k-dependent term in logL is det(C).
    C = W' * W + sigma^2 * eye(D);

    aux = bb.^2;
    if length(aux) < D
        aux(end+1:D) = 0;
    end
    detC = prod(aux + sigma^2);  % alt det(C) to avoid numerical issues

    logL = -0.5 * N * ...
        (D * log(2*pi) + log(det(C)) + trace(Cinv * S));
    logL = -0.5 * N * ...
        (D * log(2*pi) + log(detC) + trace(pinv(C) * S));
else
    logL = NaN;
end
end

function [W, C, d] = myNNMF(data, rank, reps, useParallel)
%MYNNMF Non-negative matrix factorisation with robust defaults.
%
%   Calls nnmf() with custom convergence tolerances and multiple random
%   initialisations to obtain more consistent results than a single run.
%
% Inputs:
%   data        - matrix to factorize (observations-by-features; transposed
%                 automatically when features exceed observations)
%   rank        - desired factorization rank (dimensionality)
%   reps        - (optional) number of random initialisations; default 8
%   useParallel - (optional) parallel-computation flag passed to statset;
%                 default 'always'
%
% Outputs:
%   W - left factor matrix (observations-by-rank)
%   C - right factor matrix (rank-by-features)
%   d - residual norm
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
%
% See also NNMF, STATSET.

arguments
    data
    rank        (1,1) {mustBeInteger, mustBeNonnegative}
    reps        (1,1) {mustBeInteger, mustBePositive}   = 8
    useParallel                                          = 'always'
end

if size(data, 1) < size(data, 2)
    data = data';
end

%% Handle Edge Cases
if rank == 0
    disp('There are no possible factorizations of rank 0, returning')
    return
elseif rank == size(data, 2)
    %disp('Full rank factorization: returning original matrix.')
    C = eye(size(data, 2));
    W = data;
    d = 0;
    return
end

%% Set Algorithm Parameters
nm  = numel(data);
alg = 'als';  % TODO: verify this is the optimal algorithm choice

% tolF: 0.1% relative tolerance in the objective function.
% Equals 0.001 * max(F) / rank^2 where F is the Frobenius-norm error.
tolF = sqrt(0.0001 * norm(data, 'fro')^2 / (nm * (rank^2))) + eps;

% tolX: convergence fires when the largest per-element change in W or C
% falls below 0.01% of the maximum element in those matrices.
tolX = 0.0001;

opts = statset('TolFun', tolF, 'TolX', tolX, ...
    'UseParallel', useParallel, 'Display', 'off');

%% Run NNMF
[W, C, d] = nnmf(data, rank, 'replicates', reps, ...
    'algorithm', alg, 'options', opts);

end

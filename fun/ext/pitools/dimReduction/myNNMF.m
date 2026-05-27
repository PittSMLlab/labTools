function [W,C,d] = myNNMF(data,rank,reps,useParallel)
if nargin<4
    useParallel='always';
end
if nargin<3
    reps=8;
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

end

if size(data,1)<size(data,2)
    data=data';
end

if rank==0
    disp('There are no possible factorizations of rank 0, returning')
    return
elseif rank==size(data,2)
    %disp('Full rank factorization: returning original matrix.')
    C=eye(size(data,2));
    W=data;
    d=0;
    return
end

nm=numel(data);
alg='als'; %Should verify this is the best choice
tolF=sqrt(.0001*norm(data,'fro')^2/(nm*(rank^2))) + eps; % 0.1% tolerance in objective function (note that this is 1/1000th of the max value for the tolerance function F)divided by desired rank squared.
tolX=0.0001; %This is as a percentage (0.01%). It will determine convergence if the element that changes the most in W or H changes less than 0.01% of the highest element in those matrices.

opts=statset('TolFun',tolF,'TolX',tolX,'UseParallel',useParallel,'Display','off');

[W,C,d]=nnmf(data,rank,'replicates',reps,'algorithm',alg,'options',opts);


end


function [syns,coefs,res,fullSyns] = getSynergies(data,dim,replicates,usePar)
%Returns the non-negative matrix factorization with normalized synergies

%% Check if replicates is given, if not, default
if nargin<4
    usePar='never';
end
if nargin<3
    replicates=5; %default value
end

%% Check if data is given so that the short dimension is the second one
if size(data,2)>=size(data,1)
    data=data';
    disp('Warning: data was given in the transposed form')
end

    %% Get synergies
    %Auto-replicating:
    [coefs,syns,res]=myNNMF(data,dim,replicates,usePar); %Normalized coefs
    coefs=coefs';
    syns=syns';
    res=(res*numel(data))^2;
end


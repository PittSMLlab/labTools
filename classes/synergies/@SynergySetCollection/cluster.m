function [clusteredSet,clusteringIndexes] = cluster(this,method,Nclusters)
%CLUSTER Hierarchical clustering of all synergies in a collection.
%
%   Stacks every synergy with getContentAsSet, computes the pairwise angles
% (SynergySet.distance), and builds an average-linkage tree. If Nclusters is
% empty, the number of clusters is increased from 1 until no cluster
% contains two synergies from the same SynergySet; otherwise the tree is cut
% at Nclusters.
%
% Inputs:
%   this      - SynergySetCollection object
%   method    - not used
%   Nclusters - number of clusters to force (optional)
%
% Outputs:
%   clusteredSet      - ClusteredSynergySetCollection with one SynergySet
%                       per cluster
%   clusteringIndexes - cell array shaped like the collection; cell k is a
%                       column vector with the cluster index of every
%                       synergy in set k
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox
%
% See also LINKAGE, CLUSTEREDSYNERGYSETCOLLECTION.

if nargin < 3
    Nclusters = [];
end

[contentAsSet,originalIndexes] = getContentAsSet(this);
whatMatters = contentAsSet.content;
%Should coincide with length(originalIndexes)
Nelements = size(whatMatters,2);

%% -----------------------------------------------------------------
%%Clustering method 1

%Compute appropriate distance matrix:
D = distance(contentAsSet);

%Compute linkage tree
%Can also use 'single' or 'complete' linkage. 'Single' gives not so nice
%results.
Z = linkage(D,'average');
%Dendrogram (for debugging purposes):
%figure
%dendrogram(Z)

%Succesively increase cluster number until there are no collisions, unless
%Nclusters is provided
%Collisions are defined when two elements with equal originalIndexes are
%classified as members of the same cluster.
if ~isempty(Nclusters)
    %Force number of clusters
    T = cluster(Z,'maxclust',Nclusters);
else
    %Iteratively increase number of clusters
    forbidden   = 1;
    clusterSize = 0;
    while forbidden
        %STEP 1: Increase cluster size
        clusterSize = clusterSize+1;
        %STEP 2: Do clustering
        T = cluster(Z,'maxclust',clusterSize);
        %Check if forbidden
        forbidden = ~checkBelongings(T,originalIndexes(:,1));
    end
end

%Assign output arguments
clusteringIndexes = cell(this.getCollectionSize);
for ii = 1:length(T)
    j = ind2sub(this.getCollectionSize,originalIndexes(ii,1));
    clusteringIndexes{j}(originalIndexes(ii,2),1) = T(ii);
end
clusteredSet = ClusteredSynergySetCollection(clusteringIndexes, ...
    this.content,this.indexCategories,this.indexLabels,this.name);

%-----------------------------------------------------------------
end


function [clusteredSet,clusteringIndexes]=cluster(this,method,Nclusters)

%CLUSTER Implementation of the cluster function for the class
%SynergySetCollection

if nargin<3
    Nclusters=[];
end

[contentAsSet,originalIndexes]=getContentAsSet(this);
whatMatters=contentAsSet.content;
Nelements=size(whatMatters,2); %Should coincide with length(originalIndexes)

%% -----------------------------------------------------------------
%%Clustering method 1

%Compute appropriate distance matrix:
D=distance(contentAsSet);

%Compute linkage tree
Z = linkage(D,'average'); %Can also use 'single' or 'complete' linkage. 'Single' gives not so nice results.
%Dendrogram (for debugging purposes):
%figure
%dendrogram(Z)

%Succesively increase cluster number until there are no collisions, unless Nclusters is provided
%Collisions are defined when two elements with equal originalIndexes are
%classified as members of the same cluster.
if ~isempty(Nclusters)
    %Force number of clusters
    T = cluster(Z,'maxclust',Nclusters);
else
    %Iteratively increase number of clusters
    forbidden=1;
    clusterSize=0;
    while forbidden
        %STEP 1: Increase cluster size
        clusterSize=clusterSize+1;
        %STEP 2: Do clustering
        T = cluster(Z,'maxclust',clusterSize);
        %Check if forbidden
        forbidden=~checkBelongings(T,originalIndexes(:,1));
    end
end

%Assign output arguments
clusteringIndexes=cell(this.getCollectionSize);
for i=1:length(T)
    j=ind2sub(this.getCollectionSize,originalIndexes(i,1));
    clusteringIndexes{j}(originalIndexes(i,2),1)=T(i);
end
clusteredSet=ClusteredSynergySetCollection(clusteringIndexes,this.content,this.indexCategories,this.indexLabels,this.name);

%-----------------------------------------------------------------
end


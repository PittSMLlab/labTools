classdef ClusteredSynergySetCollection < SynergySetCollection
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        originalCollection %Saving the original, unclustered synergySetCollection, just in case
        indexInOriginalCollection %Saving the linear indexes on the original collection
    end
    
    
    methods
        function s=ClusteredSynergySetCollection(clusteringIndexes,unclusteredCollectionContents,unclusteredCollectionCategories,unclusteredCollectionLabels,unclusteredCollectionName)
            clusteringIndexesAsMatrix=cell2mat(clusteringIndexes(:));
            for i=1:max(clusteringIndexesAsMatrix(:))
                content=[];
                originalIndexes=[]; %Here the index of the collection element (SynergySet) with respect to the full collection is saved
                originalIndexes2=[]; %Here the index of the particular element within the SynegySet is saved
                for j=1:numel(unclusteredCollectionContents)
                    aux=[1:length(clusteringIndexes{j})];
                    if any(clusteringIndexes{j}==i)
                        content=[content;unclusteredCollectionContents{j}.content(clusteringIndexes{j}==i,:)];
                        originalIndexes=[originalIndexes;j*ones(sum(clusteringIndexes{j}==i),1)];
                        originalIndexes2=[originalIndexes2;aux(clusteringIndexes{j}==i)];
                    end
                end
                sindexInOriginalCollection{i}=[originalIndexes,originalIndexes2];
                scontent{i,1}=SynergySet(content,unclusteredCollectionContents{1}.muscleList);
                indexLabels{1}{i,1}=num2str(i);
            end
            s=s@SynergySetCollection(scontent,{'Cluster'},indexLabels);%Call superclass constructor
            s.indexInOriginalCollection=sindexInOriginalCollection;
            s.originalCollection=SynergySetCollection(unclusteredCollectionContents,unclusteredCollectionCategories,unclusteredCollectionLabels,unclusteredCollectionName);
            s.name=['Clustered ' unclusteredCollectionName];
        end
        
        [figHandle,subplotHandles]=plot(this); %Override
        function display(this) %Override. Is this necessary?
            display@SynergySetCollection(this)
        end
        function figHandle=plotAs3DSpace(this)
            %Use multidim scaling to plot the cluster elements as points in
            %a 3D space
        end
    end
    
end


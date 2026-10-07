classdef ClusteredSynergySetCollection < SynergySetCollection
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        %Saving the original, unclustered synergySetCollection, just in case
        originalCollection
        %Saving the linear indexes on the original collection
        indexInOriginalCollection
    end


    methods
        function s = ClusteredSynergySetCollection(clusteringIndexes, ...
            unclusteredCollectionContents, ...
            unclusteredCollectionCategories,unclusteredCollectionLabels, ...
            unclusteredCollectionName)
            clusteringIndexesAsMatrix = cell2mat(clusteringIndexes(:));
            for ii = 1:max(clusteringIndexesAsMatrix(:))
                content = [];
                %Here the index of the collection element (SynergySet) with
                %respect to the full collection is saved
                originalIndexes = [];
                %Here the index of the particular element within the
                %SynegySet is saved
                originalIndexes2 = [];
                for jj = 1:numel(unclusteredCollectionContents)
                    aux = [1:length(clusteringIndexes{jj})];
                    if any(clusteringIndexes{jj} == ii)
                        content = ...
                            [content; ...
                            unclusteredCollectionContents{jj}.content( ...
                            clusteringIndexes{jj} == ii,:)];
                        originalIndexes = ...
                            [originalIndexes; ...
                            jj*ones(sum(clusteringIndexes{jj} == ii),1)];
                        originalIndexes2 = ...
                            [originalIndexes2; ...
                            aux(clusteringIndexes{jj} == ii)];
                    end
                end
                sindexInOriginalCollection{ii} = ...
                    [originalIndexes,originalIndexes2];
                scontent{ii,1} = SynergySet(content, ...
                    unclusteredCollectionContents{1}.muscleList);
                indexLabels{1}{ii,1} = num2str(ii);
            end
            %Call superclass constructor
            s = s@SynergySetCollection(scontent,{'Cluster'},indexLabels);
            s.indexInOriginalCollection = sindexInOriginalCollection;
            s.originalCollection = ...
                SynergySetCollection(unclusteredCollectionContents, ...
                unclusteredCollectionCategories, ...
                unclusteredCollectionLabels,unclusteredCollectionName);
            s.name = ['Clustered ' unclusteredCollectionName];
        end

        [figHandle,subplotHandles] = plot(this); %Override
        function display(this) %Override. Is this necessary?
            display@SynergySetCollection(this)
        end
        function figHandle = plotAs3DSpace(this)
            %Use multidim scaling to plot the cluster elements as points in
            %a 3D space
        end
    end

end


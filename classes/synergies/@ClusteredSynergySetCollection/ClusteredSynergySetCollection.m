classdef ClusteredSynergySetCollection < SynergySetCollection
    %CLUSTEREDSYNERGYSETCOLLECTION Synergies grouped by cluster.
    %
    %   A SynergySetCollection created by clustering the synergies of
    % another collection: cell k holds the SynergySet with the synergies of
    % cluster k.
    %
    % ClusteredSynergySetCollection properties:
    %   originalCollection - the unclustered SynergySetCollection
    %   indexInOriginalCollection - cell array; cell k is a Kx2 matrix with
    %                               the linear index of the source
    %                               SynergySet and the row within that set
    %                               for each synergy of cluster k
    %
    % ClusteredSynergySetCollection methods:
    %   ClusteredSynergySetCollection - constructor
    %   plot - plots every cluster
    %   display - prints the collection
    %   plotAs3DSpace - placeholder, not implemented
    %
    % Toolbox Dependencies: None
    %
    % See also SYNERGYSETCOLLECTION/CLUSTER.

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
            %CLUSTEREDSYNERGYSETCOLLECTION Constructor for the class.
            %
            %   s = ClusteredSynergySetCollection(clusteringIndexes,
            % contents, categories, labels, name) gathers the synergies that
            % share a cluster index into one SynergySet per cluster and
            % keeps the original collection.
            %
            % Inputs:
            %   clusteringIndexes - cell array shaped like the original
            %                       collection; each cell holds the cluster
            %                       index of every synergy of that set
            %   unclusteredCollectionContents - cell array of SynergySet
            %                                   objects
            %   unclusteredCollectionCategories - index categories of the
            %                                     original collection
            %   unclusteredCollectionLabels - index labels of the original
            %                                 collection
            %   unclusteredCollectionName - name of the original collection
            %
            % Outputs:
            %   s - ClusteredSynergySetCollection named 'Clustered <name>'
            %
            % Toolbox Dependencies: None

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
            %DISPLAY Prints the collection (superclass method).
            %
            % Inputs:
            %   this - ClusteredSynergySetCollection object
            %
            % Toolbox Dependencies: None

            display@SynergySetCollection(this)
        end
        function figHandle = plotAs3DSpace(this)
            %PLOTAS3DSPACE Placeholder for a multidimensional-scaling plot.
            %
            %   Intended to show the cluster elements as points in a 3-D
            % space. The method body is empty and nothing is returned.
            %
            % Inputs:
            %   this - ClusteredSynergySetCollection object
            %
            % Outputs:
            %   figHandle - not assigned
            %
            % Toolbox Dependencies: None

            %Use multidim scaling to plot the cluster elements as points in
            %a 3D space
        end
    end

end


classdef SynergySetCollection
    %SYNERGYSETCOLLECTION Array of SynergySets over the same muscles.
    %
    %   A collection holds a 1-D or N-D cell array of SynergySet objects
    % with category names and labels for each dimension of the array.
    %
    % SynergySetCollection properties:
    %   content         - cell array of SynergySet objects
    %   indexCategories - cell array of strings, one per dimension of
    %                     content, naming what that dimension indexes
    %   indexLabels     - cell array (one per dimension) of cell arrays of
    %                     strings labeling every set
    %   muscleList      - cell array of muscle names shared by all sets
    %   sortingMethod   - sorting applied to the collection ('None' if
    %                     unsorted)
    %   name            - display name (default 'Unnamed')
    %   colors          - constant cell array of default plot colors
    %
    % SynergySetCollection methods:
    %   SynergySetCollection - constructor
    %   getCollectionDim     - number of dimensions of the collection
    %   getCollectionSize    - size of content
    %   getSynergyDim        - number of muscles per synergy
    %   getContentAsSet      - all synergies stacked in one SynergySet
    %   isSorted             - true if a sorting method was applied
    %   getSetLabels         - labels of the set at a given index
    %   display              - prints names, labels, and contents
    %   plot                 - plots a 1-D collection
    %   cluster              - hierarchical clustering of all synergies
    %
    % Toolbox Dependencies: None
    %
    % See also SYNERGYSET, CLUSTEREDSYNERGYSETCOLLECTION.

    properties(SetAccess = private, GetAccess = public)
        %Cell array of synergySet objects
        content = {SynergySet([],{})};
        %Cell array of strings. its length should be equal to the dimension
        %of content. Each string represents what that dimension indexes.
        indexCategories = {};
        %Cell array of cell array of strings. First level length needs to be
        %equal to size(content,1), second level to size(content,2). Just
        %labels for every synergy set.
        indexLabels = {};
        muscleList  = {};

        %These can be get methods, no need to actually have them as
        %properties
        %collectionDim
        %synergyDim
        %collectionSize

        %These might not be necessary.
        sortingMethod = ['None'];
        %isClustered
        %clusteringMethod
    end
    properties %Public
        name = ['Unnamed'];
    end
    properties(Constant)
        colors = {[0,0.4,1]; [0,1,1]; [0,1,0]; [1,1,0]; [1,0.2,0]; ...
            [1,0,1]; [0.5,0.5,0.5]; [1,0.5,0]; [0,0.6,0]; [0,0.5,1]};
    end

    methods
        %Constructor:
        function s = SynergySetCollection(content,indexCats,indexLabels, ...
            varargin)
            %SYNERGYSETCOLLECTION Constructor for the class.
            %
            %   s = SynergySetCollection(content, indexCats, indexLabels)
            % validates that content is a cell array of SynergySets over the
            % same muscles, that the number of categories equals the
            % dimension of content, and that the label sizes match the size
            % of content. s = SynergySetCollection(..., name) also sets the
            % display name.
            %
            %   NOTE: on invalid input an error message is printed and an
            % empty collection is returned; no exception is thrown.
            %
            % Inputs:
            %   content     - cell array of SynergySet objects
            %   indexCats   - cell array of strings, one per dimension of
            %                 content (a vector counts as one dimension)
            %   indexLabels - cell array (one per dimension) of cell arrays
            %                 of label strings
            %   varargin    - optional display name (char) as first element
            %
            % Outputs:
            %   s - SynergySetCollection object
            %
            % Toolbox Dependencies: None

            %Check that content is a cell array
            if ~isa(content,'cell')
                disp(['ERROR: Contents for SynergySetCollection are ' ...
                    'not a cell array of SynergySets'])
                return
            end
            %Check that each cell contains a SynergySet
            if ~all(cellisa(content,'SynergySet'));
                disp(['ERROR: Contents for SynergySetCollection are ' ...
                    'not a cell array of SynergySets'])
                return
            end
            %Check all synergySets are of same dim, with same muscleList
            synergyDims = content{1}.getDim;
            partialMuscleList = content{1}.muscleList;
            flag = true;
            flag2 = true;
            for ii = 2:numel(content)
                flag = flag && (content{ii}.getDim == synergyDims);
                flag2 = flag2 && ...
                    all(strcmp(content{ii}.muscleList,partialMuscleList));
            end
            if ~flag || ~flag2
                disp(['ERROR: SynergySets provided are not consistent ' ...
                    '(different muscles)'])
            end
            %Check that dim of content coincides with length of indexCats
            Ndims = ndims(content);
            if Ndims == 2 %Ndims returns numbers 2 or higher
                if length(content) == numel(content) %content is vector
                    Ndims = 1;
                end
            end
            if length(indexCats) ~= Ndims
                %Error
                disp(['ERROR: number of categories is inconsistent ' ...
                    'with the size of the content'])
                return
            end
            %Check size of content coincides with size of indexLabels
            sizeContent = size(content);
            flag        = true;
            for ii = 1:length(indexCats)
                flag = flag && (sizeContent(ii) == length(indexLabels{ii}));
            end
            if ~flag
                disp('ERROR: number of labels and SynergySets is different')
                return
            end

            %Case that everything works:
            s.content = content;
            s.indexCategories = indexCats;
            s.indexLabels = indexLabels;
            s.muscleList = content{1}.muscleList;
            if nargin > 3
                if isa(varargin{1},'char')
                    s.name = varargin{1};
                end
            end
        end
        %Get and sets:
        function dim = getCollectionDim(this)
            %GETCOLLECTIONDIM Number of dimensions of the collection.
            %
            % Inputs:
            %   this - SynergySetCollection object
            %
            % Outputs:
            %   dim - 1 if content is a vector, else ndims(content)
            %
            % Toolbox Dependencies: None

            if length(this.content) == numel(this.content)
                dim = 1;
            else
                dim = ndims(this.content);
            end
        end

        function colSize = getCollectionSize(this)
            %GETCOLLECTIONSIZE Size of the cell array of SynergySets.
            %
            % Inputs:
            %   this - SynergySetCollection object
            %
            % Outputs:
            %   colSize - size(content)
            %
            % Toolbox Dependencies: None

            colSize = size(this.content);
        end

        function dim = getSynergyDim(this)
            %GETSYNERGYDIM Number of muscles per synergy.
            %
            % Inputs:
            %   this - SynergySetCollection object
            %
            % Outputs:
            %   dim - dimension of the first SynergySet
            %
            % Toolbox Dependencies: None

            dim = this.content{1}.getDim;
        end

        function [set,originalCollectionIndexes] = getContentAsSet(this)
            %GETCONTENTASSET All synergies stacked in one SynergySet.
            %
            % Inputs:
            %   this - SynergySetCollection object
            %
            % Outputs:
            %   set - SynergySet named 'SetFrom<name>Collection'
            %   originalCollectionIndexes - Kx2 matrix; row k holds the
            %                               linear index of the source
            %                               SynergySet in content and the
            %                               row of synergy k within that set
            %
            % Toolbox Dependencies: None

            setContent = [];
            originalCollectionIndexes = [];
            for ii = 1:numel(this.content)
                relevantElements = this.content{ii}.content;
                Nelements        = size(relevantElements,1);
                setContent       = [setContent;relevantElements];
                originalCollectionIndexes = ...
                    [originalCollectionIndexes; ...
                    [ii*ones(Nelements,1),[1:Nelements]']];
            end
            set = SynergySet(setContent,this.muscleList, ...
                ['SetFrom' this.name 'Collection']);
        end

        % TODO: not implemented
        getSubCollection(this,indexLabels)

        function isSorted = isSorted(this)
            %ISSORTED True if a sorting method was applied.
            %
            % Inputs:
            %   this - SynergySetCollection object
            %
            % Outputs:
            %   isSorted - logical flag
            %
            % Toolbox Dependencies: None

            if strcmpi(this.sortingMethod,'None')
                isSorted = false;
            else
                isSorted = true;
            end
        end

        function labels = getSetLabels(this,idx)
            %GETSETLABELS Labels of the SynergySet at a given index.
            %
            %   NOTE: a vector index whose length differs from the
            % collection dimension prints an error and returns an empty cell
            % array.
            %
            % Inputs:
            %   this - SynergySetCollection object
            %   idx  - linear index (scalar) or vector of subscripts, one
            %          per dimension
            %
            % Outputs:
            %   labels - cell array with one label per dimension of the
            %            collection
            %
            % Toolbox Dependencies: None

            if isscalar(idx) %Linear indexing, this will take some work
                idx2 = zeros(this.getCollectionDim,1);
                aux  = ['[idx2(1)'];
                for jj = 2:this.getCollectionDim
                    aux = [aux ',idx2(' num2str(jj) ')'];
                end
                aux = [aux ']'];
                eval([aux  '=ind2sub(this.getCollectionSize,idx);']);
            elseif length(idx) ~= this.getCollectionDim
                disp(['ERROR: index vector provided does not have size ' ...
                    'equal to the collection''s dimension'])
                labels = {};
                return
            else %Easy version
                idx2 = idx;
            end
            for ii = 1:this.getCollectionDim
                labels{ii} = this.indexLabels{ii}{idx2(ii)};
            end
        end

        %Other manipulation that implies modification:
        % TODO: not implemented
        addColumnCollection(this,colCollection,indexLabel)
        % TODO: not implemented
        addRowCollection(this,rowCollection,indexLabel)
        % TODO: not implemented
        addSynergySet(this,set,indexLabel)
        % TODO: not implemented
        sort(this)

        %Output:
        function display(this)
            %DISPLAY Prints the name, set labels, contents, and muscles.
            %
            % Inputs:
            %   this - SynergySetCollection object
            %
            % Toolbox Dependencies: None

            disp('---')
            disp([this.name ' Collection'])
            for ii = 1:numel(this.content)
                aux = this.getSetLabels(ii);
                str = [this.indexCategories{1} ' ' aux{1}];
                for jj = 2:this.getCollectionDim
                    str = [str ', ' this.indexCategories{jj} ' ' aux{jj}];
                end
                disp(str)
                content = this.content{ii}.content
            end
            muscleList = this.muscleList
            disp('---')
        end

        [figHandle,subplotHandles] = plot(this); %External file

        %Other:
        [clusteredSet,clusteringIndexes] = cluster(this,method)
    end

end


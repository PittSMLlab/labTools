classdef SynergySetCollection
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(SetAccess = private, GetAccess = public)
        content={SynergySet([],{})}; %Cell array of synergySet objects
        indexCategories={}; %Cell array of strings. its length should be equal to the dimension of content. Each string represents what that dimension indexes.
        indexLabels={}; %Cell array of cell array of strings. First level length needs to be equal to size(content,1), second level to size(content,2). Just labels for every synergy set.
        muscleList={};
        
        %These can be get methods, no need to actually have them as
        %properties
        %collectionDim
        %synergyDim
        %collectionSize
        
        %These might not be necessary.
        sortingMethod=['None'];
        %isClustered
        %clusteringMethod
    end
    properties %Public
        name=['Unnamed'];
    end
    properties(Constant)
        colors={[0,.4,1]; [0,1,1]; [0,1,0]; [1,1,0]; [1,.2,0]; [1,0,1]; [.5,.5,.5]; [1,.5,0]; [0,.6,0]; [0,.5,1]};
    end
    
    methods
        %Constructor:
        function s=SynergySetCollection(content,indexCats,indexLabels,varargin)
            %Check that content is a cell array
            if ~isa(content,'cell') 
                disp('ERROR: Contents for SynergySetCollection are not a cell array of SynergySets')
                return
            end
            %Check that each cell contains a SynergySet
            if ~all(cellisa(content,'SynergySet'));
                disp('ERROR: Contents for SynergySetCollection are not a cell array of SynergySets')
                return
            end
            %Check all synergySets are of same dim, with same muscleList
            synergyDims=content{1}.getDim;
            partialMuscleList=content{1}.muscleList;
            flag=true;
            flag2=true;
            for i=2:numel(content)
                flag=flag && (content{i}.getDim==synergyDims);
                flag2=flag2 && all(strcmp(content{i}.muscleList,partialMuscleList));
            end
            if ~flag || ~flag2
                disp('ERROR: SynergySets provided are not consistent (different muscles)')
            end
            %Check that dim of content coincides with length of indexCats
            Ndims=ndims(content);
            if Ndims==2 %Ndims returns numbers 2 or higher
                if length(content)==numel(content) %content is vector
                    Ndims=1;
                end
            end
            if length(indexCats)~=Ndims
                %Error
                disp('ERROR: number of categories is inconsistent with the size of the content')
                return
            end
            %Check size of content coincides with size of indexLabels
            sizeContent=size(content);
            flag=true;
            for i=1:length(indexCats)
                flag=flag && (sizeContent(i)==length(indexLabels{i}));
            end
            if ~flag
                disp('ERROR: number of labels and SynergySets is different')
                return
            end
            
            %Case that everything works:
            s.content=content;
            s.indexCategories=indexCats;
            s.indexLabels=indexLabels;   
            s.muscleList=content{1}.muscleList;
            if nargin>3
                if isa(varargin{1},'char')
                    s.name=varargin{1};
                end
            end
        end
        %Get and sets:
        function dim=getCollectionDim(this)
           if length(this.content)==numel(this.content)
               dim=1;
           else
               dim=ndims(this.content);
           end
        end
        
        function colSize=getCollectionSize(this)
            colSize=size(this.content);
        end
        
        function dim=getSynergyDim(this)
            dim=this.content{1}.getDim;
        end
        
        function [set,originalCollectionIndexes]=getContentAsSet(this)
            setContent=[];
            originalCollectionIndexes=[];
            for i=1:numel(this.content)
                relevantElements=this.content{i}.content;
                Nelements=size(relevantElements,1);
                setContent=[setContent;relevantElements];
                originalCollectionIndexes=[originalCollectionIndexes;[i*ones(Nelements,1),[1:Nelements]']];
            end
            set=SynergySet(setContent,this.muscleList,['SetFrom' this.name 'Collection']);
        end
        
        getSubCollection(this,indexLabels) %TO DO
        
        function isSorted=isSorted(this)
           if strcmpi(this.sortingMethod,'None')
               isSorted=false;
           else
               isSorted=true;
           end
        end
        
        function labels=getSetLabels(this,idx)
            if isscalar(idx) %Linear indexing, this will take some work
               idx2=zeros(this.getCollectionDim,1);
               aux=['[idx2(1)'];
               for j=2:this.getCollectionDim
                   aux=[aux ',idx2(' num2str(j) ')'];
               end
               aux=[aux ']'];
               eval([aux  '=ind2sub(this.getCollectionSize,idx);']);
            elseif length(idx)~=this.getCollectionDim
                disp('ERROR: index vector provided does not have size equal to the collection''s dimension')
                labels={};
                return
            else %Easy version
                idx2=idx;
            end   
            for i=1:this.getCollectionDim
                labels{i}=this.indexLabels{i}{idx2(i)};
            end
        end
        
        %Other manipulation that implies modification:
        addColumnCollection(this,colCollection,indexLabel) %TO DO
        addRowCollection(this,rowCollection,indexLabel) %TO DO
        addSynergySet(this,set,indexLabel) %TO DO
        sort(this) %TO DO
        
        %Output:
        function display(this)
           disp('---')
           disp([this.name ' Collection'])
           for i=1:numel(this.content)
               aux=this.getSetLabels(i);
               str=[this.indexCategories{1} ' ' aux{1}];
               for j=2:this.getCollectionDim
                   str=[str ', ' this.indexCategories{j} ' ' aux{j}];
               end
               disp(str)
               content=this.content{i}.content
           end
           muscleList=this.muscleList
           disp('---')
        end
        
        [figHandle,subplotHandles]=plot(this); %External file
        
        %Other:
        [clusteredSet,clusteringIndexes]=cluster(this,method)
    end
    
end


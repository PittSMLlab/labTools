classdef SynergySet
    %SynergySet Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(SetAccess = private, GetAccess = public)
        muscleList={};
        content=[];
    end
    properties %Public
        name=['Unnamed']; %Optional, string
        %metaData
        %uniqueID
    end
    properties(Constant)
        colors={[0,.4,1]; [0,1,1]; [0,1,0]; [1,1,0]; [1,.2,0]; [1,0,1]; [.5,.5,.5]; [1,.5,0]; [0,.6,0]; [0,.5,1]};
    end
    
    methods
        %Constructor:
        function s=SynergySet(content,muscleList,varargin)
            dim=size(content,2);
            if length(muscleList)~=dim
                %ERROR
                return
            else
                %s.dim=dim;
                %s.Nelements=Nelements;
                s.content=content;
                s.muscleList=muscleList;
            end  
            if nargin>2
                if isa(varargin{1},'char')
                    s.name=varargin{1}; %Needs to be a string
                end
            end
        end
        %Gets & sets:
        function dim=getDim(this)
           dim= size(this.content,2);
        end
        function Nelements=getElements(this)
            Nelements=size(this.content,1);
        end
        function content=getPartialContent(this,indexes)
            content=this.content(indexes,:);
        end
        function s=getSingleSynergy(this,index)
            s = Synergy(this.content(index,:),this.muscleList);
        end
        content=getContentAsCollection(this)
        function this=set.name(this,name)
            if isa(name,'char')
                this.name=name;
            else
                disp('Error: name is not string')
            end
        end
        
        %Output:
        function handle=plot(this,varargin) %First argument: plot handles, second argument: colors for plots
            if length(varargin)<1 || length(varargin{1})<this.getElements %Handle size incorrect, assuming no handles were given
                handle=figure;
                for i=1:this.getElements
                    subHandles(i)=subplot(1,this.getElements,i);
                end
            else
                subHandles=varargin{1};
                handle=gcf;
            end
            for i=1:this.getElements
                subplot(subHandles(i))
                hold on
                bar(this.content(i,:))
                %set(gca,'XTick',[1:this.getDim],'XTickLabel',this.muscleList)
                xticklabel_rotate90_cell([1:this.getDim],this.muscleList,'FontSize',6,'Color',[0 0 0]);
                if length(varargin)<2
                    colormap(this.colors{mod(i,10)+1}); %Fixed colors
                else
                    colormap(varargin{2}{1+mod(i-1,length(varargin{2}))}); %Color passed by caller
                end
                freezeColors
                axis([.5 this.getDim+.5 -1 1])
                hold off
            end
        end
        function display(this)
           disp('---')
           disp(['SynergySet ' this.name])
           content=this.content
           labels=this.muscleList
           disp('---')
        end
        
        %Other (misc):
        function dist=distance(this)
            %Returns a distance vector for a SynergySet, in the same format
            %as pdist
            dist=pdist(this.content,'cosine');
            dist=acosd(1-dist);
        end
        function distM=distanceMatrix(this)
            %Returns the same as distance, but structured as a matrix such that R(i,j)=R(j,i)= distance between element i and j of the set
            dist=this.distance;
            distM=squareform(dist);
        end
        %Modifiers
        function newThis=varimax(this)
           if size(this.content,1)>1
           newContent=rotatefactors(this.content','Method','varimax');
           for j=1:size(newContent,2) %Flipping synergies that are mostly negative, for aesthethic purposes strictly.
               [~,idx]=max(abs(newContent(:,j)));
               if newContent(idx,j)<0
                   newContent(:,j)=-newContent(:,j);
               end
           end
           newThis=SynergySet(newContent',this.muscleList,[this.name ' Varimax Rotated']);
           else
               newThis=this;
           end
        end
    end
    
end


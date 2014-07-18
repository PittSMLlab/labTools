classdef Synergy
    %Synergy Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(SetAccess = private, GetAccess = public)
        content=[]; %Real positive vector
        muscleList={}; %Cell array of strings
    end
    properties
        name=['Unnamed'];
        %metadata %subject number, condition, etc?
        %uniqueID %A unique number identificator, just in case?
    end
    
    methods
        %Constructor:
        function s = Synergy(content,muscleList,varargin) %Creator
            if length(content)==numel(content) %Check that content is 1-D
                if length(content)==length(muscleList)
                    if size(content,1)==1
                        s.content = content;
                    else
                        s.content=content.';
                    end
                    s.muscleList=muscleList;
                    if nargin>2
                        if isa(varargin{1},'char')
                            s.name=varargin{1};
                        end
                    end
                else
                    disp('ERROR: Attempting to create Synergy object with different number of elements and element names.')
                    return
                end
            else
                disp('ERROR: Attempting to create Synergy object with an array for content. You probably want to try to create a SynergySet.')
                return
            end
        end
        
        %Output:
        function handle=plot(this,varargin) %barGraph of synergy with appropriate labeling
            if length(varargin)<1
                handle=figure;
            else
                handle=varargin{1};
                figure(handle);
            end
            handle=figure;
            hold on
            bar(this.content)
            set(gca,'XTick',[1:this.getDim],'XTickLabel',this.muscleList)
            if length(varargin)<2
                colormap([0,0,1]); %Blue bars
            else
                colormap(varargin{2}); %Color passed by caller
            end
            hold off
        end
        function display(this)
            disp('---')
            disp(['Synergy ' this.name])
           content=this.content
           labels=this.muscleList
           disp('---')
        end
        
        %Gets and sets:
        function dim=getDim(this) %Returns dimensions of the synergy
            dim=length(this.content);
        end
        
        %Other (misc):
        function dist=distance(this,otherSynergy)
            auxSet=SynergySet([this.content;otherSynergy.content],this.muscleList);
            dist=distance(auxSet);
        end
    end
    
end


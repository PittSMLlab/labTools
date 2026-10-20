classdef SynergySet
    %SYNERGYSET Set of muscle synergies defined over the same muscles.
    %
    %   A SynergySet stores one synergy per row of content, with the muscle
    % names (muscleList) labeling the columns.
    %
    % SynergySet properties:
    %   content    - NxM matrix of muscle weights, one synergy per row
    %   muscleList - cell array of M muscle-name strings
    %   name       - display name (default 'Unnamed')
    %   colors     - constant cell array of default bar-plot colors
    %
    % SynergySet methods:
    %   SynergySet        - constructor
    %   getDim            - number of muscles (columns)
    %   getElements       - number of synergies (rows)
    %   getPartialContent - rows of content at given indexes
    %   getSingleSynergy  - one row as a Synergy object
    %   plot              - bar graph of every synergy
    %   display           - prints the name, content, and labels
    %   distance          - pairwise angles between synergies
    %   distanceMatrix    - same angles as a symmetric matrix
    %   varimax           - varimax-rotated copy of the set
    %
    % Toolbox Dependencies: Statistics and Machine Learning Toolbox
    %
    % See also SYNERGY, SYNERGYSETCOLLECTION.

    properties(SetAccess = private, GetAccess = public)
        muscleList = {};
        content    = [];
    end
    properties %Public
        name = ['Unnamed']; %Optional, string
        %metaData
        %uniqueID
    end
    properties(Constant)
        colors = {[0,0.4,1]; [0,1,1]; [0,1,0]; [1,1,0]; [1,0.2,0]; ...
            [1,0,1]; [0.5,0.5,0.5]; [1,0.5,0]; [0,0.6,0]; [0,0.5,1]};
    end

    methods
        %Constructor:
        function s = SynergySet(content,muscleList,varargin)
            %SYNERGYSET Constructor for SynergySet class.
            %
            %   s = SynergySet(content, muscleList) creates a set with one
            % synergy per row of content. s = SynergySet(content,
            % muscleList, name) also sets the display name.
            %
            %   NOTE: if length(muscleList) differs from the number of
            % columns of content, an empty SynergySet is returned without a
            % message.
            %
            % Inputs:
            %   content    - NxM matrix of muscle weights, one synergy per
            %                row
            %   muscleList - cell array of M muscle names
            %   varargin   - optional display name (char) as first element
            %
            % Outputs:
            %   s - SynergySet object
            %
            % Toolbox Dependencies: None

            dim = size(content,2);
            if length(muscleList) ~= dim
                %ERROR
                return
            else
                %s.dim=dim;
                %s.Nelements=Nelements;
                s.content = content;
                s.muscleList = muscleList;
            end
            if nargin > 2
                if isa(varargin{1},'char')
                    s.name = varargin{1}; %Needs to be a string
                end
            end
        end
        %Gets & sets:
        function dim = getDim(this)
            %GETDIM Number of muscles (columns of content).
            %
            % Inputs:
            %   this - SynergySet object
            %
            % Outputs:
            %   dim - number of columns of content
            %
            % Toolbox Dependencies: None

            dim = size(this.content,2);
        end
        function Nelements = getElements(this)
            %GETELEMENTS Number of synergies in the set (rows of content).
            %
            % Inputs:
            %   this - SynergySet object
            %
            % Outputs:
            %   Nelements - number of rows of content
            %
            % Toolbox Dependencies: None

            Nelements = size(this.content,1);
        end
        function content = getPartialContent(this,indexes)
            %GETPARTIALCONTENT Rows of content at the given indexes.
            %
            % Inputs:
            %   this    - SynergySet object
            %   indexes - row indexes (numeric or logical)
            %
            % Outputs:
            %   content - matrix with the selected synergies, one per row
            %
            % Toolbox Dependencies: None

            content = this.content(indexes,:);
        end
        function s = getSingleSynergy(this,index)
            %GETSINGLESYNERGY One synergy of the set as a Synergy object.
            %
            % Inputs:
            %   this  - SynergySet object
            %   index - row index of the synergy
            %
            % Outputs:
            %   s - Synergy object with the selected weights and the set's
            %       muscleList
            %
            % Toolbox Dependencies: None

            s = Synergy(this.content(index,:),this.muscleList);
        end
        content = getContentAsCollection(this)
        function this = set.name(this,name)
            %SET.NAME Sets the display name (char only).
            %
            %   NOTE: a non-char name leaves the previous name unchanged and
            % only prints a message.
            %
            % Inputs:
            %   this - SynergySet object
            %   name - display name (char)
            %
            % Outputs:
            %   this - SynergySet object with the updated name
            %
            % Toolbox Dependencies: None

            if isa(name,'char')
                this.name = name;
            else
                disp('Error: name is not string')
            end
        end

        %Output:
        %First argument: plot handles, second argument: colors for plots
        function handle = plot(this,varargin)
            %PLOT Bar graph of every synergy, one subplot each.
            %
            %   If no usable subplot handles are given (fewer than one per
            % synergy), a new figure with one subplot per synergy is
            % created. The x axis is labeled with the muscle names using the
            % external xticklabel_rotate90_cell, and axes colors are frozen
            % with the external freezeColors.
            %
            % Inputs:
            %   this     - SynergySet object
            %   varargin - optional: {1} subplot handles, one per synergy;
            %              {2} cell array of colormaps cycled over the
            %              synergies (default: the constant colors property)
            %
            % Outputs:
            %   handle - handle of the new figure, or gcf if subplot handles
            %            were given
            %
            % Toolbox Dependencies: None

            %Handle size incorrect, assuming no handles were given
            if length(varargin) < 1 || ...
                    length(varargin{1}) < this.getElements
                handle = figure;
                for ii = 1:this.getElements
                    subHandles(ii) = subplot(1,this.getElements,ii);
                end
            else
                subHandles = varargin{1};
                handle     = gcf;
            end
            for ii = 1:this.getElements
                subplot(subHandles(ii))
                hold on
                bar(this.content(ii,:))
                %set(gca,'XTick',[1:this.getDim],'XTickLabel', ...
                %    this.muscleList)
                xticklabel_rotate90_cell([1:this.getDim], ...
                    this.muscleList,'FontSize',6,'Color',[0 0 0]);
                if length(varargin) < 2
                    colormap(this.colors{mod(ii,10)+1}); %Fixed colors
                else
                    %Color passed by caller
                    colormap(varargin{2}{1+mod(ii-1,length(varargin{2}))});
                end
                freezeColors
                axis([0.5 this.getDim+0.5 -1 1])
                hold off
            end
        end
        function display(this)
            %DISPLAY Prints the set name, content, and muscle labels.
            %
            % Inputs:
            %   this - SynergySet object
            %
            % Toolbox Dependencies: None

            disp('---')
            disp(['SynergySet ' this.name])
            content = this.content
            labels  = this.muscleList
            disp('---')
        end

        %Other (misc):
        function dist = distance(this)
            %DISTANCE Pairwise angles between synergies, in degrees.
            %
            %   Returns the angular distance, acosd(1 - cosine distance),
            % between every pair of rows of content, in the vector format of
            % pdist.
            %
            % Inputs:
            %   this - SynergySet object
            %
            % Outputs:
            %   dist - 1xN(N-1)/2 vector of angles in degrees
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %
            % See also DISTANCEMATRIX, PDIST.

            dist = pdist(this.content,'cosine');
            dist = acosd(1-dist);
        end
        function distM = distanceMatrix(this)
            %DISTANCEMATRIX Pairwise angles as a symmetric matrix.
            %
            %   Same values as distance, arranged so that R(i,j) = R(j,i) is
            % the angle in degrees between synergies i and j.
            %
            % Inputs:
            %   this - SynergySet object
            %
            % Outputs:
            %   distM - NxN symmetric matrix of angles in degrees
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %
            % See also DISTANCE, SQUAREFORM.

            dist  = this.distance;
            distM = squareform(dist);
        end
        %Modifiers
        function newThis = varimax(this)
            %VARIMAX Varimax-rotated copy of the set.
            %
            %   Rotates the synergies with rotatefactors. Each rotated
            % synergy whose largest-magnitude weight is negative is flipped
            % in sign (cosmetic only). A set with a single synergy is
            % returned unchanged.
            %
            % Inputs:
            %   this - SynergySet object
            %
            % Outputs:
            %   newThis - rotated SynergySet named '<name> Varimax Rotated'
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %
            % See also ROTATEFACTORS.

            if size(this.content,1) > 1
                newContent = rotatefactors(this.content','Method', ...
                    'varimax');
                %Flipping synergies that are mostly negative, for aesthethic
                %purposes strictly.
                for jj = 1:size(newContent,2)
                    [~,idx] = max(abs(newContent(:,jj)));
                    if newContent(idx,jj) < 0
                        newContent(:,jj) = -newContent(:,jj);
                    end
                end
                newThis = SynergySet(newContent',this.muscleList, ...
                    [this.name ' Varimax Rotated']);
            else
                newThis = this;
            end
        end
    end

end


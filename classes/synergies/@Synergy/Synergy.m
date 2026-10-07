classdef Synergy
    %SYNERGY One muscle synergy: a vector of nonnegative muscle weights.
    %
    %   A Synergy stores one vector of muscle weights (content) together
    % with the matching muscle names (muscleList) and a display name.
    %
    % Synergy properties:
    %   content    - 1xN vector of muscle weights (real, positive)
    %   muscleList - cell array of N muscle-name strings
    %   name       - display name (default 'Unnamed')
    %
    % Synergy methods:
    %   Synergy  - constructor
    %   plot     - bar graph of the weights
    %   display  - prints the name, weights, and muscle labels
    %   getDim   - number of muscles
    %   distance - angle in degrees to another Synergy
    %
    % Toolbox Dependencies: Statistics and Machine Learning Toolbox
    %
    % See also SYNERGYSET, SYNERGYSETCOLLECTION.

    properties(SetAccess = private, GetAccess = public)
        content    = []; %Real positive vector
        muscleList = {}; %Cell array of strings
    end
    properties
        name = ['Unnamed'];
        %metadata %subject number, condition, etc?
        %uniqueID %A unique number identificator, just in case?
    end

    methods
        %Constructor:
        function s = Synergy(content,muscleList,varargin) %Creator
            %SYNERGY Constructor for Synergy class.
            %
            %   s = Synergy(content, muscleList) creates a synergy from a
            % vector of muscle weights and the matching muscle names. s =
            % Synergy(content, muscleList, name) also sets the display name.
            %
            %   NOTE: if content is not a vector or its length differs from
            % muscleList, an error message is printed and an empty Synergy
            % is returned; no exception is thrown.
            %
            % Inputs:
            %   content    - numeric vector of muscle weights (stored as a
            %                row)
            %   muscleList - cell array of muscle names, one per weight
            %   varargin   - optional display name (char) as first element
            %
            % Outputs:
            %   s - Synergy object
            %
            % Toolbox Dependencies: None

            if length(content) == numel(content) %Check that content is 1-D
                if length(content) == length(muscleList)
                    if size(content,1) == 1
                        s.content = content;
                    else
                        s.content = content.';
                    end
                    s.muscleList = muscleList;
                    if nargin > 2
                        if isa(varargin{1},'char')
                            s.name = varargin{1};
                        end
                    end
                else
                    disp(['ERROR: Attempting to create Synergy object ' ...
                        'with different number of elements and ' ...
                        'element names.'])
                    return
                end
            else
                disp(['ERROR: Attempting to create Synergy object with ' ...
                    'an array for content. You probably want to try ' ...
                    'to create a SynergySet.'])
                return
            end
        end

        %Output:
        %barGraph of synergy with appropriate labeling
        function handle = plot(this,varargin)
            %PLOT Bar graph of the synergy weights labeled by muscle.
            %
            %   NOTE: a figure handle passed in varargin{1} is activated,
            % but the bars are drawn in a newly created figure that is
            % returned.
            %
            % Inputs:
            %   this     - Synergy object
            %   varargin - optional: {1} figure handle (see NOTE), {2}
            %              colormap for the bars (default blue)
            %
            % Outputs:
            %   handle - handle of the figure containing the bar graph
            %
            % Toolbox Dependencies: None

            if length(varargin) < 1
                handle = figure;
            else
                handle = varargin{1};
                figure(handle);
            end
            handle = figure;
            hold on
            bar(this.content)
            set(gca,'XTick',[1:this.getDim],'XTickLabel',this.muscleList)
            if length(varargin) < 2
                colormap([0,0,1]); %Blue bars
            else
                colormap(varargin{2}); %Color passed by caller
            end
            hold off
        end
        function display(this)
            %DISPLAY Prints the synergy name, weights, and muscle labels.
            %
            % Inputs:
            %   this - Synergy object
            %
            % Toolbox Dependencies: None

            disp('---')
            disp(['Synergy ' this.name])
            content = this.content
            labels  = this.muscleList
            disp('---')
        end

        %Gets and sets:
        function dim = getDim(this) %Returns dimensions of the synergy
            %GETDIM Number of muscles in the synergy.
            %
            % Inputs:
            %   this - Synergy object
            %
            % Outputs:
            %   dim - length of content
            %
            % Toolbox Dependencies: None

            dim = length(this.content);
        end

        %Other (misc):
        function dist = distance(this,otherSynergy)
            %DISTANCE Angle in degrees between this synergy and another one.
            %
            %   Builds a two-row SynergySet from both synergies and returns
            % its angular distance, acosd of the cosine similarity.
            %
            % Inputs:
            %   this         - Synergy object
            %   otherSynergy - Synergy object over the same muscles
            %
            % Outputs:
            %   dist - angle between the two weight vectors in degrees
            %
            % Toolbox Dependencies: Statistics and Machine Learning Toolbox
            %
            % See also SYNERGYSET/DISTANCE.

            auxSet = SynergySet([this.content;otherSynergy.content], ...
                this.muscleList);
            dist = distance(auxSet);
        end
    end

end


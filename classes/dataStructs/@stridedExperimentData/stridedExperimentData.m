classdef stridedExperimentData
    %stridedExperimentData  Contains stride-level data for an experiment
    %
    %   stridedExperimentData organizes experimental data that has been
    %   separated into individual stride cycles. Each trial contains a
    %   cell array of strideData objects, enabling stride-by-stride
    %   analysis and visualization.
    %
    %stridedExperimentData properties:
    %   metaData - experimentMetaData object containing experimental
    %              conditions
    %   subData - subjectData object containing subject information
    %   stridedTrials - cell array of cell arrays of strideData objects
    %   isTimeNormalized - flag indicating if strides have been time-
    %                      normalized
    %
    %stridedExperimentData methods:
    %   timeNormalize - resamples all strides to uniform length
    %   getStridesFromCondition - extracts strides from specific
    %                             condition
    %   plotAllStrides - plots all individual strides for a field
    %   plotAllStridesBilateral - plots bilateral data overlaid
    %   plotAvgStride - plots average stride across conditions
    %   alignEvents - aligns data to gait events (deprecated)
    %   discardBadStrides - removes bad strides (deprecated)
    %   getAlignedData - extracts phase-aligned data
    %   getDataAsMatrices - converts stride data to matrices
    %
    %See also: experimentData, strideData, experimentMetaData

    %% Properties
    properties
        metaData % experimentMetaData type
        subData % subjectData type
        stridedTrials % cell array of cell array of strideData objects
    end

    properties (SetAccess = private)
        % This should be dependent, and be returned by checking that
        % the length of all timeSeries in all strides has the same
        % length, it is rather boring to do.
        isTimeNormalized = false;
    end

    %% Constructor
    methods
        function this = stridedExperimentData(meta, sub, strides)
            %stridedExperimentData  Constructor for
            %stridedExperimentData class
            %
            %   this = stridedExperimentData(meta, sub, strides) creates
            %   a strided experiment data object with specified metadata,
            %   subject data, and strided trials
            %
            %   Inputs:
            %       meta - experimentMetaData object
            %       sub - subjectData object
            %       strides - cell array of cell arrays of strideData
            %                 objects
            %
            %   Outputs:
            %       this - stridedExperimentData object
            %
            %   See also: experimentData/splitIntoStrides, strideData

            if isa(meta, 'experimentMetaData')
                this.metaData = meta;
            else
                ME = MException('stridedExperimentData:Constructor', ...
                    'meta is not an experimentMetaData object.');
                throw(ME);
            end
            if isa(sub, 'subjectData')
                this.subData = sub;
            else
                ME = MException('stridedExperimentData:Constructor', ...
                    'sub is not a subjectData object.');
                throw(ME);
            end
            if isa(strides, 'cell') && all(cellfun('isempty', strides) |...
                    cellisa(strides, 'cell'))
                aux = cellisa(strides, 'cell');
                idx = find(aux == 1, 1);
                % Just checking whether the first non-empty cell is
                % made of strideData objects, but should actually
                % check them all
                if all(cellisa(strides{idx}, 'strideData'))
                    this.stridedTrials = strides;
                else
                    ME = MException(...
                        'stridedExperimentData:Constructor', ...
                        'strides must contain strideData objects.');
                    throw(ME);
                end
            else
                ME = MException('stridedExperimentData:Constructor', ...
                    'strides must be a cell array.');
                throw(ME);
            end
        end
    end

    %% Dependent Property Getters
    methods
        % function a = get.isTimeNormalized(this)
        %     a = 'Who knows?'; % TODO!
        % end
    end

    %% Data Transformation Methods
    methods
        newThis = timeNormalize(this, N)
    end

    %% Data Query Methods
    methods
        strides = getStridesFromCondition(this, condition)

        structure = getDataAsMatrices(this, fields, conditions, N)
    end

    %% Visualization Methods
    methods
        function [figHandle,plotHandles]=plotAllStrides(this,field,conditions,plotHandles,figHandle)
            %To Do: need to add gait Events markers.

            % Set colors
            poster_colors;
            % Set colors order
            ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow];
            set(gcf,'DefaultAxesColorOrder',ColorOrder);

            for cond=conditions
                if nargin<5 || isempty(figHandle)
                    figHandle=figure('Name',['Subject ' num2str(this.subData.ID) ' Condition ' num2str(cond) ' ' field ]);
                else
                    figure(figHandle) %Only works for one condition!
                end
                set(figHandle,'Units','normalized','OuterPosition',[0 0 1 1])
                aux=this.getStridesFromCondition(cond);
                N=2^ceil(log2(1.5/aux{1}.(field).sampPeriod));
                structure=this.getDataAsMatrices(field,cond,N);
                M=size(structure{cond},2);
                if nargin<4 || isempty(plotHandles)
                    [b,a]=getFigStruct(M);
                    plotHandles=tight_subplot(b,a,[.02 .02],[.05 .02], [.02 .05]); %External function
                end
                if (numel(structure{cond}))>1e6
                    P=floor(1e7/numel(structure{cond}(:,:,1)));
                    warning(['There are too many strides in this condition to plot (' num2str(size(structure{cond},3)) '). Only plotting first ' num2str(P) '.'])
                    meanStr{cond}=mean(structure{cond},3);
                    structure{cond}=structure{cond}(:,:,1:P);
                end
                for i=1:M
                    %subplot(b,a,i)
                    subplot(plotHandles(i))
                    hold on
                    %title(aux{1}.(field).labels{i})
                    data=squeeze(structure{cond}(:,i,:));
                    plot([0:N-1]/N,data,'Color',[.7,.7,.7])
                    plot([0:N-1]/N,meanStr{cond}(:,i),'LineWidth',2,'Color',ColorOrder(mod(cond-1,size(ColorOrder,1))+1,:));
                    legend(aux{1}.(field).labels{i})
                    hold off
                end
            end

        end

        function [figHandle,plotHandles]=plotAllStridesBilateral(this,field,conditions,plotHandles,figHandle) %Forces 'L' and 'R' to be plotted on top of each other %To Do
            [figHandle,plotHandles]=plotAllStrides(this,field,conditions,plotHandles,figHandle);
        end

        function [figHandle,plotHandles]=plotAvgStride(this,field,conditions,plotHandles,figHandle)
            % Set colors
            poster_colors;
            % Set colors order
            ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow];
            set(gcf,'DefaultAxesColorOrder',ColorOrder);

            if nargin<5 || isempty(figHandle)
                figHandle=figure('Name',['Subject ' num2str(this.subData.ID) ' ' field ]);
            else
                figure(figHandle) %Only works for one condition!
            end
            set(figHandle,'Units','normalized','OuterPosition',[0 0 1 1])
            aux=this.getStridesFromCondition(conditions(1));
            N=2^ceil(log2(size(aux{1}.(field).Data,1)));
            structure=this.getDataAsMatrices(field,conditions,N);
            if nargin<4 || isempty(plotHandles)
                M=size(structure{1},2);
                [b,a]=getFigStruct(M);
                plotHandles=tight_subplot(b,a,[.04 .02],[.05 .02], [.04 .05]);
            end
            for i=1:M
                %subplot(b,a,i)
                subplot(plotHandles(i))
                hold on
                legStr={};
                title(aux{1}.(field).labels{i})
                for cond=conditions
                    data=mean(squeeze(structure{cond}(:,i,:)),2);
                    plot([0:N-1]/N,data,'LineWidth',2,'Color',ColorOrder(mod(cond-1,size(ColorOrder,1))+1,:))
                    legStr{end+1}=['Condition ' num2str(cond)];
                end
                if i==M
                    legend(legStr)
                end
                hold off
            end
        end
    end

    %% Data Alignment Methods
    methods
        alignedData = alignEvents(this, spacing, trial, fieldName, ...
            labelList)

        newThis = discardBadStrides(this)

        alignedData = getAlignedData(this, spacing, trial, fieldName, ...
            labelList)
    end

end


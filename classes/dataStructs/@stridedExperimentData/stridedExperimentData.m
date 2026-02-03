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
        [figHandle, plotHandles] = plotAllStrides(this, field, ...
            conditions, plotHandles, figHandle)

        [figHandle, plotHandles] = plotAllStridesBilateral(this, ...
            field, conditions, plotHandles, figHandle)

        [figHandle, plotHandles] = plotAvgStride(this, field, ...
            conditions, plotHandles, figHandle)
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


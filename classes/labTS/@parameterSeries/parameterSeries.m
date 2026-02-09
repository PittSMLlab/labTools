classdef parameterSeries < labTimeSeries
    %parameterSeries  Extends labTimeSeries to hold adaptation parameters
    %
    %   parameterSeries stores stride-by-stride adaptation parameters with
    %   associated metadata including trial information, timing, and
    %   parameter descriptions. It provides specialized methods for
    %   parameter manipulation, normalization, and analysis.
    %
    %parameterSeries properties:
    %   hiddenTime - actual time values for each stride
    %   trialTypes - cell array of trial type identifiers
    %   bad - logical vector indicating bad strides (dependent)
    %   stridesTrial - vector of trial numbers for each stride (dependent)
    %   stridesInitTime - vector of initial times for each stride
    %                     (dependent)
    %   description - cell array of parameter descriptions (dependent)
    %
    %parameterSeries methods:
    %   parameterSeries - constructor for parameter series
    %   setTrialTypes - sets trial type information
    %   isaParameter - checks if parameter exists (alias for isaLabel)
    %   indsInTrial - returns indices for specified trial(s)
    %   getParameter - retrieves parameter data (backward compatible)
    %   incorporateDependentParameters - adds computed dependent parameters
    %   cat - concatenates two parameterSeries
    %   addStrides - adds strides from another parameterSeries
    %   addNewParameter - computes and adds new parameter
    %   getDataAsPS - extracts subset as new parameterSeries
    %   appendData - appends new parameters
    %   replaceParams - replaces existing parameters
    %   markBadWhenMissingAny - marks strides bad if any param missing
    %   markBadWhenMissingAll - marks strides bad if all params missing
    %   substituteNaNs - fills NaN values, preserving fixed params
    %   markBadStridesAsNan - sets bad strides to NaN
    %   normalizeToBaseline - normalizes parameters (deprecated)
    %   linearStretch - linearly transforms parameter values
    %   fourierTransform - computes Fourier transform
    %   resample - disabled for parameterSeries
    %   resampleN - disabled for parameterSeries
    %   plotAlt - plots parameters as scatter
    %   anova - performs one-way ANOVA on parameters
    %
    %See also: labTimeSeries, adaptationData

    %% Properties
    properties
        hiddenTime
        trialTypes % SL: to support split 1 condition into multiple
    end

    properties (Dependent)
        bad
        stridesTrial
        stridesInitTime
        description
        % trialTypes % to support split 1 condition into multiple
    end

    properties (Hidden)
        description_ = {};
        trialTypes_ = {};
        fixedParams = 5;
    end

    %% Constructor
    methods
        function this = parameterSeries( ...
                data, labels, times, description, types)
            %parameterSeries  Constructor for parameterSeries class
            %
            %   this = parameterSeries(data, labels, times, description)
            %   creates a parameter series with specified data, labels,
            %   times, and descriptions
            %
            %   this = parameterSeries(data, labels, times, description,
            %   types) includes trial type information
            %
            %   Inputs:
            %       data - matrix of parameter values (strides x
            %              parameters)
            %       labels - cell array of parameter name strings
            %       times - vector of stride initial times
            %       description - cell array of parameter descriptions
            %                     (same length as labels)
            %       types - cell array of trial type identifiers
            %               (optional)
            %
            %   Outputs:
            %       this - parameterSeries object
            %
            %   See also: labTimeSeries, adaptationData

            this@labTimeSeries(data, 1, 1, labels);
            this.hiddenTime = times;
            if length(description) == length(labels)
                % Needs to be cell-array of same length as labels
                this.description_ = description;
            else
                error('paramtereSeries:constructor', ...
                    'Description input needs to be same length as labels');
            end
            if nargin > 4
                this.trialTypes_ = types;
            end
        end

        function this = setTrialTypes(this, types)
            %setTrialTypes  Sets trial type information
            %
            %   this = setTrialTypes(this, types) sets the trial types
            %   for the parameter series
            %
            %   Inputs:
            %       this - parameterSeries object
            %       types - cell array of trial type identifiers
            %
            %   Outputs:
            %       this - parameterSeries with updated trial types

            this.trialTypes_ = types;
        end
    end

    %% Dependent Property Getters
    methods
        % this could be made more efficient by fixing the indexes for these
        % parameters (which is something that already happens in practice)
        % and doing direct indexing to data
        function vals = get.bad(this)
            %get.bad  Returns bad stride flags
            %
            %   Outputs:
            %       vals - logical vector indicating bad strides
            %
            %   Note: This could be made more efficient by fixing the
            %         indexes for these parameters and doing direct
            %         indexing to data

            if this.isaParameter('bad')
                vals = this.getDataAsVector('bad');
            elseif this.isaParameter('good')
                vals = this.getDataAsVector('good');
                vals = ~vals;
            else
                % This should never be the case. Setting all values as good
                vals = false(size(this.Data, 1), 1);
            end
        end

        function vals = get.stridesTrial(this)
            %get.stridesTrial  Returns trial number for each stride
            %
            %   Outputs:
            %       vals - vector of trial numbers

            vals = this.getDataAsVector('trial');
        end

        function vals = get.stridesInitTime(this)
            %get.stridesInitTime  Returns initial time for each stride
            %
            %   Outputs:
            %       vals - vector of stride initial times

            vals = this.getDataAsVector('initTime');
        end

        function vals = get.description(this)
            %get.description  Returns parameter descriptions
            %
            %   Outputs:
            %       vals - cell array of description strings

            % if isfield(this, 'description_')
            vals = this.description_;
            % else
            %     vals = cell(size(this.labels));
            % end
        end

        function vals = get.trialTypes(this)
            %get.trialTypes  Returns trial types
            %
            %   Outputs:
            %       vals - cell array of trial type identifiers

            % if isfield(this, 'trialTypes_')
            vals = this.trialTypes_;
            % else
            %     disp('trying to access trialTypes');
            %     vals = {};
            % end
        end
    end

    %% Data Access Methods
    methods
        function [bool, idx] = isaParameter(this, labels)
            %isaParameter  Checks if parameter exists
            %
            %   [bool, idx] = isaParameter(this, labels) is an alias for
            %   isaLabel for backward compatibility
            %
            %   Inputs:
            %       this - parameterSeries object
            %       labels - string or cell array of parameter name(s)
            %
            %   Outputs:
            %       bool - logical vector indicating which parameters exist
            %       idx - vector of parameter indices
            %
            %   Note: Another name for isaLabel, backwards compatibility
            %
            %   See also: isaLabel

            [bool, idx] = this.isaLabel(labels);
        end

        inds = indsInTrial(this, t)

        [data, auxLabel] = getParameter(this, label)

        newThis = incorporateDependentParameters(this, labels)

        newThis = getDataAsPS(this, labels, strides, skipFixedParams)
    end

    %% Data Modification Methods
    methods
        newThis = cat(this, other)

        newThis = addStrides(this, other)

        newThis = addNewParameter(this, newParamLabel, funHandle, ...
            inputParameterLabels, newParamDescription)

        newThis = appendData(this, newData, newLabels, newDesc)

        this = replaceParams(this, other)
    end

    %% Bad Stride Handling Methods
    methods
        newThis = markBadWhenMissingAny(this, labels)

        newThis = markBadWhenMissingAll(this, labels)

        newThis = substituteNaNs(this, method)

        this = markBadStridesAsNan(this)
    end

    %% Normalization Methods
    methods
        this = normalizeToBaseline(this, labels, rangeValues)

        newThis = linearStretch(this, labels, rangeValues)
    end

    % function newThis=EMGnormAllData(this,labels,rangeValues)
    %     %This get the stride by stide norm
    %     %It creates NEW parameters with the same name, and the 'Norm' prefix.
    %     %This will generate collisions if run multiple times for the
    %     %same parameters
    %     %See also: adaptationData.normalizeToBaselineEpoch
    %     if isempty(rangeValues)
    %         % error('rangeValues has to be a 2 element vector');
    %         rangeValues=0;
    %     end
    %
    %     % More efficient:
    %     N=length(labels);
    %     newDesc=repmat({['Normalized to range=[' num2str(rangeValues(1))  ']']},N,1);
    %     newL=cell(N,1);
    %     nD=zeros(size(this.Data,1),N);
    %
    %     % for i=1:N
    %     %     funHandle=@(x) (x-rangeValues(1))/diff(rangeValues);
    %     %     funHandle=@(x) vecnorm(x'-rangeValues);
    %     %     newL=strcat('NormEMG',labels);
    %     %     nD(:,:)=this.computeNewParameter(newL{1},funHandle,labels(1));
    %     % end
    %     newThis=appendData(this,nD,newL,newDesc);
    % end

    %% Overridden Methods
    methods
        function F = fourierTransform(this)
            %fourierTransform  Computes Fourier transform
            %
            %   F = fourierTransform(this) computes Fourier transform with
            %   appropriate units for stride data
            %
            %   Inputs:
            %       this - parameterSeries object
            %
            %   Outputs:
            %       F - labTimeSeries with Fourier transform
            %
            %   See also: labTimeSeries/fourierTransform

            % error('parameterSeries:fourierTransform',
            %     'You cannot do that!')
            F = fourierTransform@labTimeSeries(this);
            F.TimeInfo.Units = 'strides^{-1}';
        end

        function newThis = resample(this)
            %resample  Disabled for parameterSeries
            %
            %   Note: Resampling is disabled for parameterSeries as time
            %         is not meaningful (strides are discrete events)

            % the newTS is respected as much as possible, but forcing it
            % to be a divisor of the total time range
            error('parameterSeries:resample', 'You cannot do that!');
            newThis = [];
        end

        function newThis = resampleN(this)
            %resampleN  Disabled for parameterSeries
            %
            %   Note: Resampling is disabled for parameterSeries as time
            %         is not meaningful (strides are discrete events)

            % Same as resample function, but directly fixing the number of
            % samples instead of TS
            error('parameterSeries:resampleN', 'You cannot do that!');
            newThis = [];
        end
    end

    %% Visualization Methods
    methods
        [h, h1] = plotAlt(this, h, labels, plotHandles, color)
    end

    %% Statistical Analysis Methods
    methods
        [p, postHocMatrix] = anova(this, params, groupIdxs, dispOpt)
    end

end


classdef processedEMGTimeSeries < labTimeSeries
    %processedEMGTimeSeries  Time series for processed EMG data
    %
    %   processedEMGTimeSeries extends labTimeSeries to include
    %   information about the signal processing applied to raw EMG data.
    %   It maintains a record of filters used and overrides key methods to
    %   preserve processing information when manipulating data.
    %
    %processedEMGTimeSeries properties:
    %   processingInfo - processingInfo object describing filters applied
    %   (inherits all properties from labTimeSeries)
    %
    %processedEMGTimeSeries methods:
    %   processedEMGTimeSeries - constructor for processed EMG timeseries
    %   getDataAsTS - returns processedEMGTimeSeries with specified
    %                 label(s)
    %   resampleN - resamples to N samples, preserving processing info
    %   split - splits timeseries, preserving processing info
    %
    %See also: labTimeSeries, processingInfo, EMGData

    %% Properties
    properties (SetAccess = private)
        processingInfo % processingInfo object
    end

    %% Constructor
    methods
        function this = processedEMGTimeSeries(data, t0, Ts, labels, ...
                processingInfo, Quality, QualInfo)
            %processedEMGTimeSeries  Constructor for
            %processedEMGTimeSeries class
            %
            %   this = processedEMGTimeSeries(data, t0, Ts, labels,
            %   processingInfo) creates a processed EMG timeseries with
            %   specified data and processing information
            %
            %   this = processedEMGTimeSeries(data, t0, Ts, labels,
            %   processingInfo, Quality, QualInfo) includes quality flags
            %
            %   Inputs:
            %       data - matrix of processed EMG amplitudes (samples x
            %              channels)
            %       t0 - initial time in seconds
            %       Ts - sampling period in seconds
            %       labels - cell array of EMG channel labels
            %       processingInfo - processingInfo object describing
            %                        filters applied
            %       Quality - quality flags for samples (optional)
            %       QualInfo - quality information structure (optional)
            %
            %   Outputs:
            %       this - processedEMGTimeSeries object
            %
            %   Note: Necessarily uniformly sampled
            %
            %   See also: labTimeSeries, processingInfo

            this@labTimeSeries(data, t0, Ts, labels);
            if isa(processingInfo, 'processingInfo')
                this.processingInfo = processingInfo;
            else
                ME = MException('processedEMGTimeSeries:Constructor', ...
                    ['processingInfo parameter is not an ' ...
                    'processingInfo object.']);
                throw(ME);
            end
            if nargin > 5
                this.Quality = Quality;
                this.QualityInfo = QualInfo;
            end
        end
    end

    %% Data Access Methods (Overrides)
    methods
        newTS = getDataAsTS(this, label)
    end

    %% Data Transformation Methods (Overrides)
    methods
        newThis = resampleN(this, newN)

        newThis = split(this, t0, t1)
    end

end


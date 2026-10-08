classdef processedEMGTimeSeries < labTimeSeries
    %PROCESSEDEMGTIMESERIES Time series for processed EMG data.
    %
    %   processedEMGTimeSeries extends labTimeSeries to include information
    % about the signal processing applied to raw EMG data. It maintains a
    % record of filters used and overrides key methods to preserve
    % processing information when manipulating data.
    %
    % processedEMGTimeSeries properties:
    %   processingInfo - processingInfo object describing filters applied
    %                    (inherits all properties from labTimeSeries)
    %
    % processedEMGTimeSeries methods:
    %   processedEMGTimeSeries - constructor for processed EMG timeseries
    %   getDataAsTS            - returns processedEMGTimeSeries with
    %                            specified label(s)
    %   resampleN              - resamples to N samples, preserving
    %                            processing info
    %   split                  - splits timeseries, preserving processing
    %                            info
    %
    % Toolbox Dependencies: None
    %
    % See also LABTIMESERIES, PROCESSINGINFO, EMGDATA.

    %% Properties
    properties (SetAccess = private)
        processingInfo % processingInfo object
    end

    %% Constructor
    methods
        function this = processedEMGTimeSeries(data, t0, Ts, labels, ...
            processingInfo, Quality, QualInfo)
            %PROCESSEDEMGTIMESERIES Construct a processed EMG time series.
            %
            %   this = processedEMGTimeSeries(data, t0, Ts, labels, ...
            %   processingInfo) creates a processed EMG time series with
            %   the specified data and processing information.
            %
            %   this = processedEMGTimeSeries(data, t0, Ts, labels, ...
            %   processingInfo, Quality, QualInfo) also sets the quality
            %   flags and their description.
            %
            % Inputs:
            %   data           - matrix of processed EMG amplitudes (samples
            %                    x channels)
            %   t0             - initial time in seconds
            %   Ts             - sampling period in seconds
            %   labels         - cell array of EMG channel labels
            %   processingInfo - processingInfo object describing filters
            %                    applied
            %   Quality        - quality flags for samples (optional)
            %   QualInfo       - quality information structure (optional)
            %
            % Outputs:
            %   this - processedEMGTimeSeries object
            %
            %   Note: Necessarily uniformly sampled
            %
            % Toolbox Dependencies: None
            %
            % See also LABTIMESERIES, PROCESSINGINFO.

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


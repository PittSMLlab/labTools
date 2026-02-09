classdef processingInfo
    %processingInfo  Stores information about signal processing applied
    %to data
    %
    %   processingInfo maintains a record of filters and other processing
    %   steps applied to time series data, enabling traceability of data
    %   processing pipelines.
    %
    %processingInfo properties:
    %   filterList - cell array of filter design objects or processing
    %                step descriptors
    %
    %processingInfo methods:
    %   processingInfo - constructor for processing info
    %
    %See also: labTimeSeries, fdesign

    %% Properties
    properties
        % Needs to be a 1x2 double, represents the pass-band filter used on
        % the raw data
        % bandwidth;
        % Scalar, represents the cutoff frequency for the amplitude
        % low-pass filter
        % f_cut;
        % 1xn double, represents the central frequencies of the notch
        % filters applied to the raw data
        % notchList;
        filterList
    end

    %% Constructor
    methods
        function this = processingInfo(filterList)
            %processingInfo  Constructor for processingInfo class
            %
            %   this = processingInfo(filterList) creates a processing
            %   info object with specified filter list
            %
            %   Inputs:
            %       filterList - cell array containing filter design
            %                    objects or processing step descriptors
            %
            %   Outputs:
            %       this - processingInfo object
            %
            %   See also: fdesign, labTimeSeries/lowPassFilter

            % if numel(bw) == 2
            %     this.bandwidth = bw;
            % else
            %     ME = MException('processingInfo:Constructor', ...
            %         'Bandwidth is not a 1x2 double');
            %     throw(ME);
            % end
            % if numel(f_cut) == 1
            %     this.f_cut = f_cut;
            % else
            %     ME = MException('processingInfo:Constructor', ...
            %         'f_cut is not a scalar.');
            %     throw(ME);
            % end
            % if length(notchLst) == numel(notchLst)
            %     this.notchList = notchLst;
            % else
            %     ME = MException('processingInfo:Constructor', ...
            %         'NotchList is not a 1xn double');
            %     throw(ME);
            % end
            if ~isa(filterList, 'cell')
                ME = MException('processingInfo:Constructor', ...
                    'Filter list is not a cell array');
                throw(ME);
            end
            this.filterList = filterList;
        end
    end

end


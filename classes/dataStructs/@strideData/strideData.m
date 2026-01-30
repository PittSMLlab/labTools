classdef strideData < processedLabData
    %strideData  Represents data from a single gait stride
    %
    %   strideData extends processedLabData to handle data from
    %   individual stride cycles, including stride validation, phase
    %   extraction, and time normalization.
    %
    %strideData properties:
    %   isBad - logical flag indicating if stride has inconsistent
    %           events
    %   initialEvent - first gait event in the stride
    %   originalTrial - name of parent trial from which stride was
    %                   extracted
    %
    %strideData methods:
    %
    %   fakeStride - generates fake stride by reordering phases
    %   getDoubleSupportLR - extracts left-to-right double support
    %                        phase
    %   getDoubleSupportRL - extracts right-to-left double support
    %                        phase
    %   getSingleStanceL - extracts left single stance phase
    %   getSingleStanceR - extracts right single stance phase
    %   getSwingL - extracts left swing phase
    %   getSwingR - extracts right swing phase
    %   getMasterSampleLength - returns common sample length if time
    %                           normalized
    %   timeNormalize - resamples all data to uniform length
    %   alignEvents - aligns data to gait events (unimplemented)
    %
    %strideData static methods:
    %
    %   cell2mat - converts cell array of strides to matrix
    %   plotCell - plots cell array of stride data
    %   plotCellAvg - plots average and std of stride cell array
    %
    %See also: processedLabData, labData, strideMetaData

    %% Properties
    properties (Dependent)
        isBad
        initialEvent
        originalTrial % returns string
    end

    %% Constructor
    methods
        function this = strideData(metaData, markerData, EMGData, ...
                GRFData, beltSpeedSetData, beltSpeedReadData, accData, ...
                EEGData, footSwitches, events, procEMG)
            %strideData  Constructor for strideData class
            %
            %   All arguments validated for proper type. metaData must
            %   be strideMetaData or derivedMetaData.

            if nargin < 11
                markerData = [];
                EMGData = [];
                GRFData = [];
                beltSpeedSetData = [];
                beltSpeedReadData = [];
                accData = [];
                EEGData = [];
                footSwitches = [];
                events = [];
                procEMG = [];
            end
            % Check that metaData is a srideMetaData
            if ~isa(metaData, 'strideMetaData') && ...
                    ~isa(metaData, 'derivedMetaData')
                ME = MException('strideData:Constructor', ...
                    'metaData is not of a strideMetaData object.');
                throw(ME);
            end
            this@processedLabData(metaData, markerData, EMGData, ...
                GRFData, beltSpeedSetData, beltSpeedReadData, accData, ...
                EEGData, footSwitches, events, procEMG);
            % Check that events are consistent or label the stride as 'bad'
            if ~isempty(events) && this.isBad
                warning('strideData:Constructor', ...
                    'Events are not consistent with a single stride.');
            end
        end

        %% Phase Extraction Methods
        methods
            fakeStride(this, initEvent)

            [dsLR, duration] = getDoubleSupportLR(this)

            [dsRL, duration] = getDoubleSupportRL(this)

            [int, dur] = getSingleStanceL(this)

            [int, dur] = getSingleStanceR(this)

            [int, dur] = getSwingL(this)

            [int, dur] = getSwingR(this)
        end

        %% Dependent Property Getters
        methods
            function initEv = get.initialEvent(this)
                if isempty(this.gaitEvents)
                    initEv = [];
                else
                    aux = {'LHS', 'RHS', 'LTO', 'RTO'};
                    for i = 1:length(aux)
                        evStr = aux{i};
                        event = this.gaitEvents.getDataAsVector(evStr);
                        if event(1)
                            initEv = evStr;
                            break;
                        end
                    end
                end
            end

            function b = get.isBad(this)
                evList = {'LHS', 'RHS', 'LTO', 'RTO'};
                for i = 1:length(evList)
                    eval([evList{i} ' = this.gaitEvents.getDataAsVector(evList{i});']);
                end
                % This should get events in the sequence 1, 2, 3, 4, 1...
                % with 0 for non-events
                aa = LHS + 2 * RTO + 3 * RHS + 4 * LTO;
                % Keep only event samples
                bb = diff(aa(aa ~= 0));
                % Make sure the order of events is good
                b = any(mod(bb, 4) ~= 1) || length(bb) < 3;

                % b = false;
                % aux = {'LHS', 'RTO', 'RHS', 'LTO', 'LHS', 'RTO', 'RHS'};
                % initEv = this.initialEvent;
                % lastEvIdx = 1;
                % auxIdx = find(strcmp(initEv, aux), 1);
                % newAux = aux((auxIdx + 1):(auxIdx + 3));
                % % newAux = aux{[auxIdx + 1:4, 1:auxIdx - 1]}; % This requires only the
                % % first four elements of aux.
                % for i = 1:length(newAux)
                %     event = this.gaitEvents.getDataAsVector(newAux{i});
                %     idx = find(event == 1, 1);
                %     if ~(idx > lastEvIdx)
                %         b = true;
                %         break
                %     else
                %         lastEvIdx = idx;
                %     end
                % end
            end

            function t = get.originalTrial(this)
                t = this.metaData.parentMetaData.name;
            end
        end

        %% Data Query Methods
        methods
            N = getMasterSampleLength(this)
        end

        %% Data Transformation Methods
        methods
            newThis = timeNormalize(this, N, newClass)

            newThis = alignEvents(this, events, spacing)
            end

            %% Static Methods
            methods (Static)
                strideMat = cell2mat(strides, field, N)

                plotHandles = plotCell(strides, field, ampNorm, ...
                    plotHandles, reqElements, color, plotEvents)

                [plotHandle, offset, ampCoefs] = plotCellAvg(strides, ...
                    field, N, sync_norm, ampNorm, plotHandle, side, ...
                    color, offset, plotEv)

                % function avgStride = getCellAvg(strides, N) % Pseudo-code
                %     for i = properties
                %         strideMat = cell2mat(strides, field, N) % If it is a labTS only
                %         avgFieldData = mean(strideMat, 3);
                %         avgField = fieldConstructor(avgFieldTime, avgFieldData);
                %         avgStride.field = avgField; % If it is not a labTS, make an
                %         empty field or copy it from first stride
                %     end
                % end

                % function [avgEventsTime, Labels] = plotAvgEvent
                % end
            end

            %% Private Methods
            methods (Access = private)
                interval = getIntervalBtwEvents(this, event1, event2)
            end

        end


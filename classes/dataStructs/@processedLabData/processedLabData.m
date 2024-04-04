classdef processedLabData < labData
    %processedLabData  Extends labData to include proccessed data derived
    %from the raw data.
    %
    %processedLabData properties:
    %   gaitEvents - labTS object with HS and TO events
    %   procEMGdata - processedEMGTS object
    %   angleData - labTS object with angles calculated from marker data
    %   adaptParams - parameterSeries adaptation values on a strid-by-stide basis
    %   isSingleStride - boolean flag to check length of data
    %   experimentalParams - parameterSeries for testing new adaptation
    %   parameters
    %
    %processedLabData methods:
    %
    %   getProcEMGData - accessor for processed EMGs
    %   getProcEMGList - returns list of processed EMG labels
    %   getPartialGaitEvents - accessor for specific events
    %   getEventList - returns list of event labels
    %   getAngleData - accessor for angle data
    %   getParam - accessor for adaptation parameters
    %   getExpParam - accessor for experimental adaptation parameters
    %   calcAdaptParams - re-computes adaptation parameters
    %
    %   separateIntoStrides - ?
    %   separateIntoSuperStrides - ?
    %   separateIntoDoubleStrides - ?
    %   getStrideInfo - ?
    %   getStridedField - ?
    %   getAlignedField - ?
    %
    %See also: labData, labTimeSeries, processedEMGTimeSeries, parameterSeries

    %%
    properties %(SetAccess= private)  Cannot set to private, because labData will try to set it when using split()
        gaitEvents %labTS
        procEMGData %processedEMGTS
        angleData %labTS (angles based off kinematics)
        adaptParams %paramterSeries (parameters whcih characterize adaptation process) --> must be calculated, therefore not part of constructor.
        %EMGData, which is inherited from labData, saves the FILTERED EMG data used for processing afterwards (not the RAW, which is saved in the not-procesed labData)
        COPData
        COMData
        jointMomentsData
    end

    properties (Dependent)
        isSingleStride %ever used?
        experimentalParams
    end

    %%
    methods

        %Constructor:
        function this=processedLabData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,events,procEMG,angleData,COPData,COMData,jointMomentsData,HreflexPin) %All arguments are mandatory
            if nargin<16 %metaData does not get replaced!
               markerData=[];
               EMGData=[];
               GRFData=[];
               beltSpeedSetData=[];
               beltSpeedReadData=[];
               accData=[];
               EEGData=[];
               footSwitches=[];
               events=[];
               procEMG=[];
               angleData = [];
               COPData=[];
               COMData=[];
               jointMomentsData=[];
               HreflexPin=[];
            end
            this@labData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,HreflexPin);
            this.gaitEvents=events;
            this.procEMGData=procEMG;
            this.angleData=angleData;
            this.COPData=COPData;
            this.COMData=COMData;
            this.jointMomentsData=jointMomentsData;
        end
        %Setters
        function this=set.gaitEvents(this,events)
            if isa(events,'labTimeSeries') || isempty(events)
                this.gaitEvents=events;
            else
                ME=MException('processedLabData:Constructor','events parameter is not a labTimeSeries object.');
                throw(ME);
            end
        end
        function this=set.procEMGData(this,procEMG)
            if isa(procEMG,'processedEMGTimeSeries') || isempty(procEMG)
                this.procEMGData=procEMG;
            else
                ME=MException('processedLabData:Constructor','procEMG parameter is not a processedEMGTimeSeries object.');
                throw(ME);
            end
        end
        function this=set.angleData(this,angleData)
            if isa(angleData,'labTimeSeries') || isempty(angleData)
                this.angleData=angleData;
            else
                ME=MException('processedLabData:Constructor','angleData parameter is not a labTimeSeries object.');
                throw(ME);
            end
        end
        function this=set.adaptParams(this,adaptData)
            if isa(adaptData,'parameterSeries') || isa(adaptData,'labTimeSeries')
                this.adaptParams=adaptData;
            else
                ME=MException('processedLabData:Constructor','adaptParams parameter is not a parameterSeries object.');
                throw(ME);
            end
        end

        %Access method for fields not defined in raw class.
%         function partialProcEMGData=getProcEMGData(this,muscleName)
%             partialProcEMGData=this.getPartialData('procEMGData',muscleName);
%         end
%
%         function list=getProcEMGList(this)
%             list=this.getLabelList('procEMGData');
%         end
%
        function partialGaitEvents=getPartialGaitEvents(this,eventName)
            partialGaitEvents=this.getPartialData('gaitEvents',eventName);
        end
%
%         function list=getEventList(this)
%             list=this.getLabelList('gaitEvents');
%         end
%
%         function partialAngleData= getAngleData(this,angleName)
%             partialAngleData=this.getPartialData('angleData',angleName);
%         end
%
%         function partialParamData=getParam(this,paramName)
%             partialParamData=this.getPartialData('adaptParams',paramName);
%         end
%
%         function partialParamData=getExpParam(this,paramName)
%             partialParamData=this.getPartialData('experimentalParams',paramName);
%         end

        function adaptParams=calcAdaptParams(this)
             adaptParams=calcParameters(this);
        end

        %Modifiers
        function reducedThis=reduce(this,eventLabels,N)
          %Aligns and resamples all timeseries to the same indexes and puts them all together in a single timeseries

            %Define the events that will be used for all further computations
            if nargin<2 || isempty(eventLabels)
                refLeg=this.metaData.refLeg;
                if refLeg == 'R'
                    s = 'R';    f = 'L';
                elseif refLeg == 'L'
                    s = 'L';    f = 'R';
                else
                    ME=MException('processedLabData:reduce:refLegError','the refLeg/initEventSide property of metaData must be either ''L'' or ''R''.');
                    throw(ME);
                end
                eventLabels={[s,'HS'],[f,'TO'],[f,'HS'],[s,'TO']};
            end
            if nargin<3 || isempty(N)
                N=[18 57 18 57]; %12/38% split for DS single stance, 150 samples per gait cycle, to keep it above 100Hz in general
            end
            warning('off','labTS:renameLabels:dont')
            %Synchronize all relevant TSs
            allTS=this.markerData.getDataAsTS([]);
            reducedFields{1}='markerData';
            fieldPrefixes{1}='mrk';
            fieldLabels{1}=allTS.labels;
            %ff=fields(this);
            ff={'markerData','GRFData','accData','procEMGData','angleData','COPData','COMData','jointMomentsData'}; %Exhaustive list of fields to be preserved
            ffShort={'mrk','GRF','acc','EMG','ang','COP','COM','mom'};
            for i=1:length(ff)
                field= this.(ff{i});
                if ~isempty(field) && isa(field,'labTimeSeries') && ~strcmp(ff{i},'gaitEvents') && ~strcmp(ff{i},'markerData') && ~strcmp(ff{i},'EMGData') && ~strcmp(ff{i},'adaptParams')
                    reducedFields{end+1}=ff{i};
                    fieldLabels{end+1}=strcat(ffShort{i},field.labels);
                    fieldPrefixes{end+1}=ffShort{i};
                    allTS=allTS.cat(field.getDataAsTS(field.labels).renameLabels([],fieldLabels{end}).synchTo(allTS));
                end
            end

            %Align:
            [alignTS,bad]=allTS.align(this.gaitEvents,eventLabels,N);

            %Create reduced struct:
            reducedThis=reducedLabData(this.metaData,this.gaitEvents,alignTS,bad,reducedFields,fieldPrefixes,this.adaptParams); %Constructor
            warning('on','labTS:renameLabels:dont')
        end

        function newThis=recomputeEvents(this)
          %This should be a processedLabData method
          %This should force event recomputing too
            events = getEvents(this,this.angleData);
            this.gaitEvents=events;
            this.adaptParams=calcParameters(processedData,subData,eventClass);
            newThis=this;
        end

        %Getters for dependent properties:
        function expParams=get.experimentalParams(this)
             expParams=calcExperimentalParams(this);
        end

        function b=get.isSingleStride(this)
            b=isa(this,'strideData');
        end

        %Separate into strides!
        function [arrayedEvents]=getArrayedEvents(this,eventList)
            arrayedEvents=labTimeSeries.getArrayedEvents(this.gaitEvents,eventList);
        end
        function [steppedDataArray,initTime,endTime]=separateIntoStrides(this,triggerEvent) %Splitting into single strides!
            %triggerEvent needs to be one of the valid gaitEvent labels

            [numStrides,initTime,endTime]=getStrideInfo(this,triggerEvent);
            steppedDataArray={};
            for i=1:numStrides
                steppedDataArray{i}=this.split(initTime(i),endTime(i),'strideData');
            end
        end

        function [steppedDataArray,initTime,endTime]=separateIntoSuperStrides(this,triggerEvent) %SuperStride= 1.5 strides, the minimum unit we need to get our parameters consistently for an individual stride cycle
            %triggerEvent needs to be one of the valid gaitEvent labels
            %Determine end event (ex: if triggerEvent='LHS' then we
            %need 'RHS')
            if strcmp(triggerEvent(1),'L')
                contraLeg='R';
            else
                contraLeg='L';
            end
            contraLateralTriggerEvent=[contraLeg triggerEvent(2:end)];
            [strideIdxs,initTime,endTime]=getStrideInfo(this,triggerEvent);
            [CstrideIdxs,CinitTime,CendTime]=getStrideInfo(this,contraLateralTriggerEvent);
            steppedDataArray={};
            for i=strideIdxs-1
                steppedDataArray{i}=this.split(initTime(i),CendTime(find(CendTime>initTime(i),1,'first')),'strideData');
            end
        end

        function [steppedDataArray,initTime,endTime]=separateIntoDoubleStrides(this,triggerEvent) %DoubleStride= 2 full strides, the minimum unit we need to get our parameters consistently for an individual stride cycle
             %Version deprecated on Apr 2nd 2015
            %triggerEvent needs to be one of the valid gaitEvent labels
            [strideIdxs,initTime,endTime]=getStrideInfo(this,triggerEvent);
            steppedDataArray={};
            for i=strideIdxs(1:end-1)
                steppedDataArray{i}=this.split(initTime(i),endTime(i+1),'strideData');
            end
        end

        function [numStrides,initTime,endTime]=getStrideInfo(this,triggerEvent,endEvent)

            if nargin<2 || isempty(triggerEvent)
                triggerEvent=[this.metaData.refLeg 'HS']; %Using refLeg's HS as default event for striding.
            end
                        %TODO: call onto arrayedEvents, for uniformity:
            if nargin<3 || isempty(endEvent) %using triggerEvent for endEvent
                [arrayedEvents]=getArrayedEvents(this,{triggerEvent});
                initTime=arrayedEvents(1:end-1,1);
                endTime=arrayedEvents(2:end,1);
            else
                [arrayedEvents]=getArrayedEvents(this,{triggerEvent,endEvent});
                if ~isnan(arrayedEvents(end,2)) %Last stride is incomplete
                    arrayedEvents=arrayedEvents(1:end-1,:);
                end
                initTime=arrayedEvents(:,1);
                endTime=arrayedEvents(:,2);
            end
            numStrides=size(initTime,1);

%             refLegEventList=this.getPartialGaitEvents(triggerEvent);
%             refIdxLst=find(refLegEventList==1);
%             auxTime=this.gaitEvents.Time;
%             initTime=auxTime(refIdxLst(1:end-1));
%             numStrides=length(initTime);
%             if nargin<3 || isempty(endEvent) %using triggerEvent for endEvent
%                 endTime=auxTime(refIdxLst(2:end));
%             else %End of interval depends on another event
%                 endEventList=this.getPartialGaitEvents(endEvent);
%                 endIdxLst=find(endEventList==1);
%                 i=0;
%                 noEnd=true;
%                 while i<numStrides && noEnd %This is an infinite loop...
%                     i=i+1;
%                     aux=auxTime(find(endIdxLst>refIdxLst(i),1,'first'));
%                     if ~isempty(aux)
%                         endTime(i)=aux;
%                     else
%                         endTime(i)=NaN;
%                     end
%                 end
%            end
        end

        function [numSteps,initTime,endTime,initEventSide]=getStepInfo(this,triggerEvent)
            if nargin<2 || isempty(triggerEvent)
                triggerEvent='HS'; %Using HS as default event for striding.
            end

            %Find starting events:
            rEventList=this.getPartialGaitEvents(['R' triggerEvent]);
            rIdxLst=find(rEventList==1);
            lEventList=this.getPartialGaitEvents(['L' triggerEvent]);
            lIdxLst=find(lEventList==1);

            auxTime=this.gaitEvents.Time;

            i=0;
            noEnd=true;
            firstIdx=min([rIdxLst;lIdxLst]);
            numSteps=0;
            initTime=[];
            endTime=[];
            initEventSide={};
            if ~isempty(firstIdx)
                initTime(1)=auxTime(firstIdx);
                if any(rIdxLst==firstIdx)
                    lastSideRight=true;
                else
                    lastSideRight=false;
                end
                while noEnd %This is an infinite loop...
                    i=i+1;
                    if lastSideRight
                            aux=find(auxTime(lIdxLst)>initTime(i),1,'first');
                            t=auxTime(lIdxLst(aux));
                            initEventSide{i}='R';
                    else
                            aux=find(auxTime(rIdxLst)>initTime(i),1,'first');
                            t=auxTime(rIdxLst(aux));
                            initEventSide{i}='L';
                    end
                    lastSideRight=~lastSideRight;
                    if ~isempty(aux)
                        endTime(i)=t;
                        initTime(i+1)=t;
                    else
                        endTime(i)=NaN;
                        noEnd=false;
                    end
                end
                numSteps=i;
            end
        end

        function [stridedField,bad,initTime,events]=getStridedField(this,field,events)
            warning('This is very slow and has been deprecated. Please don''t use')
            if isa(events,'char')
                events={events};
            end
            %Step 1: separate strides by the first event
            [numStrides,initTime,endTime]=getStrideInfo(this,events{1});
            M=numStrides;
            N=length(events);
            %Step 2: for each stride, find the other events (if any)
            intermediateTimes=nan(M,N-1);
            bad=false(M,1);
            for i=1:M
                for j=1:N-1
                    aux=find(this.gaitEvents.getDataAsVector(events{j+1}) & this.gaitEvents.Time>=initTime(i) & this.gaitEvents.Time<endTime(i));
                    if length(aux)==1 %Found only one event, as expected
                        intermediateTimes(i,j) = this.gaitEvents.Time(aux);
                    else
                        bad(i)=true;
                    end
                end
            end
            %Step 3: slice timeseries
            timeBreakpoints=[initTime, intermediateTimes]';
            [slicedTS,~,~]=sliceTS(this.(field),[timeBreakpoints(:); endTime(end)],0);

            %Step 4: reshape & set to [] the slices which didn't have
            %proper events
            stridedField=reshape(slicedTS,N,M)';
        end

        function [alignedField,bad]=getAlignedField(this,field,events,alignmentLengths)
            [alignedField,bad]=this.(field).align(this.gaitEvents,events,alignmentLengths);
        end
    end


end

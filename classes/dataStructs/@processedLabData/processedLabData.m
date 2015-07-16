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
        function this=processedLabData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,events,procEMG,angleData,COPData,COMData,jointMomentsData) %All arguments are mandatory
            if nargin<15 %metaData does not get replaced!
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
            end
            this@labData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches);
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
        function partialProcEMGData=getProcEMGData(this,muscleName)
            partialProcEMGData=this.getPartialData('procEMGData',muscleName);
        end
        
        function list=getProcEMGList(this)
            list=this.getLabelList('procEMGData');
        end
        
        function partialGaitEvents=getPartialGaitEvents(this,eventName)
            partialGaitEvents=this.getPartialData('gaitEvents',eventName);
        end
        
        function list=getEventList(this)
            list=this.getLabelList('gaitEvents');
        end
        
        function partialAngleData= getAngleData(this,angleName)
            partialAngleData=this.getPartialData('angleData',angleName);
        end
        
        function partialParamData=getParam(this,paramName)
            partialParamData=this.getPartialData('adaptParams',paramName);
        end
        
        function partialParamData=getExpParam(this,paramName)
            partialParamData=this.getPartialData('experimentalParams',paramName);
        end
                
        function adaptParams=calcAdaptParams(this)
             adaptParams=calcParameters(this);            
        end
           
        %Getters for dependent properties:
        function expParams=get.experimentalParams(this)
             expParams=calcExperimentalParams(this);
        end

        function b=get.isSingleStride(this)
            b=isa(this,'strideData'); 
        end
        
        %Separate into strides!
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
            %Version deprecated on Apr 2nd 2015
%             if strcmpi(triggerEvent(2:3),'HS')
%                 eventType = 'HS';
%             else
%                 eventType = 'TO';
%             end
%             if strcmpi(triggerEvent(1),'R')
%                 opLeg = 'L';
%             else
%                 opLeg = 'R';
%             end
%             refLegEventList=this.getPartialGaitEvents(triggerEvent);
%             opLegEventList=this.getPartialGaitEvents([opLeg,eventType]);
%             refIdxLst=find(refLegEventList==1);
%             opIdxLst=find(opLegEventList==1);
%             auxTime=this.gaitEvents.Time;
%             steppedDataArray={};
%             for i=1:length(refIdxLst)-2
%                 steppedDataArray{i}=this.split(auxTime(refIdxLst(i)),auxTime(opIdxLst(find(opIdxLst(:)>refIdxLst(i+1),1,'first'))),'strideData');
%             end
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
%             refLegEventList=this.getPartialGaitEvents(triggerEvent);
%             refIdxLst=find(refLegEventList==1);
%             auxTime=this.gaitEvents.Time;
%             steppedDataArray={};
%             for i=1:length(refIdxLst)-2
%                 steppedDataArray{i}=this.split(auxTime(refIdxLst(i)),auxTime(refIdxLst(find(refIdxLst(:)>refIdxLst(i+1),1,'first'))),'strideData');
%             end
            
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
            refLegEventList=this.getPartialGaitEvents(triggerEvent);
            refIdxLst=find(refLegEventList==1);
            auxTime=this.gaitEvents.Time;
            initTime=auxTime(refIdxLst(1:end-1));
            numStrides=length(initTime);
            if nargin<3 || isempty(endEvent) %using triggerEvent for endEvent
                endTime=auxTime(refIdxLst(2:end));
            else %End of interval depends on another event
                endEventList=this.getPartialGaitEvents(endEvent);
                endIdxLst=find(endEventList==1);
                i=0;
                noEnd=true;
                while i<numStrides && noEnd %This is an infinite loop...
                    i=i+1;
                    aux=auxTime(find(endIdxLst>refIdxLst(i),1,'first')); 
                    if ~isempty(aux)
                        endTime(i)=aux;
                    else
                        endTime(i)=NaN;
                    end
                end
            end
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
        
        function [alignedField,originalDurations,bad,initTime,events]=getAlignedField(this,field,events,alignmentLengths)
            [stridedField,bad,initTime,events]=getStridedField(this,field,events);
            [alignedField,originalDurations]=labTimeSeries.stridedTSToAlignedTS(stridedField(~bad,:),alignmentLengths);
        end
    end
    
    
end


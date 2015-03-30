classdef processedLabData < labData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    %%
    properties %(SetAccess= private)  Cannot set to private, because labData will try to set it when using split()
        gaitEvents %labTS
        procEMGData %processedEMGTS
        angleData %labTS (angles based off kinematics)
        adaptParams %labTS (parameters whcih characterize adaptation process) --> must be calculated, therefore not part of constructor.
        %EMGData, which is inherited from labData, saves the FILTERED EMG data used for processing afterwards (not the RAW, which is saved in the not-procesed labData)
    end
    
    properties (Dependent)        
        isSingleStride
        experimentalParams
    end
    
    %%
    methods
        
        %Constructor:
        function this=processedLabData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,events,procEMG,angleData) %All arguments are mandatory
            if nargin<12 %metaData does not get replaced!
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
            end
            this@labData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches);
            if isa(events,'labTimeSeries') || isempty(events)
                this.gaitEvents=events;
            else
                ME=MException('processedLabData:Constructor','events parameter is not a labTimeSeries object.');
                throw(ME);
            end
            if isa(procEMG,'processedEMGTimeSeries') || isempty(procEMG)
                this.procEMGData=procEMG;
            else
                ME=MException('processedLabData:Constructor','procEMG parameter is not a processedEMGTimeSeries object.');
                throw(ME);
            end
            if isa(angleData,'labTimeSeries') || isempty(angleData)
                this.angleData=angleData;
            else             
                ME=MException('processedLabData:Constructor','angleData parameter is not a labTimeSeries object.');
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
        function steppedDataArray=separateIntoStrides(this,triggerEvent) %Splitting into single strides!
            %triggerEvent needs to be one of the valid gaitEvent labels
                     
            %refLegEventList=this.getPartialGaitEvents(triggerEvent);
            %refIdxLst=find(refLegEventList==1);
            %auxTime=this.gaitEvents.Time;
            
            [strideIdxs,initTime,endTime]=getStrideInfo(this,triggerEvent);
            steppedDataArray={};
            for i=strideIdxs
                steppedDataArray{i}=this.split(initTime(i),endTime(i),'strideData');
            end
        end
        

        function steppedDataArray=separateIntoSuperStrides(this,triggerEvent) %SuperStride= 1.5 strides, the minimum unit we need to get our parameters consistently for an individual stride cycle
            %triggerEvent needs to be one of the valid gaitEvent labels
            
            %Determine end event (ex: if triggerEvent='LHS' then we
            %need 'RHS')           
            if strcmpi(triggerEvent(2:3),'HS')
                eventType = 'HS';
            else
                eventType = 'TO';
            end
            if strcmpi(triggerEvent(1),'R')
                opLeg = 'L';
            else
                opLeg = 'R';
            end
            refLegEventList=this.getPartialGaitEvents(triggerEvent);
            opLegEventList=this.getPartialGaitEvents([opLeg,eventType]);
            refIdxLst=find(refLegEventList==1);
            opIdxLst=find(opLegEventList==1);
            auxTime=this.gaitEvents.Time;
            steppedDataArray={};
            for i=1:length(refIdxLst)-2
                steppedDataArray{i}=this.split(auxTime(refIdxLst(i)),auxTime(opIdxLst(find(opIdxLst(:)>refIdxLst(i+1),1,'first'))),'strideData');
            end
        end
        
                %Development version: get strides as a 2.5 continuous strides
%         function steppedDataArray=separateIntoStrides(this,triggerEvent)
%             %triggerEvent needs to be one of the valid gaitEvent labels
%             triggerEventList=this.getPartialGaitEvents(triggerEvent);
%             if strcmpi(triggerEvent(1),'L')
%                 contraEvent=['R' triggerEvent(2:end)];
%             else
%                 contraEvent=['L' triggerEvent(2:end)];
%             end
%             contraEventList=this.getPartialGaitEvents(contraEvent);
%             idxLst=find(triggerEventList==1);
%             contraLst=find(contraEventList==1);
%             auxTime=this.gaitEvents.Time;
%             steppedDataArray={};
%             for i=1:length(idxLst)-1
%                 idxFollowingContraEvent=contraLst(contraLst>idxLst(i+1));
%                 if ~isempty(idxFollowingContraEvent)
%                     steppedDataArray{i}=this.split(auxTime(idxLst(i)),auxTime(idxFollowingContraEvent(1)),'strideData');
%                 end
%             end
%         end
        
        function steppedDataArray=separateIntoDoubleStrides(this,triggerEvent) %DoubleStride= 2 full strides, the minimum unit we need to get our parameters consistently for an individual stride cycle
            %triggerEvent needs to be one of the valid gaitEvent labels
            refLegEventList=this.getPartialGaitEvents(triggerEvent);
            refIdxLst=find(refLegEventList==1);
            auxTime=this.gaitEvents.Time;
            steppedDataArray={};
            for i=1:length(refIdxLst)-2
                steppedDataArray{i}=this.split(auxTime(refIdxLst(i)),auxTime(refIdxLst(find(refIdxLst(:)>refIdxLst(i+1),1,'first'))),'strideData');
            end
        end
        
        function [strideIdxs,initTime,endTime]=getStrideInfo(this,triggerEvent,endEvent)
            if nargin<2 || isempty(triggerEvent)
                triggerEvent=[this.metaData.refLeg 'HS']; %Using rHS as default event for striding.
            end
                refLegEventList=this.getPartialGaitEvents(triggerEvent);
                refIdxLst=find(refLegEventList==1);
                auxTime=this.gaitEvents.Time;
                initTime=auxTime(refIdxLst(1:end-1));
                strideIdxs=1:length(initTime);
            if nargin<3 || isempty(endEvent) %using triggerEvent for endEvent
                endTime=auxTime(refIdxLst(2:end));
            else %End of interval depends on another event
                endEventList=this.getPartialGaitEvents(endEvent);
                endIdxLst=find(endEventList==1);
                i=0;
                noEnd=true;
                while i<length(strideIdxs) && noEnd
                    i=i+1;
                    aux=auxTime(find(endIdxList>refIdxLst(i),1,'first')); 
                    if ~isempty(aux)
                        endTime(i)=aux;
                    else
                        endTime(i)=NaN;
                    end
                end
            end
        end
    end
    
    
end


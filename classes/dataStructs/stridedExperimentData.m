classdef stridedExperimentData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        metaData %experimentMetaData type
        subData %subjectData type
        stridedTrials %cell array of cell array of strideData objects
    end
    
    properties(SetAccess=private) 
        isTimeNormalized=false; %This should be dependent, and be returned by checking that the length of all timeSeries in all strides has the same length, it is rather boring to do.
    end
    
    methods
        %Constructor
        function this=stridedExperimentData(meta,sub,strides)
                if isa(meta,'experimentMetaData')
                    this.metaData=meta;
                else
                    ME=MException();
                    throw(ME)
                end
                if isa(sub,'subjectData')
                    this.subData=sub;
                else
                    ME=MException();
                    throw(ME)
                end
                if isa(strides,'cell') && all( cellfun('isempty',strides) | cellisa(strides,'cell'))
                    aux=cellisa(strides,'cell');
                    idx=find(aux==1,1);
                    if all(cellisa(strides{idx},'strideData')) %Just checking whether the first non-empty cell is made of strideData objects, but should actually check them all
                        this.stridedTrials=strides;
                    else
                        ME=MException();
                        throw(ME);
                    end
                else
                    ME=MException();
                    throw(ME);
                end                
        end
        
        %Getters for Dependent properties
        function a=get.isTimeNormalized(this)
            a=0; %ToDo!
        end
        
        %Modifiers
        function newThis=timeNormalize(this,N)
           %Lstrides
           newStrides=cell(1,length(this.stridedTrials));
           for trial=1:length(this.stridedTrials)
               thisTrial=this.stridedTrials{trial};
               newTrial=cell(1,length(thisTrial));
               for stride=1:length(thisTrial)
                   thisStride=thisTrial{stride};
                   newTrial{stride}=timeNormalize(thisStride,N);
               end
               newStrides{trial}=newTrial;
           end
           
           %Construct newTrial
           newThis=stridedExperimentData(this.metaData,this.subData,newStrides);
           newThis.isTimeNormalized=true;
        end
        
        function [strides,origTrialL,origTrialR]=getStridesFromCondition(this,condition)
           strides={};           
           origTrialL=[];
           origTrialR=[];
           for trial=this.metaData.trialsInCondition{condition}
               trialData=this.stridedTrials{trial};
               Nsteps=length(trialData);
               strides(end+1:end+Nsteps)=trialData;
               origTrialL(end+1:end+Nsteps)=trial;                            
               origTrialR(end+1:end+Nsteps)=trial;
           end
        end
        
        %Assess results
        
        
    end
    
end


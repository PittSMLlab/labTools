classdef stridedExperimentData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        metaData %experimentMetaData type
        subData %subjectData type
        LstridedTrials
        RstridedTrials %cell array of cell array of strideData objects
    end
    
    properties(SetAccess=private) 
        isTimeNormalized=false; %This should be dependent, and be returned by checking that the length of all timeSeries in all strides has the same length, it is rather boring to do.
    end
    
    methods
        %Constructor
        function this=stridedExperimentData(meta,sub,Lstrides,Rstrides)
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
                if isa(Lstrides,'cell') && all( cellfun('isempty',Lstrides) | cellisa(Lstrides,'cell'))
                    aux=cellisa(Lstrides,'cell');
                    idx=find(aux==1,1);
                    if all(cellisa(Lstrides{idx},'strideData')) %Just checking whether the first non-empty cell is made of strideData objects, but should actually check them all
                        this.LstridedTrials=Lstrides;
                    else
                        ME=MException();
                        throw(ME);
                    end
                else
                    ME=MException();
                    throw(ME);
                end
                if isa(Rstrides,'cell') && all( cellfun('isempty',Rstrides) | cellisa(Rstrides,'cell'))
                    aux=cellisa(Rstrides,'cell');
                    idx=find(aux==1,1);
                    if all(cellisa(Rstrides{idx},'strideData')) %Just checking whether the first non-empty cell is made of strideData objects, but should actually check them all
                        this.RstridedTrials=Rstrides;
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
           newLstrides=cell(1,length(this.LstridedTrials));
           for trial=1:length(this.LstridedTrials)
               thisTrial=this.LstridedTrials{trial};
               newTrial=cell(1,length(thisTrial));
               for stride=1:length(thisTrial)
                   thisStride=thisTrial{stride};
                   newTrial{stride}=timeNormalize(thisStride,N);
               end
               newLstrides{trial}=newTrial;
           end
           
           %Rstrides
           newRstrides=cell(1,length(this.RstridedTrials));
           for trial=1:length(this.RstridedTrials)
               thisTrial=this.RstridedTrials{trial};
               newTrial=cell(1,length(thisTrial));
               for stride=1:length(thisTrial)
                   thisStride=thisTrial{stride};
                   newTrial{stride}=timeNormalize(thisStride,N);
               end
               newRstrides{trial}=newTrial;
           end
           
           %Construct newTrial
           newThis=stridedExperimentData(this.metaData,this.subData,newLstrides,newRstrides);
           newThis.isTimeNormalized=true;
        end
        
        function [Lstrides,Rstrides,origTrialL,origTrialR]=getStridesFromCondition(this,condition)
           Lstrides={};
           Rstrides={};
           origTrialL=[];
           origTrialR=[];
           for trial=this.metaData.trialsInCondition{condition}
               trialData=this.LstridedTrials{trial};
               Nsteps=length(trialData);
               Lstrides(end+1:end+Nsteps)=trialData;
               origTrialL(end+1:end+Nsteps)=trial;
               trialData=this.RstridedTrials{trial};
               Nsteps=length(trialData);
               Rstrides(end+1:end+Nsteps)=trialData;
               origTrialR(end+1:end+Nsteps)=trial;
           end
        end
        
        %Assess results
        
        
    end
    
end


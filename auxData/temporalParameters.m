classdef temporalParameters
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        strideFullTimeL=NaN; %times for strides starting at LHS
        strideFullTimeR=NaN; %times for strides starting at RHS
        strideHalfTimeLR=NaN; %times from LHS to RHS
        strideHalfTimeRL=NaN; %times from RHS to LHS
        doubleSupportLR=NaN; %times from LHS to RTO
        doubleSupportRL=NaN; %times from RHS to LTO
        stanceTimeL=NaN; %times from LHS to LTO
        stanceTimeR=NaN; %times from RHS to RTO
        swingTimeL=NaN; %times from LTO to LHS
        swingTimeR=NaN; %times form RTO to RHS
        doubleSupportDiff=NaN;
        bad=NaN;
    end
    
    methods
        %Constructor:
        function this=temporalParameters(experimentData)
            fs=experimentData.gaitEvents.sampFreq;
            Ts=experimentData.gaitEvents.sampPeriod;
            events=experimentData.gaitEvents.getDataAsVector({'LHS','RHS','LTO','RTO'});
            LHS=events(:,1);
            RHS=events(:,2);
            LTO=events(:,3);
            RTO=events(:,4);
            Time=experimentData.gaitEvents.Time;
            refLeg=experimentData.metaData.refLeg;
            
            aux=LHS+2*RTO+3*RHS+4*LTO; %This should get events in the sequence 1,2,3,4,1... with 0 for non-events
            
%             %Find event in first sample: if it exists, the data is
%             %strideData
%             Time=[Time;Time(end)+Ts];
%             switch aux(1) %If this is not 0, then we are dealing with strideData
%                 case 1
%                     firstEvent='LHS';
%                     events=[events;true,false,false,false];
%                 case 2
%                     firstEvent='RTO';
%                     events=[events;false,false,false,true];
%                 case 3
%                     firstEvent='RHS';
%                     events=[events;false,true,false,false];
%                 case 4
%                     firstEvent='LTO';
%                     events=[events;false,false,true,false];
%                 otherwise
%                     %Not a stride
%                     Time=Time(1:end-1);
%             end
%             
%             LHS=events(:,1);
%             RHS=events(:,2);
%             LTO=events(:,3);
%             RTO=events(:,4);
%             aux=LHS+2*RTO+3*RHS+4*LTO; %This should get events in the sequence 1,2,3,4,1... with 0 for non-events
%             aux2=aux(aux~=0); %This should get rid of 0s
%             %Sanity check
%             bad=false;
%             aux3=diff(aux2); %This should only return 1s or -3s
%             if any((aux3~=1)&(aux3~=-3))
%                 disp('Warning: Non consistent event detection')
%                 bad=true;
%             end
            

            %% Case 1: the data contains several strides
            lastLHStime=0;
            lastRHStime=Time(find(RHS,1,'last'));
            lastLTOtime=0;
            lastRTOtime=0;

            if ~isempty(lastRHStime)
                NstridesL=sum(LHS(Time<lastRHStime))-1;
                inds=find(LHS(Time<lastRHStime));
            else
                NstridesL=0;
            end
            for step=1:NstridesL
                timeLHS=Time(inds(step));
                timeNextLHS=Time(inds(step+1));
                indFollowingRHS=find((Time>timeNextLHS)&RHS,1);
                timeFollowingRHS=Time(indFollowingRHS);
                
                %Check consistency:
                aa=aux(inds(step):indFollowingRHS); %Get events in this interval
                bb=diff(aa(aa~=0)); %Keep only event samples
                this.bad(step)=any(mod(bb,4)~=1) || (timeNextLHS-timeLHS)>2; %Make sure the order of events is good
                
                if ~this.bad(step)
                    timeLTO=Time(find((Time>timeLHS)&LTO,1));
                    timeRTO=Time(find((Time>timeLHS)&RTO,1));
                    timeRHS=Time(find((Time>timeLHS)&RHS,1));
                    timeFollowingRTO=Time(find((Time>timeNextLHS)&RTO,1));

                    this.stanceTimeL(step)=timeLTO-timeLHS;
                    this.strideFullTimeL(step)=timeNextLHS-timeLHS;
                    this.doubleSupportLR(step)=timeRTO-timeLHS;
                    this.strideHalfTimeLR(step)=timeRHS-timeLHS;
                    this.swingTimeL(step)=timeNextLHS-timeLTO;
                    
                    this.stanceTimeR(step)=timeFollowingRTO-timeRHS;
                    this.strideFullTimeR(step)=timeFollowingRHS-timeRHS;
                    this.doubleSupportRL(step)=timeLTO-timeRHS;
                    this.strideHalfTimeRL(step)=timeNextLHS-timeRHS;
                    this.swingTimeR(step)=timeFollowingRHS-timeRTO;
                    this.doubleSupportDiff(step)=this.doubleSupportLR(step)-this.doubleSupportRL(step);
                    
                    
                else
                    this.stanceTimeL(step)=NaN;
                    this.strideFullTimeL(step)=NaN;
                    this.doubleSupportLR(step)=NaN;
                    this.strideHalfTimeLR(step)=NaN;
                    this.swingTimeL(step)=NaN;
                    this.stanceTimeR(step)=NaN;
                    this.strideFullTimeR(step)=NaN;
                    this.doubleSupportRL(step)=NaN;
                    this.strideHalfTimeRL(step)=NaN;
                    this.swingTimeR(step)=NaN;
                    this.doubleSupportDiff(step)=NaN;
                end
                
                
                
            end

            if any(this.bad)
                disp(['Warning: Non consistent event detection in ' num2str(sum(this.bad)) 'strides;'])

            end
    end
        
        %I/O
        function [tp,paramList]=getParamsAsVector(this)
           auxLst=properties(class(this));
           for i=1:length(auxLst)
              eval(['tp(i,:)=this.' auxLst{i} ';']);
           end
           paramList=auxLst;
        end
    end
    
end


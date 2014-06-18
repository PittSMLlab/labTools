classdef processedEMGTimeSeries  < labTimeSeries
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    %%
    properties(SetAccess=private)
        processingInfo %processingInfo object
    end

    
    %%
    methods
        
        %Constructor:
        function this=processedEMGTimeSeries(data,t0,Ts,labels,processingInfo) %Necessarily uniformly sampled
            this@labTimeSeries(data,t0,Ts,labels);
            if isa(processingInfo,'processingInfo')
                this.processingInfo=processingInfo;
            else
                ME=MException('processedEMGTimeSeries:Constructor','processingInfo parameter is not an processingInfo object.');
                throw(ME)
            end
        end
        
        %-------------------
        
        %Other I/O functions:
        function newTS=getDataAsTS(this,label)
            [data,time,auxLabel]=getDataAsVector(this,label);
            newTS=processedEMGTimeSeries(data,time(1),this.sampPeriod,auxLabel,this.processingInfo);
        end

        %-------------------
        
        %Modifier functions:        
        function newThis=resampleN(this,newN) %Same as resample function, but directly fixing the number of samples instead of TS
            auxThis=this.resampleN@labTimeSeries(newN);
            newThis=processedEMGTimeSeries(auxThis.Data,auxThis.Time(1),auxThis.sampPeriod,auxThis.labels,this.processingInfo);
        end
        
        function newThis=split(this,t0,t1)
           auxThis=this.split@labTimeSeries(t0,t1);
               if auxThis.Nsamples>0 %Empty series was returned
                   newThis=processedEMGTimeSeries(auxThis.Data,auxThis.Time(1),auxThis.sampPeriod,auxThis.labels,this.processingInfo);
               else
                   newThis=processedEMGTimeSeries(auxThis.Data,0,auxThis.sampPeriod,auxThis.labels,this.processingInfo);
               end
        end
        
    end

end


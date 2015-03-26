classdef orientedLabTimeSeries  < labTimeSeries
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    %%
    properties(SetAccess=private)
        orientation %orientationInfo object
    end

    
    %%
    methods
        
        %Constructor:
        function this=orientedLabTimeSeries(data,t0,Ts,labels,orientation) %Necessarily uniformly sampled
            if nargin<1
                data=[];
                t0=[];
                Ts=[];
                labels={};
                orientation=orientationInfo();
            end
                this@labTimeSeries(data,t0,Ts,labels);
                if isa(orientation,'orientationInfo')
                    this.orientation=orientation;
                else
                    ME=MException('orientedLabTimeSeries:Constructor','Orientation parameter is not an OrientationInfo object.');
                    throw(ME)
                end
        end
        
        %-------------------
        
        %Other I/O functions:
        function [newTS,auxLabel]=getDataAsTS(this,label)
            [data,time,auxLabel]=getDataAsVector(this,label);
            newTS=orientedLabTimeSeries(data,time(1),this.sampPeriod,auxLabel,this.orientation);
        end

        %-------------------
        
        %Modifier functions:
        
        function newThis=resampleN(this,newN) %Same as resample function, but directly fixing the number of samples instead of TS
            auxThis=this.resampleN@labTimeSeries(newN);
            newThis=orientedLabTimeSeries(auxThis.Data,auxThis.Time(1),auxThis.sampPeriod,auxThis.labels,this.orientation);
        end
        
        function newThis=split(this,t0,t1)
           auxThis=this.split@labTimeSeries(t0,t1);
           newThis=orientedLabTimeSeries(auxThis.Data,auxThis.Time(1),auxThis.sampPeriod,auxThis.labels,this.orientation);
        end
        
%         function newThis=derivate(this)
%             auxThis=this.derivate@labTimeSeries;
%             newThis.orientation=this.orientation;
%         end
        
    end

end


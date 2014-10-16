classdef parameterSeries < labTimeSeries
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        hiddenTime
    end
    
    methods
        function this=parameterSeries(data,labels,times)
            this@labTimeSeries(data,1,1,labels);
            this.hiddenTime=times;
        end
        
        %Other functions that need redefining:
        function [F,f]=fourierTransform(~,~)
            error('parameterSeries:fourierTransform','You cannot do that!')
            F=[];
            f=[];
        end
        
        function newThis=resample(this) %the newTS is respected as much as possible, but forcing it to be a divisor of the total time range
            error('parameterSeries:resample','You cannot do that!')
            newThis=[];
        end
        
        function newThis=resampleN(this) %Same as resample function, but directly fixing the number of samples instead of TS
            error('parameterSeries:resampleN','You cannot do that!')
            newThis=[];
        end
        
        %Display
        function h=plot(this,h,labels) %Alternative plot: all the traces go in different axes
            if nargin<2 || isempty(h)
                h=figure;
            else
                figure(h)
            end
            N=length(this.labels);
            if nargin<3 || isempty(labels)
                relData=this.Data;
                relLabels=this.labels;
            else
               [relData,~,relLabels]=this.getDataAsVector(labels); 
               N=size(relData,2);
            end
            
            for i=1:N
                h1(i)=subplot(ceil(N/2),2,i);
                hold on
                plot(this.hiddenTime,relData(:,i),'.')
                ylabel(relLabels{i})
                hold off
            end
            linkaxes(h1,'x')
                
        end
    end
    
end


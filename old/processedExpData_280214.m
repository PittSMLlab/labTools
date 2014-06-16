classdef processedExpData
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here
    
       properties
        metaData %experimentMetaData type
        subData %subjectData type
        processedTrials %cell array of rawTrialData type
    end
    
    methods
        function this=processedExpData(meta,sub,processedTrials)

           if nargin>0 && isa(meta,'experimentMetaData')
               this.metaData=meta;
           else
               ME=MException('processedExpData:Constructor','Experiment metaData is not an experimentMetaData type object.');
               throw(ME);
           end
           
           if nargin>1 && isa(sub,'subjectData')
               this.subData=sub;
           else
               ME=MException('processedExpData:Constructor','Subject data is not a subjectData type object.');
               throw(ME);
           end
           
           if nargin>2 && isa(processedTrials,'cell') 
               aux=cellfun('isempty',processedTrials);
               aux2=find(~aux,1);
               if ~isempty(aux2) && isa(processedTrials{aux2},'processedTrialData')
                    this.processedTrials=processedTrials;
               else
                   ME=MException('processedExpData:Constructor','Processed data is not a cell array of processedTrialData type objects.');
                   throw(ME);
               end
           else
               ME=MException('processedExpData:Constructor','Processed data is not a cell array.');
               throw(ME);
           end
        end
        
    end
    
end


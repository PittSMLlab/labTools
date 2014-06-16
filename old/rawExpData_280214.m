classdef rawExpData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        metaData %experimentMetaData type
        subData %subjectData type
        rawTrials %cell array of rawTrialData type
    end
    
    methods
        function this=rawExpData(meta,sub,rawTrials)

           if nargin>0 && isa(meta,'experimentMetaData')
               this.metaData=meta;
           else
               ME=MException('rawExpData:Constructor','Experiment metaData is not an experimentMetaData type object.');
               throw(ME);
           end
           
           if nargin>1 && isa(sub,'subjectData')
               this.subData=sub;
           else
               ME=MException('rawExpData:Constructor','Subject data is not a subjectData type object.');
               throw(ME);
           end
           
           if nargin>2 && isa(rawTrials,'cell') 
               aux=cellfun('isempty',rawTrials);
               aux2=find(~aux,1);
               if ~isempty(aux2) && isa(rawTrials{aux2},'rawTrialData')
                    this.rawTrials=rawTrials;
               else
                   ME=MException('rawExpData:Constructor','Raw data is not a cell array of rawTrialData type objects.');
                   throw(ME);
               end
           else
               ME=MException('rawExpData:Constructor','Raw data is not a cell array.');
               throw(ME);
           end
        end
        
    end
    
end


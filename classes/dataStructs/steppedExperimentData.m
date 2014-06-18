classdef stridedExperimentData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        metaData %experimentMetaData type
        subData %subjectData type
        LstridedTrials
        RstridedTrials %cell array of cell array of strideData objects
    end
    
    properties (Dependent)
        isTimeNormalized %true if all elements in data share the same timeVector (equal sampling, not just range) 
    end
    
    methods
        %Constructor
        function this=stridedExperimentData(meta,sub,Lstrides,Rstrides)
                if isa(metaData,'experimentMetaData')
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
                        this.LstridedData=Lstrides;
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
                        this.RstridedData=Rstrides;
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
        
    end
    
end


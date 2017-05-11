classdef reducedLabData %AKA alignedLabData
    
    properties
        Data=[];
        bad=[];
        gaitEvents %labTS
        adaptParams
        metaData %labMetaData object
    end
    properties (Dependent)
        procEMGData %processedEMGTS
        angleData %labTS (angles based off kinematics)
        COPData
        COMData
        jointMomentsData
        markerData %orientedLabTS
        GRFData %orientedLabTS
        accData %orientedLabTS
        beltSpeedSetData %labTS, sent commands to treadmill
        beltSpeedReadData %labTS, speed read from treadmill
        footSwitchData %labTS
        strideNo
        initTimes
    end
    properties(SetAccess=private)
        fields_
        fieldPrefixes_
    end
    methods
        function this=reducedLabData(metaData,events,alignTS,bad,fields,fieldPrefixes,adaptParams) %Constructor
           this.metaData=metaData;
           this.Data=alignTS;
           this.bad=bad;
           this.fields_=fields;
           this.fieldPrefixes_=fieldPrefixes;
           this.adaptParams=adaptParams;
           this.gaitEvents=events;
        end
        
        %Getters:
        %Can we do a universal getter for dependent fields like this?
%         function pED=get(fieldName)
%             prefix=this.fieldPrefixes_(strcmp(this.fields_,fieldName));
%             pED=this.Data.getPartialDataAsATS(this.Data.getLabelsThatMatch(prefix));
%         end
        function pED=get.procEMGData(this)
            [ST,~]=dbstack;
            pED=this.universalDependentFieldGetter(ST.name);
        end
        function pED=get.angleData(this)
            [ST,~]=dbstack;
            pED=this.universalDependentFieldGetter(ST.name);
        end
        function pED=get.COPData(this)
            [ST,~]=dbstack;
            pED=this.universalDependentFieldGetter(ST.name);
        end
        function pED=get.COMData(this)
            [ST,~]=dbstack;
            pED=this.universalDependentFieldGetter(ST.name);
        end
        function pED=get.jointMomentsData(this)
            [ST,~]=dbstack;
            pED=this.universalDependentFieldGetter(ST.name);
        end
        function pED=get.markerData(this)
            [ST,~]=dbstack;
            pED=this.universalDependentFieldGetter(ST.name);
        end
        function pED=get.accData(this)
            [ST,~]=dbstack;
            pED=this.universalDependentFieldGetter(ST.name);
        end
        function pED=get.GRFData(this)
            [ST,~]=dbstack;
            pED=this.universalDependentFieldGetter(ST.name);
        end
        function pED=get.beltSpeedSetData(this)
            pED=[];
        end
        function pED=get.beltSpeedReadData(this)
            pED=[];
        end
        function pED=get.footSwitchData(this)
            pED=[];
        end
        function sN=get.strideNo(this)
            sN=size(this.Data.Data,3);
        end
        function iT=get.initTimes(this)
           iT=this.Data.eventTimes(1,1:end-1); 
        end
        
        %Setters
        function this=set.metaData(this,mD)
           %Check something 
           this.metaData=mD;
        end
        function this=set.Data(this,dd)
            if ~isa(dd,'alignedTimeSeries')
                error('reducedLabData:setData','Data needs to be an ATS')
            else
                this.Data=dd;
            end
        end
        function this=set.bad(this,b)
           if length(b)~=this.strideNo
               error('Inconsistent sizes')
           else
               this.bad=b;
           end
        end
        function this=set.gaitEvents(this,e)
           if ~isa(e,'labTimeSeries') || ~isa(e.Data,'logical')
               error('Input argument needs to be a logical labTimeSeries')
           else
               this.gaitEvents=e;
           end
        end
        function this=set.adaptParams(this,aP)
           if ~isa(aP,'parameterSeries') || size(aP.Data,1)~=this.strideNo
               error('Input argument needs to be a parameterSeries object of length equal to stride number.')
           elseif any(abs(aP.getDataAsVector('initTime')-this.initTimes')>1e-9) %Check that adaptParams is computed with the same initial event as alignTS was
               error('AdaptParams seems to have been computed with different events than the provided data (alignTS)')
           else
               this.adaptParams=aP;
           end
        end
        
    end
    methods(Hidden)
        function pED=universalDependentFieldGetter(this,funName)
            fieldName=regexp(funName,'\.get\.','split');
            prefix=this.fieldPrefixes_(strcmp(this.fields_,fieldName{2}));
            pED=this.Data.getPartialDataAsATS(this.Data.getLabelsThatMatch(prefix));
            warning('off','labTS:renameLabels:dont')
            pED=pED.renameLabels([],cellfun(@(x) x(4:end),pED.labels,'UniformOutput',false));
            warning('on','labTS:renameLabels:dont')
        end
    end
end


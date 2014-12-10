classdef labData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    %%
    properties %(SetAccess=private)
        metaData %labMetaData object
        markerData %orientedLabTS
        EMGData %labTS
        EEGData %labTS
        GRFData %orientedLabTS
        accData %orientedLabTS
        beltSpeedSetData %labTS, sent commands to treadmill
        beltSpeedReadData %labTS, speed read from treadmill
        footSwitchData %labTS
    end   
    
    %%
    methods
        
        %Constructor:
        function this=labData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches)
            %----------------
            
            %if nargin<1 || isempty(metaData)
            %    this.metaData=labMetaData(); %I think this should be mandatory and fail instead of putting an empty metaData.
            %end
            %if isa(metaData,'trialMetaData') %Had to comment this on
            %10/7/2014, because trialMetaData and experimentMetaData are no
            %longer labMetaData objects. -Pablo
                this.metaData=metaData;
            %else
            %    ME=MException('labData:Constructor','First argument (metaData) should be a labMetaData object.');
            %    throw(ME)
            %end
            if nargin<2 || isempty(markerData)
                this.markerData=[];
            elseif isa(markerData,'orientedLabTimeSeries')
                this.markerData=markerData; %Needs to be empty or have labels {'Lxxx*', 'Rxxx*'}, where 'xxx' is a 2 or 3-letter abbreviation from the list: {'ANK','TOE','HEE','KNE','TIB','THI','PEL','HIP','SHO','ELB','WRI'} or {'HEA*'}
            else
                ME=MException('labData:Constructor','Second argument (markerData) should be an orientedLabMetaData object.');
                throw(ME);
            end
            if nargin<3 || isempty(EMGData)
                this.EMGData=[];
            elseif isa(EMGData,'labTimeSeries')
                this.EMGData=EMGData; %Needs to be empty or have labels {'Lxxx', 'Rxxx'}, where 'xxx' is a 2 or 3-letter abbreviation from the list: {'TA','PER','SOL','MG','BF','RF','VM','TFL','GLU'}
            else
                ME=MException('labData:Constructor','Third argument (EMGData) should be an labMetaData object.');
                throw(ME);
            end
            if nargin<4 || isempty(GRFData)
                this.GRFData=[];
            elseif isa(GRFData,'orientedLabTimeSeries')
                this.GRFData=GRFData; %Needs to be empty or have labels {'F*L','F*R','M*R','M*L'}, where '*' is either 'x', 'y' or 'z'
            else
                ME=MException('labData:Constructor','Fourth argument (GRFData) should be an orientedLabMetaData object.');
                throw(ME);
            end
            if nargin<5 || isempty(beltSpeedSetData)
                this.beltSpeedSetData=[];
            elseif isa(beltSpeedSetData,'labTimeSeries')
                this.beltSpeedSetData=beltSpeedSetData; %Empty or labels 'L' and 'R'
            else
                ME=MException('labData:Constructor','Fifth argument (beltSpeedSetData) should be an labMetaData object.');
                throw(ME);
            end
            if nargin<6 || isempty(beltSpeedReadData)
                this.beltSpeedReadData=[];
            elseif isa(beltSpeedReadData,'labTimeSeries')
                this.beltSpeedReadData=beltSpeedReadData; %Empty or labels 'L' and 'R'
            else
                ME=MException('labData:Constructor','Sixth argument (beltSpeadReadData) should be an labMetaData object.');
                throw(ME);
            end
            if nargin<7 || isempty(accData)
                this.accData=[];
            elseif isa(accData,'orientedLabTimeSeries')
                this.accData=accData;
            else
                ME=MException('labData:Constructor','Seventh argument (accData) should be an orientedLabMetaData object.');
                throw(ME);
            end
            if nargin<8 || isempty(EEGData)
                this.EEGData=[];
            elseif isa(EEGData,'labTimeSeries')
                this.EEGData=EEGData; %Needs to be empty or have labels in the international 10-20 system.
            else
                ME=MException('labData:Constructor','Eigth argument (EEGData) should be an labMetaData object.');
                throw(ME);
            end
            if nargin<9 || isempty(footSwitches)
                this.footSwitchData=[];
            elseif isa(footSwitches,'labTimeSeries')
                this.footSwitchData=footSwitches; %Empty or labels 'L' and 'R'
            else
                ME=MException('labData:Constructor','Ninth argument (footSwitches) should be an labMetaData object.');
                throw(ME);
            end
  
            %---------------
            %Check that all data is from the same time interval: To Do!
            %---------------

            
        end
        
        
        
        %Other I/O:
        function partialMarkerData= getMarkerData(this,markerName)
            partialMarkerData=this.getPartialData('markerData',markerName);
        end
        
        function list=getMarkerList(this)
            list=this.getLabelList('markerData');
        end
        
        function partialEMGData=getEMGData(this,muscleName)
            partialEMGData=this.getPartialData('EMGData',muscleName);
        end
        
        function list=getEMGList(this)
            list=this.getLabelList('EMGData');
        end
        
        function partialEEGData=getEEGData(this,positionName) %Standard 10-20 nomenclature
            partialEEGData=this.getPartialData('EEGData',positionName);
        end
        
        function list=getEEGList(this)
            list=this.getLabelList('EEGData');
        end
        
        function partialGRFData=getGRFData(this,label)
            partialGRFData=this.getPartialData('GRFData',label);
        end
        
        function list=getGRFList(this)
            list=this.getLabelList('GRFData');
        end
        
        function specificForce=getForce(this,side,axis)
            specificForce=this.getGRFData([side 'F' axis]); %Assuming that labels in GRF data are 'FxL', 'FxR', 'FyL' and so on... 
        end
        
        function specificMoment=getMoment(this,side,axis)
            specificMoment=this.getGRFData([side 'M' axis]);
        end
        
        function beltSp=getBeltSpeed(this,side)
            beltSp=this.getPartialData('beltSpeedReadData',side);
        end
        
        
        % Process data method
        function processedData=process(this,subData)
            trialData=this;
            % 1) Extract amplitude from emg data if present
            procEMGData = processEMG(trialData);
                
            % 2) Attempt to interpolate marker data if there is missing data
            % (make into function once we have a method to do this)
            markers=trialData.markerData;
            if ~isempty(markers)
                %function goes here?
            end
            
            % 3) Calculate limb angles
            angleData = calcLimbAngles(trialData);           

            % 4) Calculate events from kinematics or force if available            
            events = getEvents(trialData,angleData);

            % 5) If 'beltSpeedReadData' is empty, try to generate it
            % from foot markers, if existent
            if isempty(trialData.beltSpeedReadData)
                trialData.beltSpeedReadData = getBeltSpeedsFromFootMarkers(trialData,events);
            end     
                
            % 6) Generate processedTrial object    
            processedData=processedTrialData(trialData.metaData,trialData.markerData,trialData.EMGData,trialData.GRFData,trialData.beltSpeedSetData,trialData.beltSpeedReadData,trialData.accData,trialData.EEGData,trialData.footSwitchData,events,procEMGData,angleData);
              
            %7) Calculate adaptation parameters - to be
            % recalculated later!!
            processedData.adaptParams=calcParameters(processedData,subData);
        end
        
        function newThis=split(this,t0,t1,newClass) %Returns an object of the same type, unless newClass is specified (it needs to be a subclass)
           newThis=[]; %Just to avoid Matlab saying this is not defined
           cname=class(this);
           if nargin<4
               %(ID,date,experimenter,desc,obs,refLeg,parentMeta)
               metaData=derivedMetaData(labDate.genIDFromClock,labDate.getCurrent,'labData.split',['Splice of ' this.metaData.description],'Auto-generated',this.metaData.refLeg,this.metaData); %HH removed 'Partial INterval' after labdata.split since 'type' propery was eliminated.
                eval(['newThis=' cname '(metaData);']); %Call empty constructor of same class
           else
               metaData=strideMetaData(labDate.genIDFromClock,labDate.getCurrent,'labData.split',['Splice of ' this.metaData.description],'Auto-generated',this.metaData.refLeg,this.metaData); %Should I call a different metaData constructor
                eval(['newThis=' newClass '(metaData);']); %Call empty constructor of same class
           end
           auxLst=properties(cname);
           for i=1:length(auxLst)
               eval(['oldVal=this.' auxLst{i} ';']) %Should try to do this only if the property is not dependent, otherwise, I'm computing things I don't need
               if isa(oldVal,'labTimeSeries') && ~strcmpi(auxLst{i},'adaptParams')
                   newVal=oldVal.split(t0,t1); %Calling labTS.split (or one of the subclass' implementation)
               elseif ~isa(oldVal,'labMetaData')
                   newVal=oldVal; %Not a labTS object, not splitting
               end
               try
                  eval(['newThis.' auxLst{i} '=newVal;']) %If this fails is because the property is not settable
               catch
                   
               end
           end
           newThis.metaData=metaData;
           
        end

    end
    
    %% Protected methods:
    methods (Access=protected)
        
       function partialData=getPartialData(this,fieldName,labels)
            if nargin<3 || isempty(labels)
               eval(['partialData=this.' fieldName ';']);
           else
               eval(['partialData=this.' fieldName '.getDataAsVector(labels);']); %Should I return this as labTS?
           end 
       end 
        
       function list=getLabelList(this,fieldName)
           eval(['list = this.' fieldName '.labels;']);
       end
       
    end
    
    
end


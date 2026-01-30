classdef experimentData
    %experimentData  Contains all information for a single experiment
    %
    %experimentData properties:
    %   metaData - experimentMetaData object
    %   subData - subjectData object
    %   data - cell array of labData objects or any objects which extend
    %          labData
    %   isRaw - returns true if data is an object of the rawLabData class
    %   isProcessed - returns true if data is an object of the processedLabData class
    %   isStepped - returns true if data is an object of the strideData class
    %   fastLeg - computes which blet ('L' or 'R') was the fast belt
    %
    %experimentData Methods:
    %   getSlowLeg - returns leg that was on the slow belt
    %   getRefLeg - returns refrence leg for parameter computations
    %   process - creates a new experimentData object with data property
    %   being a cell of processedLabData objects
    %   makeDataObj - creates an adaptationData object
    %   parameterEvolutionPlot -
    %   parameterTimeCourse -
    %   recomputeParameters -
    %   splitIntoStrides -
    %   getStridedField -
    %   getAlignedField -
    %   getConditionIdxsFromName -
    %
    %See also: experimentMetaData, subjectData, labData

    properties
        metaData % field that contains information from the experiment. Has to be an experimentMetaData object
        subData %subjectData type
        data %cell array of labData type (or its subclasses: rawLabData, processedLabData, strideData), containing data from each trial/ experiment block
    end

    properties (Dependent)
        isRaw %true if data is an object of the rawLabData class
        isProcessed %true if data is an object of the processedLabData class
        isStepped %or strided
        fastLeg
    end

    methods
        %% Constructor
        function this=experimentData(meta,sub,data)
            %inputs are metaData, subData, and rawTrialData

           if nargin>0
               this.metaData=meta;
           end
           if nargin>1
               this.subData=sub;
           end
           if nargin>2
               this.data=data;
           end
        end

        %% Setters for class properties
        function this=set.metaData(this,meta)
            %define or re-define metaData for this experiment
            %
            %INPUT: metaData object
            if isa(meta,'experimentMetaData')
               this.metaData=meta;
           else
               ME=MException('experimentData:Constructor','Experiment metaData is not an experimentMetaData type object.');
               throw(ME);
           end
        end
        function this=set.subData(this,sub)
            %define or re-define subjectData
            %
            %INPUT: subjectData object
            if isa(sub,'subjectData')
               this.subData=sub;
           else
               ME=MException('experimentData:Constructor','Subject data is not a subjectData type object.');
               throw(ME);
            end
        end
        function this=set.data(this,data)
            %define or redefine experiment data
            %
            %INPUT: labData object or one of its subclasses
            if isa(data,'cell')  % Has to be array of labData type cells.
               aux=find(cellfun('isempty',data)~=1);
               for i=1:length(aux)
                   if ~isa(data{aux(i)},'labData') && ~isa(data{aux(i)},'reducedLabData')
                       ME=MException('experimentData:Constructor','Data is not a cell array of labData (or one of its subclasses) objects.');
                       throw(ME);
                   end
               end
               this.data=data;
           else
               ME=MException('experimentData:Constructor','Data is not a cell array.');
               throw(ME);
            end
        end

        %% Getters for Dependent properties
        function a=get.isProcessed(this)
            %Returns true if the trials have been processed (i.e. parameters have been calculated through ladData.process()), and false if
            %they contain only rawData.
            %   INPUTS:
            %       this: experimentData object
            %   OUTPUTS:
            %       a: boolean
            aux=cellfun('isempty',this.data);
            idx=find(aux~=1); %Not empty
            a=true;
            for i=idx
               if ~isa(this.data{i},'processedLabData')
                   a=false;
               end
            end
        end

        function a=get.isStepped(this)
            %returns true if data is an object of the strideData class
            aux=cellfun('isempty',this.data);
            idx=find(aux~=1,1);
            a=isa(this.data{idx},'strideData');
        end

        function a=get.isRaw(this)
            %returns true if data is an object of the rawLabData class
            aux=cellfun('isempty',this.data);
            idx=find(aux~=1,1);
            a=isa(this.data{idx},'rawLabData');
        end

        function fastLeg=get.fastLeg(this)
            error('Unimplemented. Try getRefLeg, which reads slow/fast leg labels from trial metaData.')
            %based on each trial, determine from the data (not metadata which could be wrong) which leg is the fast leg, even
            %if there is no belt data
            %
            %returns 'R' or 'L'
            vR=[];
            vL=[];
            trials=cell2mat(this.metaData.trialsInCondition);
            for i=1:length(trials)
                trial=trials(i);
                if ~this.isStepped
                    if ~isempty(this.data{trial}.beltSpeedReadData)
                        %Old version: Need to fix, as
                        %we are not really populating the beltSpeedReadData
                        %field.
                        %vR(end+1)=nanmean(this.data{trial}.beltSpeedReadData.getDataAsVector('R'));
                        %vL(end+1)=nanmean(this.data{trial}.beltSpeedReadData.getDataAsVector('L'));
                        %New version:
                        %TODO: Need to come up with an appropriate velocity
                        %measurement if we want this function to work
                        %properly.
                    end
                else %Stepped trial
                    for step=1:length(this.data{trial})
                        if ~isempty(this.data{trial}{step}.beltSpeedReadData)
                            %vR(end+1)=nanmean(this.data{trial}{step}.beltSpeedReadData.getDataAsVector('R'));
                            %vL(end+1)=nanmean(this.data{trial}{step}.beltSpeedReadData.getDataAsVector('L'));
                        end
                    end
                end
            end
            if ~isempty(vR) && ~isempty(vL)
                if nanmean(vR)<nanmean(vL)
                    fastLeg='L';
                elseif nanmean(vR)>nanmean(vL)
                    fastLeg='R'; %Defaults to this, even if there is no beltSpeedData
                else
                    error('experimentData:fastLeg','Both legs are moving at the same speed');
                end
            else
                error('experimentData:fastLeg','No data to compute fastest leg, try using expData.getRefLeg which reads from each trial''s metaData.');
            end
        end

        function ageInMonths=getSubjectAgeAtExperimentDate(this)
            if ~isempty(this.subData.age)
                ageInMonths=this.subData.age*12; %In months
            elseif ~isempty(this.subData.dateOfBirth)
                warning('expData:subjectDOB','subject metadata contains DOB, this may be a privacy issue.')
                dob=this.subData.dateOfBirth;
                testData=this.metaData.date;
                [ageInMonths]=testData.timeSince(dob);
            else
                error('expData:subjectDOB','Could not establish subject age at experiment time.')
            end
        end

        function slowLeg=getSlowLeg(this)
            %determine which leg is the slow leg, simply the opposite of
            %the fast leg, be sure to call get.fastLeg() first
            %
            %returns 'R' or 'L'
            if strcmpi(this.fastLeg,'L')
                slowLeg='R';
            elseif strcmpi(this.fastLeg,'R')
                slowLeg='L';
            else
                slowLeg=[];
            end
        end

        function refLeg=getRefLeg(this)
            %By majority vote over trials, returns the reference leg for
            %the entire experiment
            %
            %returns 'R' or 'L'
            refLeg={};
           for i=1:length(this.data)%Going over trials
               if ~isempty(this.data{i})
               refLeg{i}=this.data{i}.metaData.refLeg;
               end
           end
           Rvotes=sum(strcmp(refLeg,'R'));
           Lvotes=sum(strcmp(refLeg,'L'));
           if Rvotes>Lvotes
               refLeg='R';
           elseif Rvotes<Lvotes
               refLeg='L';
           else
               error('experimentData:getRefLeg','Could not determine unique reference leg');
           end
        end

        function fL=getNonRefLeg(this)
            %returns the non-reference leg, 'R' or 'L'
            sL=this.getRefLeg;
            if strcmp(sL,'R')
                fL='L';
            else
                fL='R';
            end
        end

        %% processing
        function processedThis=process(this,eventClass)

        if nargin<2 || isempty(eventClass)
            eventClass=[];
        end
        %process  process full experiment
        %
        %Returns a new experimentData object with same metaData, subData and processed (trial) data.
        %This is done by iterating through data (trials) and
        %processing each by using labData.process
        %ex: expData=rawExpData.process
        %
        %INPUTS:
        %this: experimentData object
        %
        %OUTPUTS:
        %processedThis: experimentData object with processed data
        %
        %See also: labData

            for trial=1:length(this.data)
                disp(['Processing trial ' num2str(trial) '...'])
                if ~isempty(this.data{trial})
                    procData{trial}=this.data{trial}.process(this.subData,eventClass);
                else
                   procData{trial}=[];
                end
            end
            %this=checkMarkerHealth(this);
            processedThis=experimentData(this.metaData,this.subData,procData);
        end

        function [allTrialModels,modelScore,badFlag]=extractMarkerModels(this)
            noFixFlag=false; %This flag will prevent trying to find permutations to fix data, which can be slow.
            %First: build models
            m=cell(length(this.data),1);
            badFlag=false(size(m));
            modelScore=nan(size(m));
            modelScore2=nan(size(m));
            permuteList=[];
            for trial=1:length(this.data)
                if ~isempty(this.data{trial})
                    aux=this.data{trial}.markerData;
                    [aux,m{trial},permuteList,modelScore(trial),badFlag(trial),modelScore2(trial)]=aux.fixBadLabels(permuteList);
                end
            end
            allTrialModels=m;
        end

        function this=checkMarkerHealth(this,refTrial)
            disp(['Checking marker health...'])

            %First: build models
            [allTrialModels,modelScore,badFlag]=extractMarkerModels(this);

            %Second: select best model
            %TODO: move this chunk to its own function?
            noOutlierTest=false;
            if (nargin<2 || isempty(refTrial)) && ~all(badFlag)
                modelScore(badFlag)=Inf;
                [~,refTrial]=nanmin(modelScore);
            elseif all(badFlag) %Undefined refTrial but all trials are bad
                 warning('Could not find suitable data for model training. Not testing for outliers.')
                 noOutlierTest=true; %This flag prevents the testing for outliers later on.
            end
            try %If there is a model
                mm=allTrialModels{refTrial};
                fprintf(['Using trial ' num2str(refTrial) ' to train outlier detection model...\n'])
                mm.seeModel;
            catch
                %nop
            end

            %Third: for each trial, get  missing markers, analyze fitted model and  find outliers through best model
            for trial=1:length(this.data)
                disp(['Checking trial ' num2str(trial) '...'])
                if ~isempty(this.data{trial})
                    aux=this.data{trial}.markerData;

                    %A: check missing data & fill gaps
                    [~,~,missing]=aux.assessMissing([],-1);

                    %B: analyze fitted models.
                    [~]=validateMarkerModel(allTrialModels{trial},true);

                    %C: find outliers
                    if ~noOutlierTest
                        aux=aux.findOutliers(mm,true);
                        this.data{trial}.markerData=aux;
                    end
                end
            end
            disp(['Outlier data added in Quality field']);
        end


         function this=computeAngles(this)%added by Digna
            for trial=1:length(this.data)
                disp(['Computing angles for trial ' num2str(trial) '...'])
                if ~isempty(this.data{trial})
                    this.data{trial}.angleData=this.data{trial}.calcLimbAngles;
                else

                end
            end
       end

		function adaptData=makeDataObj(this,filename,experimentalFlag,contraLateralFlag)
        %MAKEDATAOBJ  creates an object of the adaptationData class.
        %   adaptData=expData.makeDataObj(filename,experimentalFlag)
        %
        %INPUTS:
        %this: experimentData object
        %filename: string (typically subject identifier)
        %experimentalFlag: boolean - false (or 0) prevents experimental
        %parameter calculation and inclusion
        %
        %OUTPUTS:
        %adptData: object if the adaptationData class, which is
        %saved to present working directory if a filename is specified.
        %
        %   Examples:
        %
        %   adaptData=expData.makeDataObj('Sub01') saves adaptationData
        %   object to Sub01params.mat
        %
        %   adaptData=expData.makeDataObj('',false) does not include
        %   experimentalParams in adaptData object and does not save to file
        %
        %See also: adaptationData, paramData
            if ~(this.isProcessed)
                ME=MException('experimentData:makeDataObj','Cannot create an adaptationData object from unprocessed data!');
                throw(ME);
            end

            if nargin<3
                experimentalFlag=[];
            end
            if nargin<2
                filename=[];
            end
            if nargin<4
                contraLateralFlag=[];
            end
            adaptData=makeDataObjNew(this,filename,experimentalFlag,contraLateralFlag);
        end

        function reducedThis=reduce(this,eventLabels,N)
            if nargin<2 || isempty(eventLabels)
                s=this.getRefLeg;
                f=this.getNonRefLeg;
                eventLabels={[s,'HS'],[f,'TO'],[f,'HS'],[s,'TO']};
            end
            if nargin<3
                N=[];
            end
            redData=cell(size(this.data));
            for i=1:length(this.data)
                redData{i}=this.data{i}.reduce(eventLabels,N);
            end
            reducedThis=experimentData(this.metaData,this.subData,redData);
        end


        %% Display
        %HH: I don't like either of these functions. They take way too long
        %to run, and at the time being they assume that if a field isn't a
        %label of the adaptParams property, then it must be a label of
        %experimentalParams (which is a bad assumption becasue it could
        %result in 5+ minutes of waiting just to find out the parameter
        %doesn't exist.)
        %PI, 5/26/2015: Agreed. Is there any other way to do it if someone asks for a
        %label that does not exist? Do note that these functions are here
        %for flexibility of the code, but the really efficient way to do it
        %is generate an adaptData object (and save it) and use its plotting
        %functions (which is what these do). Perhaps we could issue a
        %warning or a disclaimer telling the user that this takes TOO long.
        function [h,adaptDataObject]=parameterEvolutionPlot(this,field)
            %???
            %
            %INPUTS:
            %field,
            if ~(this.isProcessed)
                ME=MException('experimentData:parameterEvolutionPlot','Cannot generate parameter evolution plot from unprocessed data!');
                throw(ME);
            end
            if ~isempty(this.data{1}) && (all(this.data{1}.adaptParams.isaLabel(field)))
                adaptDataObject=this.makeDataObj([],0);
                h=adaptDataObject.plotParamByConditions(field);
            else
                adaptDataObject=this.makeDataObj; %Creating adaptationData object, to include experimentalParams (which are Dependent and need to be computed each time). Otherwise we could just access this.data{trial}.experimentalParams
                h=adaptDataObject.plotParamByConditions(field);
            end
        end

        function [h,adaptDataObject]=parameterTimeCourse(this,field)
            if ~(this.isProcessed)
                ME=MException('experimentData:parameterTimeCourse','Cannot generate parameter time course plot from unprocessed data!');
                throw(ME);
            end
            if ~isempty(this.data{1}) && (all(this.data{1}.adaptParams.isaLabel(field)))
                adaptDataObject=this.makeDataObj([],0);
                h=adaptDataObject.plotParamTimeCourse(field);
            else
                adaptDataObject=this.makeDataObj; %Creating adaptationData object, to include experimentalParams (which are Dependent and need to be computed each time). Otherwise we could just access this.data{trial}.experimentalParams
                h=adaptDataObject.plotParamTimeCourse(field);
            end
        end

        %% Update/modify
        function this=recomputeParameters(this,eventClass,initEventSide,parameterClasses)
        %RECOMPUTEPARAMETERS recomputes adaptParams for all labData
        %objects in experimentData.data.
        %
        %   Example: if expData is an object of the experimentalData class,
        %       expData=expData.recomputeParameters
        %   will recompute expData.data{i}.adaptParams for all i where
        %   i is a trial of the experiment
        %
        %   See also: parameterSeries
            if nargin<2 || isempty(eventClass)
                eventClass=[];
            end
            if nargin<3 || isempty(initEventSide)
                initEventSide=[];
            end
            if nargin<4 || isempty(parameterClasses)
                parameterClasses=[];
            end
            trials=cell2mat(this.metaData.trialsInCondition);
            for t=trials
                  newParams=calcParameters(this.data{t},this.subData,eventClass,initEventSide,parameterClasses);
                  this.data{t}.adaptParams=this.data{t}.adaptParams.replaceParams(newParams);
            end
        end

        function this=flushAndRecomputeParameters(this,eventClass,initEventSide)
        %FLUSHANDRECOMPUTEPARAMETERS recomputes adaptParams for all labData
        %objects in experimentData.data
        %Different from recomputeParameters() it throws away the previously
        %existing parameters [recompute only substitutes IF there are name
        %collisions, so it allows for recomputing only force or EMG params]
        %
        %   Example: if expData is an object of the experimentalData class,
        %       expData=expData.recomputeParameters
        %   will recompute expData.data{i}.adaptParams for all i where
        %   i is a trial of the experiment
        %
        %   See also: parameterSeries
            if nargin<2 || isempty(eventClass)
                eventClass=[];
            end
            if nargin<3 || isempty(initEventSide)
                initEventSide=[];
            end
            trials=cell2mat(this.metaData.trialsInCondition);
            for t=trials
                  this.data{t}.adaptParams=calcParameters(this.data{t},this.subData,eventClass,initEventSide,[]);
            end
        end

        function this=recomputeEvents(this,eventClass,initEventSide)
        %RECOMPUTEEVENTS recomputes events AND parameters for all trials,
        %with default options.
        %See also: processedLabData.recomputeEvents
            trials=cell2mat(this.metaData.trialsInCondition);
            for t=trials
                  this.data{t}=recomputeEvents(this.data{t}); %This recomputes events AND recomputes parameters (otherwise parameters will not correspond to the new events)
            end
        end

        function stridedExp=splitIntoStrides(this,refEvent)
        %This might not be used?
            if ~this.isStepped && this.isProcessed
                for trial=1:length(this.data)
                    disp(['Splitting trial ' num2str(trial) '...'])
                    trialData=this.data{trial};
                    if ~isempty(trialData)
                        if nargin<2 || isempty(refEvent)
                            refEvent=[trialData.metaData.refLeg,'HS'];
                            %Assuming that the first event of each stride should be
                            %the heel strike of the refLeg! (check c3d2mat -
                            %refleg should be opposite the dominant/fast leg)
                        end
                        aux=trialData.separateIntoStrides(refEvent);
                        strides{trial}=aux;
                    else
                        strides{trial}=[];
                    end
                end
                stridedExp=stridedExperimentData(this.metaData,this.subData,strides);
            else
                disp('Cannot stride experiment because it is raw or already strided.');
            end
        end

        function [stridedField,bad,originalTrial,originalInitTime,events]=getStridedField(this,field,conditions,events)
            if nargin<4 || isempty(events)
                events=[this.getSlowLeg 'HS'];
            end
           if nargin<3 || isempty(conditions)
               trials=cell2mat(this.metaData.trialsInCondition);
           else
               if ~isa(conditions,'double') %If conditions are given by name, and not by index
                   conditions=getConditionIdxsFromName(this,conditions);
               end
               trials=cell2mat(this.metaData.trialsInCondition(conditions));
           end
           stridedField={};
           bad=[];
           originalInitTime=[];
           originalTrial=[];
           for i=trials
              %[aux,bad1,initTime1]=this.data{i}.(field).splitByEvents(this.data{i}.gaitEvents,events);
              [aux,bad1,initTime1,events]=this.data{i}.getStridedField(field,events);
              stridedField=[stridedField; aux];
              bad=[bad; bad1];
              originalTrial=[originalTrial; i*ones(size(bad1))];
              originalInitTime=[originalInitTime; initTime1];
           end
        end

        function [alignedField,originalTrial,bad]=getAlignedField(this,field,conditions,events,alignmentLengths)
           if nargin<4 || isempty(events)
               events=[this.getSlowLeg 'HS'];
           end
           if nargin<3 || isempty(conditions)
               trials=cell2mat(this.metaData.trialsInCondition);
           else
               if ~isa(conditions,'double') %If conditions are given by name, and not by index
                   conditions=getConditionIdxsFromName(this,conditions);
               end
               trials=cell2mat(this.metaData.trialsInCondition(conditions));
           end
           bad=[];
           originalInitTime=[];
           originalTrial=[];
           originalDurations=[];
           for i=trials %Trials in condition
              %[aux,bad1,initTime1]=this.data{i}.(field).splitByEvents(this.data{i}.gaitEvents,events);
              [alignedField1,bad1]=this.data{i}.getAlignedField(field,events,alignmentLengths);
              if i==trials(1)
                  alignedField=alignedField1;
              else
                  force=false;
                  alignedField=alignedField.cat(alignedField1,[],force);
              end
              bad=[bad; bad1];
              originalTrial=[originalTrial; i*ones(size(bad1))];
              %originalInitTime=[originalInitTime; initTime1];
              %originalDurations=[originalDurations; originalDurations1];
           end
        end

        %% Auxiliar
        function conditionIdxs=getConditionIdxsFromName(this,conditionNames)
            %Looks for condition names that are similar to the ones given
            %in conditionNames and returns the corresponding condition idx
            %ConditionNames should be a cell array containing a string or
            %another cell array of strings in each of its cells.
            %E.g. conditionNames={'Base','Adap',{'Post','wash'}}
            conditionIdxs=this.metaData.getConditionIdxsFromName(conditionNames);
        end

        function [numStrides,trials,initTimes,endTimes]=getStrideInfo(this,eventClass)
            numStrides=0;
            initTimes=[];
            endTimes=[];
            trials=[];
            for t=1:length(this.data)
                if ~isempty(this.data{t})
                [numStrides_,initTimes_,endTimes_]=getStrideInfo(this.data{t},eventClass);
                numStrides=numStrides+numStrides_;
                initTimes=[initTimes;initTimes_];
                endTimes=[endTimes;endTimes_];
                trials=[trials;t*ones(numStrides_,1)];
                end
            end
        end
    end
	methods (Hidden=true, Access=private)
		function adaptData=makeDataObjNew(this,filename,experimentalFlag,contraLateralFlag)
            %This function may not be compatible with certain methods of the
            %adaptationData class

            if isempty(contraLateralFlag) || contraLateralFlag==0 %Normal parameters
                %nop
            else %Computing all parameters on a contraLateral way (this is, we compute parameters using the NON reference leg as the 'slow' one, opposite to the default computation)
                if strcmp(this.getRefLeg,'R')
                    initEventSide='L';
                elseif strcmp(this.getRefLeg,'L')
                    initEventSide='R';
                else
                    ME=MException('makeDataObject:ContralateralComputation','Could not determine proper reference leg for this experiment.');
                    throw(ME);
                end
                this=recomputeParameters(this,[],initEventSide); %Using default event class ('', as opposed to 'force' or 'kin')
            end

            for i=1:length(this.data) %Trials
                if ~isempty(this.data{i}) && ~isempty(this.data{i}.adaptParams)
                    %Get data from this trial:
                    aux=this.data{i}.adaptParams;
                    trialTypes{i}=this.data{i}.metaData.type;
                    if ~(nargin>2 && ~isempty(experimentalFlag) && experimentalFlag==0)
                        aux=cat(aux,this.data{i}.experimentalParams);
                    end
                    %Concatenate with other trials:
                    if ~isempty(aux.Data) %Case in which no strides were detected for a trial, it could happen. Not concatenating those
                        if ~exist('paramData','var')
                            paramData=aux;
                        else
                            paramData=addStrides(paramData,aux);
                        end
                    end
                end
            end
            % HH: remove all bad strides completely
            % paramData=parameterSeries(paramData.Data(paramData.bad==0,:),paramData.labels,paramData.hiddenTime(paramData.bad==0),paramData.description);
            paramData=paramData.setTrialTypes(trialTypes);
            adaptData=adaptationData(this.metaData,this.subData,paramData);
            if nargin>1 && ~isempty(filename)
                save([filename 'params.mat'],'adaptData','-v7.3'); %HH edit 2/12 - added 'params' to file name so experimentData file isn't overwritten
            end
        end
    end
    methods (Static)
        function this=loadobj(this)
            if ~isempty(this.subData.dateOfBirth)
                warning('expData:subjectDOB',['Subject data contains DOB information for subject ' this.subData.ID '. Data will be hidden. You should overwrite (save) your file with this new version to prevent this warning in the future. Please check that all other information is intact before overwriting.'])
                %Determine age (in months):
                age=round(this.metaData.date.timeSince(this.subData.dateOfBirth));
                %Scrub DOB from subject meta data, save age at experiment time (in years):
                this.subData=subjectData([],this.subData.sex,this.subData.dominantLeg,this.subData.dominantArm,this.subData.height,this.subData.weight,age/12,this.subData.ID);
            end
        end
    end
end

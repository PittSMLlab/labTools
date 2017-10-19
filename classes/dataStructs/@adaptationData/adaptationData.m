classdef adaptationData
%ADAPTATIONDATA - Class to store all parameters of interest for every stride
%in an experiment
%   Objects of this class can be generated from experimentData by calling
%   experimentData.makeDataObj
%
%adaptationData properties:
%   metaData - object if the experimentMetaData class
%   subData - object of the subjectData class
%   data - object of the parameterSeries class
%
%adaptationData methods:
%   removeBias - subtract off mean baseline values
%   normalizeBias -
%   getParameterList - obtain an array of strings with the labels of the all parameters
%   getParamInTrial - obtain data for a parameter in a specific trial
%   getParamInCond - obtain data for a parameter in a specific condition
%   isaCondition - check whether a condition exitsts in an experiment
%   getEarlyLateData -
%   getBias -
%   getConditionIdxsFromName -
%   getIndsInCondition -
%   plotParamTimeCourse - plot the time course of a parameter
%   plotGroupedSubjectsTimeCourse -
%   plotGroupedSubjects -
%   plotGroupedSubjectsBars -
%   getGroupedData -
%   plotAvgTimeCourse -
%   groupedScatterPlot -
%   correlations -
%   See also: experimentData

    properties
        metaData %cell array with information related with the experiment (type of protocol, date, experimenter, conditions...)in a experimentMetaData object
        subData %cell array with information of the subject (DOB, sex, height, weight...)in a subjectData object
        data %cell array of parameterSeries type
    end

    properties(Hidden)
        TMbias_=[];
        OGbias_=[];
    end

    methods
        %Constructor
        function this=adaptationData(meta,sub,data)

            if nargin>0 && isa(meta,'experimentMetaData')
                this.metaData=meta;
            else
                ME=MException('adaptationData:Constructor','metaData is not an experimentMetaData type object.');
                throw(ME);
            end

            if nargin>1 && isa(sub,'subjectData')
                this.subData=sub;
            else
                ME=MException('adaptationData:Constructor','Subject data is not a subjectData type object.');
                throw(ME);
            end

            if nargin>2 && (isa(data,'parameterSeries') || isa(data,'paramData'))
                this.data=data;
            else
                ME=MException('adaptationData:Constructor','Data is not a parameterSeries type object.');
                throw(ME);
            end
        end

        function tT=trialTypes(this)
            if ~isempty(this.data.trialTypes)
                tT=this.data.trialTypes; %Tries to read from parameterSeries' trialType field, if it was populated, as we expect it to be with newer versions
            else %If the field was not populated, make an educated guess.
                tT=cell(1,this.metaData.Ntrials);
                for i=1:this.metaData.Ntrials
                    condInd=nan;
                   for j=1:length(this.metaData.conditionName)
                      if any(this.metaData.trialsInCondition{j}==i)
                          condInd=j;
                          break
                      end
                   end
                   if isnan(condInd)
                       tT{i}='mis';
                   elseif ~isempty(strfind(this.metaData.conditionName{condInd},'OG'))
                    tT{i}='OG';
                   elseif ~isempty(strfind(this.metaData.conditionName{condInd},'incline')) || ~isempty(strfind(this.metaData.conditionName{condInd},'hill'))
                       tT{i}='IN';
                   else
                       tT{i}='TM';
                   end
                end
            end
        end
        %Modifiers

        [newThis,baseValues,typeList]=removeBiasV2(this,conditions,normalizeFlag) %Going to deprecate in favor of removeBiasV3's simpler code
        [newThis,baseValues,typeList]=removeBiasV3(this,conditions,normalizeFlag)

        function [newThis,baseValues,typeList]=removeBias(this,conditions)
        % Removes baseline value for all parameters.
        % removeBias('condition') or removeBias({'Condition1','Condition2',...})
        % removes the median value of every parameter from each trial of the
        % same type as the condition entered. If no condition is
        % specified, then the condition name that contains both the
        % type string and the string 'base' is used as the baseline
        % condition.
        %
        %INPUTS:
        %this: experimentData object
        %conditions: conditions to use as reference
        %
        %OUTPUTS:
        %newThis: experimentData object with the bias remove
        %baseValues: values used to calculated the average used to remove the bias
        %typeList; type of condition (OG or TM)
        %
        %EX:[newThis,baseValues,typeList]=adaptData.removeBias('TM base');

            if nargin<2
                conditions=[];
            end
            [newThis,baseValues,typeList]=removeBiasV3(this,conditions);
            newThis.TMbias_=baseValues(strcmp(typeList,'TM'),:);
            newThis.OGbias_=baseValues(strcmp(typeList,'OG'),:);
        end

        function [newThis]=removeAltBias(this,condName,strideNo,exemptStrides,medianFlag,normalizeFlag,removeBadFlag)
           %Same as removeBias, but for an arbitrary subset of strides
           %(e.g. remove the mean of the first 20 strides of adaptation)
           if nargin<7 || isempty(removeBadFlag) || removeBadFlag==0
               base=getEarlyLateData_v2(this,[],condName,0,strideNo,exemptStrides,exemptStrides); %Not removing bad strides
           else
               base=getEarlyLateData_v2(this.removeBadStrides,[],condName,0,strideNo,exemptStrides,exemptStrides); %Removing bad strides for the purpose of baseline computations
           end

           if nargin<5 || isempty(medianFlag) || medianFlag==0
               base=nanmean(squeeze(base{1}));
           else
               base=nanmedian(squeeze(base{1}));
           end
           newThis=this;
           dataOld=this.data.Data;
            if normalizeFlag==0
                %added lines to ensure that if certain parameters never
                %have a baseline to remove the bias, they are not assigned
                %as NaN from the bsxfun @minus.
                %data(isnan(data))=-100000;
                base(isnan(base))=0;%do not subtract a bias if there is no bias to remove
                newData=bsxfun(@minus,dataOld,base); %Substracting baseline
            else
                base(isnan(base))=1;%do not subtract a bias if there is no bias to remove
                newData=bsxfun(@rdivide,dataOld,base); %Dividing by baseline
            end
            M=newThis.data.fixedParams;
            newThis.data.Data(:,M+1:end)=newData(:,newThis.data.fixedParams+1:end); %Not removing bias for 'fixed' params: initTime, finalTime, trial, good, bad
            %newData(isnan(data))=nan;
            if isempty(this.TMbias_) %Default if bias was not removed previously
                newThis.TMbias_=[zeros(1,M) base(M+1:end)];
                newThis.OGbias_=[zeros(1,M) base(M+1:end)];
            else
                if normalizeFlag==0
                    newThis.TMbias_=newThis.TMbias_+[zeros(1,M) base(M+1:end)];
                    newThis.OGbias_=newThis.OGbias_+[zeros(1,M) base(M+1:end)];
                else
                    newThis.TMbias_=newThis.TMbias_.*[zeros(1,M) base(M+1:end)];
                    newThis.OGbias_=newThis.OGbias_.*[zeros(1,M) base(M+1:end)];
                end
            end
        end

        function [newThis,baseValues,typeList]=normalizeBias(this,conditions)
            if nargin<2
                conditions=[];
            end
            [newThis,baseValues,typeList]=removeBiasV3(this,conditions,1);
        end

        function [newThis]=normalizeToBaseline(this,labelPrefix,baseConds2)
           %This normalization takes the last N strides from a given
           %'baseline' condition and uses it to normalize values of the
           %parameter for the whole experiment.
           %Meant to be used for EMG parameters ONLY
           %It creates NEW parameters with the same name, and the 'Norm' prefix.
           %See also: EMGnormalization (example) parameterSeries.normalizeToBaseline
            warning('This function is meant to be used for EMG parameters only. Use at own risk.')
            if nargin<3
                baseConds2=[];
            end
            if nargin<2
                error('Need to provide a suffix for parameters')
            end

            if isa(labelPrefix,'char')
                labelPrefix={labelPrefix};
            end
            
            if nargin<2 || isempty(baseConds2)
                [baseConds,tType]=this.getBaseConditions;
            else
                baseConds=baseConds2;
            end
            if length(baseConds)>1 %More than 1 baseline found
               idx=find(strcmp(tType,'TM'));
               warning(['More than 1 baseline condition found or provided. Using the first that matches TM type trials: ' baseConds{idx}])
               baseCond=baseConds{idx};
            end
            for i=1:length(labelPrefix)
                %First: get all parameters with given prefix
                labels=this.data.getLabelsThatMatch(['^' labelPrefix{i} '\d+$']);
                %Second: get baseline data for those
                [baseData]=getBaseData(this,baseCond,labels);
                range=squeeze(nanmean(baseData,2));
                rangeValues=[min(range) max(range)];
                this.data=this.data.normalizeToBaseline(labels,rangeValues);
            end
            newThis=this;
        end

        function newThis=removeBadStrides(this,markAsNaNflag)
            if nargin<2 || isempty(markAsNaNflag)
               markAsNaNflag=false; 
            end
            if isa(this.data,'paramData') %What does this do?
                newParamData=this.data;
            else
                aux=this.data;
                inds=~aux.bad;
                if ~markAsNaNflag
                    newParamData=parameterSeries(aux.Data(inds,:),aux.labels,aux.hiddenTime(inds),aux.description);
                    newParamData=newParamData.setTrialTypes(aux.trialTypes);
                else
                    newParamData=this.data.markBadStridesAsNan;
                end
            end
            newThis=adaptationData(this.metaData,this.subData,newParamData);
        end

        function newThis=addNewParameter(this,newParamLabel,funHandle,inputParameterLabels,newParamDescription)
           %This function allows to compute new parameters from other existing parameters and have them added to the data.
           %This is useful when trying out new parameters without having to
           %recompute all existing parameters.
           %INPUT:
           %newPAramLAbel: string with the name of the new parameter
           %funHandle: a function handle with N input variables, whose
           %result will be used to compute the new parameter
           %inputParameterLabels: the parameters that will replace each of
           %the variables in the funHandle
           %EXAMPLE:
           %I want to define a new normalized version of the contributions,
           %that divides contributions by avg. step time and avg. step
           %velocity, so that the velocity contribution is now a
           %measure of belt-speed ratio. In order to do that, I will take
           %the velocityContributionAlt (which already exists and is
           %velocityContribution divided by strideTime, so it is just half
           %the difference of velocities) and then divide it by velocity sum.
           %Velocity sum can be computed by dividing stepTimeContribution
           %by stepTimeDifference (there are other possibilities to compute
           %the same thing. The final equation will look like this:
           %newVelocityContribution = velocityContributionAlt./(2*stepTimeContribution/stepTimeDiff)
           %This can be implemented as:
           %newThis = this.addNewParameter('newVelocityContribution',@(x,y,z)x./(2*y./z),{'velocityContributionAlt','stepTimeContribution','stepTimeDiff'},'velocityContribution normalized to strideTime times average velocity');
           newPS=this.data.addNewParameter(newParamLabel,funHandle,inputParameterLabels,newParamDescription);
           this.data=newPS;
           newThis=this;
        end

        function newThis=replaceLR(this)
            %Idea: get any label that uses 'L' or 'R' and replace it by 'S'
            %and 'F' as corresponds.
            %Also need to write the inverse function
        end

        function [biasTM,biasOG]=getBias(this,labels)
            if isempty(this.TMbias_)
                warning('This adaptationData object is not unbiased.')
                bias=[];
            else
                if nargin>1 && ~isempty(labels)
                    [boolFlag,idx]=this.data.isaLabel(labels);
                    biasOG=this.OGbias_(idx(boolFlag));
                    biasTM=this.TMbias_(idx(boolFlag));
                else %Fast eval
                    biasOG=this.OGbias_;
                    biasTM=this.TMbias_;
                end
            end
        end

        function newThis=markBadWhenMissingAny(this,labels)
            newThis=this;
            newThis.data=newThis.data.markBadWhenMissingAny(labels);
        end

        function newThis=markBadWhenMissingAll(this,labels)
            newThis=this;
            newThis.data=newThis.data.markBadWhenMissingAll(labels);
        end

        function newThis=renameParams(this,oldLabels,newLabels)

              [b,ii]=isaLabel(this.data,oldLabels);
              if any(b)
              newL=this.data.labels;
              newL(ii(b))=newLabels(b);
              newParam=parameterSeries(this.data.Data,newL,this.data.hiddenTime,this.data.description,this.data.trialTypes)     ;
              newThis=this;
              newThis.data=newParam;
              %unique(this.data.stridesTrial)
              %unique(newThis.data.stridesTrial)
              else
                  newThis=this;
              end

        end

        function newThis=getPartialParameters(this,labels)
           newThis=this;
           newThis.data=this.data.getDataAsPS(labels);
        end

        function ageInMonths=getSubjectAgeAtExperimentDate(this)
            dob=this.subData.dateOfBirth;
            testData=this.metaData.date;
            [ageInMonths]=testData.timeSince(dob);
        end

        function newThis=medianFilter(this,N)
            newThis=this;
            newThis.data=this.data.medianFilter(N);
        end

        function newThis=monoLS(this,trialBased,order,Nregularization)
            newThis=this;
            %For each condition, or trial:
            if trialBased==1
                t=unique(this.data.getDataAsVector('trial'));
                for i=1:length(t)
                    [partialData,indData]=this.getParamInTrial([],t(i));
                    aux=monoLS(partialData(:,6:end),[],order,Nregularization);
                    newThis.data.Data(indData,6:end)=aux;
                end
            else %Condition based
                t=unique(1:length(this.metaData.trialsInCondition));
                for i=1:length(t)
                    [partialData,indData]=this.getParamInCond([],t(i));
                    aux=monoLS(partialData(:,6:end),[],order,Nregularization);
                    newThis.data.Data(indData,6:end)=aux;
                end
            end


        end

        function newThis=substituteNaNs(this,method)
            if nargin<2 || isempty(method)
                method='linear';
            end
            newThis=this;
            newThis.data=this.data.substituteNaNs(method);
        end

        %Other I/O functions:
        function [labelList,descriptionList]=getParameterList(this)
        %obtain an array of strings with the labels of the all parameters
        %INPUT:
        %this: experimentData object
        %
        %OUTPUT:
        %labelList: array of strings with the labels name
        %
        %EX: labelList=adaptData.getParameters;
            labelList=this.data.labels;
            descriptionList=this.data.description;
        end

        function [data,inds,auxLabel]=getParamInTrial(this,label,trial)
        %Obtain strides information for a parameter in a specific trial
        %
        %INPUTS:
        %this: experimentData object
        %label: Specific parameter to required information (alphaFast,Sout,velocityContribution....)
        %trial: number of the trial that information is needed
        %
        %OUTPUTS:
        %data: information of the parameter in the trial
        %inds: Position of data points in the matrix
        %auxLabel: Parameter evaluated
        %
        %Ex: [data,inds,auxLabel]=adaptData.getParamInTrial('alphaFast',2)
        %See also: adaptationData.getParamInCond
            if isempty(label)
                label=getParameterList(this);
            end

            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end
            % validate label(s)
            [boolFlag,labelIdx]=this.data.isaParameter(auxLabel);

            % validate trial(s)
            trialNum = [];
            for t=trial
                if isempty(this.data.indsInTrial(t))
                    warning(['Trial number ' num2str(t) ' is not a trial in this experiment.'])
                else
                    trialNum(end+1)=t;
                end
            end
            %get data
            inds=cell2mat(this.data.indsInTrial(trialNum));
            data=this.data.Data(inds,labelIdx(boolFlag==1));
            auxLabel=this.data.labels(labelIdx(boolFlag==1));
        end

        function [data,inds,auxLabel,origTrials]=getParamInCond(this,label,condition,removeBias)
        %Obtain strides information for a parameter in a condition.
        %INPUTS:
        %this: experimentData object
        %label: Specific parameter to required information (alphaFast,Sout,velocityContribution....)
        %condition: Specific condition that information is needed
        %removeBias: 1 to activate function to remove bias, 0 or empty to no activate function
        %
        %OUTPUTS:
        %data: information of the parameter in the trial
        %inds: Position of data points in the matrix
        %auxLabel: Parameter evaluated
        %origTrials: Numbers of trials that compose the condition
        %
        %EX: adaptData.getParamInCond('alphaFast','OG base',0)
        %See also: adaptationData.getParamInTrial
        %          adaptationData.removeBias

%             if nargin<4 || isempty(removeBias)
%                 removeBias=0;
%             end
            if nargin<2 || isempty(label)
                label=this.data.labels;
            end
            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end
            % validate label(s)
            [boolFlag,labelIdx]=this.data.isaParameter(auxLabel);

            % validate condition(s)
            if nargin<3 || isempty(condition) || (~isa(condition,'cell') && any(isnan(condition)))
                condition=this.metaData.conditionName(~cellfun(@isempty,this.metaData.conditionName));
            end
            condNum = [];
            if isa(condition,'char')
                condition={condition};
            end

            if isa(condition,'cell')
                condNum=this.metaData.getConditionIdxsFromName(condition);
                if any(isnan(condNum))
                    warning([this.subData.ID ' did not perform condition ''' condition{isnan(condNum)} ''''])
                end
                condNum(isnan(condNum))=[];
            elseif isa(condition,'double')
                condNum=condition;
            else
                ME=MException('AdaptData.getParamInCond','Condition has to be char, cell of char, or double');
                throw(ME)
            end

            %get data
            if nargin>3 && ~isempty(removeBias) %Default: no bias removal
                error('Remove bias is no longer supported from within getParamInCond. Remove bias first and then call this function')
            end

            trials=cell2mat(this.metaData.trialsInCondition(condNum));
            inds=cell2mat(this.data.indsInTrial(trials));
            origTrials=[];
            for i=1:length(trials)
                origTrials(end+1:end+length(this.data.indsInTrial(i)))=i; %What's the purpose of this??
            end
            data=this.data.Data(inds,labelIdx(boolFlag==1));
            auxLabel=this.data.labels(labelIdx(boolFlag==1));
        end

        function [boolFlag,labelIdx]=isaCondition(this,cond)
            if isa(cond,'char')
                auxCond{1}=cond;
            elseif isa(cond,'cell')
                auxCond=cond;
            elseif isa(cond,'double')
                auxCond=this.metaData.conditionName(cond);
            end
            N=length(auxCond);
            boolFlag=false(N,1);
            labelIdx=zeros(N,1);
            for j=1:N
                for i=1:length(this.metaData.conditionName)
                    if strcmpi(auxCond{j},this.metaData.conditionName{i})
                        boolFlag(j)=true;
                        labelIdx(j)=i;
                        break;
                    end
                end
            end
            for i=1:length(boolFlag)
                if boolFlag(i)==0
                    warning([this.subData.ID 'did not perform condition ''' cond{i} ''' or the condition is misspelled.'])
                end
            end
        end

        function [veryEarlyPoints,earlyPoints,latePoints]=getEarlyLateData(this,labels,conds,removeBiasFlag,earlyNumber,lateNumber,exemptLast)
        %obtain the earliest and late data points for conditions
		%allow to eliminate very late data points
		%Predefine values:
		%earlyNumber=5
		%veryEarlyPoints=3
		%latePoints=20
		%exemptLast=5
		%
		%INPUTS:
		%this:experimentData object
		%labels: parameters to plot
		%conds: condition that information is needed
		%removeBiasFlag:1 to activate function to remove bias, 0 or empty to no activate function
		%earlyNumber:number of strides to take as earliest values
		%lateNumber: number of strides to take as late values
		%exemptLast: number of strides to discard
		%OUTPUTS:
		%veryEarlyPoints:  value of the 3 strides on the condition
		%earlyPoints: value of the earliest strides
		%latePoints: value of the late strides
		%
		%EX:[veryEarlyPoints,earlyPoints,latePoints]=adaptData.getEarlyLateData({'Sout'},{'TM base'},1,5,40,5);

            N1=3;%all(cellfun(@(x) isa(x,'char'),conds))
            if isa(conds,'char')
                conds={conds};
            elseif ~isa(conds,'cell') && ~all(cellfun(@(x) isa(x,'char'),conds))
                error('adaptationData:getEarlyLateData','Conditions must be a string or a cell array containing strings.');
            end
            nConds=length(conds);
            if nargin<2 || ~(isa(labels,'char') || (isa(labels,'cell') && all(cellfun(@(x) isa(x,'char'),labels)) ))
                error('adaptationData:getEarlyLateData','Labels must be a string or a cell array containing strings.')
            end
            if nargin<5 || isempty(earlyNumber)
                N2=5; %early number of points
            else
                N2=earlyNumber;
            end
            if nargin<6 || isempty(lateNumber)
                N3=20; %late number of points
            else
                N3=lateNumber;
            end
            if nargin<7 || isempty(exemptLast)
                Ne=5;
            else
                Ne=exemptLast;
            end
            if nargin<4 || isempty(removeBiasFlag)
                removeBiasFlag=1; %Default
            end
            [dataPoints]=getEarlyLateData_v2(this,labels,conds,removeBiasFlag,[N1,N2,-N3],Ne,0);
            veryEarlyPoints=dataPoints{1};
            earlyPoints=dataPoints{2};
            latePoints=dataPoints{3};
            warning('adaptationData:getEarlyLateData','This function is being deprecated, use getEarlyLateDatav2 instead')
        end

        function conditionIdxs=getConditionIdxsFromName(this,conditionNames)
            %Looks for condition names that are similar to the ones given
            %in conditionNames and returns the corresponding condition idx
            %ConditionNames should be a cell array containing a string or
            %another cell array of strings in each of its cells.
            %E.g. conditionNames={'Base','Adap',{'Post','wash'}}
            conditionIdxs=this.metaData.getConditionIdxsFromName(conditionNames);
        end

        function inds=getIndsInCondition(this,conditionNames)
            %Get condition indexes if not already provided:
            if isa(conditionNames,'char') || isa(conditionNames,'cell')
                conditionIdxs=this.metaData.getConditionIdxsFromName(conditionNames);
            else
                conditionIdxs=conditionNames;
            end
            inds={};
            for i=1:length(conditionIdxs)
                if ~isnan(conditionIdxs)
                    %Get trials in each condition:
                    trials=cell2mat(this.metaData.trialsInCondition(conditionIdxs(i)));
                    %Now, get inds in each trial:
                    inds{i}=cell2mat(this.data.indsInTrial(trials));
                else
                    inds{i}=[];
                end
            end
        end

        function trialNums=getTrialsInCond(this,conditionNames)
            trialNums=this.metaData.getTrialsInCondition(conditionNames);
        end


        %Stats testing:
        % 1) Multiple groups

        function [p,anovatab,stats,postHoc,postHocEstimate,data]=anova1(this,param,conds,groupingStrides,exemptFirst,exemptLast)
            %Post-hoc is Bonferroni corrected t-test
            [data]=getEarlyLateData_v2(this,param,conds,0,groupingStrides,exemptLast,exemptFirst);
            for i=1:length(data)
                group{i}=repmat([1:length(conds)]',1,abs(groupingStrides(i))) + (i-1)*length(conds);
            end
            newData=cell2mat(data); %This concatenates (cat) the data along the second dimension by default, new Data should be a 2-D array of conditionxs x strides
            newGroups=cell2mat(group);
            [p,anovatab,stats]=anova1(newData(:),newGroups(:),'off');
            %Tukey-Kramer post-hoc:
            c=multcompare(stats); %By default uses tukey-kramer / honest signficant difference
            M=length(conds)*length(groupingStrides);
            postHoc=nan(M);
            postHocEstimate=nan(M);
            postHoc(sub2ind([M,M],c(:,1),c(:,2)))=c(:,6);
            postHocEstimate(sub2ind([M,M],c(:,1),c(:,2)))=c(:,4);
        end

        function [p,anovatab,stats,postHoc,postHocEstimate,data]=kruskalwallis(this,param,conds,groupingStrides,exemptFirst,exemptLast)
            if isa(param,'char')
                param={param};
            end
            if length(param)>1
                for i=1:length(param)
                [p{i},anovatab{i},stats{i},postHoc{i},postHocEstimate{i},data{i}]=kruskalwallis(this,param{i},conds,groupingStrides,exemptFirst,exemptLast);
                end
            else
            %Post-hoc is a Bonferroni corrected Mann-Whitney-Wilcoxon U
            %(ranked sum) test.
            [data]=getEarlyLateData_v2(this,param,conds,0,groupingStrides,exemptLast,exemptFirst);
            for i=1:length(data)
                group{i}=repmat([1:length(conds)]',1,abs(groupingStrides(i))) + (i-1)*length(conds);
            end
            newData=cell2mat(data); %This concatenates (cat) the data along the second dimension by default, new Data should be a 2-D array of conditionxs x strides
            newGroups=cell2mat(group);
            [p,anovatab,stats]=kruskalwallis(newData(:),newGroups(:),'off');
            M=length(conds)*length(groupingStrides);
            postHoc=nan(M);
            postHocEstimate=nan(M);
            %Tukey-Kramer post-hoc:
            %c=multcompare(stats); %By default uses tukey-kramer / honest signficant difference
            %postHoc(sub2ind([M,M],c(:,1),c(:,2)))=c(:,6);
            %postHocEstimate(sub2ind([M,M],c(:,1),c(:,2)))=c(:,4);
            %MWW-U post-hoc:
            for i=1:M
                for j=i+1:M
                    [p,~,s]=ranksum(newData(newGroups==i),newData(newGroups==j));
                    postHoc(i,j)=p;
                    postHocEstimate(i,j)=s.zval;
                end
            end
            end
        end
        %function [p,data]=twoSampleTtest()
        %
        %end
        %function [p,data]=twoSampleMWWU()
        %
        %end

        %Display functions:
        function [figHandle,plotHandles]=plotParamTimeCourse(this,label,runningBinSize,trialMarkerFlag,conditions,medianFlag,plotHandles)
                    %Plot of the behaviour of parameters through the different conditions
            %specify the parameter behaviour on each condition and trial
            %
            %INPUTS:
            %this:experimentData object
            %label: parameters to plot
            %runningBinSize: number of data points to considered to make an average
            %trialMarkerFlag: 1 to identify the different trials that compose a single condition.
            %
            %OUTPUT:
            %figHandle: number of the figure where is the plot
            %
            %EX: adaptData.plotParamTimeCourse('spatialContribution',2,1)
            if isa(label,'char')
                label={label};
            end
            if nargin<4 || isempty(trialMarkerFlag)
                trialMarkerFlag=0;
            end
            if nargin<3 || isempty(runningBinSize)
                runningBinSize=1;
            end
            if nargin<5 || isempty(conditions)
                conditions=this.metaData.conditionName;
            end
            if nargin<6 || isempty(medianFlag)
                medianFlag=[];
            end
            if nargin<7
                plotHandles=[];
            end
            figHandle=adaptationData.plotAvgTimeCourse({this},label(:)',conditions,runningBinSize,trialMarkerFlag,[],[],[],[],[],[],medianFlag,plotHandles);
        end

        [inds,names]=getEarlyLateIdxs(this,conds,numberOfStrides,exemptLast,exemptFirst)

        [dataPoints]=getEarlyLateData_v2(this,labels,conds,removeBiasFlag,numberOfStrides,exemptLast,exemptFirst)

        [figHandle,plotHandles]=plotParamBarsByConditionsv2(this,label,number,exemptLast,exemptFirst,condList,mode,plotHandles);

        function dataPoints=getDataFromInds(this,inds,labels,padWithNaNFlag)
            %Returns data associated to certain stride indexes (e.g. strides 1, 3, 10:15, 21)
            %Inds comes from a call to getEarlyLateIdxs:
            %[inds]=this.getEarlyLateIdxs(conds,numberOfStrides,exemptLast,exemptFirst);
            if nargin<3 || isempty(labels) %More efficient call for when we want everything
                data=this.data.Data;
            else
                data=this.data.getDataAsVector(labels);
            end
            if nargin<4 || isempty(padWithNaNFlag)
               padWithNaNFlag=false;
            end
            nConds=size(inds{1},2);
            nLabels=size(data,2);

            for j=1:length(inds)
                nSteps=size(inds{j},1);
                %for i=1:nConds
                %    dataPoints{j}(i,:,:)=data(inds{j}(:,i),:);
                %end
                %This line does the same as the for loop commented above:
                if any(isnan(inds{j}(:)))
                    if ~padWithNaNFlag
                        error('adaptationData:getDataFromInds',['Could not retrieve for subject ' this.subData.ID ' because some of the indexes given are NaN.'])
                    else
                    %A less drastic option:
                        warning('adaptationData:getDataFromInds',['Index strides for ' this.subData.ID ' are NaN. Data will be padded with NaNs.'])
                        inds{j}=inds{j}';
                        auxInds=inds{j}(~isnan(inds{j}(:)));
                        auxData=nan(numel(inds{j}),nLabels);
                        auxData(~isnan(inds{j}(:)),:)=data(auxInds,:);
                        dataPoints{j}=reshape(auxData,nConds,nSteps,nLabels);
                    end
                else
                    dataPoints{j}=reshape(data(inds{j}',:),nConds,nSteps,nLabels);
                end
            end
        end

        function [fh,ph]=plotTimeAndBars(this,labels,conds,binwidth,trialMarkerFlag,medianFlag,ph,numberOfStrides,monoLSfitFlag)
            %Plots time courses and early/late averaged data in bar form
            %INPUTS:
            %monoLSfitFlag: a value in the [0,3] integer range. 0 plots
            %no fits, 1 plots condition based fit, 2 plots trial based fit,
            %3 plots condition & trial based fits

            fh=figure;

            M=length(labels);
            if nargin<7 || isempty(ph) || size(ph,1)~=M || size(ph,2)~=2
            clear ph
            for i=1:M
                ph(i,1)=subplot(M,3,[1:2]+3*(i-1));
                ph(i,2)=subplot(M,3,[3]+3*(i-1));
            end
            end

            %Defaults:
            plotHandles=[]; %Not allowed
            exemptFirst=1;
            exemptLast=5;
            mode=[];

            %Time courses:
            this.plotParamTimeCourse(labels,binwidth,trialMarkerFlag,conds,medianFlag,ph(:,1));
            if mod(monoLSfitFlag,2)==1 %Add condition based monoLS fits if flag=1,3
                % Third plot: use monotonic LS, constraining derivatives up to 2nd order to have no sign changes, using no regularization, and fitting a single function for each condition
                order=1;
                reg=1;
                medianAcrossSubj=0;
                trialBased=0;
                filterFlag=[medianAcrossSubj,order,reg,trialBased];
                colorOrder=repmat(.6*ones(1,3),3,1); %Changing colors for plot
                binWidth=1;
                %Do the plot:
                adaptationData.plotAvgTimeCourse(this,labels,conds,binWidth,[],[],[],colorOrder,[],[],[],filterFlag,ph(:,1));
            end
            if monoLSfitFlag>1 %Add trial based monoLS fits if flag=2,3
                % Third plot: use monotonic LS, constraining derivatives up to 2nd order to have no sign changes, using no regularization, and fitting a single function for each TRIAL
                order=1;
                reg=1;
                medianAcrossSubj=0;
                trialBased=1;
                filterFlag=[medianAcrossSubj,order,reg,trialBased];
                colorOrder=repmat(0*ones(1,3),3,1); %Changing colors for plot
                binWidth=1;
                %Do the plot:
                adaptationData.plotAvgTimeCourse(this,labels,conds,binWidth,[],[],[],colorOrder,[],[],[],filterFlag,ph(:,1));
            end


            %Add bars:
            this.plotParamBarsByConditionsv2(labels,numberOfStrides,exemptLast,exemptFirst,conds,mode,ph(:,2));

            for i=1:M
                subplot(ph(i,1));
                grid on
                axis tight
                aa=axis;
                subplot(ph(i,2));
                grid on
                ab=axis;
                axis([ab(1:2) aa(3:4)])
                if i~=M
                    ph(i,1).XTickLabel={};
                    ph(i,2).XTickLabel={};
                else
                    subplot(ph(i,1))
                    legend off
                end
                ph(i,2).Title.String=labels{i};
            end
        end
    end



    methods(Static)

         [figHandle,allData]=plotGroupedSubjectsTimeCourse(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,earlyNumber,lateNumber,exemptLast,legendNames)

         [figHandle,allData]=plotGroupedSubjects(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,earlyNumber,lateNumber,exemptLast,legendNames) %Will deprecate, use plotGroupedSubjectsBars instead.

         [figHandle,allData]=plotGroupedSubjectsBars(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,earlyNumber,lateNumber,exemptLast,legendNames,significanceThreshold,plotHandles,colors)

         varargout=plotAvgTimeCourse(adaptDataList,params,conditions,binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder,biofeedback,removeBiasFlag,groupNames,medianFlag,plotHandles,alignEnd,alignIni)

         [figHandle]=scatterPlotLab(adapDataList,labels,conditionIdxs,figHandle,marker,binSize,trajectoryColor,removeBias,addID)

         [figHandle]=Correlations(adapDataList, results,epochx,epochy,param1,groups,colorOrder,type)

        function [fh,ph,allData]=plotGroupedTimeAndBars(adaptDataGroups,labels,conds,binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder,biofeedback,removeBiasFlag,groupNames,medianFlag,plotHandles,numberOfStrides)

            fh=figure;

            M=length(labels);
            clear ph
            for i=1:M
                ph(i,1)=subplot(M,3,[1:2]+3*(i-1));
                ph(i,2)=subplot(M,3,[3]+3*(i-1));
            end

            %Defaults:
            plotHandles=[]; %Not allowed
            if nargin<8 || isempty(colorOrder)
                colorScheme
            colorOrder=color_palette;
            end
            plotIndividualsFlag=indivFlag;
            legendNames=[];
            significanceThreshold=.05;
            removeBiasFlag=0; %Disallowing removeBiasFlag
            significancePlotMatrix=[];
            alignEnd=abs(numberOfStrides(2));
            signifPlotMatrixConds=[];
            exemptFirst=1;
            exemptLast=5;

            %Time courses:
            adaptData=cellfun(@(x) x.adaptData,adaptDataGroups,'UniformOutput',false);
            fh=adaptationData.plotAvgTimeCourse(adaptData,labels,conds,binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder,biofeedback,removeBiasFlag,groupNames,medianFlag,ph(:,1),alignEnd);

            %Add bars:
            [fh,allData]=groupAdaptationData.plotMultipleGroupsBars(adaptDataGroups,labels,removeBiasFlag,plotIndividualsFlag,conds,numberOfStrides,exemptFirst,exemptLast,groupNames,significanceThreshold,ph(:,2),colorOrder,significancePlotMatrix,medianFlag,signifPlotMatrixConds);

            for i=1:M
                subplot(ph(i,2));
                grid on
                aa=axis;
                subplot(ph(i,1));
                grid on
                ab=axis;
                axis([ab(1:2) aa(3:4)])
            end
        end

        function groupData=createGroupAdaptData(adaptDataList)
            %Check that it is a single cell array of chars (subIDs):

            %Load and construct object:
            for i=1:length(adaptDataList)
                try
                    a=load(adaptDataList{i});
                catch ME
                    warning('Could not find filename as provided. Trying alternative spellings.')
                    try
                        a=load([adaptDataList{i} 'Params']);
                    catch
                        try
                            a=load([adaptDataList{i} 'params']);
                        catch
                            warning('Alternative spellings failed too.')
                            throw(ME)
                        end
                    end
                end
                data{i}=a.('adaptData');
                ID{i}=a.('adaptData').subData.ID;
            end
            groupData=groupAdaptationData(ID,data);
        end

        function [veryEarlyPoints,earlyPoints,latePoints,pEarly,pLate,pChange,pSwitch]=getGroupedData(adaptDataList,label,conds,removeBiasFlag,earlyNumber,lateNumber,exemptLast)

            if ~(isa(label,'char') || (isa(label,'cell') && length(label)==1 && (isa(label{1},'char'))))
                error('adaptationData:getGroupedData','Only one parameter can be retrieved at a time.'); %This is NOT true (?). Fix.
            end

            %Create a groupAdaptationData object and use it to get the
            %requested data in matrix form:
            groupData=adaptationData.createGroupAdaptData(adaptDataList);
            [data]=groupData.getGroupedData(label,conds,removeBiasFlag,[3,earlyNumber,-lateNumber],0,exemptLast);
            earlyPoints=data{2};
            veryEarlyPoints=data{1};
            latePoints=data{3};

            %Compute some stats (this may only work properly if length(label)==1)
            if length(label)>1
                pEarly=[];
                pLate=[];
                pChange=[];
                pSwitch=[];
            else
                aux1=squeeze(nanmean(earlyPoints,2)); %Averaging across strides
                aux2=squeeze(nanmean(latePoints,2));
                pSwitch=[];
                for i=1:size(aux1,1) %For all conditions requested
                    for j=1:size(aux1,1)
                        if i~=j
                            [~,pEarly(i,j)] =ttest(aux1(i,:),aux1(j,:)); %Testing early points across all conds
                            [~,pLate(i,j)] =ttest(aux2(i,:),aux2(j,:)); %Testing late points across all conds
                        else
                            pEarly(i,j)=NaN;
                            pLate(i,j)=NaN;
                        end
                    end
                    [~,pChange(i)]=ttest(aux1(i,:),aux2(i,:)); %Testing changes within each condition
                    if i>1
                        [~,pSwitch(i-1)]=ttest(aux2(i-1,:),aux1(i,:)); %Testing changes from end of one condition to start of the next
                    end
                end
            end
        end

%         function figHandle=groupedScatterPlot(adaptDataList,labels,conditionIdxs,binSize,figHandle,trajColors,removeBias)
%
%             if isa(adaptDataList,'cell')
%                 if ~isa(adaptDataList{1},'cell')
%                     adaptDataList={adaptDataList};
%                 end
%             elseif isa(adaptDataList,'char')
%                 adaptDataList={{adaptDataList}};
%             end
%             Ngroups=length(adaptDataList);
%
%             if nargin<7 || isempty(removeBias)
%                 removeBias=0;
%             end
%             if nargin<5 || isempty(figHandle)
%                 figHandle=figure;
%             else
%                 figure(figHandle);
%                 hold on
%             end
%             markerList={'x','o','.','+','*','s','v','^','d'};
%             if nargin<3 || isempty(conditionIdxs)
%                 conditionIdxs=[];
%             end
%             if nargin<4 || isempty(binSize)
%                 binSize=[];
%             end
%             for g=1:Ngroups
%                 for i=1:length(adaptDataList{g})
%                     r=(i-1)/(length(adaptDataList{g})-1);
%                     if nargin<6 || isempty(trajColors)
%                         trajColor=[1,0,0] + r*[-1,0,1];
%                     elseif iscell(trajColors)
%                         trajColor=trajColors{i};
%                     elseif size(trajColors,2)==3
%                         trajColor=trajColors(mod(i,size(trajColors,1))+1,:);
%                     else
%                         warning('Could not interpret trajecColors input')
%                         trajColor='k';
%                     end
%                     this=adaptDataList{g}{i};
%                     fieldList=fields(this);
%                     a=this.(fieldList{1});
%                     if iscell(conditionIdxs) %This gives the possibility to pass condition names instead of the indexes for each subject, which might be different
%                         conditionIdxs1=getConditionIdxsFromName(a,conditionIdxs);
%                     else
%                         conditionIdxs1=conditionIdxs;
%                     end
%                     figHandle=scatterPlotLab(adaptDataList,labels,conditionIdxs,figHandle,markerList{mod(i,length(markerList))+1},binSize,trajColor,removeBias,1);
%                        figHandle=scatterPlotLab(adaptDataList,labels,conditionIdxs,figHandle,markerList,binSize,[],removeBias,1);
%                 end
%             end
%
%         end

        [figHandle,allData]=plotGroupedSubjectsBarsv2(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,significanceThreshold,plotHandles,colors,medianFlag)
    end %static methods

end

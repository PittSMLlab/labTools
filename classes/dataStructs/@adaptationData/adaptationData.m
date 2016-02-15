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
%   See also: experimentData
    
    properties
        metaData %cell array with information related with the experiment (type of protocol, date, experimenter, conditions...)in a experimentMetaData object 
        subData %cell array with information of the subject (DOB, sex, height, weight...)in a subjectData object
        data %cell array of labData type (or its subclasses: rawLabData, processedLabData, strideData), containing data from each trial/ experiment block
    end
    
    properties (Dependent)
        
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
        end
        
        function [newThis,baseValues,typeList]=normalizeBias(this,conditions)
            if nargin<2
                conditions=[];
            end
            [newThis,baseValues,typeList]=removeBiasV3(this,conditions,1);
        end
        
        function newThis=removeBadStrides(this)
            if isa(this.data,'paramData')
                newParamData=this.data;
            else
                inds=find(this.data.bad==0);
                newParamData=parameterSeries(this.data.Data(inds,:),this.data.labels,this.data.hiddenTime(inds),this.data.description);
                newParamData=newParamData.setTrialTypes(this.data.trialTypes);
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
%             switch removeBias
%                 case 1
%                 this=this.removeBias;
%                 case 2
%                 this=this.normalizeBias;
%                 case 0
%                     %nop
%                 otherwise
%                     error('Invalid value of removeBiasFlag')
%             end
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
        
        function [baseValues,baseTypes]=getBias(this,conditions)
            warning('adaptationData:getBias','This function is not yet implemented.')
            baseValues=[];
            baseTypes=[];
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
        function figHandle=plotParamTimeCourse(this,label,runningBinSize,trialMarkerFlag,conditions,medianFlag)
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
            figHandle=adaptationData.plotAvgTimeCourse({this},label(:)',conditions,runningBinSize,trialMarkerFlag,[],[],[],[],[],[],medianFlag);
        end
        
        function figHandle=scatterPlot(this,labels,conditionIdxs,figHandle,marker,binSize,trajectoryColor,removeBias,addID)
           %Plots up to 3 parameters as coordinates in a single cartesian axes system
           markerList={'x','o','.','+','*','s','v','^','d'};
           colorScheme
           if nargin<9 || isempty(addID)
              addID=0; 
           end
           if nargin<8 || isempty(removeBias)
               removeBias=0;
           end
           if nargin<4 || isempty(figHandle)
              figHandle=figure; 
           else
               figure(figHandle)
           end
           if nargin<7 || isempty(trajectoryColor)
               trajectoryColor=[0,0,0]; %Black
           end
           if nargin<5 || isempty(marker)
               marker=markerList{randi(length(markerList),1)};
           end
           if nargin<3 || isempty(conditionIdxs)
               conditionIdxs=1:length(this.metaData.conditionName);
           end
           aux=cell2mat(colorConds');
           set(gca,'ColorOrder',aux(1:length(conditionIdxs),:));
           hold on
           if length(labels)>3
               error('adaptationData:scatterPlot','Cannot plot more than 3 parameters at a time')
           end
           markerFaceColors={'r','b',[1,.8,0],'g','y','w','c','m','k'};
           if length(labels)==3
               last=[];
               for c=1:length(conditionIdxs)
                   if removeBias==1
                       this=this.removeBias;
                   end
                    [data,~,~,origTrials]=getParamInCond(this,labels,conditionIdxs(c));
                    if nargin>5 && ~isempty(binSize) && binSize>1
                        %aux2=conv2(double(~isnan(data)),ones(binSize,1),'same');
                        %data(isnan(data(:)))=0; %Substituting NaNs
                        %data2=conv2(data,ones(binSize,1),'same')./aux2; %Moving avg.
                        %data=data2(1:binSize:end,:);    %Plotting only one point every bin_size, so each point plotted is independent of others
                        for i=1:size(data,2)
                            data(:,i)=smooth(data(:,i),binSize,'rlowess');
                        end
                    end
                    if ~isempty(binSize) && binSize~=0
                        hh(c)=plot3(data(:,1),data(:,2),data(:,3),marker,'LineWidth',1,'Color',aux(mod(c,size(aux,1))+1,:));
                        uistack(hh(c),'bottom')
                    end
                    if ~isempty(last)
                            %annotation('textarrow',[last(1) mean(data(:,1))],[last(2) mean(data(:,2))],'String',this.subData.ID)
                        %h=plot3([last(1) nanmedian(data(:,1))],[last(2) nanmedian(data(:,2))],[last(3) nanmedian(data(:,3))],'Color',trajectoryColor,'LineWidth',2);
                        h=plot3(data(:,1),data(:,2),data(:,3),'Color',trajectoryColor.^(c/length(conditionIdxs)),'LineWidth',1);
                        uistack(h,'bottom')
                        plot3([nanmedian(data(:,1))],[nanmedian(data(:,2))],[nanmedian(data(:,3))],'o','MarkerFaceColor',markerFaceColors{mod(c,length(markerFaceColors))+1},'Color',trajectoryColor)
                    else
                       if addID==1
                            %annotation('textarrow',[last(1) mean(data(:,1))],[last(2) mean(data(:,2))],'String',this.subData.ID)
                            hhh=text([nanmedian(data(:,1))],[nanmedian(data(:,2))],[nanmedian(data(:,3))],this.subData.ID);
                            set(hhh,'LineWidth',1,'FontSize',14);
                       end
                    end
                    last=nanmedian(data,1);
               end
              xlabel(labels{1})
              ylabel(labels{2})
              zlabel(labels{3})
           elseif length(labels)==2
               last=[];
               for c=1:length(conditionIdxs)
                   if removeBias==1
                       this=this.removeBias;
                   end
                    [data,~,~,origTrials]=getParamInCond(this,labels,conditionIdxs(c));
                    if nargin>5 && ~isempty(binSize) && binSize>1
                        data2=conv2(data,ones(binSize,1)/binSize);
                        data=data2(1:binSize:end,:);
                    end
                    cc=aux(mod(c,size(aux,1))+1,:);
                    if nargin>5 && ~isempty(binSize) && binSize==0
                        hh(c)=plot(data(:,1),data(:,2),marker,'LineWidth',1,'Color',cc);
                        uistack(hh(c),'bottom')
                    end
                    if ~isempty(last)
                        %annotation('textarrow',[last(1) mean(data(:,1))],[last(2) mean(data(:,2))],'String',this.subData.ID)
                        h=plot([last(1) nanmedian(data(:,1))],[last(2) nanmedian(data(:,2))],'Color',trajectoryColor,'LineWidth',2);
                        uistack(h,'bottom')
                        plot([nanmedian(data(:,1))],[nanmedian(data(:,2))],'o','Color',trajectoryColor,'MarkerFaceColor',markerFaceColors{mod(c,length(markerFaceColors))+1})
                    end
                    last=nanmedian(data,1);
               end
               xlabel(labels{1})
               ylabel(labels{2})
           end
           if exist('hh','var') && ~isempty(hh)
                legend(hh,this.metaData.conditionName{conditionIdxs})
           end
           hold off     
        end
        
        [inds,names]=getEarlyLateIdxs(this,conds,numberOfStrides,exemptLast,exemptFirst)
        
        [dataPoints]=getEarlyLateData_v2(this,labels,conds,removeBiasFlag,numberOfStrides,exemptLast,exemptFirst)
        
        [figHandle]=plotParamBarsByConditionsv2(this,label,number,exemptLast,exemptFirst,condList,mode);
        
        function dataPoints=getDataFromInds(this,inds,labels)
            %Returns data associated to certain stride indexes (e.g.
            %strides
            %1, 3, 10:15, 21)
            %Inds comes from a call to getEarlyLateIdxs:
            %[inds]=this.getEarlyLateIdxs(conds,numberOfStrides,exemptLast,exemptFirst);
            data=this.data.getDataAsVector(labels);
            nConds=size(inds{1},2);
            for j=1:length(inds)
                %for i=1:nConds
                %    dataPoints{j}(i,:,:)=data(inds{j}(:,i),:);
                %end
                %This line does the same as the for loop commented above:
                dataPoints{j}=reshape(data(inds{j}',:),nConds,size(inds{j},1),length(labels)); 
            end
        end
    end
    
    
    
    methods(Static)

        [figHandle,allData]=plotGroupedSubjectsTimeCourse(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,earlyNumber,lateNumber,exemptLast,legendNames)
        
        [figHandle,allData]=plotGroupedSubjects(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,earlyNumber,lateNumber,exemptLast,legendNames) %Will deprecate, use plotGroupedSubjectsBars instead.
        
        [figHandle,allData]=plotGroupedSubjectsBars(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,earlyNumber,lateNumber,exemptLast,legendNames,significanceThreshold,plotHandles,colors)
        
        varargout=plotAvgTimeCourse(adaptDataList,params,conditions,binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder,biofeedback,removeBiasFlag,groupNames,medianFlag,plotHandles,alignEnd)
        
        function groupData=createGroupAdaptData(adaptDataList)
            %Check that it is a single cell array of chars (subIDs):
            
            %Load and construct object:
            for i=1:length(adaptDataList)
                a=load(adaptDataList{i});
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
          
        function figHandle=groupedScatterPlot(adaptDataList,labels,conditionIdxs,binSize,figHandle,trajColors,removeBias)
            
            if isa(adaptDataList,'cell')
                if ~isa(adaptDataList{1},'cell')
                    adaptDataList={adaptDataList};
                end
            elseif isa(adaptDataList,'char')
                adaptDataList={{adaptDataList}};
            end
            Ngroups=length(adaptDataList);
            
            if nargin<7 || isempty(removeBias)
                removeBias=0;
            end
            if nargin<5 || isempty(figHandle)
                figHandle=figure;
            else
                figure(figHandle);
                hold on
            end
            markerList={'x','o','.','+','*','s','v','^','d'};
            if nargin<3 || isempty(conditionIdxs)
                conditionIdxs=[];
            end
            if nargin<4 || isempty(binSize)
                binSize=[];
            end
            for g=1:Ngroups
                for i=1:length(adaptDataList{g})
                    r=(i-1)/(length(adaptDataList{g})-1);
                    if nargin<6 || isempty(trajColors)
                        trajColor=[1,0,0] + r*[-1,0,1];
                    elseif iscell(trajColors)
                        trajColor=trajColors{i};
                    elseif size(trajColors,2)==3
                        trajColor=trajColors(mod(i,size(trajColors,1))+1,:);
                    else
                        warning('Could not interpret trajecColors input')
                        trajColor='k';
                    end
                    a=load(adaptDataList{g}{i});
                    fieldList=fields(a);
                    this=a.(fieldList{1});
                    if iscell(conditionIdxs) %This gives the possibility to pass condition names instead of the indexes for each subject, which might be different
                        conditionIdxs1=getConditionIdxsFromName(this,conditionIdxs);
                    else
                        conditionIdxs1=conditionIdxs;
                    end
                    figHandle=scatterPlot(this,labels,conditionIdxs1,figHandle,markerList{mod(i,length(markerList))+1},binSize,trajColor,removeBias,1);
                end
            end
            
        end
        
        [figHandle,allData]=plotGroupedSubjectsBarsv2(adaptDataList,label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,significanceThreshold,plotHandles,colors)
    end %static methods
    
end
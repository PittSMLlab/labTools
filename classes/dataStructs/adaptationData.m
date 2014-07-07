classdef adaptationData
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        metaData %experimentMetaData type
        subData %subjectData type
        data %Contains adaptation parameters
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
            
            if nargin>2 && isa(data,'paramData')
                this.data=data;
            else
                ME=MException('adaptationData:Constructor','Data is not a paramData type object.');
                throw(ME);
            end
        end
        
        function newThis=removeBias(this)
            %find baseline conditions
            %NOTE: this assumes that the condition names will contain the
            %string "base" if they are a baseline trial
            conds=this.metaData.conditionName;
            trialsInCond=this.metaData.trialsInCondition;
            ogTrials=[];
            ogBaseTrials=[];
            tmTrials=[];
            tmBaseTrials=[];
            for c=1:length(conds)
                rawTrials=trialsInCond{c};
                trials=find(ismember(cell2mat(trialsInCond),rawTrials));
                if all(strcmpi(this.data.trialTypes(trials),'OG'))                              
                    ogTrials=[ogTrials trials];
                    if ~isempty(strfind(lower(conds{c}),'base'))
                        ogBaseTrials=[ogBaseTrials trials];
                    end
                elseif all(strcmpi(this.data.trialTypes(trials),'TM'))                     
                    tmTrials=[tmTrials trials];
                    if ~isempty(strfind(lower(conds{c}),'base'))                                         
                        tmBaseTrials=[tmBaseTrials trials];
                    end
                end
            end
            if ~isempty(tmBaseTrials)
                base=nanmedian(this.data.Data(cell2mat(this.data.indsInTrial(tmBaseTrials)),:));
                inds=cell2mat(this.data.indsInTrial(tmTrials));
                newData(inds,:)=this.data.Data(inds,:)-repmat(base,length(inds),1);
            else
                warning('No treadmill baseline trials detected. Bias not removed')
            end
            if ~isempty(ogBaseTrials)
                ogBase=nanmedian(this.data.Data(cell2mat(this.data.indsInTrial(ogBaseTrials)),:)); %should it be nanmean?
                ogInds=cell2mat(this.data.indsInTrial(ogTrials));
                newData(ogInds,:)=this.data.Data(ogInds,:)-repmat(ogBase,length(ogInds),1);
            else
                warning('No overground baseline trials detected. Bias not removed')
            end                    
            %this code can probably be cleaned up by taking advantage of
            %other functions in this class such as getParamInCond...
            newParamData=paramData(newData,this.data.labels,this.data.indsInTrial);
            newThis=adaptationData(this.metaData,this.subData,newParamData);
        end
        
        %Other I/O functions:
        function [data,auxLabel]=getParamInTrial(this,label,trial)
            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end
            % validate label(s)
            [boolFlag,labelIdx]=this.data.isaLabel(auxLabel);
            for i=1:length(boolFlag)
                if boolFlag(i)==0
                    warning(['Label ' auxLabel{i} ' is not a parameter in this data set.'])
                end
            end
            % validate condition(s)
            trialNum = [];
            for t=trial
                if isempty(this.data.indsInTrial(t))
                    warning(['Condition number ' num2str(t) ' is not condition in this experiment.'])
                else
                    trialNum(end+1)=t;
                end
            end
            
            %get data
            inds=cell2mat(this.data.indsInTrial(trialNum));
            data=this.data.Data(inds,labelIdx(boolFlag==1));
            auxLabel=this.data.labels(labelIdx(boolFlag==1));
        end
        
        function [data,auxLabel]=getParamInCond(this,label,condition)
            if isa(label,'char')
                auxLabel={label};
            else
                auxLabel=label;
            end
            % validate label(s)
            [boolFlag,labelIdx]=this.data.isaLabel(auxLabel);
            for i=1:length(boolFlag)
                if boolFlag(i)==0
                    warning(['Label ' auxLabel{i} ' is not a parameter in this data set.'])
                end
            end
            % validate condition(s)
            condNum = [];
            if isa(condition,'char')
                condNum=find(strcmpi(this.metaData.conditionName,condition));
            elseif isa(condition,'cell')
                for i=1:length(condition)
                    boolFlags=strcmpi(this.metaData.conditionName,condition{i});
                    if any(boolFlags)
                        condNum(end+1)=find(boolFlags);
                    else
                        warning(['Label ' condition{i} ' is not a condition name in this experiment.'])
                    end
                end
            else %a numerical vector
                for i=1:length(condition)
                    if isempty(this.metaData.trialsInCondition(condition(i)))
                        warning(['Condition number ' num2str(condition(i)) ' is not condition in this experiment.'])
                    else
                        condNum(end+1)=condition(i);
                    end
                end
            end
            
            %get data
            trials=cell2mat(this.metaData.trialsInCondition(condNum));
            auxTrials=find(ismember(cell2mat(this.metaData.trialsInCondition),trials));
            inds=cell2mat(this.data.indsInTrial(auxTrials));
            
            data=this.data.Data(inds,labelIdx(boolFlag==1));
            auxLabel=this.data.labels(labelIdx(boolFlag==1));
        end           
        
        function plotParamTimeCourse(this,label)   
            
            figureFullScreen
            
            figsz=[0 0 1 1];
            %in pixels:
            vertpad = 30/scrsz(4); %padding on the top and bottom of figure
            horpad = 60/scrsz(3);  %padding on the left and right of figure
            
            % Set colors
            poster_colors;
            % Set colors order
            ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow];
            set(gcf,'DefaultAxesColorOrder',ColorOrder);
            
            %find subplot size with width to hieght ratio of 4:1
            [rows,cols]=subplotSize(length(label),1,4);
            
            conds=unique(this.metaData.getCondLstPerTrial);
            conds(isnan(conds))=[];
            nConds=length(conds);
            nPoints=size(this.data.Data,1);            
            rowind=1;
            colind=0;            
            for l=label
                dataPoints=NaN(nPoints,nConds);
                for i=1:nConds
                    rawTrials=this.metaData.trialsInCondition{conds(i)};
                    if ~isempty(rawTrials)
                        trials=find(ismember(cell2mat(this.metaData.trialsInCondition),rawTrials));
                        for t=trials
                            inds=this.data.indsInTrial{t};
                            dataPoints(inds,i)=this.getParamInTrial(l,t);
                        end
                    end
                end
                %find graph location
                bottom=figsz(4)-(rowind*figsz(4)/rows)+vertpad;
                left=colind*(figsz(3))/cols+horpad;
                rowind=rowind+1;
                if rowind>rows
                    colind=colind+1;
                    rowind=1;
                end
                subplot('Position',[left bottom (figsz(3)/cols)-2*horpad (figsz(4)/rows)-2*vertpad]);                
                plot(dataPoints,'.','MarkerSize',15)  
                axis tight
                title([l{1},' (',this.subData.ID ')'])                
            end
     
            condDes = this.metaData.conditionName;
            legend(condDes(conds)); %this is for the case when a condition number was skipped
        end
        
        function plotParamTrialTimeCourse(this,label)   
            
            figureFullScreen
            
            figsz=[0 0 1 1];
            %in pixels:
            vertpad = 30/scrsz(4); %padding on the top and bottom of figure
            horpad = 60/scrsz(3);  %padding on the left and right of figure
            
            % Set colors
            poster_colors;
            % Set colors order
            ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow];
            set(gcf,'DefaultAxesColorOrder',ColorOrder);
            
            %find subplot size, using width to height ratio of 1:4
            [rows,cols]=subplotSize(length(label),1,4);
            
            nTrials=this.metaData.Ntrials;
            nPoints=size(this.data.Data,1);
            
            rowind=1;
            colind=0;            
            for l=label
                dataPoints=NaN(nPoints,nTrials);
                for i=1:nTrials                    
                    inds=this.data.indsInTrial{i};
                    dataPoints(inds,i)=this.getParamInTrial(l,i);                    
                end
                %find graph location
                bottom=figsz(4)-(rowind*figsz(4)/rows)+vertpad;
                left=colind*(figsz(3))/cols+horpad;
                rowind=rowind+1;
                if rowind>rows
                    colind=colind+1;
                    rowind=1;
                end
                subplot('Position',[left bottom (figsz(3)/cols)-2*horpad (figsz(4)/rows)-2*vertpad]);               
                plot(dataPoints,'.','MarkerSize',15)  
                axis tight
                title([l{1},' (',this.subData.ID ')'])                 
            end
        
            trialNums = cell2mat(this.metaData.trialsInCondition);
            legendEntry={};
            for i=1:length(trialNums)
                legendEntry{end+1}=num2str(trialNums(i));
            end
            legend(legendEntry); %this is for the case when a condition number was skipped
        end
        
        function plotParamByConditions(this,label)
            figureFullScreen
            
            figsz=[0 0 1 1];
            %in pixels:
            vertpad = 30/scrsz(4); %padding on the top and bottom of figure
            horpad = 60/scrsz(3);  %padding on the left and right of figure
            
            % Set colors
            poster_colors;
            % Set colors order
            ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow];
            set(gcf,'DefaultAxesColorOrder',ColorOrder);
            
                        %find subplot size with width to hieght ratio of 4:1
            [rows,cols]=subplotSize(length(label),1,4);

            conds=unique(this.metaData.getCondLstPerTrial);
            conds=conds(~isnan(conds));
            nConds=length(conds);
            nPoints=size(this.data.Data,1);            
            rowind=1;
            colind=0;            
            for l=label
                earlyPoints=[];
                veryEarlyPoints=[];
                latePoints=[];
                for i=1:nConds
                    rawTrials=this.metaData.trialsInCondition{conds(i)};
                    trials=find(ismember(cell2mat(this.metaData.trialsInCondition),rawTrials));
                    aux=this.getParamInTrial(l,trials(1));
                    veryEarlyPoints(i,:)=aux(1:3);
                    earlyPoints(i,:)=aux(1:5);
                    aux=this.getParamInTrial(l,trials(end));
                    try
                        N2=min([20,length(aux)-5]);
                        latePoints(i,:)=aux(end-N2-4:end-5);
                    catch
                        latePoints(i,:)=NaN;
                    end
                end
                %find graph location
                bottom=figsz(4)-(rowind*figsz(4)/rows)+vertpad;
                left=colind*(figsz(3))/cols+horpad;
                rowind=rowind+1;
                if rowind>rows
                    colind=colind+1;
                    rowind=1;
                end
                subplot('Position',[left bottom (figsz(3)/cols)-2*horpad (figsz(4)/rows)-2*vertpad]);          
                hold on
                
                bar(1:3:3*nConds,nanmean(earlyPoints,2),.3,'FaceColor',[.6,.6,.6])
                bar(2:3:3*nConds,nanmean(latePoints,2),.3,'FaceColor',[0,.3,.6])
                errorbar(1:3:3*nConds,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2)
                errorbar(2:3:3*nConds,nanmean(latePoints,2), nanstd(latePoints,[],2)/sqrt(size(latePoints,2)),'.','LineWidth',2)
                xTickPos=[1:3:3*nConds] +.5;
                set(gca,'XTick',xTickPos,'XTickLabel',this.metaData.conditionName(conds))
                axis tight
                title([l{1},' (',this.subData.ID ')'])     
                hold off
            end
     
            condDes = this.metaData.conditionName;
            legend('Early (first 5 strides)','Late (last 20 (-5) strides)'); %this is for the case when a condition number was skipped
        end
    end
    
    methods(Static)
        function plotGroupedSubjects(adaptDataList,label,removeBiasFlag)
            figureFullScreen
            
            figsz=[0 0 1 1];
            %in pixels:
            vertpad = 30/scrsz(4); %padding on the top and bottom of figure
            horpad = 60/scrsz(3);  %padding on the left and right of figure
            
            % Set colors
            poster_colors;
            % Set colors order
            ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow];
            set(gcf,'DefaultAxesColorOrder',ColorOrder);
            
                        %find subplot size with width to hieght ratio of 4:1
            [rows,cols]=subplotSize(length(label),1,4);
            
            load(adaptDataList{1});
            this=adaptData;
            conds=unique(this.metaData.getCondLstPerTrial);
            conds=conds(~isnan(conds));
            nConds=length(conds);          
            rowind=1;
            colind=0;            
            for l=label
                earlyPoints=[];
                veryEarlyPoints=[];
                latePoints=[];
                earlySte=[];
                veryEarlySte=[];
                lateSte=[];
                for subject=1:length(adaptDataList) %Getting data for each subject in the list
                    load(adaptDataList{subject});
                    if nargin<3 || isempty(removeBiasFlag) || removeBiasFlag==1
                        this=adaptData.removeBias; %Default behaviour
                    else
                        this=adaptData;
                    end
                for i=1:nConds
                    rawTrials=this.metaData.trialsInCondition{conds(i)};
                    trials=find(ismember(cell2mat(this.metaData.trialsInCondition),rawTrials));
                    if ~isempty(trials)
                        aux=this.getParamInTrial(l,trials(1));
                        veryEarlyPoints(i,subject)=mean(aux(1:3));
                        earlyPoints(i,subject)=mean(aux(1:5));
                        aux=this.getParamInTrial(l,trials(end));
                        N2=min([20,length(aux)-5]);
                        latePoints(i,subject)=mean(aux(end-N2-4:end-5));
                    else
                        veryEarlyPoints(i,subject)=NaN;
                        earlyPoints(i,subject)=NaN;
                        latePoints(i,subject)=NaN;
                    end
                end
                end
                %find graph location
                bottom=figsz(4)-(rowind*figsz(4)/rows)+vertpad;
                left=colind*(figsz(3))/cols+horpad;
                rowind=rowind+1;
                if rowind>rows
                    colind=colind+1;
                    rowind=1;
                end
                subplot('Position',[left bottom (figsz(3)/cols)-2*horpad (figsz(4)/rows)-2*vertpad]);          
                hold on

                bar(1:3:3*nConds,nanmean(earlyPoints,2),.3,'FaceColor',[.6,.6,.6]) 
                bar(2:3:3*nConds,nanmean(latePoints,2),.3,'FaceColor',[0,.3,.6])
                plot(1:3:3*nConds,earlyPoints,'x','LineWidth',2)
                plot(2:3:3*nConds,latePoints,'x','LineWidth',2)
                errorbar(1:3:3*nConds,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2)
                errorbar(2:3:3*nConds,nanmean(latePoints,2), nanstd(latePoints,[],2)/sqrt(size(latePoints,2)),'.','LineWidth',2)
                xTickPos=[1:3:3*nConds] +.5;
                set(gca,'XTick',xTickPos,'XTickLabel',this.metaData.conditionName(conds))
                axis tight
                title([l{1}])     
                hold off
            end
     
            condDes = this.metaData.conditionName;
            legend([{'Early (first 5 strides)','Late (last 20 (-5) strides)'}, adaptDataList ]); 
        end
    end

end

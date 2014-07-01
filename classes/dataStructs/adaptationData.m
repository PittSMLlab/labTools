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
            %string "base" and that the over ground trials contain the
            %string "over","ground", or "OG"
            conds=this.metaData.conditionName;
            trialsInCond=this.metaData.trialsInCondition;
            ogTrials=[];
            ogBaseTrials=[];
            trials=[];
            baseTrials=[];
            for c=1:length(conds)
                if ~isempty(strfind(lower(conds{c}),'over')) || ~isempty(strfind(lower(conds{c}),'ground')) || ~isempty(strfind(lower(conds{c}),'og'))
                    rawTrials=trialsInCond{c};                    
                    ogTrials=[ogTrials find(ismember(cell2mat(trialsInCond),rawTrials))];
                    if ~isempty(strfind(lower(conds{c}),'base'))
                        rawTrials=trialsInCond{c};     
                        ogBaseTrials=[ogBaseTrials find(ismember(cell2mat(trialsInCond),rawTrials))];
                    end
                else
                    rawTrials=trialsInCond{c};                    
                    trials=[trials find(ismember(cell2mat(trialsInCond),rawTrials))];
                    if ~isempty(strfind(lower(conds{c}),'base'))
                        rawTrials=trialsInCond{c};                    
                        baseTrials=[baseTrials find(ismember(cell2mat(trialsInCond),rawTrials))];
                    end
                end
            end
            ogBase=nanmedian(this.data.Data(cell2mat(this.data.indsInTrial(ogBaseTrials)),:)); %should it be nanmena?
            base=nanmedian(this.data.Data(cell2mat(this.data.indsInTrial(baseTrials)),:));
            ogInds=cell2mat(this.data.indsInTrial(ogTrials));
            inds=cell2mat(this.data.indsInTrial(trials));
            newData(ogInds,:)=this.data.Data(ogInds,:)-repmat(ogBase,length(ogInds),1);
            newData(inds,:)=this.data.Data(inds,:)-repmat(base,length(inds),1);
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
            horpad = 20/scrsz(3);  %padding on the left and right of figure
            
            % Set colors
            poster_colors;
            % Set colors order
            ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow];
            set(gcf,'DefaultAxesColorOrder',ColorOrder);
            
            %find subplot size with width to hieght ratio of 4:1
            [rows,cols]=subplotSize(length(label),1,4);
            
            conds=unique(this.metaData.getCondLstPerTrial);
            nConds=length(conds);
            nPoints=size(this.data.Data,1);            
            rowind=1;
            colind=0;            
            for l=label
                dataPoints=NaN(nPoints,nConds);
                for i=1:nConds
                    rawTrials=this.metaData.trialsInCondition{conds(i)};
                    trials=find(ismember(cell2mat(this.metaData.trialsInCondition),rawTrials));
                    for t=trials
                        inds=this.data.indsInTrial{t};
                        dataPoints(inds,i)=this.getParamInTrial(l,t);
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
                title(l)                
            end
     
            condDes = this.metaData.conditionName;
            legend(condDes(~cellfun('isempty',condDes))); %this is for the case when a condition number was skipped
        end
        
        function plotParamTrialTimeCourse(this,label)   
            
            figureFullScreen
            
            figsz=[0 0 1 1];
            %in pixels:
            vertpad = 30/scrsz(4); %padding on the top and bottom of figure
            horpad = 20/scrsz(3);  %padding on the left and right of figure
            
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
                title(l)                
            end
        
            trialNums = cell2mat(this.metaData.trialsInCondition);
            legendEntry={};
            for i=1:length(trialNums)
                legendEntry{end+1}=num2str(trialNums(i));
            end
            legend(legendEntry); %this is for the case when a condition number was skipped
        end
    end
end


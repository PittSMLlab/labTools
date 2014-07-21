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
        
        function newThis=removeBias(this,conditions)
            % removeBias('condition') or removeBias({'Condition1','Condition2',...}) 
            % removes the median value of every parameter from each trial of the
            % same type as the condition entered. If no condition is
            % specified, then the condition name that contains both the
            % type string and the string 'base' is used as the baseline
            % condition.
                     
            trialsInCond=this.metaData.trialsInCondition;
            conds=this.metaData.conditionName;
            trialTypes=this.data.trialTypes;
            types=unique(trialTypes);
            labels=this.data.labels;
            trialKey=[cell2mat(trialsInCond)' find(~cellfun(@isempty,this.data.trialTypes))'];   %In the future we will get rid of this. This means that we will have a dummy varaible were: trialKey(i) = i
            
            if nargin<2 || isempty(conditions)
                %if no conditions were entered, this just searches all
                %condition names for the string 'base'                
                for t=1:length(types)
                    allTrials=[];
                    baseTrials=[];
                    for c=1:length(conds)
                        trials=trialKey(ismember(trialKey(:,1),trialsInCond{c}),2)';
                        if all(strcmpi(trialTypes(trials),types{t}))
                            allTrials=[allTrials trials];
                            if ~isempty(strfind(lower(conds{c}),'base')) && ~isempty(strfind(lower(conds{c}),lower(types{t})))
                                baseTrials=[baseTrials trials];
                            end
                        end
                    end
                    if ~isempty(baseTrials)
                        base=nanmedian(this.getParamInTrial(labels,baseTrials));
                        inds=cell2mat(this.data.indsInTrial(allTrials));
                        newData(inds,:)=this.data.Data(inds,:)-repmat(base,length(inds),1);
                    else
                        warning(['No ' types{t} ' baseline trials detected. Bias not removed from ' types{t} ' trials.'])
                        inds=cell2mat(this.data.indsInTrial(allTrials));
                        newData(inds,:)=this.data.Data(inds,:);
                    end
                end
            else
                %convert any condition input into correct format
                if isa(conditions,'char')
                    conditions={conditions};
                elseif isa(conditions,'double')
                    conditions=conds(conditions);
                end
                
                % validate condition(s)
                [boolFlag,labelIdx]=this.isaCondition(conditions);
                for i=1:length(boolFlag)
                    if boolFlag(i)==0
                        warning([conditions{i} ' is not a condition in this data set.'])
                    end
                end             
                
                for t=1:length(types)
                    allTrials=[];
                    baseTrials=[];
                    cInput=conditions(boolFlag==1);
                    for c=1:length(conds)
                        trials=trialKey(ismember(trialKey(:,1),trialsInCond{c}),2)';
                        if all(strcmpi(trialTypes(trials),types{t}))
                            allTrials=[allTrials trials];
                            if any(ismember(cInput,conds{c}))
                                baseTrials=[baseTrials trials];
                            end
                        end
                    end
                    if ~isempty(baseTrials)
                        base=nanmedian(this.getParamInTrial(labels,baseTrials));
                        inds=cell2mat(this.data.indsInTrial(allTrials));
                        newData(inds,:)=this.data.Data(inds,:)-repmat(base,length(inds),1);
                    else
                        warning(['No ' types{t} ' baseline trials detected. Bias not removed from ' types{t} ' trials.'])
                        inds=cell2mat(this.data.indsInTrial(allTrials));
                        newData(inds,:)=this.data.Data(inds,:);
                    end
                end
                
            end
                        
            newParamData=paramData(newData,labels,this.data.indsInTrial,this.data.trialTypes);
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
                        warning([condition{i} ' is not a condition name in this experiment.'])
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
            trialKey=[cell2mat(this.metaData.trialsInCondition)' find(~cellfun(@isempty,this.data.trialTypes))'];
            trials=trialKey(ismember(trialKey(:,1),cell2mat(this.metaData.trialsInCondition(condNum))),2);                    
            inds=cell2mat(this.data.indsInTrial(trials));
            
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
            
            conds=find(~cellfun(@isempty,this.metaData.conditionName));
            nConds=length(conds);
            nPoints=size(this.data.Data,1);
            trialKey=[cell2mat(this.metaData.trialsInCondition)' find(~cellfun(@isempty,this.data.trialTypes))'];
            rowind=1;
            colind=0;
            for l=label
                dataPoints=NaN(nPoints,nConds);
                for i=1:nConds
                    trials=trialKey(ismember(trialKey(:,1),this.metaData.trialsInCondition{conds(i)}),2);     
                    if ~isempty(trials)                        
                        for t=trials'
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
            
            nTrials=length(cell2mat(this.metaData.trialsInCondition));
            trials=find(~cellfun(@isempty,this.data.indsInTrial));
            nPoints=size(this.data.Data,1);
            
            rowind=1;
            colind=0;
            for l=label
                dataPoints=NaN(nPoints,nTrials);
                for i=1:nTrials                                       
                    inds=this.data.indsInTrial{trials(i)};
                    dataPoints(inds,i)=this.getParamInTrial(l,trials(i));                    
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
            
            conds=find(~cellfun(@isempty,this.metaData.conditionName));
            nConds=length(conds);
            trialKey=[cell2mat(this.metaData.trialsInCondition)' find(~cellfun(@isempty,this.data.trialTypes))'];
            nPoints=size(this.data.Data,1);
            rowind=1;
            colind=0;
            for l=label
                earlyPoints=[];
                veryEarlyPoints=[];
                latePoints=[];
                for i=1:nConds
                    trials=trialKey(ismember(trialKey(:,1),this.metaData.trialsInCondition{conds(i)}),2);                    
                    aux=this.getParamInCond(l,conds(i));
                    try %Try to get the first strides, if there are enough
                        veryEarlyPoints(i,:)=aux(1:3);
                        earlyPoints(i,:)=aux(1:5);
                    catch %In case there aren't enough strides, assign NaNs to all
                        veryEarlyPoints(i,:)=NaN;
                        earlyPoints(i,:)=NaN;
                    end
                    
                    %Last 20 steps, excepting the very last 5
                    idx=length(trials);
                    try
                        N2=20;
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
                
                bar([1:3:3*nConds]-.25,nanmean(veryEarlyPoints,2),.15,'FaceColor',[.8,.8,.8])
                bar([1:3:3*nConds]+.25,nanmean(earlyPoints,2),.15,'FaceColor',[.6,.6,.6])
                bar(2:3:3*nConds,nanmean(latePoints,2),.3,'FaceColor',[0,.3,.6])
                errorbar([1:3:3*nConds]-.25,nanmean(veryEarlyPoints,2), nanstd(veryEarlyPoints,[],2)/sqrt(size(veryEarlyPoints,2)),'.','LineWidth',2)
                errorbar([1:3:3*nConds]+.25,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2)
                errorbar(2:3:3*nConds,nanmean(latePoints,2), nanstd(latePoints,[],2)/sqrt(size(latePoints,2)),'.','LineWidth',2)
                %plot([1:3:3*nConds]-.25,veryEarlyPoints,'x','LineWidth',2,'Color',[0,.8,.3])
                %plot([1:3:3*nConds]+.25,earlyPoints,'x','LineWidth',2,'Color',[0,.8,.3])
                %plot(2:3:3*nConds,latePoints,'x','LineWidth',2,'Color',[0,.6,.2])
                xTickPos=[1:3:3*nConds] +.5;
                set(gca,'XTick',xTickPos,'XTickLabel',this.metaData.conditionName(conds))
                axis tight
                title([l{1},' (',this.subData.ID ')'])
                hold off
            end
            
            condDes = this.metaData.conditionName;
            legend('Very early (first 3 strides)','Early (first 5 strides)','Late (last 20 (-5) strides)'); %this is for the case when a condition number was skipped
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
        end
    end
    
    
    
    methods(Static)
        function plotGroupedSubjects(adaptDataList,label,removeBiasFlag)
            
            %First: see if adaptDataList is a single subject (char), a cell
            %array of subject names (one group of subjects), or a cell array of cell arrays of
            %subjects names (several groups of subjects), and put all the
            %cases into the same format
            if isa(adaptDataList,'cell')
                if isa(adaptDataList{1},'cell')
                    auxList=adaptDataList;
                else
                    auxList{1}=adaptDataList;
                end
            elseif isa(adaptDataList,'char')
                auxList={adaptDataList};
            end
            Ngroups=length(auxList);
            
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
            
            load(auxList{1}{1});
            this=adaptData;
            conds=find(~cellfun(@isempty,this.metaData.conditionName));
            nConds=length(conds);
            rowind=1;
            colind=0;
            for l=label
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
                
                for group=1:Ngroups
                    earlyPoints=[];
                    veryEarlyPoints=[];
                    latePoints=[];
                    for subject=1:length(auxList{group}) %Getting data for each subject in the list
                        load(auxList{group}{subject});
                        if nargin<3 || isempty(removeBiasFlag) || removeBiasFlag==1
                            this=adaptData.removeBias; %Default behaviour
                        else
                            this=adaptData;
                        end
                            trialKey=[cell2mat(this.metaData.trialsInCondition)' find(~cellfun(@isempty,this.data.trialTypes))'];
                        for i=1:nConds                            
                            trials=trialKey(ismember(trialKey(:,1),this.metaData.trialsInCondition{conds(i)}),2);
                            if ~isempty(trials)
                                aux=this.getParamInCond(l,conds(i));
                                try %Try to get the first strides, if there are enough
                                    veryEarlyPoints(i,subject)=mean(aux(1:3));
                                    earlyPoints(i,subject)=mean(aux(1:5));
                                catch %In case there aren't enough strides, assign NaNs to all
                                    veryEarlyPoints(i,subject)=NaN;
                                    earlyPoints(i,subject)=NaN;
                                end
                                
                                %Last 20 steps, excepting the very last 5
                                try
                                    N2=20;
                                    latePoints(i,subject)=mean(aux(end-N2-4:end-5));
                                catch
                                    latePoints(i,subject)=NaN;
                                end
                            else
                                veryEarlyPoints(i,subject)=NaN;
                                earlyPoints(i,subject)=NaN;
                                latePoints(i,subject)=NaN;
                            end
                        end
                    end
                    
                    
                    if Ngroups==1 %Only plotting first 3 strides AND first 5 strides if there is only one group
                        bar([1:3:3*nConds]-.25+(group-1)/Ngroups,nanmean(veryEarlyPoints,2),.15/Ngroups,'FaceColor',[.85,.85,.85].^group)
                        bar([1:3:3*nConds]+.25+(group-1)/Ngroups,nanmean(earlyPoints,2),.15/Ngroups,'FaceColor',[.7,.7,.7].^group)
                    else
                        h(2*(group-1)+1)=bar([1:3:3*nConds]+(group-1)/Ngroups,nanmean(earlyPoints,2),.3/Ngroups,'FaceColor',[.6,.6,.6].^group);
                    end
                    
                    h(2*group)=bar([2:3:3*nConds]+(group-1)/Ngroups,nanmean(latePoints,2),.3/Ngroups,'FaceColor',[0,.4,.7].^group);
                    if Ngroups==1 %Only plotting individual subject performance if there is only one group
                        plot([1:3:3*nConds]-.25+(group-1)/Ngroups,veryEarlyPoints,'x','LineWidth',2)
                        plot([1:3:3*nConds]+.25+(group-1)/Ngroups,earlyPoints,'x','LineWidth',2)
                        plot([2:3:3*nConds]+(group-1)/Ngroups,latePoints,'x','LineWidth',2)
                    end
                    if Ngroups==1 %Only plotting first 3 strides AND first 5 strides if there is only one group
                        errorbar([1:3:3*nConds]-.25+(group-1)/Ngroups,nanmean(veryEarlyPoints,2), nanstd(veryEarlyPoints,[],2)/sqrt(size(veryEarlyPoints,2)),'.','LineWidth',2)
                        errorbar([1:3:3*nConds]+.25+(group-1)/Ngroups,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2)
                    else
                        errorbar([1:3:3*nConds]+(group-1)/Ngroups,nanmean(earlyPoints,2), nanstd(earlyPoints,[],2)/sqrt(size(earlyPoints,2)),'.','LineWidth',2)
                    end
                    
                    errorbar([2:3:3*nConds]+(group-1)/Ngroups,nanmean(latePoints,2), nanstd(latePoints,[],2)/sqrt(size(latePoints,2)),'.','LineWidth',2)
                end
                xTickPos=[1:3:3*nConds] +.5;
                set(gca,'XTick',xTickPos,'XTickLabel',this.metaData.conditionName(conds))
                axis tight
                title([l{1}])
                hold off
            end
            
            
            condDes = this.metaData.conditionName;
            if Ngroups==1
                legend([{'Very early (first 3 strides)','Early (first 5 strides)','Late (last 20 (-5) strides)'}, auxList{1} ]);
            else
                legStr={};
                for group=1:Ngroups
                    legStr=[legStr, {['Early (first 5), Group ' num2str(group)],['Late (last 20 (-5)), Group ' num2str(group)]}];
                end
                legend(h,legStr)
            end
        end
    end
    
end

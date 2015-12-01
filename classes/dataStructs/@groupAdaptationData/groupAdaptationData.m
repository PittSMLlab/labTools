classdef groupAdaptationData
    %groupAdaptaitonData  contains the adaptation data objects for a group
    %of subjects
    %
    %groupAdaptaitonData properties:
    %   ID - cell array of strings listing subject ID's in group
    %   adaptData - cell array of adaptationData objects
    %
    %groupAdaptaitonData Methods:
    %
    %See also: experimentMetaData, subjectData, adaptationData
    
    properties
        ID %cell array of strings listing subject ID's in group
        adaptData % cell array of adaptationData objects
    end
    
    properties (Dependent)
        
    end
    
    methods
        %% Constructor
        function this=groupAdaptationData(ID,data)
            if nargin>1 && length(ID)==length(data)
                boolFlag=false(1,length(data));
                for i=1:length(data)
                    boolFlag(i)=isa(data{i},'adaptationData');
                end
                if all(boolFlag)
                    this.ID=ID;
                    this.adaptData=data;
                end
            end
        end
        
        %% Other Functions
        
        function conditions = getCommonConditions(this,subs)
            if nargin<2 || isempty(subs)
                subs=1:length(this.ID);
            else
                if isa(subs,'cell')
                    subs=find(ismember(this.ID,subs));
                end
            end
            conditions=this.adaptData{subs(1)}.metaData.conditionName;
            conditions=conditions(~cellfun('isempty',conditions));
            for s=2:length(subs)
                conds=this.adaptData{subs(s)}.metaData.conditionName;
                conds=conds(~cellfun('isempty',conds));
                %check if current subject had conditions other than the rest
                for c=1:length(conds)                    
                    if ~ismember(lower(conds(c)),lower(conditions))
                        %Subs.(abrevGroup).conditions{end+1}=conditions{c};
                        disp(['Warning: ' this.ID{subs(s)} ' performed ' conds{c} ', but it was not perfomred by all subjects.'])
                    end                    
                end
                %check if current subject didn't have a condition that the rest had
                for c=1:length(conditions)
                    if ~ismember(lower(conditions(c)),lower(conds)) && ~isempty(conditions{c})
                        disp(['Warning: ' this.ID{subs(s)} ' did not perform ' conditions{c} ' but ' strjoin(this.ID(subs(1:s-1)),', ') ' did.'])
                        conditions{c}='';
                    end
                end
                %refresh conditions by removing empty cells (if you remove
                %them above, the for loop doesn't work any more)
                conditions=conditions(~cellfun('isempty',conditions));
            end
        end
        
        function [parameters,descriptions] = getCommonParameters(this,subs)
            if nargin<2 || isempty(subs)
                subs=1:length(this.ID);
            else
                if isa(subs,'cell')
                    subs=find(ismember(this.ID,subs));
                end
            end
            [parameters,descriptions]=this.adaptData{1}.getParameterList;
            for s=2:length(subs)
                params=this.adaptData{subs(s)}.getParameterList;
                %check if current subject had parameters other than the rest
                for p=1:length(params)                    
                    if ~ismember(params(p),parameters)
                        disp(['Warning: ' this.ID{subs(s)} ' has ' params{p} ', but it was not computed for all subjects.'])
                    end                    
                end
                %check if current subject didn't have a parameter that the rest had
                for p=1:length(parameters)
                    if ~ismember(parameters(p),params)
                        disp(['Warning: '  parameters{p} 'was not computed for' this.ID{subs(s)} ', but was for ' strjoin(this.ID(1:subs(1:s-1)),', ') '.'])
                        parameters{p}='';                        
                    end
                end
                %refresh parameters by removing empty cells (if you remove
                %them above, the for loop doesn't work any more)
                inds=find(~cellfun('isempty',parameters));
                parameters=parameters(inds);
                descriptions=descriptions(inds);
            end
        end
        
        %Modifiers
        function newThis=cat(this,other)
            newThis=groupAdaptationData([this.ID other.ID],[this.adaptData other.adaptData]);            
        end
        
        function newThis=removeBadStrides(this)
            newThis=this;
           for i=1:length(this.ID)
              newThis.adaptData{i}=this.adaptData{i}.removeBadStrides;
           end
        end
        
        function newThis=markBadWhenMissingAny(this,labels)
            newThis=this;
           for i=1:length(this.ID)
              newThis.adaptData{i}=this.adaptData{i}.markBadWhenMissingAny(labels);
           end
        end
        
        function newThis=markBadWhenMissingAll(this,labels)
            newThis=this;
           for i=1:length(this.ID)
              newThis.adaptData{i}=this.adaptData{i}.markBadWhenMissingAll(labels);
           end
        end
        
        function newThis=removeBias(this)
            newThis=this;
            for i=1:length(this.ID)
                newThis.adaptData{i}=this.adaptData{i}.removeBias;
            end
              
        end
        function newThis=normalizeBias(this)
            newThis=this;
            for i=1:length(this.ID)
                newThis.adaptData{i}=this.adaptData{i}.normalizeBias;
            end
              
        end
        
        %I/O
        function data=getAdaptData(this,subID)
           subInd=find(ismember(subID,this.ID));
           if subInd ~= 0
               data = this.adaptData{subInd};
           else
               data =[];
           end
        end
        
        function [inds,names]=getGroupedInds(this,conds,numberOfStrides,exemptFirst,exemptLast)
            for subject=1:length(this.adaptData) %Getting data for each subject in the list
                [inds(:,subject),names]=this.adaptData{subject}.getEarlyLateIdxs(conds,numberOfStrides,exemptLast,exemptFirst);
            end
        end
        
        function [data]=getGroupedData(this,label,conds,removeBiasFlag,numberOfStrides,exemptFirst,exemptLast)
            if removeBiasFlag
                this=this.removeBias;
            end
            [inds,names]=getGroupedInds(this,conds,numberOfStrides,exemptFirst,exemptLast);  
            [data]=getGroupedDataFromInds(this,inds,label);
        end
        
        function [data]=getGroupedDataFromInds(this,inds,label)
            data=cell(size(inds,1));
            nConds=size(inds{1,1},2);
            nLabs=length(label);
            nSubs=length(this.ID);
            %Initialize:
            for i=1:length(data)
               data{i}=zeros(nConds,size(inds{i,1},1),nLabs,nSubs);  %Conds x strideGroups x labels x subs
            end
            
%             for subject=1:length(this.adaptData) %Getting data for each subject in the list
%                data_aux=getEarlyLateData_v2(this.adaptData{subject},label,conds,0,numberOfStrides,exemptLast,exemptFirst);
%                for i=1:length(data)
%                    data{i}(:,:,:,subject)=data_aux{i}; %conds x strides x parameters(labels) x subjects
%                end
%             end
            
            %Alt: (using the inds data, so we are sure we are actually
            %getting the same strides when calling upon any function)            
            for j=1:length(this.adaptData) %For each sub
                allData=this.adaptData{j}.getDataFromInds(inds(:,j),label);
                for i=1:length(data) %For each strideGroup
                    data{i}(:,:,:,j)=allData{i};
                end
            end
            
        end
        
        function [meanData,stdData]=getAvgGroupedData(this,label,conds,removeBiasFlag,numberOfStrides,exemptFirst,exemptLast)
            [data]=getGroupedData(this,label,conds,removeBiasFlag,numberOfStrides,exemptFirst,exemptLast);
            for i=1:length(data)
               meanData(:,i,:,:)=nanmean(data{i},2); %conds x strideGroups x parameters x subjects
               stdData(:,i,:,:)=nanstd(data{i},[],2); 
            end
        end
        
        %Visualization
        %Scatter
        
        %TimeCourses
        function varargout=plotAvgTimeCourse(this,params,conditions,binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder,biofeedback,removeBiasFlag,groupNames,medianFlag,plotHandles)
            if nargin<4 || isempty(binwidth)
                binwidth=[];
            end
            if nargin<5
                trialMarkerFlag=[];
            end
            if nargin< 6
                indivFlag=[];
            end
            if nargin<7
                indivSubs=[];
            end
            if nargin<8
                colorOrder=[];
            end
            if nargin<9 
                biofeedback=[];
            end
            if nargin<10
                removeBiasFlag=0;%Default = noremoval;
            end
            if nargin<11
                groupNames=[];
            end
            if nargin<12
                medianFlag=[];
            end
            if nargin<13
                plotHandles=[];
            end
                
            varargout=adaptationData.plotAvgTimeCourse({this},params,conditions,binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder,biofeedback,removeBiasFlag,groupNames,medianFlag,plotHandles);
        end
        
        %Bars
        [figHandle,allData]=plotBars(this,label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,significanceThreshold,plotHandles,colors,signPlotMatrix);
        
        %Stats
        %function []=anova2()
        %
        %end
        
        %function []=anova1()
        %    
        %end
        
        function [p,table,stats,postHoc,postHocEstimates,data]=friedman(this,label,conds,groupingStrides,exemptFirst,exemptLast,interactionFlag,avgFlag)
            %Runs Friedman (non-parametric 1-way repeated measures anova
            %equivalent) for the grouped data. Individual ID is considered to be the blocking factor, each individual is
            %considered to be a block.
            %It works by finding the indexes corresponding to conditions/strides desired, and calls on friedmanI.
            %TODO: Should check that numberOfStrides groups are given in
            %chronological order & that so are the conditions in condList
            %as it expects ordered things.

            if nargin<7
                interactionFlag=[];
            end
            if nargin<8
                avgFlag=[];
            end
            N=abs(groupingStrides(1));
            M=length(conds)*length(groupingStrides);
            if any(abs(groupingStrides)~=N) %Friedman has to be balanced
                warning(['Friedman test only supports balanced designs (all groups should have the same number of strides). Will use ' num2str(N) ' strides in all conditions.'])
                groupingStrides=N*sign(groupingStrides);
            end
            inds=this.getGroupedInds(conds,groupingStrides,exemptFirst,exemptLast);
            inds=cell2mat(inds');
            [~,ii]=sort(nanmean(inds,1)); %Sorting so groups are presented in appearance order. 
            inds=inds(:,ii);
            inds=mat2cell(inds,N*ones(length(this.ID),1),M);
            [p,table,stats,postHoc,postHocEstimates,data]=friedmanI(this,label,inds,interactionFlag,avgFlag);
        end
        
        function [p,table,stats,postHoc,postHocEstimates,data]=anova1RM(this,label,conds,groupingStrides,exemptFirst,exemptLast,interactionFlag,avgFlag)
            %TODO: Should check that numberOfStrides groups are given in
            %chronological order & that so are the conditions in condList
            %as it expects ordered things.

            if nargin<7
                interactionFlag=[];
            end
            if nargin<8
                avgFlag=[];
            end
            N=abs(groupingStrides(1));
            M=length(conds)*length(groupingStrides);
            if any(abs(groupingStrides)~=N) %Friedman has to be balanced
                warning(['Anova1-RM test currently only supports balanced designs (all groups should have the same number of strides). Will use ' num2str(N) ' strides in all conditions.'])
                groupingStrides=N*sign(groupingStrides);
            end
            inds=this.getGroupedInds(conds,groupingStrides,exemptFirst,exemptLast);
            inds=cell2mat(inds');
            [~,ii]=sort(nanmean(inds,1)); %Sorting so groups are presented in appearance order. 
            inds=inds(:,ii);
            inds=mat2cell(inds,N*ones(length(this.ID),1),M);
            [p,table,stats,postHoc,postHocEstimates,data]=anova1RMI(this,label,inds,interactionFlag,avgFlag);
        end
        
        function [p,table,stats,postHoc,postHocEstimates,allData]=friedmanI(this,label,inds,interactionFlag,avgFlag)
            %Runs Friedman (non-parametric 1-way repeated measures anova
            %equivalent) for the grouped data. Individual ID is considered to be the blocking factor, each individual is
            %considered to be a block, and the different index groups are
            %compared to each other.
            
            %inds should be a cell with length = #subs and its contents a
            %NxM matrix, where M is the number of groups to be tested and N
            %the number of strides/repetitions in each group
            %Inds here follows a slightly different specification from that
            %returned by getGroupedInds. In order to format the output of
            %that function to the input of this, the following lines need to
            %be executed:
            %N=size(inds{1},1);
            %M=size(inds{1},2)*size(inds,1);
            %inds=mat2cell(cell2mat(inds'),N*ones(length(this.ID),1),M);
            
            %Check that the size of inds is the same for all 
            %subjects (friedman needs to be balanced)
            
            %Check that size(inds,1)==#subs
            
            %Do Friedman
            N=size(inds{1},1); %Number of strides per stride group
            M=size(inds{1},2); %Number of stride groups
            P=length(this.ID); %#subs
            if isa(label,'char')
                label={label};
            end
            if nargin<4 || isempty(interactionFlag)
                interactionFlag=0; %No interactions is default
            end
            if nargin<5 || isempty(avgFlag)
                avgFlag=0;
            end
            switch interactionFlag
                case 1
                    model='full';
                case 0
                    model='linear';
            end
            if length(label)>1 %For multiple parameters
                for i=1:length(label)
                    [p{i},table{i},stats{i},postHoc{i},postHocEstimates{i},allData{i}]=this.friedmanI(label{i},inds,interactionFlag,avgFlag);
                end
            else
                allData=nan(N,P,M);                
                for j=1:P
                    aux=this.adaptData{j}.data.getDataAsVector(label); %Should I be normalizing or removing bias?
                    for i=1:M
                        allData(:,j,i)=aux(inds{j}(:,i));
                    end
                end
                if avgFlag==1
                    allData=nanmean(allData,1);
                    N=1;
                end
                data=reshape(allData,N*P,M); %Setting up the data in the shape required by Friedman
                [p,table,stats]=friedman(data,N,'off'); %This fails if there are any nan in newData
                %Post-hoc: more friedman, but on paired columns. As such it
                %may be unnecessary, since the user can have this info by
                %just calling on friedman with the reduced data
                postHoc=nan(M);
                postHocEstimates=nan(M);
                %Post-hoc: Default is tukey-kramer
                %mm=multcompare(stats,'Dimension',2,'Display','off','CType','bonferroni'); %Post-hoc across stride groups
                %postHoc(sub2ind([M,M],mm(:,1),mm(:,2)))=mm(:,6);
                %postHocEstimates(sub2ind([M,M],mm(:,1),mm(:,2)))=mm(:,4);
                for i=1:M
                    for j=i+1:M
                        [postHoc(i,j),~,s]=friedman(data(:,[i,j]),N,'off');
                        postHocEstimates(i,j)=diff(s.meanranks);
                    end
                end
            end
        end
        
        function [p,table,stats,postHoc,postHocEstimates,allData]=anova1RMI(this,label,inds,interactionFlag,avgFlag)
            %One-way repeated measures anova, using each individual as a
            %block, and testing across stride groups (e.g. early adap vs late
            %base)
            %Inds here follows a slightly different specification from that
            %returned by getGroupedInds. In order to format the output of
            %that function to the input of this, the following lines need to
            %be executed:
            %N=size(inds{1},1);
            %M=size(inds{1},2)*size(inds,1);
            %inds=mat2cell(cell2mat(inds'),N*ones(length(this.ID),1),M);
            N=size(inds{1},1);%Number of strides per stride group
            M=size(inds{1},2);%Number of strideGroups 
            P=length(this.ID); %#subs = size(inds,2)
            if isa(label,'char')
                label={label};
            end
            if nargin<4 || isempty(interactionFlag)
                interactionFlag=0; %No interactions is default
            end
            if nargin<5 || isempty(avgFlag)
                avgFlag=0;
            end
            switch interactionFlag
                case 1
                    model='full';
                case 0
                    model='linear';
            end
            if length(label)>1 %For multiple parameters
                for i=1:length(label)
                    [p{i},table{i},stats{i},postHoc{i},postHocEstimates{i},allData{i}]=anova1RMI(this,label{i},inds,interactionFlag,avgFlag);
                end
            else
                allData=nan(N,P,M);                
                for j=1:P %For each sub
                    aux=this.adaptData{j}.data.getDataAsVector(label); %Should I be normalizing or removing bias?
                    for i=1:M %For each strideGroup
                        allData(:,j,i)=aux(inds{j}(:,i)); %Strides x sub x strideGroup
                    end
                end
                if avgFlag==1
                    allData=nanmean(allData,1);
                    N=1;
                end
                data=reshape(allData,N*P,M); 
                subID=repmat(this.ID,N,M);
                strideGroup=repmat([1:M],N*P,1);
                [p,table,stats,~]=anovan(data(:),{subID(:) strideGroup(:)},'display','off','random',[1],'varnames',{'subID','strideGroup'},'model',model);
                postHoc=nan(M);
                postHocEstimates=nan(M);
                allData=data;
                %Post-hoc: Default is tukey-kramer
                mm=multcompare(stats,'Dimension',2,'Display','off','CType','bonferroni'); %Post-hoc across stride groups
                postHoc(sub2ind([M,M],mm(:,1),mm(:,2)))=mm(:,6);
                postHocEstimates(sub2ind([M,M],mm(:,1),mm(:,2)))=mm(:,4);
            end
        end
        
        function [p,anovatab,stats,postHoc,postHocEstimate,data]=summaryKW(this,param,conds,groupingStrides,exemptFirst,exemptLast)
            %Runs kruskal-wallis for each individual, and returns
            %summarized results.
           for i=1:length(this.ID)
               [p{i},anovatab{i},stats{i},postHoc{i},postHocEstimate{i},data{i}]=this.adaptData{i}.kruskalwallis(param,conds,groupingStrides,exemptFirst,exemptLast);
           end
        end
        
    end
    methods(Static)
       % Several groups visualization
       [figHandle,allData]=plotMultipleGroupsBars(this,label,removeBiasFlag,plotIndividualsFlag,condList,numberOfStrides,exemptFirst,exemptLast,legendNames,significanceThreshold,plotHandles,colors,significancePlotMatrix);
       
       % Several groups stats
       function [p]=compareMultipleGroups(groups,label,condition,numberOfStrides,exemptFirst,exemptLast)
           %Check that there are exactly two groups

            for j=1:length(condition)
                for i=1:length(numberOfStrides)
                    for k=1:length(label)
                        data1=groups{1}.getAvgGroupedData(label(k),condition(j),0,numberOfStrides(i),exemptFirst,exemptLast);
                        data2=groups{2}.getAvgGroupedData(label(k),condition(j),0,numberOfStrides(i),exemptFirst,exemptLast);
                        [~,p(j,i,k),ci,stats]=ttest(squeeze(data1),squeeze(data2));
                    end
                end
            end
       end
        
    end
end


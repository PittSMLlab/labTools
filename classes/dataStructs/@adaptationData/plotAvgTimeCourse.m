function varargout=plotAvgTimeCourse(adaptDataList,params,conditions,binwidth,trialMarkerFlag,indivFlag,indivSubs,colorOrder,biofeedback,removeBiasFlag,labels,filterFlag,plotHandles,alignEnd,alignIni)
%adaptDataList must be cell array of 'param.mat' file names
%params is cell array of parameters to plot, or cell array of adaptationData objects. List with commas to
%plot on separate graphs or with semicolons to plot on same graph.
%conditions is cell array of conditions to plot
%binwidth is the number of data points to average in time
%indivFlag - set to true to plot individual subject time courses
%indivSubs - must be a cell array of 'param.mat' file names that is
%a subset of those in the adaptDataList. Plots specific subjects
%instead of all subjects.
%
% figHandle = plotAvgTimeCourse(adaptDataList,params,conditions,binwidth,trialMarkerFlag,indivFlag,indivSubs)
% [Avg, Indiv] = plotAvgTimeCourse(figHandle,adaptDataList,params,conditions,binwidth,trialMarkerFlag)


%% Check inputs

% See if adaptDataList is a single subject (char), a cell
% array of subject names (one group of subjects), or a cell array of cell arrays of
% subjects names (several groups of subjects), and put all the
% cases into the same format
if isa(adaptDataList,'cell')
    if ~isa(adaptDataList{1},'cell')
        adaptDataList={adaptDataList};
    end
elseif isa(adaptDataList,'char') || isa(adaptDataList,'adaptationData')
    adaptDataList={{adaptDataList}};
end
legacyVersion=false;
if isa(adaptDataList{1}{1},'char')
    legacyVersion=true;
end
Ngroups=length(adaptDataList);

% make sure params is a cell array
if isa(params,'char')
    params={params};
end

% check condition input %TO DO: allow for condition numbers
if nargin>2
    if isa(conditions,'char')
        conditions={conditions};
    end
else
    if ~legacyVersion
        conditions=adaptDataList{1}{1}.metaData.conditionName; %default
    else
        error('No condition list provided')
    end
end
nConds=length(conditions);
cond=cell(1,nConds);
Opacity=.3;
for c=1:nConds
    if isa(conditions{c},'cell')
        cond{c}=conditions{c}{1}(ismember(conditions{c}{1},['A':'Z' 'a':'z' '0':'9']));
    elseif isa(conditions{c},'char')
        cond{c}=conditions{c}(ismember(conditions{c},['A':'Z' 'a':'z' '0':'9'])); %remove non alphanumeric characters
    else
        error('Conditions argument is neither a string, a cell array of strings or a cell array of cell array of strings.')
    end
end


if nargin<4 || isempty(binwidth)
    binwidth=1; %default
end

if nargin<5 || length(trialMarkerFlag)~=length(cond)
    trialMarkerFlag=false(1,length(cond));
end

if nargin<6 || isempty(indivFlag)
    indivFlag=false;
end

if nargin>6
    if isa(indivSubs,'cell') && ~isempty(indivSubs)
        if ~isa(indivSubs{1},'cell')
            indivSubs{1}=indivSubs;
        end
    elseif isa(indivSubs,'char')
        indivSubs{1}={indivSubs};
    end
end

% if nargin<9
    maxNumPts=false; %set to true to plot the maximum number of strides per trial/condition
    %                      otherwise, the subject with the fewest strides in a particular trial/condition
    %                      determines the number of strides plotted.
%     if ~isempty(alignEnd)
%         maxNumPts=true;
%     end
% end
if nargin<10 || isempty(removeBiasFlag)
    removeBiasFlag=0;
end

if nargin<12 || isempty(filterFlag)
    filterFlag=0;
end
%Added 9/28/2016: separated the two functionalities of 'medianFlag' into
%'medianFlag' and 'medianFilter'. Now accept that users may pass a scalar
%flag or a 2x1 flag vector, where the first index indicates the FILTER
%flag (median across samples), and the second indicates the GROUP flag (median across subjects).
%Update: 3/01/2017: if the vector is of length 3, using monoLS filter
%instead of median
monoFlag=false;
if numel(filterFlag)<2
    medianFilter=filterFlag;
    medianFlag=filterFlag;
elseif numel(filterFlag)==2
    medianFilter=filterFlag(1);
    medianFlag=filterFlag(2);
elseif numel(filterFlag)==4 %This is interpreted as using the monoLS filter, instead of median filter for samples
    monoFlag=true;
    medianFlag=filterFlag(1); %Taking median across groups, or not
    monoNder=filterFlag(2); %
    monoNreg=filterFlag(3);
    monoTrialBased=filterFlag(4);
    medianFilter=0;
else
    error('filterFlag length not recognized: can be a binary scalar (for median across subjects and samples), a 2x1 binary vector (to do median across samples or subjects), or 4x1 vector (to use monoLS for samples)')
end


if nargin<14 || alignEnd==0
    alignEnd=[];
end

if nargin<15 || alignIni==0
    alignIni=[];
end

%% Initialize plot

% axesFontSize=14;
% labelFontSize=0;
% titleFontSize=24;
axesFontSize=20;
labelFontSize=10;
titleFontSize=18;
if nargin<13 || isempty(plotHandles) || length(plotHandles)~=length(params)
    [ah,figHandle]=optimizedSubPlot(size(params,2),4,1,'tb',axesFontSize,labelFontSize,titleFontSize);
else
    ah=plotHandles;
    figHandle=gcf;
end
legendStr=cell(1);

% Set colors order
if nargin<8 || isempty(colorOrder) || size(colorOrder,2)~=3
    poster_colors;
    colorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow; [0 0 0];[0 1 1];p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow; [0 0 0];[0 1 1]];
     colorOrder=[ colorOrder; colorOrder;colorOrder];
end

lineOrder={'-','--','-.',':'};

%% determine length of trials or conditions
s=1; %subject counter
values=struct([]);
for group=1:Ngroups
    for subject=1:length(adaptDataList{group})
        %Load subject
        adaptData = adaptDataList{group}{subject};
        if legacyVersion
            load(adaptData)
        end
        adaptData = adaptData.removeBadStrides;
        if removeBiasFlag==1
            adaptData = adaptData.removeBias;
        elseif removeBiasFlag==2
            if any(contains(params,'hreflex','IgnoreCase',true))
                numStrides = -100;  % last 100 strides for 10 stimuli
                adaptData = removeBiasV4(adaptData,[],1,[],numStrides);
            else
                adaptData = adaptData.normalizeBias;
            end
        end

        for c=1:nConds
            if trialMarkerFlag(c)
                trials=num2cell(adaptData.getTrialsInCond({conditions{c}}));
            else
                trials={adaptData.getTrialsInCond({conditions{c}})}; %all trials in the condition are one "trial"
            end

            for t=1:length(trials) %length(trials) is always 1
                %Check
                if ~all(adaptData.data.isaParameter(params))
                    error('Not all provided labels are parameters in this subject')
                    keyboard %This shouldnt happen
                end
                if monoFlag && ~monoTrialBased
                    dataPts2=adaptData.getParamInTrial(params,trials{t});
                    dataPts=monoLS(dataPts2,[],monoNder,monoNreg);
                elseif monoFlag
                    dataPts=[];
                    for j=1:length(trials{1})
                        origData=adaptData.getParamInTrial(params,trials{1}(j));
                        aux=monoLS(origData,[],monoNder,monoNreg);
                        dataPts=[dataPts; aux];
                    end
                else
                    try % It is an experiment with perceptual tasks
                        dataPts=adaptData.getParamInTrial({params,'percTaskInitStride','percTaskEndStride'},trials{t});
                    catch
                        dataPts=adaptData.getParamInTrial(params,trials{t});
                    end
%                     dataPts=dataPts(2:end-5);
                end
                nPoints=size(dataPts,1);
                M=2000; %this assumes that the max number of data points that could exist in a single conition or trial is M
                if nPoints == 0
                    numPts.(cond{c}).(['trial' num2str(t)])(s)=NaN;
                else
                    numPts.(cond{c}).(['trial' num2str(t)])(s)=nPoints;
                    if ~isempty(alignEnd) %Aligning data to the end, too
                        if strcmpi(cond{c},'catch')
                            numPts.([cond{c}]).(['trial' num2str(t)])(s)=nPoints;
                        else
                            numPts.([cond{c} 'End']).(['trial' num2str(t)])(s)=alignEnd+50;
                        end
                    end
                end
                try
                    paramsTemp=[params,'percTaskInitStride','percTaskEndStride'];
                    for p=1:length(paramsTemp) % It is an experiment with perceptual tasks
                        %initialize so there are no inconsistant dimensions or out of bounds errors
                        values(group).(paramsTemp{p}).(cond{c}).(['trial' num2str(t)])(subject,:)=NaN(1,M);
                        values(group).(paramsTemp{p}).(cond{c}).(['trial' num2str(t)])(subject,1:nPoints)=dataPts(:,p);
                        if ~isempty(alignEnd) %Aligning data to the end too, by creating a fake condition
                            if strcmpi(cond{c},'catch')
                                values(group).(paramsTemp{p}).(cond{c}).(['trial' num2str(t)])(subject,:)=NaN(1,M);
                                values(group).(paramsTemp{p}).(cond{c}).(['trial' num2str(t)])(subject,1:nPoints)=dataPts(:,p);
                            else
                                values(group).(paramsTemp{p}).([cond{c} 'End']).(['trial' num2str(t)])(subject,:)=[nan(50,1); dataPts(end-alignEnd+1:end,p)];
                            end
                        end
                    end
                catch
                    for p=1:length(params)
                        %initialize so there are no inconsistant dimensions or out of bounds errors
                        values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subject,:)=NaN(1,M);
                        values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subject,1:nPoints)=dataPts(:,p);
                        if ~isempty(alignEnd) %Aligning data to the end too, by creating a fake condition
                            if strcmpi(cond{c},'catch')
                                values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subject,:)=NaN(1,M);
                                values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subject,1:nPoints)=dataPts(:,p);
                            else
                                values(group).(params{p}).([cond{c} 'End']).(['trial' num2str(t)])(subject,:)=[nan(50,1); dataPts(end-alignEnd+1:end,p)];
                            end
                        end
                    end
                end
            end
        end
        s=s+1;
    end
end

%% Do the actual plotting
Li=cell(1);
avg=struct([]);
se=struct([]);
indiv=struct([]);
if ~isempty(alignEnd)
   newCond=cell(2*length(cond),1);
   newCond(1:2:end)=cond;
   newCond(2:2:end)=strcat(cond,'End');
   catchindx=find(strcmpi(newCond,'catchEnd'));
   if ~isempty(catchindx);
   newCond{catchindx}=[];
   end
   newCond=newCond(~cellfun('isempty',newCond));
   cond=newCond;
   cond=newCond;
   nConds=length(cond);
end

p=length(params);
for group=1:Ngroups
    Xstart=1;
    lineX=0;
    for c=1:nConds
        for t=1:length(fields(values(group).(params{p}).(cond{c})))

            % 1) find the length of each trial
            if maxNumPts
                %to plot the MAX number of pts in each trial:
                [maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
                while maxPts>1.25*nanmax(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end]))
                        numPts.(cond{c}).(['trial' num2str(t)])(loc)=nanmean(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end])); %do not include min in mean (?)
                    [maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
                end
                if maxPts==0
                    continue
                end
            else
                %to plot the MIN number of pts in each trial:
                [maxPts,loc]=nanmin(numPts.(cond{c}).(['trial' num2str(t)]));
                while maxPts<0.75*nanmin(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end]))
                        numPts.(cond{c}).(['trial' num2str(t)])(loc)=nanmean(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end])); %do not include min in mean (?)
                    [maxPts,loc]=nanmin(numPts.(cond{c}).(['trial' num2str(t)]));
                end
                if maxPts==0
                    continue
                end
            end

            for p=1:length(params)

                if ~isnan(maxPts)%do not try to plot if maxPts is NaN, this indicates that there is no c3d for this trial
                    allValues=values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,1:maxPts);
                else
                    allValues = NaN;%set plot values to NaN when there is no c3d data
                end

                % 2) average across subjuects within bins

                %Find (running) averages and standard deviations for bin data
                binwidthNew = binwidth;
                numVals = size(allValues,2);
                if binwidth > numVals
                    warning(['Specified bin width exceeds the number ' ...
                        'of strides in trial. Reducing bin width to be' ...
                        ' number of strides.']);
                    binwidthNew = numVals;
                end
                start=1:numVals-(binwidthNew-1);
                stop = start + (binwidthNew-1);
%                 %Find (simple) averages and standard deviations for bin data
%                 start = 1:binwidth:(size(allValues,2)-binwidth+1);
%                 stop = start+(binwidth-1);

                for i = 1:length(start)
                    t1 = start(i);
                    t2 = stop(i);
                    bin = allValues(:,t1:t2);

                    if length(adaptDataList{group})>1 %Several subjects
                        %errors calculated as standard error of averaged subject points
                        if medianFilter==0
                            subBin=nanmean(bin,2); %Mean across time
                        else
                            subBin=nanmedian(bin,2); %Median across  time
                        end
                        if medianFlag==0
                            avg(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanmean(subBin); %Mean across subjects
                            se(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanstd(subBin)/sqrt(length(subBin));  
                        else %Using median and 15.87-84.13 percentiles
                            avg(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanmedian(subBin);
                            se(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=.5*diff(prctile(subBin,[16,84]))/sqrt(length(subBin));
                        end
                         indiv(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,i)=subBin;
                    else %Single subject
                        %errors calculated as standard error of all data
                        %points within a bin
                        if medianFlag==0
                            avg(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanmean(reshape(bin,1,numel(bin)));
                            indiv(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,i)=nanmean(bin,2);
                            se(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanstd(reshape(bin,1,numel(bin)))/sqrt(binwidthNew);
                        else
                            avg(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanmedian(reshape(bin,1,numel(bin)));
                            indiv(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,i)=nanmedian(bin,2);
                            se(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=.5*diff(prctile(reshape(bin,1,numel(bin)),[16,84]))/sqrt(binwidthNew);
                        end
                    end
                end

                % 3) plot data
                if size(params,1)>1
                    axes(ah)
                    g=p;
                    Cdiv=group;
                    if Ngroups==1
                        legStr=params(p);
                    else
                        if ~legacyVersion
                            if length(adaptDataList{group})>1
                                legStr={[params{p} ' ' adaptDataList{group}{1}.metaData.ID]};
                            else
                                legStr={[params{p} ' ' adaptDataList{group}{1}.subData.ID]};
                            end
                        else
                            if length(adaptDataList{group})>1
                                legStr={[params{p} ' ' adaptDataList{group}{1}]};
                            else
                                legStr={[params{p} ' ' adaptDataList{group}{1}]};
                            end

                        end

                    end
                else
                    axes(ah(p))
                    g=group;
                    Cdiv=1;
                end
                hold on                
                afterTrialPad=5; %adds empty space to end of trial/condition (in strides)
                y=[avg(group).(params{p}).(cond{c}).(['trial' num2str(t)]), NaN(1,afterTrialPad)];
                E=[se(group).(params{p}).(cond{c}).(['trial' num2str(t)]), NaN(1,afterTrialPad)];


               %                 condLength=length(y);
%                 x=Xstart:Xstart+condLength-1;

                if isempty(alignIni) %DULCE
                    condLength=length(y);
                    x=Xstart:Xstart+condLength-1;
                elseif ~isempty(alignIni) && strcmp(cond{c}(end-2:end), 'End')
                    condLength=length(y);
                    x=Xstart:Xstart+condLength-1;
                else
                    x=Xstart:Xstart+alignIni-1;
                    y=y(1:length(x));
                    E=E(1:length(x));
                    condLength=length(y);
                end
          
                %Biofeedback
                if nargin>8 && ~isempty(biofeedback)
                    if biofeedback==1 && strcmp(params{p},'alphaFast')
                        w=adaptData{group}{1}.getParamInCond('TargetHitR',conditions{c});
                    elseif biofeedback==1 &&  strcmp(params{p},'alphaSlow')
                        w=adaptData{group}{1}.getParamInCond('TargetHitL',conditions{c});
                    elseif biofeedback==0
                        biofeedback=[];
                    else
                        w=adaptData.getParamInCond('TargetHit',conditions{c});
                    end
                else
                    biofeedback=[];
                end

                if indivFlag %plotting all individual subjects
                    nSubs=length(adaptDataList{group});
                    subjects=cell(1,nSubs);
                    for s=1:nSubs
                        if ~legacyVersion
                            subjects{s}=adaptDataList{group}{s}.subData.ID;
                        else
                            subjects{s}=adaptDataList{group}{s}(1:end-6);
                        end
                    end
                    if ~isempty(indivSubs) && ~isempty(indivSubs{group}{1}) %plot specific individual subjects
                        subsToPlot=indivSubs{group};
                    else
                        subsToPlot=adaptDataList{group};
                    end
                    for s=1:length(subsToPlot)
                        if ~legacyVersion
                            id=subsToPlot{s}.subData.ID;
                        else
                            id=subsToPlot{s}(1:end-6);
                        end
                        subInd=find(ismember(subjects,id),1,'first');
                        y_indiv=[indiv(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subInd,:), NaN(1,afterTrialPad)];
                        %%to plot as dots:
                        %plot(x,y_ind,'o','MarkerSize',3,'MarkerEdgeColor',colorOrder(subInd,:),'MarkerFaceColor',colorOrder(subInd,:));
                        %%to plot as lines:
                        Li{group}(s)=plot(x,y_indiv(1:length(x)),lineOrder{g},'color',colorOrder(mod(subInd-1,size(colorOrder,1))+1,:),'Tag',id);
                        if ~legacyVersion
                            legendStr{group}(s)={subsToPlot{s}.subData.ID};
                        else
                            legendStr{group}(s)={subsToPlot{s}};
                        end
                    end
                    %plot average of group if there is more than one person
                    %in the group
                    if length(adaptDataList{group})>1
                        Li{group}(length(subsToPlot)+1)=plot(x,y,'o','MarkerSize',5,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0.7 0.7 0.7].^group);
                        legendStr{group}(length(subsToPlot)+1)={['Average ' adaptDataList{group}{1}.metaData.ID]};
                    end
                else %only plot group averages
                     if Ngroups==1 && ~(size(params,1)>1) && isempty(biofeedback)  %one group (each condition colored different)
                        if isempty(biofeedback)
                            [Pa, Li{c}]=nanJackKnife(x,y,E,colorOrder(c,:),colorOrder(c,:)+0.5.*abs(colorOrder(c,:)-1),Opacity);
                        else
                            [Pa, Li{c}]=nanJackKnife(x,y,E,colorOrder(c,:),colorOrder(c,:)+0.5.*abs(colorOrder(c,:)-1),Opacity,w);
                        end
                        %set(Li{c},'Clipping','off')
                        H=get(Li{c},'Parent');                        
                        try    
                            if length(adaptDataList{group}) == 1
                                initIdx=find(values.percTaskInitStride.(cond{c}).(['trial' num2str(t)])==1);
                                finalIdx=find(values.percTaskEndStride.(cond{c}).(['trial' num2str(t)])==1);
                                for i=1:length(initIdx)
                                    pp=patch(x(1)+[initIdx(i) finalIdx(i) finalIdx(i) initIdx(i)],[-0.25 -0.25 0.25 0.25],.85*ones(1,3),'FaceAlpha',.9,'EdgeColor','none','DisplayName','task');
                                    uistack(pp,'bottom');
                                end
                                legendStr={[adaptData.metaData.conditionName(adaptData.getConditionIdxsFromName(conditions)), {'task'}]};
                            end
                        catch
                            % Skip for know since there are no perceptual
                            % trials on this trial or experiment
                            legendStr={adaptData.metaData.conditionName(adaptData.getConditionIdxsFromName(conditions))};
                        end
                   elseif size(params,1)>1 && isempty(biofeedback)%Each parameter colored differently (and shaded differently for different groups)
                        ind=(group-1)*size(params,1)+p;
                        color=colorOrder(mod(g-1,size(colorOrder,1))+1,:)./Cdiv;
                        [Pa, Li{ind}]=nanJackKnife(x,y,E,color,color+0.5.*abs(color-1),Opacity);
                        %set(Li{ind},'Clipping','off')
                        H=get(Li{ind},'Parent');
                        legendStr{ind}=legStr;
                elseif  isempty(biofeedback) %Each group colored differently
                        color=colorOrder(g,:)./Cdiv;
                        [Pa, Li{g}]=nanJackKnife(x,y,E,color,color+0.5.*abs(color-1),Opacity);
                        %set(Li{g},'Clipping','off')
                        H=get(Li{g},'Parent');
                        if ~legacyVersion
                            if length(adaptDataList{g})>1
                                legendStr{g}={adaptDataList{g}{1}.metaData.ID};
                            else
                                legendStr{g}={adaptDataList{g}{1}.subData.ID};
                            end
                        else
                            if length(adaptDataList{g})>1
                                legendStr{g}={adaptDataList{g}{1}};
                            else
                                legendStr{g}={adaptDataList{g}{1}};
                            end

                        end
                    elseif ~(size(params,1)>1) && ~isempty(biofeedback)
                        color=colorOrder(g,:)./Cdiv;
                        [Pa, Li{g}]=nanJackKnife(x,y,E,color,color+0.5.*abs(color-1),Opacity,w);
                        %set(Li{g},'Clipping','off')
                        H=get(Li{g},'Parent');
                        group=adaptData{g}{1}.subData.ID;
                        abrevGroup=[group];
                        legendStr{g}={[ abrevGroup]};
                        elseif Ngroups==1 && ~(size(params,1)>1) && ~isempty(biofeedback)
                        [Pa, Li{c}]=nanJackKnife(x,y,E,colorOrder(c,:),colorOrder(c,:)+0.5.*abs(colorOrder(c,:)-1),Opacity,w);
                        %set(Li{c},'Clipping','off')
                        H=get(Li{c},'Parent');
                        legendStr={conditions};
                    elseif ~(size(params,1)>1) && ~isempty(biofeedback)
                        color=colorOrder(g,:)./Cdiv;
                        [Pa, Li{g}]=nanJackKnife(x,y,E,color,color+0.5.*abs(color-1),Opacity,w);
                        %set(Li{g},'Clipping','off')
                        H=get(Li{g},'Parent');
                        load([adaptDataList{g}{1,1}])
                        group=adaptData.subData.ID;
                        abrevGroup=[group];
                        legendStr{g}={[ abrevGroup]};
                    end
                    %set(Pa,'Clipping','off')
                    set(H,'Layer','top')
                end
            end
          Xstart=Xstart+condLength;
        end

        if c==nConds && group==Ngroups
            %on last iteration of conditions loop, add title and
            %vertical lines to seperate conditions
            for p=1:length(params)
                if ~(size(params,1)>1)
                    axes(ah(p))
                    %title(params{p},'fontsize',titleFontSize)
                    ylabel(params{p})
                else
                    axes(ah)
                end
                axis tight
                %if isempty(alignEnd)
                %    line([lineX; lineX],ylim,'color','k')
                %else %When plotting data aligned to end, only put a vertical line for actual condition end
                %    line([lineX(1:2:end); lineX(1:2:end)],ylim,'color','k')
                %end
                xticks=lineX+diff([lineX Xstart])./2;

                %set(gca,'fontsize',axesFontSize,'Xlim',[0 Xstart],'Xtick', xticks, 'Xticklabel', adaptData.metaData.conditionName(adaptData.getConditionIdxsFromName(conditions)))
                if ~isempty(alignEnd)

                    xticks=[[0 lineX(3:2:end)];xticks(1:2:end)];
                    xticks=xticks(:);
                    xtl=[adaptData.metaData.conditionName(adaptData.getConditionIdxsFromName(conditions));adaptData.metaData.conditionName(adaptData.getConditionIdxsFromName(conditions))];
                    xtl=xtl(:);
                    xtl(1:2:end)={''};
                    %xtl=cond;
                    %xtl(1:2:end)=strcat(xtl(1:2:end),'Early');
                    %xticks(2:2:end)=xticks(2:2:end)+25;

                else
                    xtl=adaptData.metaData.conditionName(adaptData.getConditionIdxsFromName(conditions));
                end
%                 set(gca,'fontsize',axesFontSize,'Xlim',[0 Xstart],'Xtick', xticks, 'Xticklabel', xtl)
                %h=refline(0,0);
                %set(h,'color','k')
            end
            hold off
        end
        lineX(end+1)=Xstart-0.5;
    end
end

%linkaxes(ah,'x')
set(gcf,'color','w');
set(gcf,'Renderer','painters');
if nargin<11 || isempty(labels) || indivFlag==1
    if size(legendStr(:),2)>10
        try
            legend([Li{:},pp],[legendStr{:}],'NumColumns',3,'Location','Best','AutoUpdate',false)
        catch
            legend([Li{:}],[legendStr{:}],'NumColumns',3,'Location','Best','AutoUpdate',false)
        end
    else
        try
            legend([Li{:},pp],[legendStr{:}],'Location','Best','AutoUpdate',false)
        catch
            legend([Li{:}],[legendStr{:}],'Location','Best','AutoUpdate',false)
        end
    end
else
    labels={labels}';
    legend([Li{:}],[labels{:}],'Location','Best','AutoUpdate',false)
end
%% outputs
if nargout<2
    varargout{1}=figHandle;
elseif nargout==2
    varargout{1}=avg;
    varargout{2}=indiv;
elseif nargout==3
    varargout{1}=figHandle;
    varargout{2}=avg;
    varargout{3}=indiv;
else
    varargout{1}=figHandle;
    varargout{2}=avg;
    varargout{3}=indiv;
    varargout{4}=ah; %axes handles
end

%% Sending patches to back
p=findobj(gcf,'Type','Patch');
if ~isempty(p)
    for i=1:length(p)
    uistack(p(i),'bottom')
    end
end

%% Eliminating marker edge color
%p=findobj(gcf,'Type','Line');
%set(p,'MarkerEdgeColor','none')

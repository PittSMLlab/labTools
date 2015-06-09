function varargout=plotAvgTimeCourse(adaptDataList,params,conditions,binwidth,trialMarkerFlag,indivFlag,indivSubs)
%adaptDataList must be cell array of 'param.mat' file names
%params is cell array of parameters to plot. List with commas to
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

maxNumPts=false; %set to true to plot the maximum number of strides per trial/condition
                 %otherwise, the subject with the fewest strides in a particular trial/condition
                 %determines the number of strides plotted.
%% Check inputs

% See if adaptDataList is a single subject (char), a cell
% array of subject names (one group of subjects), or a cell array of cell arrays of
% subjects names (several groups of subjects), and put all the
% cases into the same format
if isa(adaptDataList,'cell')
    if ~isa(adaptDataList{1},'cell')
        adaptDataList{1}=adaptDataList;
    end
elseif isa(adaptDataList,'char')
    adaptDataList{1}={adaptDataList};
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
    load(adaptDataList{1}{1})
    conditions=adaptData.metaData.conditionName; %default
end
for c=1:length(conditions)
    if isa(conditions{c},'cell')
        cond{c}=conditions{c}{1}(ismember(conditions{c}{1},['A':'Z' 'a':'z' '0':'9']));
    elseif isa(conditions{c},'char')
        cond{c}=conditions{c}(ismember(conditions{c},['A':'Z' 'a':'z' '0':'9'])); %remove non alphanumeric characters
    else
        error('Conditions argument is neither a string, a cell array of strings or a cell array of cell array of strings.')
    end
end

if nargin<4
    binwidth=1; %default
end

if nargin<5 || length(trialMarkerFlag)~=length(cond)
    trialMarkerFlag=false(1,length(cond));
end     

if nargin<6 || isempty(indivFlag)
    indivFlag=false;
end

if nargin>6    
    if isa(indivSubs,'cell')
        if ~isa(indivSubs{1},'cell')
            indivSubs{1}=indivSubs;
        end
    elseif isa(indivSubs,'char')
        indivSubs{1}={indivSubs};
    end
else
    indivSubs={{}};    
end

%% Initialize plot

axesFontSize=8;
labelFontSize=0;
titleFontSize=12;
[ah,figHandle]=optimizedSubPlot(size(params,2),4,1,'tb',axesFontSize,labelFontSize,titleFontSize);
legendStr={};

% Set colors
%poster_colors
% Set colors order
%ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow; [0 0 0]];

poster_colorsHH;
% Set colors order
%            %OA       OG        OANC       YA     OASV         OGNC       YASV        YG      YGNC           YASS        YGSS          OGSS          OASS
% ColorOrder=[p_red; p_orange; p_violet; p_green; p_dark_red; p_yellow; p_dark_green; p_blue; p_dark_blue; p_fade_green; p_fade_blue; p_fade_orange; p_fade_red];
ColorOrder= [p_red; p_orange; p_green; p_blue; p_indigo;  p_dark_red; p_dark_green; p_dark_blue; p_violet; p_fade_red; p_fade_orange; p_fade_yellow; p_fade_green; p_fade_blue; p_gray; p_black];

LineOrder={'-',':','--','-.'};

%% Load data and determine length of trials or conditions
nConds=length(conditions);
s=1; %subject counter
for group=1:Ngroups
    for subject=1:length(adaptDataList{group})
        %Load subject
        load(adaptDataList{group}{subject});
        adaptData = adaptData.removeBadStrides;
        adaptData = adaptData.removeBias;
        
        for c=1:nConds
            if trialMarkerFlag(c)
                trials=num2cell(adaptData.getTrialsInCond(conditions{c}));
            else
                trials={adaptData.getTrialsInCond(conditions{c})}; %all trials in the condition are one "trial"
            end
            
            for t=1:length(trials)
                dataPts=adaptData.getParamInTrial(params,trials{t});
                nPoints=size(dataPts,1);
                if nPoints == 0
                    numPts.(cond{c}).(['trial' num2str(t)])(s)=NaN;
                else
                    numPts.(cond{c}).(['trial' num2str(t)])(s)=nPoints;
                end
                for p=1:length(params)
                    %itialize so there are no inconsistant dimensions or out of bounds errors
                    values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subject,:)=NaN(1,2000); %this assumes that the max number of data points that could exist in a single conition or trial is 2000
                    
%                     %%VELOCITY CONTRIBUTION IS FLIPPED HERE
%                     if strcmp(params{p},'velocityContribution')
%                         values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subject,1:nPoints)=-dataPts(:,p);
%                     else
                    values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subject,1:nPoints)=dataPts(:,p);
%                     end
                end
            end
        end
        s=s+1;
    end
end

%% Do the actual plotting

for group=1:Ngroups
    Xstart=1;
    lineX=0;
    subjects=adaptDataList{group};
    for c=1:length(conditions)
        for t=1:length(fields(values(group).(params{p}).(cond{c})));
            
            % 1) find the length of each trial
            if maxNumPts
                %to plot the MAX number of pts in each trial:
                [maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
                while maxPts>1.25*nanmax(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end]))
                    numPts.(cond{c}).(['trial' num2str(t)])(loc)=nanmean(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end])); %do not include min in mean
                    [maxPts,loc]=nanmax(numPts.(cond{c}).(['trial' num2str(t)]));
                end
                if maxPts==0
                    continue
                end
            else
                %to plot the MIN number of pts in each trial:
                [maxPts,loc]=nanmin(numPts.(cond{c}).(['trial' num2str(t)]));
                while maxPts<0.75*nanmin(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end]))
                    numPts.(cond{c}).(['trial' num2str(t)])(loc)=nanmean(numPts.(cond{c}).(['trial' num2str(t)])([1:loc-1 loc+1:end])); %do not include min in mean
                    [maxPts,loc]=nanmin(numPts.(cond{c}).(['trial' num2str(t)]));
                end
                if maxPts==0
                    continue
                end
            end            
            
            for p=1:length(params)                
                
                allValues=values(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,1:maxPts);

                % 2) average across subjuects within bins

                %Find (running) averages and standard deviations for bin data
                start=1:size(allValues,2)-(binwidth-1);
                stop=start+binwidth-1;
%                 %Find (simple) averages and standard deviations for bin data
%                 start = 1:binwidth:(size(allValues,2)-binwidth+1);
%                 stop = start+(binwidth-1);

                for i = 1:length(start)
                    t1 = start(i);
                    t2 = stop(i);
                    bin = allValues(:,t1:t2);

                    %errors calculated as standard error of averaged subject points
                    subBin=nanmean(bin,2);
                    avg(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanmean(subBin);
                    se(group).(params{p}).(cond{c}).(['trial' num2str(t)])(i)=nanstd(subBin)/sqrt(length(subBin));
                    indiv(group).(params{p}).(cond{c}).(['trial' num2str(t)])(:,i)=subBin;

%                     %errors calculated as standard error of all data
%                     %points (before indiv subjects are averaged)
%                     avg.(params{p}).(cond{c})(i)=nanmean(reshape(bin,1,numel(bin)));
%                     se.(params{p}).(cond{c})(i)=nanstd(reshape(bin,1,numel(bin)))/sqrt(binwidth);
%                     indiv.(params{p}).(cond{c})(:,i)=nanmean(bin,2);
                end

                % 3) plot data
                if size(params,1)>1
                    axes(ah)
                    g=p;
                    Cdiv=group;
                    if Ngroups==1
                        legStr=params(p);
                    else
                        if length(adaptDataList{group})>1
                            load(adaptDataList{group}{1})
                            legStr={[params{p} ' ' adaptData.metaData.ID]};
                        else
                            legStr={[params{p} ' ' adaptDataList{group}{:}]};                            
                        end
                        
                    end
                else
                    axes(ah(p))
                    g=group;
                    Cdiv=1;
                end
                hold on
                afterTrialPad=5; %adds empty sapce to end of trial/condition (in strides)
                y=[avg(group).(params{p}).(cond{c}).(['trial' num2str(t)]), NaN(1,afterTrialPad)];
                E=[se(group).(params{p}).(cond{c}).(['trial' num2str(t)]), NaN(1,afterTrialPad)];
                condLength=length(y);
                x=Xstart:Xstart+condLength-1;

                if indivFlag %plotting all individual subjects
                    if ~isempty(indivSubs{1}) %plot specific individual subjects
                        subsToPlot=indivSubs{group};
                    else
                        subsToPlot=subjects;
                    end
                    for s=1:length(subsToPlot)
                        subInd=find(ismember(subjects,subsToPlot{s}));
                        y_ind=[indiv(group).(params{p}).(cond{c}).(['trial' num2str(t)])(subInd,:), NaN(1,afterTrialPad)];
                        %%to plot as dots:
                        %plot(x,y_ind,'o','MarkerSize',3,'MarkerEdgeColor',ColorOrder(subInd,:),'MarkerFaceColor',ColorOrder(subInd,:));
                        %%to plot as lines:
                        Li{group}(s)=plot(x,y_ind,LineOrder{g},'color',ColorOrder(mod(subInd-1,size(ColorOrder,1))+1,:));
                        legendStr{group}=subsToPlot;
                    end
                    if length(adaptDataList{group})>1
                        Li{group}(end+1)=plot(x,y,'o','MarkerSize',3,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0.7 0.7 0.7].^group);                    
                        load(adaptDataList{group}{1})
                        legendStr{group}(end+1)={['Average ' adaptData.metaData.ID]};                                               
                    end                    
                else %only plot group averages
                    if Ngroups==1 && ~(size(params,1)>1) %one group (each condition colored different)
                        [Pa, Li{c}]=nanJackKnife(x,y,E,ColorOrder(c,:),ColorOrder(c,:)+0.5.*abs(ColorOrder(c,:)-1),0.7);
                        set(Li{c},'Clipping','off')
                        H=get(Li{c},'Parent');
                        legendStr={conditions};
                    elseif size(params,1)>1 %Each parameter colored differently (and shaded differently for different groups)
                        ind=(group-1)*size(params,1)+p;
                        color=ColorOrder(g,:)./Cdiv;
                        [Pa, Li{ind}]=nanJackKnife(x,y,E,color,color+0.5.*abs(color-1),0.7);
                        set(Li{ind},'Clipping','off')
                        H=get(Li{ind},'Parent');
                        legendStr{ind}=legStr;
                    else %Each group colored differently
                        color=ColorOrder(g,:)./Cdiv;
                        [Pa, Li{g}]=nanJackKnife(x,y,E,color,color+0.5.*abs(color-1),0.7);
                        set(Li{g},'Clipping','off')
                        H=get(Li{g},'Parent');
                        if length(adaptDataList{g})>1
                            load(adaptDataList{g}{1})
                            legendStr{g}={adaptData.metaData.ID};
                        else
                            legendStr{g}=adaptDataList{g}(:);
                        end
                    end
                    set(Pa,'Clipping','off')
                    set(H,'Layer','top')
                end               
            end
            Xstart=Xstart+condLength;
        end
        
        if c==length(conditions) && group==Ngroups
            %on last iteration of conditions loop, add title and
            %vertical lines to seperate conditions
            for p=1:length(params)
                if ~(size(params,1)>1)
                    axes(ah(p))
                    title(params{p},'fontsize',titleFontSize)
                else
                    axes(ah)
                end
                axis tight
                line([lineX; lineX],ylim,'color','k')
                xticks=lineX+diff([lineX Xstart])./2;
                set(gca,'fontsize',axesFontSize,'Xlim',[0 Xstart],'Xtick', xticks, 'Xticklabel', conditions)
            end
            h=refline(0,0);
            set(h,'color','k')
            hold off
        end
        lineX(end+1)=Xstart-0.5;        
    end
end

%linkaxes(ah,'x')
%set(gcf,'Renderer','painters');
legend([Li{:}],[legendStr{:}])

%% outputs
if nargout<2
    varargout{1}=figHandle;
elseif nargout==2
    varargout{1}=avg;
    varargout{2}=indiv;
else
    varargout{1}=figHandle;
    varargout{2}=avg;
    varargout{3}=indiv;
end
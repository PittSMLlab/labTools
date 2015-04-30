function results = expResults(SMatrix,groups,plotFlag,indivFlag)
%% THIS FUNCTION IS OLD AND HAS BEEN REPLACED BY getResults !!!


% Set colors
poster_colors;
% Set colors order
GreyOrder=[0 0 0 ;1 1 1;0.5 0.5 0.5;0.1 0.1 0.1;0.7 0.7 0.7;0.2 0.2 0.2;0.8 0.8 0.8;0.3 0.3 0.3;0.9 0.9 0.9];
ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow; p_gray; p_black;p_red];

catchNumPts = 3; % catch
steadyNumPts = 40; %end of adaptation
transientNumPts = 5; % OG and Washout

if nargin<2 || isempty(groups)
    groups=fields(SMatrix);          
end
ngroups=length(groups);

results.spatialSteady.avg=[];
results.spatialSteady.sd=[];
results.stepTimeSteady.avg=[];
results.stepTimeSteady.sd=[];
results.relStepTime.avg=[];
results.relStepTime.sd=[];
results.relSpatial.avg=[];
results.relSpatial.sd=[];
results.expSpeed.avg=[];
results.expSpeed.sd=[];
results.OGafter.avg=[];
results.OGafter.sd=[];

for g=1:ngroups
    %get subjects in group
    subjects=SMatrix.(groups{g}).IDs(:,1); 
  
    spatialSteady=[];
    stepTimeSteady=[];
    velocitySteady=[];
    relSpatial=[];
    relStepTime=[];
    ogafter=[];
    expSpeed=[];
        
    for s=1:length(subjects)
        %load subject
        load([subjects{s} 'params.mat'])
                
        %normalize contributions based on combined step lengths
        SLf=adaptData.data.getParameter('stepLengthFast');
        SLs=adaptData.data.getParameter('stepLengthSlow');
        Dist=SLf+SLs;
        contLabels={'spatialContribution','stepTimeContribution','velocityContribution','netContribution'};
        [~,dataCols]=isaParameter(adaptData.data,contLabels);
        for c=1:length(contLabels)
            contData=adaptData.data.getParameter(contLabels(c));
            contData=contData./Dist;
            adaptData.data.Data(:,dataCols(c))=contData;
        end
        
        %remove baseline bias
        adaptDataNoBias=adaptData.removeBias;
                
        %calculate spatial and step time contribution as a percent of velocity
        %contribution during steady state

        spatialData=adaptDataNoBias.getParamInCond('spatialContribution','re-adaptation');
        stepTimeData=adaptDataNoBias.getParamInCond('stepTimeContribution','re-adaptation');
        velocityData=adaptDataNoBias.getParamInCond('velocityContribution','re-adaptation');
        
        spatialSteady=[spatialSteady;nanmean(spatialData((end-5)-steadyNumPts+1:(end-5)))];
        stepTimeSteady=[stepTimeSteady;nanmean(stepTimeData((end-5)-steadyNumPts+1:(end-5)))];
        velocitySteady=[velocitySteady;nanmean(velocityData((end-5)-steadyNumPts+1:(end-5)))];
        
        relSpatial=[relSpatial; spatialSteady(end)/abs(velocitySteady(end))*100];
        relStepTime=[relStepTime; stepTimeSteady(end)/abs(velocitySteady(end))*100];
        
        expSpeed=[expSpeed; mean(adaptData.getParamInCond('equivalentSpeed','TM base'))];
        
        params={'spatialContribution','stepTimeContribution'};
        %calculate OG after as mean values during strides which cause a
        %maximum deviation from zero in step length asymmetry during
        %'transientNumPts' consecutive steps within first 10 strides
        stepAsymData=adaptData.getParamInCond('stepLengthAsym','OG post');
        transferData=adaptData.getParamInCond(params,'OG post');
        [newStepAsymData,~]=bin_dataV1(stepAsymData(1:10,:),transientNumPts);
        [newTransferData,~]=bin_dataV1(transferData(1:10,:),transientNumPts);
        [~,maxLoc]=max(abs(newStepAsymData),[],1);
%             ind=sub2ind(size(newTransferData),maxLoc*ones(1,length(params)),1:length(params));
        ogafter=[ogafter; newTransferData(maxLoc,:)];
        
    end       

    
    nSubs=length(subjects);
    
    results.spatialSteady.avg(end+1,:)=nanmean(spatialSteady,1);
    results.spatialSteady.sd(end+1,:)=nanstd(spatialSteady,1)./sqrt(nSubs);
    results.spatialSteady.indiv.(groups{g})=spatialSteady;
    
    results.stepTimeSteady.avg(end+1,:)=nanmean(stepTimeSteady,1);
    results.stepTimeSteady.sd(end+1,:)=nanstd(stepTimeSteady,1)./sqrt(nSubs);
    results.stepTimeSteady.indiv.(groups{g})=stepTimeSteady;
    
    results.relSpatial.avg(end+1,:)=nanmean(relSpatial,1);
    results.relSpatial.sd(end+1,:)=nanstd(relSpatial,1)./sqrt(nSubs);
    results.relSpatial.indiv.(groups{g})=relSpatial;
    
    results.relStepTime.avg(end+1,:)=nanmean(relStepTime,1);
    results.relStepTime.sd(end+1,:)=nanstd(relStepTime,1)./sqrt(nSubs);
    results.relStepTime.indiv.(groups{g})=relStepTime;
    
    results.expSpeed.avg(end+1,:)=nanmean(expSpeed,1);
    results.expSpeed.sd(end+1,:)=nanstd(expSpeed,1)./sqrt(nSubs);
    results.expSpeed.indiv.(groups{g})=expSpeed;
    
    results.OGafter.avg(end+1,:)=nanmean(ogafter,1);
    results.OGafter.sd(end+1,:)=nanstd(ogafter,1)./sqrt(nSubs);
    results.OGafter.indiv.(groups{g})=ogafter;
end

%plot stuff

if nargin>2 && ~isempty(plotFlag)
    
    figure
    hold on
    
    for b=1:ngroups
        ph(b)=plot(results.stepTimeSteady.indiv.(groups{b}),results.spatialSteady.indiv.(groups{b}),'.','color',ColorOrder(b,:),'markerSize',20);
    end
    
    title('Treadmill Steady State')
    ylabel('Spatial Contribution')
    xlabel('Step Time Cont')
    
    legend(ph,groups)
    
    figure
    hold on
    
    for b=1:ngroups
        ph2(b)=plot(results.OGafter.indiv.(groups{b})(:,2),results.OGafter.indiv.(groups{b})(:,1),'.','color',ColorOrder(b,:),'markerSize',20);
    end
    
    title('OG after')
    ylabel('Spatial Contribution')
    xlabel('Step Time Cont')
    
    legend(ph2,groups)
    
    figure 
    hold on
    
    for b=1:ngroups
        ph3(b)=plot(results.relStepTime.indiv.(groups{b}),results.relSpatial.indiv.(groups{b}),'.','color',ColorOrder(b,:),'markerSize',20);
    end
    
    plot([0 100],[100 0],'k','linewidth',2)
    
    set(gca,'Ylim',[0 120])
    set(gca,'Xlim',[0 80])           
    
    ylabel('Relative Spatial Contribution')
    xlabel('Relative Step Time Cont')

    legend(ph3,groups)
    
    figure
    hold on
    
    for b=1:ngroups
        nSubs=length(SMatrix.(groups{b}).IDs(:,1));
        if nargin>3 && ~isempty(indivFlag)
            bar(b,results.expSpeed.avg(b),'facecolor',GreyOrder(b,:));
            for s=1:nSubs
                plot(b,results.expSpeed.indiv.(groups{b})(s),'*','Color',ColorOrder(s,:))
            end
        else
            bar(b,results.expSpeed.avg(b),'facecolor',ColorOrder(b,:));
        end                                
    end
    errorbar(results.expSpeed.avg,results.expSpeed.sd,'.','LineWidth',2,'Color','k')
    axis tight
    set(gca,'Xtick',1:ngroups,'XTickLabel',groups,'fontSize',12,'Ylim',[0 1500])   
    
end
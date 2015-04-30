function results = getResults(SMatrix,params,groups,maxPerturb,plotFlag,indivFlag)

% define number of points to use for calculating values
catchNumPts = 3; %catch
steadyNumPts = 40; %end of adaptation
transientNumPts = 5; %OG and Washout

if nargin<3 || isempty(groups)
    groups=fields(SMatrix);  %default        
end
ngroups=length(groups);


% Initialize values to calculate
results.OGbase.avg=[];
results.OGbase.se=[];

results.TMbase.avg=[];  
results.TMbase.se=[];

results.AvgAdaptBeforeCatch.avg=[];
results.AvgAdaptBeforeCatch.se=[];

results.AvgAdaptAll.avg=[];
results.AvgAdaptAll.se=[];

results.ErrorsOut.avg=[];
results.ErrorsOut.se=[];

results.TMsteadyBeforeCatch.avg=[];
results.TMsteadyBeforeCatch.se=[];

results.catch.avg=[];
results.catch.se=[];

results.TMsteady.avg=[];
results.TMsteady.se=[];

results.OGafter.avg=[];
results.OGafter.se=[];

results.TMafter.avg=[];
results.TMafter.se=[];

results.Transfer.avg=[];
results.Transfer.se=[];

results.Washout.avg=[];
results.Washout.se=[];

results.Transfer2.avg=[];
results.Transfer2.se=[];

results.Washout2.avg=[];
results.Washout2.se=[];


for g=1:ngroups
    
    % get subjects in group
    subjects=SMatrix.(groups{g}).IDs(:,1);
    
    OGbase=[];
    TMbase=[];
    avgAdaptBC=[];
    avgAdaptAll=[];
    errorsOut=[];    
    tmsteadyBC=[];
    tmCatch=[];
    tmsteady=[];    
    ogafter=[];
    tmafter=[];
    transfer=[];
    washout=[];
    transfer2=[];
    washout2=[];
        
    for s=1:length(subjects)
        % load subject
        load([subjects{s} 'params.mat'])       
        
        % remove baseline bias
        adaptData=adaptData.removeBias;        
        
         if nargin>3 && maxPerturb==1             
                       
            % compute TM and OG base in same manner as calculating OG after and TM after
            stepAsymData=adaptData.getParamInCond('stepLengthAsym','OG base');
            OGbaseData=adaptData.getParamInCond(params,'OG base');
            OGbase=[OGbase; smoothedMax(OGbaseData(1:10,:),transientNumPts,stepAsymData(1:10))];

            stepAsymData=adaptData.getParamInCond('stepLengthAsym','TM base');
            TMbaseData=adaptData.getParamInCond(params,'TM base');
            if isempty(TMbaseData)
                stepAsymData=adaptData.getParamInCond('stepLengthAsym',{'slow base','fast base'});
                TMbaseData=adaptData.getParamInCond(params,{'slow base','fast base'});
            end
            TMbase=[TMbase; smoothedMax(TMbaseData(1:10,:),transientNumPts,stepAsymData(1:10))];

            % compute catch as mean value during strides which caused a
            % maximum deviation from zero during 'catchNumPts' consecutive
            % strides
            stepAsymData=adaptData.getParamInCond('stepLengthAsym','catch');
            tmcatchData=adaptData.getParamInCond(params,'catch');
            tmCatch=[tmCatch; smoothedMax(tmcatchData,transientNumPts,stepAsymData)];
            
            % compute OG after as mean values during strides which cause a
            % maximum deviation from zero in STEP LENGTH ASYMMETRY during
            % 'transientNumPts' consecutive strides within first 10 strides
            stepAsymData=adaptData.getParamInCond('stepLengthAsym','OG post');
            ogafterData=adaptData.getParamInCond(params,'OG post');
            ogafter=[ogafter; smoothedMax(ogafterData(1:10,:),transientNumPts,stepAsymData(1:10))];
            
            % compute TM after-effects same as OG after-effect
            stepAsymData=adaptData.getParamInCond('stepLengthAsym','TM post');
            tmafterData=adaptData.getParamInCond(params,'TM post');            
            tmafter=[tmafter; smoothedMax(tmafterData(1:10,:),transientNumPts,stepAsymData(1:10))];
            
        else
            
            % calculate TM and OG base in same manner as calculating OG after and TM after
            OGbaseData=adaptData.getParamInCond(params,'OG base');
            OGbase=[OGbase; nanmean(OGbaseData(1:transientNumPts,:))];

            TMbaseData=adaptData.getParamInCond(params,'TM base');
            if isempty(TMbaseData)
                TMbaseData=adaptData.getParamInCond(params,{'slow base','fast base'});
            end            
            TMbase=[TMbase; nanmean(TMbaseData(1:transientNumPts,:))];
            
            % compute catch
            tmcatchData=adaptData.getParamInCond(params,'catch');
            if isempty(tmcatchData)
                newtmcatchData=NaN(1,length(params));
            elseif size(tmcatchData,1)<3
                newtmcatchData=nanmean(tmcatchData);
            else
                newtmcatchData=nanmean(tmcatchData(1:catchNumPts,:));
                %newtmcatchData=nanmean(tmcatchData);
            end
            tmCatch=[tmCatch; newtmcatchData];  
            
            % compute OG post
            ogafterData=adaptData.getParamInCond(params,'OG post');
            ogafter=[ogafter; nanmean(ogafterData(1:transientNumPts,:))];
            
            % compute TM post
            tmafterData=adaptData.getParamInCond(params,'TM post');
            tmafter=[tmafter; nanmean(tmafterData(1:transientNumPts,:))];            
        end
                
        % compute TM steady state before catch (mean of first transinetNumPts of last transinetNumPts+5 strides)
        adapt1Data=adaptData.getParamInCond(params,'adaptation');
        tmsteadyBC=[tmsteadyBC; nanmean(adapt1Data((end-5)-transientNumPts+1:(end-5),:))];
        
        % compute TM steady state before OG walking (mean of first steadyNumPts of last steadyNumPts+5 strides)
        adapt2Data=adaptData.getParamInCond(params,'re-adaptation');
        tmsteady=[tmsteady; nanmean(adapt2Data((end-5)-steadyNumPts+1:(end-5),:))];

        % compute average adaptation value before the catch
        avgAdaptBC=[avgAdaptBC; nanmean(adapt1Data)];
        
        % compute average adaptation of all adaptation walking (both
        % before and after catch)
        adaptAllData=adaptData.getParamInCond(params,{'adaptation','re-adaptation'});
        avgAdaptAll=[avgAdaptAll; nanmean(adaptAllData)];
        
        % Calculate Errors outside of baseline during adaptation
        mu=nanmean(TMbaseData);
        sigma=nanstd(TMbaseData);
        upper=mu+2.*sigma;
        lower=mu-2.*sigma;
        for i=1:length(params)
            outside(i)=sum(adapt1Data(:,i)>upper(i) | adapt1Data(:,i)<lower(i));
        end
        errorsOut=[errorsOut; 100.*(outside./size(adapt1Data,1))];       
    end   
    
    %calculate relative after-effects
%     transfer=[transfer; 100*(ogafter./(tmcatch))];
%     transfer=[transfer; 100*(ogafter./(tmcatch(:,3)*ones(1,3)))];
    transfer=[transfer; 100*(ogafter./(tmCatch))];
    washout=[washout; 100-(100*(tmafter./tmCatch))];

    transfer2=[transfer2; 100*(ogafter./tmsteady)];
    washout2=[washout2; 100-(100*(tmafter./tmsteady))];
    
    nSubs=length(subjects);
    
    results.OGbase.avg(end+1,:)=nanmean(OGbase,1);
    results.OGbase.se(end+1,:)=nanstd(OGbase,1)./sqrt(nSubs);
        
    results.TMbase.avg(end+1,:)=nanmean(TMbase,1);
    results.TMbase.se(end+1,:)=nanstd(TMbase,1);
    
    results.AvgAdaptBeforeCatch.avg(end+1,:)=nanmean(avgAdaptBC,1);
    results.AvgAdaptBeforeCatch.se(end+1,:)=nanstd(avgAdaptBC,1)./sqrt(nSubs);
    
    results.AvgAdaptAll.avg(end+1,:)=nanmean(avgAdaptAll,1);
    results.AvgAdaptAll.se(end+1,:)=nanstd(avgAdaptAll,1)./sqrt(nSubs);
    
    results.ErrorsOut.avg(end+1,:)=nanmean(errorsOut,1);
    results.ErrorsOut.se(end+1,:)=nanstd(errorsOut,1)./sqrt(nSubs);      
    
    results.TMsteadyBeforeCatch.avg(end+1,:)=nanmean(tmsteadyBC,1);
    results.TMsteadyBeforeCatch.se(end+1,:)=nanstd(tmsteadyBC,1)./sqrt(nSubs);
       
    results.catch.avg(end+1,:)=nanmean(tmCatch,1);
    results.catch.se(end+1,:)=nanstd(tmCatch,1)./sqrt(nSubs);
        
    results.TMsteady.avg(end+1,:)=nanmean(tmsteady,1);
    results.TMsteady.se(end+1,:)=nanstd(tmsteady,1)./sqrt(nSubs);
    
    results.OGafter.avg(end+1,:)=nanmean(ogafter,1);
    results.OGafter.se(end+1,:)=nanstd(ogafter,1)./sqrt(nSubs);
        
    results.TMafter.avg(end+1,:)=nanmean(tmafter,1);
    results.TMafter.se(end+1,:)=nanstd(tmafter,1)./sqrt(nSubs);
         
    results.Transfer.avg(end+1,:)=nanmean(transfer,1);
    results.Transfer.se(end+1,:)=nanstd(transfer,1)./sqrt(nSubs);
        
    results.Washout.avg(end+1,:)=nanmean(washout,1);
    results.Washout.se(end+1,:)=nanstd(washout,1)./sqrt(nSubs);
       
    results.Transfer2.avg(end+1,:)=nanmean(transfer2,1);
    results.Transfer2.se(end+1,:)=nanstd(transfer2,1)./sqrt(nSubs);
        
    results.Washout2.avg(end+1,:)=nanmean(washout2,1);
    results.Washout2.se(end+1,:)=nanstd(washout2,1)./sqrt(nSubs);
    
    if g==1 %This seems ridiculous, but I don't know of another way to do it without making MATLAB mad. The results.(whatever) structure needs to be in this format to make life easier for using SPSS
        for p=1:length(params)        
            results.OGbase.indiv.(params{p})=[g*ones(nSubs,1) OGbase(:,p)];
            results.TMbase.indiv.(params{p})=[g*ones(nSubs,1) TMbase(:,p)];
            results.AvgAdaptBeforeCatch.indiv.(params{p})=[g*ones(nSubs,1) avgAdaptBC(:,p)];
            results.AvgAdaptAll.indiv.(params{p})=[g*ones(nSubs,1) avgAdaptAll(:,p)];
            results.ErrorsOut.indiv.(params{p})=[g*ones(nSubs,1) errorsOut(:,p)];
            results.TMsteadyBeforeCatch.indiv.(params{p})=[g*ones(nSubs,1) tmsteadyBC(:,p)];
            results.catch.indiv.(params{p})=[g*ones(nSubs,1) tmCatch(:,p)];
            results.TMsteady.indiv.(params{p})=[g*ones(nSubs,1) tmsteady(:,p)];
            results.OGafter.indiv.(params{p})=[g*ones(nSubs,1) ogafter(:,p)];
            results.TMafter.indiv.(params{p})=[g*ones(nSubs,1) tmafter(:,p)];
            results.Transfer.indiv.(params{p})=[g*ones(nSubs,1) transfer(:,p)];
            results.Washout.indiv.(params{p})=[g*ones(nSubs,1) washout(:,p)];
            results.Transfer2.indiv.(params{p})=[g*ones(nSubs,1) transfer2(:,p)];
            results.Washout2.indiv.(params{p})=[g*ones(nSubs,1) washout2(:,p)];
        end
    else        
        for p=1:length(params)     
            results.OGbase.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) OGbase(:,p)];
            results.TMbase.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) TMbase(:,p)];
            results.AvgAdaptBeforeCatch.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) avgAdaptBC(:,p)];
            results.AvgAdaptAll.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) avgAdaptAll(:,p)];
            results.ErrorsOut.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) errorsOut(:,p)];
            results.TMsteadyBeforeCatch.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) tmsteadyBC(:,p)];
            results.catch.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) tmCatch(:,p)];
            results.TMsteady.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) tmsteady(:,p)];
            results.OGafter.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) ogafter(:,p)];
            results.TMafter.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) tmafter(:,p)];
            results.Transfer.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) transfer(:,p)];
            results.Washout.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) washout(:,p)];
            results.Transfer2.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) transfer2(:,p)];
            results.Washout2.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) washout2(:,p)];
        end
    end
end

%plot stuff
if nargin>4 && plotFlag
    
    % FIRST: plot baseline values against catch and transfer
    epochs={'AvgAdaptAll','TMsteady','catch','TMafter','OGafter'};
    if nargin>5 %I imagine there has to be a better way to do this...
        barGroups(SMatrix,results,groups,params,epochs,indivFlag)
    else
        barGroups(SMatrix,results,groups,params,epochs)
    end
    
    % SECOND: plot average adaptation values?
    epochs={'AvgAdaptBeforeCatch','TMsteadyBeforeCatch','AvgAdaptAll','TMsteady'};
    if nargin>5 
        barGroups(SMatrix,results,groups,params,epochs,indivFlag)
    else
        barGroups(SMatrix,results,groups,params,epochs)
    end   

end



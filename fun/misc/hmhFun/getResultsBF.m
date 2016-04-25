function results = getResultsBF(SMatrix,groups,plotFlag,indivFlag)

params={'SlowLeg', 'FastLeg'};

% define number of points to use for calculating values
catchNumPts = 3; %catch
steadyNumPts = 40; %end of adaptation
transientNumPts = 5; %OG and Washout

if nargin<3 || isempty(groups)
    groups=fields(SMatrix);  %default
end
ngroups=length(groups);


% Initialize values to calculate
results.BFafter1.avg=[];
results.BFafter1.se=[];

results.BFafter2.avg=[];
results.BFafter2.se=[];

results.MapShort.avg=[];
results.MapShort.se=[];

results.MapMid.avg=[];
results.MapMid.se=[];

results.MapLong.avg=[];
results.MapLong.se=[];


for g=1:ngroups
    
    % get subjects in group
    subjects=SMatrix.(groups{g}).ID;
    
    BFafter1=[];
    BFafter2=[];
    MapShort=[];
    MapMid=[];
    MapLong=[];
    
    for s=1:length(subjects)
        % load subject
        DATA=load([subjects{s} '_PerceptionBF_day.mat']);
        eval(['DATA=DATA.' subjects{s} ';']);
        
        [rhits, lhits, rts, lts, color]=getHits(DATA);
        
        RDATA=[];
        LDATA=[];
        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        %organize the data
        PossibleTarget=unique(rts{1});
        LLL=max(PossibleTarget);
        SS=min(PossibleTarget);
        MM=median(PossibleTarget);
        
        for z = 1:length(rts)
            
            for t=1:length(rts{z})
                if rts{z}(t)==LLL
                    RDATA(t)=3;
                elseif rts{z}(t)==SS
                    RDATA(t)=1;
                elseif rts{z}(t)==MM
                    RDATA(t)=2;
                else
                    break
                end
            end
            
            for t=1:length(lts{z})
                if lts{z}(t)==LLL
                    LDATA(t)=3;
                elseif lts{z}(t)==SS
                    LDATA(t)=1;
                elseif lts{z}(t)==MM
                    LDATA(t)=2;
                else
                    break
                end
            end
            
            t=1;
            r=1;
            RR{z}=[0, 0, 0];
            while t<length(rts{z})
                RR{z}(r, RDATA(t))=mean(rhits{z}(t:(find(RDATA(t:end)~=RDATA(t),1, 'first')+t-2)));
                if isnan(RR{z}(r, RDATA(t)))
                    RR{z}(r, RDATA(t))=mean(rhits{z}(t:end));
                end
                t=find(RDATA(t:end)~=RDATA(t),1, 'first')+t-1;
                if isempty(t)
                    t=length(rts{z});
                end
                if  RR{z}(r, RDATA(t))~=0;
                    r=r+1;
                end
            end
            t=1;
            r=1;
            LL{z}=[0, 0, 0];
            while t<length(lts{z})
                LL{z}(r, LDATA(t))=mean(lhits{z}(t:(find(LDATA(t:end)~=LDATA(t),1, 'first')+t-2)));
                if isnan(LL{z}(r, LDATA(t)))
                    LL{z}(r, LDATA(t))=mean(lhits{z}(t:end));
                end
                t=find(LDATA(t:end)~=LDATA(t),1, 'first')+t-1;
                if isempty(t)
                    t=length(lts{z});
                end
                if  LL{z}(r,LDATA(t))~=0;
                    r=r+1;
                end
            end
            clear RDATA LDATA
        end
        DDR{1}=RR{4}-RR{3};% Error Clamp
        DDR{2}=nanmean(RR{5}-RR{2}); %Map
        
        DDL{1}=LL{4}-LL{3};
        DDL{2}=nanmean(LL{5}-LL{2});
        
        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if DATA.fastleg=='r'
            %Order independent
            MapShort=[MapShort; DDL{2}(1, 1) DDR{2}(1, 1)];
            MapMid=[MapMid; DDL{2}(1, 2) DDR{2}(1, 2)];
            MapLong=[MapLong; DDL{2}(1, 3) DDR{2}(1, 3)];
            %Order Dependent
            if rts{3}(1)==SS
                BFafter1=[BFafter1; DDL{1}(1, 1) DDR{1}(1, 1)];
                BFafter2=[BFafter2; DDL{1}(1, 3) DDR{1}(1, 3)];
            else
                BFafter1=[BFafter1; DDL{1}(1, 3) DDR{1}(1, 3)];
                BFafter2=[BFafter2; DDL{1}(1, 1) DDR{1}(1, 1)];
            end
        elseif DATA.fastleg=='l'
            %Order independent
            MapShort=[MapShort; DDR{2}(1, 1) DDL{2}(1, 1)];
            MapMid=[MapMid; DDR{2}(1, 2) DDL{2}(1, 2)];
            MapLong=[MapLong; DDR{2}(1, 3) DDL{2}(1, 3)];
            %Order Dependent
            if rts{3}(1)==SS
                BFafter1=[BFafter1; DDR{1}(1, 1) DDL{1}(1, 1)];
                BFafter2=[BFafter2; DDR{1}(1, 3) DDL{1}(1, 3)];
            else
                BFafter1=[BFafter1; DDR{1}(1, 3) DDL{1}(1, 3)];
                BFafter2=[BFafter2; DDR{1}(1, 1) DDL{1}(1, 1)];
            end
        else
            cprintf('err','WARNING: Which leg is fast????');
        end
        
        
        
    end
    
    nSubs=length(subjects);
    
    results.BFafter1.avg(end+1,:)=nanmean(BFafter1,1);
    results.BFafter1.se(end+1,:)=nanstd(BFafter1,1)./sqrt(nSubs);
    
    results.BFafter2.avg(end+1,:)=nanmean(BFafter2,1);
    results.BFafter2.se(end+1,:)=nanstd(BFafter2,1)./sqrt(nSubs);
    
    results.MapShort.avg(end+1,:)=nanmean(MapShort,1);
    results.MapShort.se(end+1,:)=nanstd(MapShort,1)./sqrt(nSubs);
    
    results.MapMid.avg(end+1,:)=nanmean(MapMid,1);
    results.MapMid.se(end+1,:)=nanstd(MapMid,1)./sqrt(nSubs);
    
    results.MapLong.avg(end+1,:)=nanmean(MapLong,1);
    results.MapLong.se(end+1,:)=nanstd(MapLong,1)./sqrt(nSubs);
    
    
    if g==1 %This seems ridiculous, but I don't know of another way to do it without making MATLAB mad. The results.(whatever).indiv structure needs to be in this format to make life easier for using SPSS
        for p=1:length(params)
            results.BFafter1.indiv.(params{p})=[g*ones(nSubs,1) BFafter1(:,p)];
            results.BFafter2.indiv.(params{p})=[g*ones(nSubs,1) BFafter2(:,p)];
            results.MapShort.indiv.(params{p})=[g*ones(nSubs,1) MapShort(:,p)];
            results.MapMid.indiv.(params{p})=[g*ones(nSubs,1) MapMid(:,p)];
            results.MapLong.indiv.(params{p})=[g*ones(nSubs,1) MapLong(:,p)];
        end
    else
        for p=1:length(params)
            results.BFafter1.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) BFafter1(:,p)];
            results.BFafter2.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) BFafter2(:,p)];
            results.MapShort.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) MapShort(:,p)];
            results.MapMid.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) MapMid(:,p)];
            results.MapLong.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) MapLong(:,p)];
        end
    end
end

%stats
resultNames=fieldnames(results);
%if StatFlag==1
for h=1:length(resultNames)
    for i=1:size(results.BFafter1.avg, 2)%size(StatReady, 2)
        [~, results.(resultNames{h}).p(i)]=ttest(results.(resultNames{h}).indiv.(params{i})(:, 2));
    end
end


%plot stuff
if plotFlag
    epochs={'BFafter1','BFafter2', 'MapShort', 'MapMid', 'MapLong'};
    if nargin>3 %I imagine there has to be a better way to do this...
        barGroups(SMatrix,results,groups,params,epochs,indivFlag)
    else
        barGroups(SMatrix,results,groups,params,epochs)
    end
end



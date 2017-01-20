function results = getResults(Study,params,groups,maxPerturb,plotFlag,indivFlag)

% define number of points to use for calculating values
catchNumPts = 5; %catch
steadyNumPts = 40; %end of adaptation
transientNumPts = 5; %OG and Washout

nParams=length(params);

if nargin<3 || isempty(groups)
    groups=fields(Study);  %default
end
nGroups=length(groups);

if nargin<5 || isempty(plotFlag)
    plotFlag=1;
end

% Initialize outcome measures to compute
outcomeMeasures =...
    {'OGbase',...% 
    'TMbase',...
    'AvgAdaptBeforeCatch',...
    'AvgAdaptAll',...
    'ErrorsOut',...
    'AdaptExtentBeforeCatch',...
    'Catch',...
    'AdaptIndex',...
    'OGafter',... %First 5 strides
    'OGafterEarly',... %From 6 to 20
    'OGafterLate',...
    'AvgOGafter'...
    'TMafter',...
    'TMafterEarly',...
    'TMafterLate',...
    'Transfer',...
    'Washout',...
    'Washout2',...
    'Transfer2',...
    };


for i =1:length(outcomeMeasures)
    results.(outcomeMeasures{i}).avg=NaN(nGroups,nParams);
    results.(outcomeMeasures{i}).se=NaN(nGroups,nParams);
end


for g=1:nGroups
    
    % get number of subjects in group
    nSubs=length(Study.(groups{g}).ID);
    
    % clear/initialize measures
    for i=1:length(outcomeMeasures)
        eval([outcomeMeasures{i} '=NaN(nSubs,nParams);'])
    end
    
    AdaptExtent=[];
    
    for s=1:nSubs
        % load subject
        adaptData=Study.(groups{g}).adaptData{s};
        
        % remove baseline bias
        adaptData=adaptData.removeBadStrides;
        adaptData.data.Data= medfilt1(adaptData.data.Data);
        adaptData=adaptData.removeBias;
        
        if nargin>3 && maxPerturb==1
            
            % compute TM and OG base in same manner as calculating OG after and TM after
            if nansum(cellfun(@(x) strcmp(x, 'OG base'), adaptData.metaData.conditionName))==1
                stepAsymData=adaptData.getParamInCond('stepLengthAsym','OG base');
                OGbaseData=adaptData.getParamInCond(params,'OG base');
                OGbase(s,:)=smoothedMax(OGbaseData(1:10,:),transientNumPts,stepAsymData(1:10));
            end
            
            stepAsymData=adaptData.getParamInCond('stepLengthAsym','TM base');
            TMbaseData=adaptData.getParamInCond(params,'TM base');
            if isempty(TMbaseData)
                stepAsymData=adaptData.getParamInCond('stepLengthAsym',{'slow base','fast base'});
                TMbaseData=adaptData.getParamInCond(params,{'slow base','fast base'});
            end
            TMbase(s,:)=smoothedMax(TMbaseData(1:10,:),transientNumPts,stepAsymData(1:10));
            
            % compute catch as mean value during strides which caused a
            % maximum deviation from zero during 'catchNumPts' consecutive
            % strides
            if nansum(cellfun(@(x) strcmp(x, 'catch'), lower(adaptData.metaData.conditionName)))==1
                stepAsymData=adaptData.getParamInCond('stepLengthAsym','catch');
                tmcatchData=adaptData.getParamInCond(params,'catch');
                Catch(s,:)=smoothedMax(tmcatchData,catchNumPts,stepAsymData);
            end
            
            
            % compute OG after as mean values during strides which cause a
            % maximum deviation from zero in STEP LENGTH ASYMMETRY during
            % 'transientNumPts' consecutive strides within first 10 strides
            if nansum(cellfun(@(x) strcmp(x, 'OG post'), adaptData.metaData.conditionName))==1
                stepAsymData=adaptData.getParamInCond('stepLengthAsym','OG post');
                ogafterData=adaptData.getParamInCond(params,'OG post');
                OGafter(s,:)= smoothedMax(ogafterData(1:10,:),transientNumPts,stepAsymData(1:10));
            end
            
            % compute TM after-effects same as OG after-effect
            stepAsymData=adaptData.getParamInCond('stepLengthAsym','TM post');
            tmafterData=adaptData.getParamInCond(params,'TM post');
            TMafter(s,:)= smoothedMax(tmafterData(1:10,:),transientNumPts,stepAsymData(1:10));
            
        else
            
            % calculate TM and OG base in same manner as calculating OG after and TM after
            if nansum(cellfun(@(x) strcmp(x, 'OG base'), adaptData.metaData.conditionName))==1
                OGbaseData=adaptData.getParamInCond(params,'OG base');
                OGbase(s,:)= nanmean(OGbaseData(1:transientNumPts,:));
            end
            
            if nansum(cellfun(@(x) strcmp(x, 'TM base'), adaptData.metaData.conditionName))==1
                TMbaseData=adaptData.getParamInCond(params,'TM base');
                if isempty(TMbaseData)
                    TMbaseData=adaptData.getParamInCond(params,{'slow base','fast base'});
                end
                TMbase(s,:)=nanmean(TMbaseData(1:transientNumPts,:));
            end
            
            % compute catch
            if nansum(cellfun(@(x) strcmp(x, 'catch'), lower(adaptData.metaData.conditionName)))==1
                tmcatchData=adaptData.getParamInCond(params,'catch');
                if isempty(tmcatchData)
                    newtmcatchData=NaN(1,nParams);
                elseif size(tmcatchData,1)<3
                    newtmcatchData=nanmean(tmcatchData);
                else
                    newtmcatchData=nanmean(tmcatchData(1:catchNumPts,:));
                    %newtmcatchData=nanmean(tmcatchData);
                end
                Catch(s,:)=newtmcatchData;
            end
            
            % compute OG post
            if nansum(cellfun(@(x) strcmp(x, 'OG post'), adaptData.metaData.conditionName))==1
                ogafterData=adaptData.getParamInCond(params,'OG post');
                OGafter(s,:)=nanmean(ogafterData(1:transientNumPts,:));
                OGafterEarly(s,:)=nanmean(ogafterData(transientNumPts+1:transientNumPts+20,:));
                OGafterLate(s,:)=nanmean(ogafterData((end-5)-steadyNumPts+1:(end-5),:)); %Last strides
                
                %Sum of OG after-effects
                AvgOGafter(s,:)=mean(ogafterData(1:min([end 50])));
            end
            
            % compute TM post
            if nansum(cellfun(@(x) strcmp(x, 'TM post'), adaptData.metaData.conditionName))==1
                tmafterData=adaptData.getParamInCond(params,'TM post');
                TMafter(s,:)=nanmean(tmafterData(1:transientNumPts,:));
                TMafterEarly(s,:)=nanmean(tmafterData(transientNumPts+1:transientNumPts+20,:));
                TMafterLate(s,:)=nanmean(tmafterData((end-5)-steadyNumPts+1:(end-5),:));
            end
        end
        
        
        if nansum(cellfun(@(x) strcmp(x, 'catch'), lower(adaptData.metaData.conditionName)))==1
            % compute TM steady state before catch (mean of first transinetNumPts of last transinetNumPts+5 strides)
            adapt1Data=adaptData.getParamInCond(params,'adaptation');
            adapt1Velocity=adaptData.getParamInCond('velocityContributionNorm2','adaptation');
            
            %       StartAdapt(s,:)=nanmean(adapt1Data(1:transientNumPts,:));
            AdaptExtentBeforeCatch(s,:)=nanmean(adapt1Data((end-5)-transientNumPts+1:(end-5),:)); %Few strides before catch
            
            %start of step length = end of velocityCont
            idx = find(strcmpi(params, 'stepLengthAsym'));
            if isempty(idx)
                idx = find(strcmpi(params, 'netContributionNorm2'));
            end
            if ~isempty(idx)
                AdaptExtentBeforeCatch(s,idx)=AdaptExtentBeforeCatch(s,idx)-nanmean(adapt1Velocity((end-2)-transientNumPts+1:(end-2),:));
            end
            
            % compute average adaptation value before the catch
            AvgAdaptBeforeCatch(s,:)= nanmean(adapt1Data);
        end
        
        %
        
        % compute TM steady state before OG walking (mean of first steadyNumPts of last steadyNumPts+5 strides)
        adapt2Data=[];
        if nansum(cellfun(@(x) strcmp(x, 're-adaptation'), lower(adaptData.metaData.conditionName)))==1
            adapt2Data=adaptData.getParamInCond(params,'re-adaptation');
            adapt2Sasym=adaptData.getParamInCond('stepLengthAsym','re-adaptation');
            adapt2Velocity=adaptData.getParamInCond('velocityContributionNorm2','re-adaptation');
        elseif isempty(adapt2Data)
            adapt2Data=adaptData.getParamInCond(params,{'adaptation'});
            adapt2Sasym=adaptData.getParamInCond('stepLengthAsym','adaptation');
            adapt2Velocity=adaptData.getParamInCond('velocityContributionNorm2','adaptation');
        end
        
        
        AdaptIndex(s,:)= nanmean(adapt2Data((end-5)-steadyNumPts+1:(end-5),:)); %last 40 straides of adaptation
        
        idx = find(strcmpi(params, 'stepLengthAsym'));
        if isempty(idx)
            idx = find(strcmpi(params, 'netContributionNorm2'));
        end
        if ~isempty(idx)
            AdaptIndex(s,idx)=nanmean(adapt2Sasym((end-5)-steadyNumPts+1:(end-5),:)-adapt2Velocity((end-5)-steadyNumPts+1:(end-5),:));
        end
        
        AdaptExtent(s,:)=nanmean(adapt2Sasym((end-5)-steadyNumPts+1:(end-5),:)-adapt2Velocity((end-5)-steadyNumPts+1:(end-5),:));
        
        
        
        
        % compute average adaptation of all adaptation walking (both
        % before and after catch)
        adaptAllData=adaptData.getParamInCond(params,{'adaptation','re-adaptation'});
        AvgAdaptAll(s,:)= nanmean(adaptAllData);
        
        % Calculate Errors outside of baseline during adaptation
        mu=nanmean(TMbaseData);
        sigma=nanstd(TMbaseData);
        upper=mu+2.*sigma;
        lowerb=mu-2.*sigma;
        for i=1:nParams
            outside(i)=sum(adapt1Data(:,i)>upper(i) | adapt1Data(:,i)<lowerb(i));
        end
        ErrorsOut(s,:)= 100.*(outside./size(adapt1Data,1));
    end
    


% compute extent of adaptation as difference between start and end
%     AdaptExtentBeforeCatch=TMsteadyBeforeCatch-StartAdapt;
%     AdaptExtent=TMsteady-StartAdapt;

%calculate relative after-effects
if nansum(cellfun(@(x) strcmp(x, 'OG post'), adaptData.metaData.conditionName))==1 && nansum(cellfun(@(x) strcmp(x, 'adaptation'), lower(adaptData.metaData.conditionName)))==1 || nansum(cellfun(@(x) strcmp(x, 're-adaptation'), lower(adaptData.metaData.conditionName)))==1
    idx = find(strcmpi(params, 'stepLengthAsym'));
    if isempty(idx)
        idx = find(strcmpi(params, 'netContributionNorm2'));
    end
    if ~isempty(idx)
        Transfer= 100*(OGafter./(Catch(:,idx)*ones(1,nParams)));
    else
        Transfer= 100*(OGafter./Catch);
    end
    Transfer2= 100*(OGafter./(AdaptExtent*ones(1,nParams)));
end

if nansum(cellfun(@(x) strcmp(x, 'adaptation'), lower(adaptData.metaData.conditionName)))==1 || nansum(cellfun(@(x) strcmp(x, 're-adaptation'), lower(adaptData.metaData.conditionName)))==1
    idx = find(strcmpi(params, 'stepLengthAsym'));
    if isempty(idx)
        idx = find(strcmpi(params, 'netContributionNorm2'));
    end
    if ~isempty(idx)
        Washout= 100*(1-(TMafter./(Catch(:,idx)*ones(1,nParams))));
    else
        Washout = 100*(1-(TMafter./Catch));
    end
    Washout2= 100-(100*(TMafter./(AdaptExtent*ones(1,nParams))));
end


for j=1:length(outcomeMeasures)
    eval(['results.(outcomeMeasures{j}).avg(g,:)=nanmean(' outcomeMeasures{j} ',1);']);
    eval(['results.(outcomeMeasures{j}).se(g,:)=nanstd(' outcomeMeasures{j} './sqrt(nSubs));']);
end

if g==1 %This seems ridiculous, but I don't know of another way to do it without making MATLAB mad.
    
    if plotFlag
        for p=1:nParams
            for m = 1:length(outcomeMeasures)
                eval(['results.(outcomeMeasures{m}).indiv.(params{p}) = [g*ones(nSubs,1) ' outcomeMeasures{m} '(:,p)];'])
            end
        end
    else
        %for stats
        for m=1:length(outcomeMeasures)
            %The results.(whatever).indiv structure needs to be in this format to make life easier for using SPSS
            eval(['results.(outcomeMeasures{m}).indiv=[g*ones(nSubs,1) ' outcomeMeasures{m} '];'])
        end
    end
    
else
    if plotFlag
        for p=1:nParams
            for m = 1:length(outcomeMeasures)
                eval(['results.(outcomeMeasures{m}).indiv.(params{p})(end+1:end+nSubs,1:2) = [g*ones(nSubs,1) ' outcomeMeasures{m} '(:,p)];'])
            end
        end
    else
        %for stats
        for m=1:length(outcomeMeasures)
            eval(['results.(outcomeMeasures{m}).indiv(end+1:end+nSubs,:)=[g*ones(nSubs,1) ' outcomeMeasures{m} '];'])
        end
    end
    
end
end

%plot stuff
if plotFlag
    
    %     % FIRST: plot baseline values against catch and transfer
    %     epochs={'AdaptExtent','Catch','OGafter','TMafter'};
    %     if nargin>5 %I imagine there has to be a better way to do this...
    %         barGroups(Study,results,groups,params,epochs,indivFlag)
    %     else
    %         barGroups(Study,results,groups,params,epochs)
    %     end
    
    %     % SECOND: plot average adaptation values?
    %     epochs={'AvgAdaptBeforeCatch','TMsteadyBeforeCatch','AvgAdaptAll','TMsteady'};
    %     if nargin>5
    %         barGroups(SMatrix,results,groups,params,epochs,indivFlag)
    %     else
    %         barGroups(SMatrix,results,groups,params,epochs)
    %     end
    
    %     % SECOND: plot average adaptation values?
    %     epochs={'AvgAdaptAll','TMsteady','catch','Transfer'};
    %     if nargin>5
    %         barGroups(SMatrix,results,groups,params,epochs,indivFlag)
    %     else
    %         barGroups(SMatrix,results,groups,params,epochs)
    %     end
end




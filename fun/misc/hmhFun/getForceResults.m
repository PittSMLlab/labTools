function results = getForceResults( SMatrix,params,groups,maxPerturb,plotFlag,indivFlag, removeBias )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% define number of points to use for calculating values
catchNumPts = 3; %catch
steadyNumPts = 40; %end of adaptation
transientNumPts = 5; %OG and Washout

if nargin<3 || isempty(groups)
    groups=fields(SMatrix);  %default
end
ngroups=length(groups);

% Initialize values to calculate
results.DelFAdapt.avg=[];
results.DelFAdapt.se=[];

results.DelFDeAdapt.avg=[];
results.DelFDeAdapt.se=[];

results.TMSteady.avg=[];
results.TMSteady.se=[];

results.TMafter.avg=[];
results.TMafter.se=[];

results.TMSteadyWBias.avg=[];
results.TMSteadyWBias.se=[];

results.TMafterWBias.avg=[];
results.TMafterWBias.se=[];

results.SlowBase.avg=[];
results.SlowBase.se=[];

results.FastBase.avg=[];
results.FastBase.se=[];

results.MidBase.avg=[];
results.MidBase.se=[];

results.BaseAdapDiscont.avg=[];
results.BaseAdapDiscont.se=[];

results.BasePADiscont.avg=[];
results.BasePADiscont.se=[];

results.SpeedAdapDiscont.avg=[];
results.SpeedAdapDiscont.se=[];

results.SpeedSSDiscont.avg=[];
results.SpeedSSDiscont.se=[];

results.SpeedPADiscont.avg=[];
results.SpeedPADiscont.se=[];

results.EarlyA.avg=[];
results.EarlyA.se=[];

results.LateP.avg=[];
results.LateP.se=[];

results.Washout2.avg=[];
results.Washout2.se=[];

results.FlatWash.avg=[];
results.FlatWash.se=[];

results.PLearn.avg=[];
results.PLearn.se=[];

results.lenA.avg=[];
results.lenA.se=[];

for g=1:ngroups
    
    % get subjects in group
    subjects=SMatrix.(groups{g}).ID;
    
    DelFAdapt=[];
    DelFDeAdapt=[];
    FBase=[];
    SBase=[];
    MBase=[];
    TMSteady=[];
    tmafter=[];
    BaseAdapDiscont=[];
    BasePADiscont=[];
    TMSteadyWBias=[];
    tmafterWBias=[];
    SpeedAdapDiscont=[];
    SpeedPADiscont=[];
    EarlyA=[];
    LateP=[];
    washout2=[];
    FlatWash=[];
    plearn=[];
    lenA=[];
    SpeedSSDiscont=[];
    for s=1:length(subjects)
        % load subject
        adaptData=SMatrix.(groups{g}).adaptData{s};
        
        % remove baseline bias
        adaptData=adaptData.removeBadStrides;
                %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% %         if  ~exist('removeBias') || removeBias==1
% %             adaptData=adaptData.removeBiasV3;
% %         end
        nSubs=length(subjects);
        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        %%Calculate Params
        %Paramerters with the BIAS included~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        AANamesWBias=adaptData.metaData.conditionName(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), 'ada'))), 1, 'first'));
        ADataWBias=adaptData.getParamInCond(params, AANamesWBias);
        
     
        
        if strcmp(groups(g), 'InclineStroke')
            EarlyPANamesWBias=adaptData.metaData.conditionName(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), 'catch')))));
            LatePANamesWBias=adaptData.metaData.conditionName(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), 'TM base')))));
            PDataEarlyWBias=adaptData.getParamInCond(params,EarlyPANamesWBias);
            PDataLateWBias=adaptData.getParamInCond(params,LatePANamesWBias);
        else
            PANamesWBias=adaptData.metaData.conditionName(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), 'ada'))), 1, 'first')+1);
            if strcmp(PANamesWBias, 'catch')
                PANamesWBias=adaptData.metaData.conditionName(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), 'ada'))), 2, 'first')+1);
            end
            PDataWBias=adaptData.getParamInCond(params,PANamesWBias);
        end
% %         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%         if  ~exist('removeBias') || removeBias==1
%             adaptData=adaptData.removeBiasV3;
%         end
%         nSubs=length(subjects);
%         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        if isempty(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), 'fast')))))
            FBaseData=NaN*ones(1,length(params));
        else
            FBaseData=adaptData.getParamInCond(params,'fast');
        end
        
        if isempty(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), 'slow')))))
            SBaseData=NaN*ones(1,length(params));
        else
            SBaseData=adaptData.getParamInCond(params,'slow');
        end
        
        if isempty(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), 'tm base')))))
            MBaseData=NaN*ones(1,length(params));
        else
            MBaseData=adaptData.getParamInCond(params,'TM base');
        end
        
        
% % %         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if  ~exist('removeBias') || removeBias==1
            adaptData=adaptData.removeBiasV3;
        end
        nSubs=length(subjects);
% % %         
% % %         %%Calculate Params
        
        %Adaptation Paramerters~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        AANames=adaptData.metaData.conditionName(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), 'ada'))), 1, 'first'));
        AData=adaptData.getParamInCond(params, AANames);
        EarlyA=[EarlyA; nanmean(AData(1:20,:))];%New WAY
        %EarlyA=[EarlyA; nanmean(AData(1:5,:))];%NORMAL WAY
        %tempTT=adaptData.getParamInCond(params,'TM base');
lenA=[lenA; length(AData).*ones(1, length(params))];
        %          %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%         EarlyAtemp=[]; %New and probably temporary!
%         figure
%         for cat=1:length(params)
%             MedData=medfilt1(AData(:, cat), 10);
%             if strcmp(params(cat), 'FyBF')==1 || (strcmp(params(cat), 'FyPS')==1 && strcmp(groups{g}, 'DeclineYoungAbrupt')==1) || (strcmp(params(cat), 'FyPS')==1 && strcmp(groups{g}, 'FlatYoungAbrupt')==1) 
% %                 subplot(2, 2, cat);
% %                 line([0 700],[nanmean(AData((end-5)-steadyNumPts+1:(end-5),cat)) nanmean(AData((end-5)-steadyNumPts+1:(end-5),cat))], 'Color', 'g', 'LineWidth', 5); hold on;
% %                 plot(AData(:, cat), '.k');
% %                 plot(MedData, 'r');
%                 EarlyAtemp=[EarlyAtemp max(MedData(5:100))];
% %                 line([0 700],[max(MedData(5:100)) max(MedData(5:100))],'Color', 'b');
% %                 line([0 700],[nanmean(AData(1:20,cat)) nanmean(AData(1:20,cat))],'Color', 'k', 'LineStyle',':');
% %                 title([subjects{s} params(cat) 'maxed'])
% %                 legend({'SS', 'Raw', 'Median filtered', 'Early', 'old Early'})
%             elseif strcmp(params(cat), 'FyBS')==1  || strcmp(params(cat), 'FyPF')==1 || (strcmp(params(cat), 'FyPS')==1 && strcmp(groups{g}, 'InclineYoungAbrupt')==1)
% %                 subplot(2, 2, cat);line([0 700],[nanmean(AData((end-5)-steadyNumPts+1:(end-5),cat)) nanmean(AData((end-5)-steadyNumPts+1:(end-5),cat))], 'Color', 'g', 'LineWidth', 5); hold on;
% %                 plot(AData(:, cat), '.k');
% %                 plot(MedData, 'r');
%                 EarlyAtemp=[EarlyAtemp min(MedData(5:100))];
% %                 line([0 700],[min(MedData(5:100)) min(MedData(5:100))],'Color', 'b');
% %                 line([0 700],[nanmean(AData(1:20,cat)) nanmean(AData(1:20,cat))],'Color', 'k', 'LineStyle',':');
% %                 title([subjects{s} params(cat) 'mined'])
%             end
%             
%             clear MedData
%         end
%         EarlyA=[EarlyA; EarlyAtemp];
%         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%          %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%         EarlyAtemp=[]; %New and probably temporary!
%         for cat=1:length(params)
%             EarlyAtemp=[EarlyAtemp smoothedMin(abs(AData(1:50, cat)),transientNumPts )];%NOT REALLY SURE IF THIS SHOULD ALWAYS BE MIN
%         end
%         EarlyA=[EarlyA; EarlyAtemp];
%         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        %AData=adaptData.getParamInCond(params,'adaptation');
        %DelFAdapt=[DelFAdapt; nanmean(AData((end-5)-steadyNumPts+1:(end-5),:))-nanmean(AData(6:6+transientNumPts,:))];
        %DelFAdapt=[DelFAdapt; nanmean(AData(end-44:end-5, :))-nanmean(AData(1:5,:))];%OLD
        %DelFAdapt=[DelFAdapt; nanmean(AData(end-44:end-5, :))-EarlyA(s, :)];%NEW
        %TMSteady=[TMSteady; nanmean(AData(end-44:end-5, :))];%OROGNOAL
        
        TMSteady=[TMSteady; nanmean(AData((end-5)-steadyNumPts+1:(end-5),:))];
        %DelFAdapt=[DelFAdapt; nanmean(AData((end-5)-steadyNumPts+1:(end-5),:))-EarlyA(s, :)];%NEW
        DelFAdapt=[DelFAdapt; TMSteady(s, :)-EarlyA(s, :)];%NEW
        TMSteadyWBias=[TMSteadyWBias; nanmean(ADataWBias(end-44:end-5, :))];
       

        
        %Post-Adaptation Paramerters~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        if strcmp(groups(g), 'InclineStroke')
            EarlyPANames=adaptData.metaData.conditionName(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), 'catch')))));
            LatePANames=adaptData.metaData.conditionName(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), 'TM base')))));
            %CJS --> Where I ought to code transfer if I want to look at
            %this...
            PDataEarly=adaptData.getParamInCond(params,EarlyPANames);
            PDataLate=adaptData.getParamInCond(params,LatePANames);
            DelFDeAdapt=[DelFDeAdapt; nanmean(PDataLate(end-44:end-5, :))-nanmean(PDataEarly(1:5,:))];
            %DelFDeAdapt=[DelFDeAdapt; nanmean(PDataLate(end-44:end-5, :))-nanmean(PDataEarly(1:20,:))];
% %             DelFDeAdapt=[DelFDeAdapt; nanmean(PDataLate(6:end-4, :))-nanmean(PDataEarly(1:5,:))];
% %             %DelFDeAdapt=[DelFDeAdapt; nanmean(PDataLate(6:end-4, :))-nanmean(PDataEarly(1:20,:))];
        else
            PANames=adaptData.metaData.conditionName(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), 'ada'))), 1, 'first')+1);
            if strcmp(PANames, 'catch')
                PANames=adaptData.metaData.conditionName(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), 'ada'))), 2, 'first')+1);
            end
            PData=adaptData.getParamInCond(params,PANames);
            %PData=adaptData.getParamInCond(params,'TM post');
            DelFDeAdapt=[DelFDeAdapt; nanmean(PData(end-44:end-5, :))-nanmean(PData(1:5,:))];
            %DelFDeAdapt=[DelFDeAdapt; nanmean(PData(end-44:end-5, :))-nanmean(PData(1:20,:))];
        end
        tmafter=[tmafter; nanmean(PData(1:5, :))];%NORMAL WAY
% %         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%         tmaftertemp=[]; %New and probably temporary!
%         for cat=1:length(params)
%             tmaftertemp=[tmaftertemp smoothedMax(abs(PData(1:50, cat)),transientNumPts )];
%         end
%         tmafter=[tmafter; tmaftertemp];
% %         %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        tmafterWBias=[tmafterWBias; nanmean(PDataWBias(1:5, :))];
        LateP=[LateP; nanmean(PData(end-44:end-5, :))];
        
        
         
         
         %If inclince decline then flat post -- NEw
         if ~isempty(find(cellfun(@(x) ~isempty(x),(regexp(lower(adaptData.metaData.conditionName), lower('flat post'))))))
             FlatWashoutData=adaptData.getParamInCond(params,'flat post');
             FlatWash=[FlatWash; nanmean(FlatWashoutData(1:transientNumPts,:))];
         else
             FlatWash=[FlatWash; NaN.*ones(1, length(params))];
         end
         
         %Baseline Adaptation Paramerters~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        FBase=[FBase; nanmean(FBaseData(6:end-4, :))];
        SBase=[SBase; nanmean(SBaseData(6:end-4, :))];
        MBase=[MBase; nanmean(MBaseData(6:end-4, :))];
% %         FBase=[FBase; nanmean(FBaseData((end-5)-steadyNumPts+1:(end-5), :))];
% %         SBase=[SBase; nanmean(SBaseData((end-5)-steadyNumPts+1:(end-5), :))];
% %         MBase=[MBase; nanmean(MBaseData((end-5)-steadyNumPts+1:(end-5), :))];
        
        
        BaseAdapDiscont=[BaseAdapDiscont; nanmean(AData(1:5,:))-nanmean(MBaseData(6:end-4, :))];
        BasePADiscont=[BasePADiscont; nanmean(PData(1:5,:))-nanmean(MBaseData(6:end-4, :))];
        
        fast=find(strcmp(params, {'FyPF'})+strcmp(params, {'FyBF'})+strcmp(params, {'XFast'}));
        slow=find(strcmp(params, {'FyPS'})+strcmp(params, {'FyBS'})+strcmp(params, {'XSlow'}));
        speedBias=[];
        speedPABias=[];
        for w=1:length(fast)
            speedBias(fast(w))=FBase(s, fast(w));
            speedPABias(fast(w))=SBase(s, fast(w));
        end
        for w=1:length(slow)
            speedBias(slow(w))=SBase(s, slow(w));
            speedPABias(slow(w))=FBase(s, slow(w));
        end
        if length(speedBias)<length(params)
            speedBias=[speedBias zeros(1, length(params)-length(speedBias))];
        end
        %SpeedAdapDiscont=[SpeedAdapDiscont; nanmean(ADataWBias(end-44:end-5, :))-speedBias];
        SpeedAdapDiscont=[SpeedAdapDiscont; nanmean(ADataWBias(1:5, :))-speedBias];
        SpeedPADiscont=[SpeedPADiscont; nanmean(PDataWBias(1:5, :))-speedBias];
        %TMSteady=[TMSteady; nanmean(ADataWBias(end-44:end-5, :))-speedBias];
        %SpeedSSDiscont=[SpeedSSDiscont; nanmean(AData((end-5)-steadyNumPts+1:(end-5),:))-speedBias];
        SpeedSSDiscont=[SpeedSSDiscont; nanmean(ADataWBias((end-5)-steadyNumPts+1:(end-5),:))-speedBias];
        
        clear speedBias
        %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    end
    
    Breaking=find(strcmp(params, {'FyBS'})+strcmp(params, {'FyBF'}));
    if ~isempty(Breaking)
        DelFAdapt(:, Breaking)=-1.*DelFAdapt(:, Breaking);
        DelFDeAdapt(:, Breaking)=-1.*DelFDeAdapt(:, Breaking);
        
        %             if ~all(all(isnan(FBase))) && ~all(all(isnan(SBase))) && ~all(all(isnan(MBase)))
        %             FBase(:, Breaking)=-1.*FBase(:, Breaking);
        %             SBase(:, Breaking)=-1.*SBase(:, Breaking);
        %             MBase(:, Breaking)=-1.*MBase(:, Breaking);
        %             end
        
        % TMSteady(:, Breaking)=-1.*TMSteady(:, Breaking);
        
    end
    
        washout2=[washout2; 100-(100*(tmafter./TMSteady))];
        plearn=[plearn; (100*(tmafter./TMSteady))];
        
    % Initialize values to calculate
    results.DelFAdapt.avg(end+1,:)=nanmean(DelFAdapt,1);
    results.DelFAdapt.se(end+1,:)=nanstd(DelFAdapt,1)./sqrt(nSubs);
    
    results.DelFDeAdapt.avg(end+1,:)=nanmean(DelFDeAdapt,1);
    results.DelFDeAdapt.se(end+1,:)=nanstd(DelFDeAdapt,1)./sqrt(nSubs);
    
    results.TMSteady.avg(end+1,:)=nanmean(TMSteady,1);
    results.TMSteady.se(end+1,:)=nanstd(TMSteady,1)./sqrt(nSubs);
    
    results.TMafter.avg(end+1,:)=nanmean(tmafter,1);
    results.TMafter.se(end+1,:)=nanstd(tmafter,1)./sqrt(nSubs);
    
    results.TMSteadyWBias.avg(end+1,:)=nanmean(TMSteadyWBias,1);
    results.TMSteadyWBias.se(end+1,:)=nanstd(TMSteadyWBias,1)./sqrt(nSubs);
    
    results.TMafterWBias.avg(end+1,:)=nanmean(tmafterWBias,1);
    results.TMafterWBias.se(end+1,:)=nanstd(tmafterWBias,1)./sqrt(nSubs);
    
    results.FastBase.avg(end+1,:)=nanmean(FBase,1);
    results.FastBase.se(end+1,:)=nanstd(FBase,1)./sqrt(nSubs);
    
    results.SlowBase.avg(end+1,:)=nanmean(SBase,1);
    results.SlowBase.se(end+1,:)=nanstd(SBase,1)./sqrt(nSubs);
    
    results.MidBase.avg(end+1,:)=nanmean(MBase,1);
    results.MidBase.se(end+1,:)=nanstd(MBase,1)./sqrt(nSubs);
    
    results.BaseAdapDiscont.avg(end+1,:)=nanmean(BaseAdapDiscont,1);
    results.BaseAdapDiscont.se(end+1,:)=nanstd(BaseAdapDiscont,1)./sqrt(nSubs);
    
    results.BasePADiscont.avg(end+1,:)=nanmean(BasePADiscont,1);
    results.BasePADiscont.se(end+1,:)=nanstd(BasePADiscont,1)./sqrt(nSubs);
    
    results.SpeedAdapDiscont.avg(end+1,:)=nanmean(SpeedAdapDiscont,1);
    results.SpeedAdapDiscont.se(end+1,:)=nanstd(SpeedAdapDiscont,1)./sqrt(nSubs);
    
    results.SpeedPADiscont.avg(end+1,:)=nanmean(SpeedPADiscont,1);
    results.SpeedPADiscont.se(end+1,:)=nanstd(SpeedPADiscont,1)./sqrt(nSubs);
    
    results.EarlyA.avg(end+1,:)=nanmean(EarlyA,1);
    results.EarlyA.se(end+1,:)=nanstd(EarlyA,1)./sqrt(nSubs);
    
    results.LateP.avg(end+1,:)=nanmean(LateP,1);
    results.LateP.se(end+1,:)=nanstd(LateP,1)./sqrt(nSubs);
    
       results.Washout2.avg(end+1,:)=nanmean(washout2,1);
    results.Washout2.se(end+1,:)=nanstd(washout2)./sqrt(nSubs);
    
            results.FlatWash.avg(end+1,:)=nanmean(    FlatWash,1);
    results.FlatWash.se(end+1,:)=nanstd(FlatWash)./sqrt(nSubs);
    
                results.PLearn.avg(end+1,:)=nanmean(    plearn,1);
    results.PLearn.se(end+1,:)=nanstd(plearn)./sqrt(nSubs);
    
                    results.lenA.avg(end+1,:)=nanmean(    lenA,1);
    results.lenA.se(end+1,:)=nanstd(lenA)./sqrt(nSubs);
    
                        results.SpeedSSDiscont.avg(end+1,:)=nanmean(SpeedSSDiscont,1);
    results.SpeedSSDiscont.se(end+1,:)=nanstd(SpeedSSDiscont)./sqrt(nSubs);
    
    if g==1 %This seems ridiculous, but I don't know of another way to do it without making MATLAB mad. The results.(whatever).indiv structure needs to be in this format to make life easier for using SPSS
        for p=1:length(params)
            results.DelFAdapt.indiv.(params{p})=[g*ones(nSubs,1) DelFAdapt(:,p)];
            results.DelFDeAdapt.indiv.(params{p})=[g*ones(nSubs,1) DelFDeAdapt(:,p)];
            results.FastBase.indiv.(params{p})=[g*ones(nSubs,1) FBase(:,p)];
            results.SlowBase.indiv.(params{p})=[g*ones(nSubs,1) SBase(:,p)];
            results.MidBase.indiv.(params{p})=[g*ones(nSubs,1) MBase(:,p)];
            results.TMSteady.indiv.(params{p})=[g*ones(nSubs,1) TMSteady(:,p)];
            results.TMafter.indiv.(params{p})=[g*ones(nSubs,1) tmafter(:,p)];
            results.TMSteadyWBias.indiv.(params{p})=[g*ones(nSubs,1) TMSteadyWBias(:,p)];
            results.TMafterWBias.indiv.(params{p})=[g*ones(nSubs,1) tmafterWBias(:,p)];
            results.BaseAdapDiscont.indiv.(params{p})=[g*ones(nSubs,1) BaseAdapDiscont(:,p)];
            results.BasePADiscont.indiv.(params{p})=[g*ones(nSubs,1) BasePADiscont(:,p)];
            results.SpeedAdapDiscont.indiv.(params{p})=[g*ones(nSubs,1) SpeedAdapDiscont(:,p)];
            results.SpeedPADiscont.indiv.(params{p})=[g*ones(nSubs,1) SpeedPADiscont(:,p)];
            results.EarlyA.indiv.(params{p})=[g*ones(nSubs,1) EarlyA(:,p)];
            results.LateP.indiv.(params{p})=[g*ones(nSubs,1) LateP(:,p)];
            results.Washout2.indiv.(params{p})=[g*ones(nSubs,1) washout2(:,p)];
            results.FlatWash.indiv.(params{p})=[g*ones(nSubs,1)     FlatWash(:,p)];
             results.PLearn.indiv.(params{p})=[g*ones(nSubs,1)    plearn(:,p)];
             results.lenA.indiv.(params{p})=[g*ones(nSubs,1)    lenA(:,p)];
             results.SpeedSSDiscont.indiv.(params{p})=[g*ones(nSubs,1)    SpeedSSDiscont(:,p)];
             
        end
    else
        for p=1:length(params)
            results.DelFAdapt.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) DelFAdapt(:,p)];
            results.DelFDeAdapt.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) DelFDeAdapt(:,p)];
            results.FastBase.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) FBase(:,p)];
            results.SlowBase.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) SBase(:,p)];
            results.MidBase.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) MBase(:,p)];
            results.TMSteady.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) TMSteady(:,p)];
            results.TMafter.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) tmafter(:,p)];
            results.TMSteadyWBias.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) TMSteadyWBias(:,p)];
            results.TMafterWBias.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) tmafterWBias(:,p)];
            results.BaseAdapDiscont.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) BaseAdapDiscont(:,p)];
            results.BasePADiscont.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) BasePADiscont(:,p)];
            results.SpeedAdapDiscont.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) SpeedAdapDiscont(:,p)];
             results.SpeedPADiscont.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) SpeedPADiscont(:,p)];
             results.EarlyA.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) EarlyA(:,p)];
             results.LateP.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) LateP(:,p)];
             results.Washout2.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1) washout2(:,p)];
             results.FlatWash.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1)     FlatWash(:,p)];
             results.PLearn.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1)    plearn(:,p)];
             results.lenA.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1)    lenA(:,p)];
             results.SpeedSSDiscont.indiv.(params{p})(end+1:end+nSubs,1:2)=[g*ones(nSubs,1)    SpeedSSDiscont(:,p)];
        end
    end
end
StatFlag=1;
resultNames=fieldnames(results);
indiData=[];
if ~isempty(find(strcmp(groups, 'InclineStroke'))) && ~isempty(find(strcmp(groups, 'InclineStrokeNoCatch')))
    whereArt=[find(strcmp(groups, 'InclineStroke'))  find(strcmp(groups, 'InclineStrokeNoCatch'))];
    for h=1:length(resultNames)
        indiData=[];
        for p=1:size(results.DelFAdapt.avg, 2)
            %Change the individual columns so that it shows this group as one
            Group1=find(results.(resultNames{h}).indiv.(params{p})(:, 1)==whereArt(1));
            Group2=find(results.(resultNames{h}).indiv.(params{p})(:, 1)==whereArt(2));
            results.(resultNames{h}).indiv.(params{p})([Group1; Group2], 1)=whereArt(1).*ones(length([Group1; Group2]), 1);
            indiData=[indiData  results.(resultNames{h}).indiv.(params{p})([Group1; Group2], 2)];
        end
        %change the avg and se to reflect one less group and use individual
        %data to recalculate these
        results.(resultNames{h}).avg(whereArt(1), :)=nanmean(indiData);
        results.(resultNames{h}).se(whereArt(1), :)=nanstd(indiData,1)./sqrt(length([Group1; Group2]));
        results.(resultNames{h}).avg(whereArt(2), :)=[];
        results.(resultNames{h}).se(whereArt(2), :)=[];
        %change groups
    end
    groups(whereArt(2))=[];
end


%if StatFlag==1
for h=1:length(resultNames)
    for i=1:size(results.DelFAdapt.avg, 2)%size(StatReady, 2)
        if size(results.DelFAdapt.avg, 1)==2 %Can just used a ttest, which will be PAIRED
            Group1=find(results.(resultNames{h}).indiv.(params{i})(:, 1)==1);
            Group2=find(results.(resultNames{h}).indiv.(params{i})(:, 1)==2);
            %[~, results.(resultNames{h}).p(i)]=ttest(results.(resultNames{h}).indiv.(params{i})(Group1, 2), results.(resultNames{h}).indiv.(params{i})(Group2, 2));
        else% have to do an anova
            [results.(resultNames{h}).p(i), ~, stats]=anova1(results.(resultNames{h}).indiv.(params{i})(:, 2), results.(resultNames{h}).indiv.(params{i})(:, 1), 'off');
            results.(resultNames{h}).postHoc{i}=[NaN NaN];
            if results.(resultNames{h}).p(i)<=0.05 && exist('stats')==1
                [c,~,~,gnames]=multcompare(stats, 'CType', 'lsd');
                results.(resultNames{h}).postHoc{i}=c(find(c(:,6)<=0.05), 1:2);
                %postHoc{i-1, h}=c(find(c(:,6)<=0.05), 1:2);
            end
        end
    end
end
% p(1)=[];
%end
close all

%plot stuff
if nargin>4 && plotFlag
    
    % FIRST: plot baseline values against catch and transfer
    %%epochs={'TMSteady','TMSteadyWBias', 'DelFAdapt', 'BaseAdapDiscont','TMafter','TMafterWBias','DelFDeAdapt', 'BasePADiscont'};
    %%epochs={'SlowBase','FastBase', 'TMSteadyWBias', 'TMSteady','DelFAdapt', 'BaseAdapDiscont'};
    %epochs={'SlowBase','FastBase', 'TMSteady','DelFAdapt','BaseAdapDiscont'};%, 'BasePADiscont'};
    %%epochs={'TMSteady','SpeedAdapDiscont', 'DelFAdapt','TMafter','SpeedPADiscont', 'DelFDeAdapt'};
    %%epochs={'SlowBase','FastBase', 'TMSteady','DelFAdapt','TMafter','DelFDeAdapt'};
    %epochs={'TMSteady','TMafter', 'DelFDeAdapt', 'DelFAdapt', 'DelFDeAdapt'};
    %epochs={ 'BaseAdapDiscont', 'DelFAdapt', 'TMSteady','TMafter','DelFDeAdapt'};
    %epochs={'SlowBase','FastBase', 'MidBase', 'EarlyA', 'TMSteady','SpeedSSDiscont'};
    epochs={'DelFAdapt','DelFDeAdapt','SlowBase','FastBase', 'MidBase',};
    %%epochs={'BaseAdapDiscont','DelFDeAdapt'};
    %%epochs={'TMSteady', 'SlowBase', 'FastBase', 'MidBase'};
    if nargin>5 %I imagine there has to be a better way to do this...
        barGroups(SMatrix,results,groups,params,epochs,indivFlag)
    else
        barGroups(SMatrix,results,groups,params,epochs)
    end
    
end

end


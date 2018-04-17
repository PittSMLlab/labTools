function [model,btab,wtab,anovatab,maineff,posthocGroup,posthocEpoch,posthocEpochByGroup,posthocGroupByEpoch]=AnovaEpochs(groups,groupsNames,label,eps)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Performs ANOVA on a parameter in a series of defined epochs    %%
%                                                               %%
%Applications                                                   %%
% - Oneway ANOVA if nepochs=1 and ngroups>1                     %%
% - Oneway RM ANOVA if nepochs>1 and ngroups=1                  %%
% - Twoway RM ANOVA if nepochs>1 and ngroups>1                  %%
%                                                               %%
%Input variables:                                               %%
% - groups: groupAdaptationData with one or more groups         %% 
% - groupsNames: names of groups                                %%
% - label: name of parameter of interest                        %%
% - eps: epoch dataset created with defineEpochs                %% 
%                                                               %%
%                                                               %%
%Output variables:                                              %%
% - t: Table generated to perform ANOVA                         %%
% - model: fitted model                                         %% 
% - btab: between subjects ANOVA table                          %%
% - wtab: within subjects ANOVA table                           %%
% - anovatab: combined table                                    %%
% - maineff: table with maineff of group and epoch              %%
% - posthocGroup: table with posthoc results                    %%
% - posthocEpoch: table with posthoc results                    %%
% - posthocEpochByGroup                                         %%
% - posthocGroupByEpoch                                         %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

posthocGroup=[];
posthocEpoch=[];
posthocEpochByGroup=[];
posthocGroupByEpoch=[];




%%Step 1: Create table with data of interest
t=table;
%create croup variable
for i=1:length(groups)
    nsub=length(groups{i}.adaptData);
    if i==1
        subcodes=cellstr(repmat(groupsNames{i},nsub,1));
    else
        subcodes=[subcodes;cellstr(repmat(groupsNames{i},nsub,1))];
    end
end
t.group=nominal(subcodes);
epData=[];
for i=1:length(groups)
    epData=[epData;transpose(squeeze(groups{i}.getEpochData(eps,label)))];
end
for e = 1:length(eps)
    eval(['t.ep',num2str(e),'=epData(:,',num2str(e),');']);
end

%%Step 2: perform ANOVA and posthoc tests
maineff=table;

%determine which type of ANOVA
if length(eps) == 1 %Oneway ANOVA
   posthocGroup=table;
   
   
    [pval,anovatab,model] = anova1(t.ep1,t.group,'off');
    wtab=[];btab=[];%these are for repeated measures or mixed ANOVA's;
    c = multcompare(model,'display','off','CType','lsd');
    c2 = multcompare(model,'display','off','CType','bonferroni');
    c3 = multcompare(model,'display','off','CType','hsd');
    F=cell2mat(anovatab(2,find(strcmp(anovatab(1,:),'F')==1)));
    p=cell2mat(anovatab(2,find(strcmp(anovatab(1,:),'Prob>F')==1)));
    maineff.names={'group';'epoch';'interaction';'modelpval'};maineff.F=[F;NaN;NaN;NaN];maineff.p=[p;NaN;NaN;pval];%table with main effects
    posthocGroup.groups1=groupsNames(c(:,1))';posthocGroup.groups2=groupsNames(c(:,2))';%groups to compare
    posthocGroup.meandiff=c(:,4);posthocGroup.lowerbound=c(:,3);posthocGroup.upperbound=c(:,5);posthocGroup.pvalLSD=c(:,6);
    posthocGroup.pvalBonferroni=c2(:,6);posthocGroup.pvalTukey=c3(:,6);
    [posthocGroup.hBenHoch,dt1,dt2] = BenjaminiHochberg(c(:,6),0.05);%FDR of 0.05 seems reasonable; 
    clear F p pval c c2 c3 dt1 dt2; 
    
elseif length(groups) == 1 %Oneway RM ANOVA
    posthocEpoch=table;
    
    %perform RM ANOVA with between-group factor set to 1; I cross-validated
    %with an older function from file exchange (anova_rm.m), which yields
    %similar results. I prefer this method, since it does not fail for NaN's.
    rm=fitrm(t,['ep1-ep',num2str(length(eps)),'~1'],'WithinDesign',Meas,'WithinModel','epoch');
    wtab=ranova(rm); btab=[];
    if rm.mauchly.pValue>.05%spherecity can be assumed
        maineff.names={'group';'epoch';'interaction';'modelpval'};maineff.F=[NaN;wtab.F(1);NaN;NaN];maineff.p=[NaN;wtab.pValue(1);NaN;NaN];%table with main effects
    else %use greenhouse geisser
         maineff.names={'group';'epoch';'interaction';'modelpval'};maineff.F=[NaN;wtab.F(1);NaN;NaN];maineff.p=[NaN;wtab.pValueGG(1);NaN;NaN];%table with main effects
    end
   
    %perform pairwise comparisons by hand, since multcompare does not
    %account for repeated observations.
    
    ncomp=[length(eps)*(length(eps)-1)]/2;
    comp=1;
    for e=1:length(eps)
        for e2=1:length(eps)
            if e>e2;
                posthocEpoch.ep1(comp)=eps.Properties.ObsNames(e);
                posthocEpoch.ep2(comp)=eps.Properties.ObsNames(e2);
                [H,P,CI] = ttest(t.(['ep',num2str(e)]),t.(['ep',num2str(e2)]));
                posthocEpoch.meandiff(comp)=mean(CI);
                posthocEpoch.lowerbound(comp)=CI(1);
                posthocEpoch.upperbound(comp)=CI(2);
                posthocEpoch.pval(comp)=P;
                posthocEpoch.pvalBonferroni(comp)=P/ncomp;                
                clear H P CI
                comp=comp+1;
            end
        end
    end
    [posthocEpoch.hBenHoch,dt1,dt2] = BenjaminiHochberg(posthocEpoch.pval,0.05);clear dt1 dt2
     
    
    
    
elseif length(eps) > 1 || length(groups) > 1 %Two-way RM ANOVA
   posthocEpoch=table;
   posthocGroupByEpoch=table;
   posthocEpochByGroup=table;
    
    rm=fitrm(t,['ep1-ep',num2str(length(eps)),'~group'],'WithinDesign',Meas,'WithinModel','epoch');
    wtab=ranova(rm); btab=anova(rm);
    if rm.mauchly.pValue>.05%spherecity can be assumed
        maineff.names={'group';'epoch';'interaction';'modelpval'};maineff.F=[btab.F(2);wtab.F(1);wtab.F(2);NaN];maineff.p=[btab.pValue(2);wtab.pValue(1);wtab.pValue(2);NaN];%table with main effects
    else %use greenhouse geisser
         maineff.names={'group';'epoch';'interaction';'modelpval'};maineff.F=[btab.F(2);wtab.F(1);wtab.F(2);NaN];maineff.p=[btab.pValue(2);wtab.pValueGG(1);wtab.pValueGG(2);NaN];%table with main effects
    end  
     
    %perform pairwise comparisons for epoch    
    ncomp=[length(eps)*(length(eps)-1)]/2;
    comp=1;
    for e=1:length(eps)
        for e2=1:length(eps)
            if e<e2;
                posthocEpoch.ep1(comp)=eps.Properties.ObsNames(e);
                posthocEpoch.ep2(comp)=eps.Properties.ObsNames(e2);
                [H,P,CI] = ttest(t.(['ep',num2str(e)]),t.(['ep',num2str(e2)]));
                posthocEpoch.meandiff(comp)=mean(CI);
                posthocEpoch.lowerbound(comp)=CI(1);
                posthocEpoch.upperbound(comp)=CI(2);
                posthocEpoch.pval(comp)=P;
                posthocEpoch.pvalBonferroni(comp)=P/ncomp;                
                clear H P CI
                comp=comp+1;
            end
        end
    end
    [posthocEpoch.hBenHoch,dt1,dt2] = BenjaminiHochberg(posthocEpoch.pval,0.05);clear dt1 dt2
    
    %perform pairwise comparisons between groups for each epoch    
    %first create subtable for each group
    t2=[];
    for g = 1:length(groups)
        t2{g}=t(t.group==groupsNames(g),:);
    end
    
    ncomp=([length(groups)*(length(groups)-1)]/2)*length(eps);
    comp=1;
    for e = 1:length(eps)
        for g1 = 1:length(groups)
            for g2 = 1:length(groups)
                if g1<g2
                    posthocGroupByEpoch.epoch(comp)=eps.Properties.ObsNames(e);
                    posthocGroupByEpoch.group_1(comp)=groupsNames(g1);
                    posthocGroupByEpoch.group_2(comp)=groupsNames(g2);
                    [H,P,CI] = ttest2(t2{g1}.(['ep',num2str(e)]),t2{g2}.(['ep',num2str(e)]));
                    posthocGroupByEpoch.meandiff(comp)=mean(CI);
                    posthocGroupByEpoch.lowerbound(comp)=CI(1);
                    posthocGroupByEpoch.upperbound(comp)=CI(2);
                    posthocGroupByEpoch.pval(comp)=P;
                    posthocGroupByEpoch.pvalBonferroni(comp)=P/ncomp;                
                    clear H P CI
                    comp=comp+1;                     
                end
            end
        end
    end
    [posthocGroupByEpoch.hBenHoch,dt1,dt2] = BenjaminiHochberg(posthocGroupByEpoch.pval,0.05);clear dt1 dt2
    
    %perform pairwise comparisons between epochs for each group
    ncomp=([length(eps)*(length(eps)-1)]/2)*length(groups);
    comp=1;   
    for g = 1:length(groups)
        for e=1:length(eps)
            for e2=1:length(eps)
                if e<e2;
                    posthocEpochByGroup.group(comp)=groupsNames(g);
                    posthocEpochByGroup.ep1(comp)=eps.Properties.ObsNames(e);
                    posthocEpochByGroup.ep2(comp)=eps.Properties.ObsNames(e2);
                    [H,P,CI] = ttest(t2{g1}.(['ep',num2str(e)]),t2{g1}.(['ep',num2str(e2)]));
                    posthocEpochByGroup.meandiff(comp)=mean(CI);
                    posthocEpochByGroup.lowerbound(comp)=CI(1);
                    posthocEpochByGroup.upperbound(comp)=CI(2);
                    posthocEpochByGroup.pval(comp)=P;
                    posthocEpochByGroup.pvalBonferroni(comp)=P/ncomp;
                    clear H P CI
                    comp=comp+1;
                end
            end
        end
    end
    [posthocEpochByGroup.hBenHoch,dt1,dt2] = BenjaminiHochberg(posthocEpochByGroup.pval,0.05);clear dt1 dt2
    
end   
    
    
end

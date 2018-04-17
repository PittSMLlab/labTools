function [model,btab,wtab,anovatab,maineff,posthoc]=AnovaEpochs(groups,groupsNames,label,eps,postHocCorrection,postHocEpochFlag,postHocGroupFlag)

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
% - postHocCorrection: method for posthoc                       %%
% - postHocEpochFlag: set to 1 to compare epochs for each group %%
% - postHocGroupFlag: set to 1 to compare groups for each epoch %%
%                                                               %%
%Output variables:                                              %%
% - t: Table generated to perform ANOVA                         %%
% - model: fitted model                                         %% 
% - btab: between subjects ANOVA table                          %%
% - wtab: within subjects ANOVA table                           %%
% - anovatab: combined table                                    %%
% - maineff: table with maineff of group and epoch              %%
% - posthoc: table with posthoc results                         %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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

%%Step 2: perform ANOVA
%determine which type of ANOVA
if length(eps) == 1 
    modtype = 1; %Oneway ANOVA
    [p,anovatab,model] = anova1(t.ep1,t.group,'off');
    wtab=[];btab=[];
    [c,m,h,nms] = multcompare(model,'display','off');
    F=cell2mat(anovatab(2,find(strcmp(anovatab(1,:),'F')==1)));
    p=cell2mat(anovatab(2,find(strcmp(anovatab(1,:),'Prob>F')==1)));
    maineff=dataset({'group';'epoch';'interaction'},{F;NaN;NaN},{p;NaN;NaN},'Varnames',{'effect','F','p'});
    
    %do multiple comparisons
    
elseif length(groups) == 1
    modtype = 2; %Oneway RM ANOVA
elseif length(eps) > 1 || length(groups) > 1
    modtype = 3; %Two-way RM ANOVA
end


Meas = table([1:length(eps)]','VariableNames',{'epoch'});%table for within-subject design

rm=fitrm(t,['ep1-ep',num2str(length(eps)),'~group'],'WithinDesign',Meas,'WithinModel','epoch');




if length(groups)==1
    %Oneway repeated measures ANOVA
else
    %TwoWay repeated measures ANOVA
    
end

%%Step3: perform posthoc

end
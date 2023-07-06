%%Traces from example subject to show how data is summarized
%% Load data
% clear all; close all; clc
% % load('.../GYAAT_01.mat');
% subID = 'NTR_03';
% scriptDir = fileparts(matlab.desktop.editor.getActiveFilename); 
% load([scriptDir '/data/' subID])

%% Loading data for Boyan
% we need to load to expData files due to the problems with sensor 8 box 1
% after trial 1

% load('NimbG_Boyan_RPER.mat')
% expData2=expData;
% load('NimbG_Boyan.mat')

%% Set muscle to plot

muscle={'TA', 'PER', 'SOL', 'LG', 'MG', 'BF', 'SEMB', 'SEMT', 'VM', 'VL', 'RF', 'TFL', 'GLU','HIP'};
normalize = 1;  % 1 to normalize data
normCond = {'OG base'};

%% Baseline condtions 
conds={'OG base','TM tied 2','TR Base'};
late=1;
strides=40;
fh=plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond);

%% Late condition 
late=1;
strides=40;
conds={'OG base','TM tied 2',...
    'TR Base','Adaptation',...
    'Post 1','Post 2'};
fh=plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond);


%% Early conditions 
late=0;
strides=10;
conds={'TR Base','Pos short',...
    'Neg Short','Adaptation',...
    'Post 1','Post 2'};
fh=plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond);

%% Saving the data 
% if late
%     if baselate
%         saveas(fh, [scriptDir '/EMGTraces/' subID '_BaseLate.png']);
%     else
%         saveas(fh, [scriptDir '/EMGTraces/' subID '_Late.png']);
%     end
% else
%     saveas(fh, [scriptDir '/EMGTraces/' subID '_Early.png']);
% end


%% Old code use as references to understand the functions above

% late=1;
% baselate=0;
% missing = [];
% %% Align it
% 
% conds={'OG base','TM tied 1','Pos short',...
%     'Neg Short','TR Base','Adaptation',...
%     'Post 1','Post 2'};
% 
% % condlegend={'TM base','Early Adapt','Late Adapt','Early Post','Late Post','Short Pos','Short Neg'};
% condlegend=conds;
% events={'RHS','LTO','LHS','RTO'};
% % condlegend={'Early Adapt','Short Pos','Short Neg'};
% alignmentLengths=[16,32,16,32];
% muscle={'TA'};%, 'PER', 'SOL', 'LG', 'MG', 'BF', 'SEMB', 'SEMT', 'VM', 'VL', 'RF', 'TFL', 'GLU','HIP'};
% 
% lm=1:2:35;
% if late==1
%     if baselate==1
%         condlegend={'OGbase_{late}','TMbase3','TRbase_{late}','Post2_{late}'};
%     else
%         condlegend={'OGbase_{late}','TMbase3_{late}','TRbase_{late}','Adaptation_{late}',...
%             'Post1_{late}','Post2_{late}'};
%     end
% else
%     condlegend={'OGbase','Pos Short','Neg Short',...
%         'Post1','Post2'};
%     
% end
% % for late=1:2
% fh=figure('Units','Normalized');
% % load(['SCB0',num2str(s), '.mat'])
% 
% for m=1:length(muscle)
%     
%     % OG base: no Nimbus
%     %     load('NimbG_Boyan_RPER.mat')
%     RBaseoff=expData.getAlignedField('procEMGData',conds(1),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LBaseoff=expData.getAlignedField('procEMGData',conds(1),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     %     load('NimG_Boyan.mat')
%     % TM Nimbus: Nimbus off
%     RTMBaseoff=expData.getAlignedField('procEMGData',conds(2),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LTMBaseoff=expData.getAlignedField('procEMGData',conds(2),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     %Short Split +
%     RPosi=expData.getAlignedField('procEMGData',conds(4),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LPosi=expData.getAlignedField('procEMGData',conds(4),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     %Short Split +
%     RNeg=expData.getAlignedField('procEMGData',conds(3),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LNeg=expData.getAlignedField('procEMGData',conds(3),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     %OG nimbus
%     RTRBase=expData.getAlignedField('procEMGData',conds(5),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LTRBase=expData.getAlignedField('procEMGData',conds(5),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     % Adaptation
%     RAdap=expData.getAlignedField('procEMGData',conds(6),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LAdap=expData.getAlignedField('procEMGData',conds(6),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     % OG post: No nimbus
%     RPost=expData.getAlignedField('procEMGData',conds(7),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LPost=expData.getAlignedField('procEMGData',conds(7),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     %Washout
%     RPostWash=expData.getAlignedField('procEMGData',conds(8),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LPostWash=expData.getAlignedField('procEMGData',conds(8),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     % Create plots
%     % close all;
%     poster_colors;
%     colorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow; [0 0 0]];
%     condColors=colorOrder;
%     
%     % fh=figure('Units','Normalized','Position',[0 0 .45 .2]);
%     
%     % norm2=max(allmuscle.Data);
%     % allmuscle.Data=bsxfun(@rdivide,allmuscle.Data,norm2);
%     
%     for l=1:2
%         switch l
%             case 1
%                 
%                 %Late
%                 Nimbusoff=RBaseoff.getPartialStridesAsATS(size(RBaseoff.Data,3)-40:size(RBaseoff.Data,3));
%                 TMbase=RTMBaseoff.getPartialStridesAsATS(size(RTMBaseoff.Data,3)-40:size(RTMBaseoff.Data,3));
%                 Base=RTRBase.getPartialStridesAsATS(size(RTRBase.Data,3)-40:size(RTRBase.Data,3));
%                 Adaptation=RAdap.getPartialStridesAsATS(size(RAdap.Data,3)-40:size(RAdap.Data,3));
%                 Washout_Late=RPostWash.getPartialStridesAsATS(size(RPostWash.Data,3)-40:size(RPostWash.Data,3));
%                 Post_Late=RPost.getPartialStridesAsATS(size(RPost.Data,3)-40:size(RPost.Data,3));
%                 
%                 %Early
%                 Post=RPost.getPartialStridesAsATS(1:30);
%                 Pos=RPosi.getPartialStridesAsATS(1:29);
%                 Neg=RNeg.getPartialStridesAsATS(1:30);
%                 Washout=RPostWash.getPartialStridesAsATS(1:30);              
%                 
%                 tit=['R' muscle{m}];
%             case 2
%                 
%                 %Late
%                 Nimbusoff=LBaseoff.getPartialStridesAsATS(size(LBaseoff.Data,3)-40:size(LBaseoff.Data,3));
%                 TMbase=LTMBaseoff.getPartialStridesAsATS(size(LTMBaseoff.Data,3)-40:size(LTMBaseoff.Data,3));
%                 Base=LTRBase.getPartialStridesAsATS(size(LTRBase.Data,3)-40:size(LTRBase.Data,3));
%                 Adaptation=LAdap.getPartialStridesAsATS(size(LAdap.Data,3)-40:size(LAdap.Data,3));
%                 Post_Late=LPost.getPartialStridesAsATS(size(LPost.Data,3)-40:size(LPost.Data,3));
%                 Washout_Late=LPostWash.getPartialStridesAsATS(size(LPostWash.Data,3)-40:size(LPostWash.Data,3));
%                 
%                 %Early
%                 Pos=LPosi.getPartialStridesAsATS(1:30);
%                 Neg=LNeg.getPartialStridesAsATS(1:30);
%                 Post=LPost.getPartialStridesAsATS(1:30);
%                 Washout=LPostWash.getPartialStridesAsATS(1:30);
%                 
%                 tit=['L' muscle{m}];
%                 
%         end
%         %     allmuscle=EMG.getPartialStridesAsATS(1:size(EMG.Data,3))
%         
%         norm2=nanmean(nanmax(squeeze(Base.Data)));
%         %Late
%         Nimbusoff.Data=bsxfun(@rdivide,Nimbusoff.Data,norm2);
%         TMbase.Data=bsxfun(@rdivide,TMbase.Data,norm2);
%         Base.Data=bsxfun(@rdivide,Base.Data,norm2);
%         Adaptation.Data=bsxfun(@rdivide,Adaptation.Data,norm2);
%         Post_Late.Data=bsxfun(@rdivide,Post_Late.Data,norm2);                
%         Washout_Late.Data=bsxfun(@rdivide,Washout_Late.Data,norm2);
%         
%         %             Early
%         Pos.Data=bsxfun(@rdivide,Pos.Data,norm2);
%         Neg.Data=bsxfun(@rdivide,Neg.Data,norm2);
%         Post.Data=bsxfun(@rdivide,Post.Data,norm2);
%         Washout.Data=bsxfun(@rdivide,Washout.Data,norm2);
%         
%         condColors=colorOrder;
%         % ph=[];
%         ph1=[];
%         prc=[16,84];
%         MM=sum(alignmentLengths);
%         M=cumsum([0 alignmentLengths]);
%         xt=sort([M,M(1:end-1)+[diff(M)/2]]);
%         phaseSize=8;
%         xt=[0:phaseSize:MM];
%         %xt=[0:8:MM];s
%         fs=16; %FontSize
%         
%         
%         ph=subplot(5,6,lm(m)+l-1);
%         %     ph=subplot(1,2,l);
%         set(gcf,'color','w');
%         %     set(ph,'Position',[.07 .48 .35 .45]);
%         hold on
%         
%         
%         if late==1
%             %             title('Late Phases')
%             if baselate==1
%                 Nimbusoff.plot(fh,ph,condColors(1,:),[],0,[-49:0],prc,true);
%                 TMbase.plot(fh,ph,condColors(2,:),[],0,[-49:0],prc,true);
%                 Base.plot(fh,ph,condColors(5,:),[],0,[-49:0],prc,true);
%             else
%                 Nimbusoff.plot(fh,ph,condColors(1,:),[],0,[-49:0],prc,true);
%                 TMbase.plot(fh,ph,condColors(2,:),[],0,[-49:0],prc,true);
%                 Base.plot(fh,ph,condColors(5,:),[],0,[-49:0],prc,true);
%                 Adaptation.plot(fh,ph,condColors(6,:),[],0,[-49:0],prc,true);
%                 Post_Late.plot(fh,ph,condColors(7,:),[],0,[-49:0],prc,true);              
%                 Washout_Late.plot(fh,ph,condColors(8,:),[],0,[-49:0],prc,true);
%             end
%         else
%             %             fh2=figure('Units','Normalized');
%             %             title('Early Phases')
%             Base.plot(fh,ph,condColors(5,:),[],0,[-49:0],prc,true);
%             Pos.plot(fh,ph,condColors(6,:),[],0,[-49:0],prc,true);
%             Neg.plot(fh,ph,condColors(4,:),[],0,[-49:0],prc,true);
%             Post.plot(fh,ph,condColors(7,:),[],0,[-49:0],prc,true);
%             Washout.plot(fh,ph,condColors(8,:),[],0,[-49:0],prc,true);
%         end
%         axis tight
%         ylabel('')
%         ylabel(tit)
%         %     set(ph,'YTick',[0,1],'YTickLabel',{'0%','100%'})
%         grid on
%         ll=findobj(ph,'Type','Line');
% 
%     end
%     % legend(ll(end:-1:1),condlegend{:})
% end
% if late==1
%     title('Late Phases')
%     
% else
%     %             fh2=figure('Units','Normalized');
%     title('Early Phases')
% end
% legend(ll(end:-1:1),condlegend{:})
% % end%%
% 

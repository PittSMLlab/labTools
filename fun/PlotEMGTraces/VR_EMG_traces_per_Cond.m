%%Traces from example subject to show how data is summarized
%% Load data
% load('/Volumes/Users/Dulce/R01_Nimbus2021/VROG_Devon/VrG_Devon.mat')
% subID = 'CTR_01';
% scriptDir = fileparts(matlab.desktop.editor.getActiveFilename); 
% load([scriptDir '/data/' subID])

%% Set muscle to plot

muscle={'TA', 'PER', 'SOL', 'LG', 'MG', 'BF', 'SEMB', 'SEMT', 'VM', 'VL', 'RF', 'TFL', 'GLU','HIP'};
normalize = 1;  % 1 to normalize data
normCond = {'TR base'};

%% Baseline condtions 
conds={'OG base','TM tied 1','TR base'};
late=1;
strides=40;
fh=plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond);

%% Late condition 
late=1;
strides=40;
conds={'OG base','TM tied 1',...
    'TR base','Adaptation',...
    'Post 1','Post 2'};
fh=plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond);


%% Early conditions 
late=0;
strides=30;
conds={'TR base','Pos short',...
    'Neg Short','Adaptation',...
    'Post 1','Post 2'};
fh=plotEMGtraces(expData,conds,muscle,late,strides,normalize,normCond);



%% save figures
% if late
%     if baseOnly
%         saveas(fh, [scriptDir '/EMGTraces/' subID '_BaseLate.png']);
%     else
%         saveas(fh, [scriptDir '/EMGTraces/' subID '_Late.png']);
%     end
% else
%     saveas(fh, [scriptDir '/EMGTraces/' subID '_Early.png']);
% end


%% Set period to plot
% close all;
% late=1;
% baseOnly=0;

%% Old code use as references to understand the functions above

% conds={'OG base','TR base','Pos Short','Neg Short',...
%     'TM tied 1',...
%     'Adaptation','Post 1','Post 2'};
% 
% 
% events={'RHS','LTO','LHS','RTO'};
% 
% alignmentLengths=[16,32,16,32];
% 
% muscle={'TA', 'PER', 'SOL', 'LG', 'MG', 'BF', 'SEMB', 'SEMT', 'VM', 'VL', 'RF', 'TFL', 'GLU','HIP'};
% % muscle={'HIP'};
% lm=1:2:35;
% 
% if late==1
%     
%     if baseOnly==1 
%         condlegend={'OGbase_{late}','TRbase_{late}','TMtied1_{late}'};
%     else
%         condlegend={'OGbase_{late}','TRbase_{late}','TMtied1_{late}','Adaptation_{late}',...
%             'Post1_{late}','Post2_{late}'};
%     end
%     
% else
%     condlegend={'TRbase_{late}','Pos Short','Neg Short',...
%         'Post1_{early}','Post2_{early}'}; 
% end
% 
% fh=figure('Units','Normalized');
% 
% 
% for m=1:length(muscle)
%     
%     %OG base No VR
%     ROGBase=expData.getAlignedField('procEMGData',conds(1),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LOGBase=expData.getAlignedField('procEMGData',conds(1),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     %TM base VR
%     RTRbase=expData.getAlignedField('procEMGData',conds(2),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LTRbase=expData.getAlignedField('procEMGData',conds(2),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     %Short Split + No VR
%     RPosi=expData.getAlignedField('procEMGData',conds(3),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LPosi=expData.getAlignedField('procEMGData',conds(3),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     %Short Split - No VR
%     RNeg=expData.getAlignedField('procEMGData',conds(4),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LNeg=expData.getAlignedField('procEMGData',conds(4),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     %TM base no VR
%     RTMBase=expData.getAlignedField('procEMGData',conds(5),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LTMBase=expData.getAlignedField('procEMGData',conds(5),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     %Adaptation VR
%     RAdap=expData.getAlignedField('procEMGData',conds(6),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LAdap=expData.getAlignedField('procEMGData',conds(6),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     %OG post NO VR
%     RPost1=expData.getAlignedField('procEMGData',conds(7),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LPost1=expData.getAlignedField('procEMGData',conds(7),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     %TMpost VR
%     RPost2=expData.getAlignedField('procEMGData',conds(8),events,alignmentLengths).getPartialDataAsATS({['R' muscle{m}]});
%     LPost2=expData.getAlignedField('procEMGData',conds(8),events([3,4,1,2]),alignmentLengths).getPartialDataAsATS({['L' muscle{m}]});
%     
%     % Create plots
%     % close all;
%     poster_colors;
%     colorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow; [0 0 0]];
%     condColors=colorOrder;
%     
%     
%     for l=1:2
%         switch l
%             case 1
%                 
%                 %Late
%                 OGbase_late=ROGBase.getPartialStridesAsATS(size(ROGBase.Data,3)-40:size(ROGBase.Data,3));
%                 TRbase_late=RTRbase.getPartialStridesAsATS(size(RTRbase.Data,3)-40:size(RTRbase.Data,3));
%                 TMBase_late=RTMBase.getPartialStridesAsATS(size(RTMBase.Data,3)-40:size(RTMBase.Data,3));
%                 Adaptation_late=RAdap.getPartialStridesAsATS(size(RAdap.Data,3)-40:size(RAdap.Data,3));
%                 Post2_Late=RPost2.getPartialStridesAsATS(size(RPost2.Data,3)-40:size(RPost2.Data,3));
%                 Post1_Late=RPost1.getPartialStridesAsATS(size(RPost1.Data,3)-40:size(RPost1.Data,3));
%                 
%                 %Early
%                 Post1_early=RPost1.getPartialStridesAsATS(1:30);
%                 Pos=RPosi.getPartialStridesAsATS(1:30);
%                 Neg=RNeg.getPartialStridesAsATS(1:30);
%                 Post2_early=RPost2.getPartialStridesAsATS(1:30);
%                 
%                 
%                 
%                 tit=['R' muscle{m}];
%             case 2
%                 
%                 %Late
%                 OGbase_late=LOGBase.getPartialStridesAsATS(size(LOGBase.Data,3)-40:size(LOGBase.Data,3));
%                 TRbase_late=LTRbase.getPartialStridesAsATS(size(LTRbase.Data,3)-40:size(LTRbase.Data,3));
%                 TMBase_late=LTMBase.getPartialStridesAsATS(size(LTMBase.Data,3)-40:size(LTMBase.Data,3));
%                 Adaptation_late=LAdap.getPartialStridesAsATS(size(LAdap.Data,3)-40:size(LAdap.Data,3));
%                 
%                 %                 if m==14
%                 %
%                 %                 else
%                 Post1_Late=LPost1.getPartialStridesAsATS(size(LPost1.Data,3)-40:size(LPost1.Data,3));
%                 Post2_Late=LPost2.getPartialStridesAsATS(size(LPost2.Data,3)-40:size(LPost2.Data,3));
%                 %                 end
%                 
%                 
%                 
%                 %Early
%                 Pos=LPosi.getPartialStridesAsATS(1:30);
%                 Neg=LNeg.getPartialStridesAsATS(1:30);
%                 Post1_early=LPost1.getPartialStridesAsATS(1:30);
%                 Post2_early=LPost2.getPartialStridesAsATS(1:30);
%                 %                 if m==14
%                 %
%                 %                 else
%                 %
%                 %                 end
%                 
%                 
%                 tit=['L' muscle{m}];
%                 
%         end
%         
%         norm2=nanmean(nanmax(squeeze(TRbase_late.Data)));
%         
%         %Late
%         OGbase_late.Data=bsxfun(@rdivide,OGbase_late.Data,norm2);
%         TRbase_late.Data=bsxfun(@rdivide,TRbase_late.Data,norm2);
%         TMBase_late.Data=bsxfun(@rdivide,TMBase_late.Data,norm2);
%         Adaptation_late.Data=bsxfun(@rdivide,Adaptation_late.Data,norm2);
%         Post1_Late.Data=bsxfun(@rdivide,Post1_Late.Data,norm2);
%         Post2_Late.Data=bsxfun(@rdivide,Post2_Late.Data,norm2);
%         
%         %             Early
%         Pos.Data=bsxfun(@rdivide,Pos.Data,norm2);
%         Neg.Data=bsxfun(@rdivide,Neg.Data,norm2);
%         Post1_early.Data=bsxfun(@rdivide,Post1_early.Data,norm2);
%         Post2_early.Data=bsxfun(@rdivide,Post2_early.Data,norm2);
%         %
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
%             if baseOnly==1
%                 OGbase_late.plot(fh,ph,condColors(1,:),[],0,[-49:0],prc,true);
%                 TRbase_late.plot(fh,ph,condColors(2,:),[],0,[-49:0],prc,true);
%                 TMBase_late.plot(fh,ph,condColors(5,:),[],0,[-49:0],prc,true);
%             else
%                 OGbase_late.plot(fh,ph,condColors(1,:),[],0,[-49:0],prc,true);
%                 TRbase_late.plot(fh,ph,condColors(2,:),[],0,[-49:0],prc,true);
%                 TMBase_late.plot(fh,ph,condColors(5,:),[],0,[-49:0],prc,true);
%                 Adaptation_late.plot(fh,ph,condColors(6,:),[],0,[-49:0],prc,true);
%                 Post1_Late.plot(fh,ph,condColors(7,:),[],0,[-49:0],prc,true);
%                 Post2_Late.plot(fh,ph,condColors(8,:),[],0,[-49:0],prc,true);
%                 
%                 
%             end
%             %
%         else
%             TRbase_late.plot(fh,ph,condColors(2,:),[],0,[-49:0],prc,true);
%             Pos.plot(fh,ph,condColors(9,:),[],0,[-49:0],prc,true);
%             Neg.plot(fh,ph,condColors(4,:),[],0,[-49:0],prc,true);
%             Post1_early.plot(fh,ph,condColors(7,:),[],0,[-49:0],prc,true);
%             Post2_early.plot(fh,ph,condColors(8,:),[],0,[-49:0],prc,true);
%         end
%         axis tight
%         ylabel('')
%         ylabel(tit)
%         %     set(ph,'YTick',[0,1],'YTickLabel',{'0%','100%'})
%         grid on
%         ll=findobj(ph,'Type','Line');
%         
%     end
% end
% if late==1
%     title('Late Phases')
%     
% else
%     title('Early Phases')
% end
% legend(ll(end:-1:1),condlegend{:})
% % end%%
% set(gcf,'color','w');


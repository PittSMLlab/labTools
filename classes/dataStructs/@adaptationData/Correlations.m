function Correlations(adapDataList, results,params,conds,groups,colorOrder,type)

% Set colors order
if nargin<6 || isempty(colorOrder) || size(colorOrder,2)~=3
    poster_colors;
    colorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow; [0 0 0]];
end

if type==1 %%by Epochs
    
    ah=optimizedSubPlot(length(params), length(params), 1);
    hold on
    i=1;
for p=1:length(params)
    
    Y=results.(conds{1}).indiv.(params{p})(:,2);
    X=results.(conds{2}).indiv.(params{p})(:,2);
    groupKey=results.(conds{1}).indiv.(params{p})(:,1);
  
    groupNums=unique(groupKey);
    axes(ah(p))
    hold on
    for g=groupNums'
        plot(X(groupKey==g),Y(groupKey==g),'.','markerSize',15,'color',colorOrder(g,:))
     end
    
    lm = fitlm(X,Y,'linear');
    Pslope=double(lm.Coefficients{2,4});
    Pintercept=double(lm.Coefficients{1,4});
    Y_fit=lm.Fitted;
    coef=double(lm.Coefficients{:,1});%Intercept=(1, 1), slop=(2,1)
    Rsquared=lm.Rsquared.Ordinary;
    R=corr(X,Y);
    Resid=lm.Residuals.Studentized;
    
    %Pearson Coefficient
    FullMeta=find(isnan(X)~=1);
    [RHO_Pearson,PVAL_Pearson] = corr(X(FullMeta),Y(FullMeta),'type', 'Pearson');
    
    %Spearman Coefficient
    [RHO_Spearman,PVAL_Spearman] = corr(X(FullMeta),Y(FullMeta),'type', 'Spearman');
    
    plot(X,Y_fit,'k');
    hold on
  
    x1 = 1.*nanmax(X);
    y1 = 1.*nanmean(Y);
    
    label1 = sprintf('r = %0.2f, \n Pearson = %0.2f, \n  (p = %0.3f) ',R, RHO_Pearson, PVAL_Pearson);
    text(x1,y1,label1,'fontsize',14)
    
    ylabel([conds{2}],'fontsize',16)
    xlabel([conds{1}],'fontsize',16)
    title([params{p}],'fontsize',16)
%     title({[epoch1 ' ' params{var} ' vs. ' meta{cog}] ; ['(n = ' num2str(length(subjects)) ')']},'fontsize',16)
   
     set(gca,'fontsize',14)
    
    axis equal
    axis tight
    axis square
    i=i+1;
            legend(groups)
end 
    if length(params)<=4 
        clearvars -except SMatrix results epochx epochy params meta  groups colorOrder i ah
        set(gcf,'renderer','painters')
    else
        clearvars -except SMatrix results epochx epochy params meta  groups colorOrder
    end
% end
elseif type==2 %by Parameters 
   
    ah=optimizedSubPlot(length(conds), length(conds), 1); 
    hold on
    i=1;
 for p=1:length(conds)
    
    Y=results.(conds{p}).indiv.(params{1})(:,2);
    X=results.(conds{p}).indiv.(params{2})(:,2);
    groupKey=results.(conds{p}).indiv.(params{1})(:,1);
  
    groupNums=unique(groupKey);
    axes(ah(p))
    hold on
    for g=groupNums'
        plot(X(groupKey==g),Y(groupKey==g),'.','markerSize',15,'color',colorOrder(g,:))
     end
    
    lm = fitlm(X,Y,'linear');
    Pslope=double(lm.Coefficients{2,4});
    Pintercept=double(lm.Coefficients{1,4});
    Y_fit=lm.Fitted;
    coef=double(lm.Coefficients{:,1});%Intercept=(1, 1), slop=(2,1)
    Rsquared=lm.Rsquared.Ordinary;
    R=corr(X, Y);
    Resid=lm.Residuals.Studentized;
    
    %Pearson Coefficient
    FullMeta=find(isnan(X)~=1);
    [RHO_Pearson,PVAL_Pearson] = corr(X(FullMeta),Y(FullMeta),'type', 'Pearson');
    
    %Spearman Coefficient
    [RHO_Spearman,PVAL_Spearman] = corr(X(FullMeta),Y(FullMeta),'type', 'Spearman');
    
    plot(X,Y_fit,'k');
    hold on
  
    x1 = 1.*nanmax(X);
    y1 = 1.*nanmean(Y);
    
    label1 = sprintf('r = %0.2f, \n Pearson = %0.2f, \n  (p = %0.3f) ',R, RHO_Pearson, PVAL_Pearson);
    text(x1,y1,label1,'fontsize',14)
    
    ylabel([params{2}],'fontsize',16)
    xlabel([params{1}],'fontsize',16)
    title([conds{p}],'fontsize',16)
%     title({[epoch1 ' ' params{var} ' vs. ' meta{cog}] ; ['(n = ' num2str(length(subjects)) ')']},'fontsize',16)
   
     set(gca,'fontsize',14)
    
    axis equal
    axis tight
    axis square
    i=i+1;
            legend(groups)
end 
    if length(params)<=4 
        clearvars -except SMatrix results epochx epochy params meta  groups colorOrder i ah
        set(gcf,'renderer','painters')
    else
        clearvars -except SMatrix results epochx epochy params meta  groups colorOrder
    end   
end

set(gcf,'renderer','painters')
end
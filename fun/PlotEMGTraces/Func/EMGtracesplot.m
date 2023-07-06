%% Set period to plot
late=1;
baselate=1;
missing = [];
%% Align it

% conds={'OG base','TM tied 1','Pos short',...
%     'Neg Short','TR Base','Adaptation',...
%     'Post 1','Post 2'};

muscle={'TA', 'PER', 'SOL', 'LG', 'MG', 'BF', 'SEMB', 'SEMT', 'VM', 'VL', 'RF', 'TFL', 'GLU','HIP'};


lm=1:2:35;
if late==1
    strides=40;
    if baselate==1
        conds={'OG base','TM tied 1','TR Base'};
        condlegend={'OGbase_{late}','TMbase3','TRbase_{late}'};
    else
        conds={'OG base','TM tied 1','TR Base','Adaptation',...
            'Post 1','Post 2'};
        condlegend={'OGbase_{late}','TMbase3_{late}','TRbase_{late}','Adaptation_{late}',...
            'Post1_{late}','Post2_{late}'};
    end
else
    strides=30;
    conds={'TR base','Pos short','Neg Short',...
        'Post 1','Post 2'};
    condlegend={'TRbase','Pos Short','Neg Short',...
        'Post1','Post2'};
    
end


fh=figure('Units','Normalized');
condColors=colorOrder;

ph1=[];
prc=[16,84];
MM=sum(alignmentLengths);
M=cumsum([0 alignmentLengths]);
xt=sort([M,M(1:end-1)+[diff(M)/2]]);
phaseSize=8;
xt=[0:phaseSize:MM];

fs=16; %FontSize


set(gcf,'color','w')
hold on

for m=1:length(muscle)
    leg={'R','L'};
    for l=1:2
        for c=1:length(conds)
            
            
            if l==1
                data=getDataEMGtraces(expData,muscle{m},conds(c),leg{l},late,strides);
                norm=getDataEMGtraces(expData,muscle{m},{'TR base'},leg{l},1,40);
                tit=['R' muscle{m}];
            elseif l==2
                data=getDataEMGtraces(expData,muscle{m},conds(c),leg{l},late,strides);
                norm=getDataEMGtraces(expData,muscle{m},{'TR base'},leg{l},1,40);
                tit=['L' muscle{m}];
            end
            norm=nanmean(nanmax(squeeze(norm.Data)));
            data.Data=bsxfun(@rdivide,data.Data,norm);
            ph=subplot(5,6,lm(m)+l-1);
            data.plot(fh,ph,condColors(c,:),[],0,[-49:0],prc,true);
            
            
        end
        axis tight
        ylabel('')
        ylabel(tit)
        grid on
        ll=findobj(ph,'Type','Line');

        
    end
    
    
    
    
    
end
if late==1
    title('Late Phases')
    
else
    title('Early Phases')
end
legend(ll(end:-1:1),condlegend{:})

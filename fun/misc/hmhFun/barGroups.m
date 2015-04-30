function barGroups(SMatrix,results,groups,params,epochs,indivFlag)
%Make a bar plot to compare groups for a given epoch and parameter
%   TO DO: make function be able to accept a group array that is different
%   thand the groups in the results matrix
    
% Set colors for plots. Each group is assigned a color so that it will be
% plotted as that color no matter which groups are fed in to the function.
poster_colorsHH; %Harrison's custom colors

%            %OA       OG        OANC       YA     OASV         OGNC       YASV        YG      YGNC           YASS        YGSS          OGSS          OASS
%ColorOrder=[p_red; p_orange; p_violet; p_green; p_dark_red; p_yellow; p_dark_green; p_blue; p_dark_blue; p_fade_green; p_fade_blue; p_fade_orange; p_fade_red];
ColorOrder=[p_red; p_orange; p_green; p_blue; p_fade_green; p_fade_blue; p_fade_orange; p_fade_red];

% Set grey colors to use when individual subjects are plotted 
GreyOrder=[0 0 0 ;1 1 1;0.5 0.5 0.5;0.2 0.2 0.2;0.9 0.9 0.9;0.1 0.1 0.1;0.8 0.8 0.8;0.3 0.3 0.3;0.7 0.7 0.7];

%ColorOrder=[p_red; p_orange; p_fade_green; p_fade_blue; p_plum; p_green; p_blue; p_fade_red; p_lime; p_yellow; p_gray; p_black;[1 1 1]];           
%ColorOrder=[p_red; p_orange; p_green; p_blue; p_dark_blue; p_fade_green; p_fade_blue; p_fade_orange; p_fade_red];
           %OA       OG        YA       YG      YGNC           YASS        YGSS          OGSS          OASS
ngroups=length(groups);         
numPlots=length(epochs)*length(params);
numE=length(epochs);
ah=optimizedSubPlot(numPlots,length(params),numE,'ltr');
i=1;
for p=1:length(params)
   limy=[];
   for t=1:numE
       axes(ah(i))
       hold on
       for b=1:ngroups
           nSubs=length(SMatrix.(groups{b}).IDs(:,1));
           ind=find(strcmp(fields(SMatrix),groups{b}));
           if nargin>5 && indivFlag
               bar(b,results.(epochs{t}).avg(b,p),'facecolor',GreyOrder(ind,:));
               for s=1:nSubs
                   plot(b,results.(epochs{t}).indiv.(groups{b})(s,p),'*','Color',ColorOrder(s,:))
               end
           else
               bar(b,results.(epochs{t}).avg(b,p),'facecolor',ColorOrder(ind,:));
           end
       end
       errorbar(results.(epochs{t}).avg(:,p),results.(epochs{t}).se(:,p),'.','LineWidth',2,'Color','k')
       set(gca,'Xtick',1:ngroups,'XTickLabel',groups,'fontSize',12)
       axis tight
       limy=[limy get(gca,'Ylim')];
       ylabel(params{p})
       title(epochs{t})
       i=i+1;
   end
   set(ah(p*numE-(numE-1):p*numE),'Ylim',[min(limy) max(limy)])
   set(gcf,'Renderer','painters');
end

end


function [fh,ph]=prettyBarPlot(data,colors,medianFlag,pairingLines,groupNames, conditionNames,plotHandle)
%Data is PxMxN, where:
%M is a number of groups (unpaired factor)
%N is a number of conditions/epochs/measurements (paired/repeated factor)
%P is the number of datapoints in each group/condition

P=size(data,1); %#datapoints
M=size(data,2); %Conditions (x spacing)
N=size(data,3); %Groups (colored)

%Parse input:
if nargin<2 || isempty(colors)
    figuresColorMap
    colors=condColors;
end
if nargin<3 || isempty(medianFlag)
   medianFlag=1; %Median +- iqr as plot default 
end
if nargin<4 || isempty(pairingLines)
    pairingLines=2; %Individual datapoints as default
end
if nargin<5 || isempty(groupNames) || length(groupNames)~=N
    groupNames=strcat('Group ', num2str([1:N]'));
end
if nargin<6 || isempty(conditionNames) || length(conditionNames)~=M
    conditionNames=strcat('Condition ', num2str([1:M]'));
end

%PLOT------------
if nargin<7 || isempty(plotHandle)
fh=figure('Units','Normalized','OuterPosition',[0 .5 .3 .5]);
ph=gca;
hold on
else
    axes(plotHandle);
    ph=gca;
    fh=gcf;
    hold on
end
%Bars:
if medianFlag==1
    m=squeeze(nanmedian(data));
    s=squeeze(iqr(data));
else
    m=squeeze(nanmean(data));
    s=squeeze(nanstd(data));
end
bb=bar(m,'FaceAlpha',.6,'EdgeColor','none');
pause(.1) %Without this the graphics engine doesnt return proper handles
xo=nan(N,1);
for i=1:length(bb) %length(bb) should be N
    xo(i)=get(bb(i),'xoffset');
    bb(i).FaceColor=colors(i,:);
end
%Add mean and std of pop:
%errorbar(reshape(.15*[-1 1]+[1; 2],4,1),mean(data),std(data),'Color','k','LineWidth',2,'LineStyle','none')
for i=1:N
    errorbar(xo(i)+[1:M]',m(:,i),[],s(:,i),'Color',colors(i,:),'LineWidth',2,'LineStyle','none')
end

%Add individual datapoints:
switch pairingLines
    case 0
        %nop
    case 1 %pairing lines (this is for side-by-side bars, corresponding to the same condition in two groups)
        for i=1:M
            pp1=plot(i+xo-.05*sign(xo),squeeze(data(:,i,:)),'k');
        end
    case 2 %single datapoints
        for i=1:N
            %Optional: hide half of the bars
            dX=mean(diff(xo))/2;
            for j=1:M
                %rectangle((xo(i)+j)+[0,dX,dX,0],[0 0 1 1]*bb(i).YData(j));
                h=bb(i).YData(j);
                if h>=0
                    rectangle('Position',[xo(i)+j+.01 0 dX h],'EdgeColor','None','FaceColor','w');
                else
                    rectangle('Position',[xo(i)+j+.01 h dX -h],'EdgeColor','None','FaceColor','w');
                end
                scatter(xo(i)+j+.01*randn(size(data,1),1)+dX/2,squeeze(data(:,j,i)),50,colors(i,:),'filled','MarkerFaceAlpha',.6);
            end
            %pp1=plot(xo(i)+[1:M]+.01*randn(size(data,1),1)+dX/2,squeeze(data(:,:,i)),'o','MarkerFaceColor',colors(i,:),'MarkerEdgeColor','none');
            
        end
end

legend(groupNames);
set(gca,'XTick',[1:M],'XTickLabel',conditionNames);
end
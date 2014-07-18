function [figHandle,subplotHandles] = plot(this,figHandle,handleVector,colorClusters,colorInd1,markerInd2)
%PLOT Implementation for ClusteredSynergySetCollection

Nplots=numel(this.content);
Ndims=this.getSynergyDim;

%Figure handle argument
if (nargin>1)&& ~isempty(figHandle)
    if isscalar(figHandle)
        h=figure(figHandle);
    else
        h=[];
    end
else
    h=[];
end
if isempty(h)
    h=figure;
end
set(h,'Name',[this.name ' Collection'])
set(gcf,'units','normalized','outerposition',[0 0 1 1])

%subplot handleVector argument
if (nargin>2) && ~isempty(handleVector) 
    %Check that handleVector has adequate size
    if length(handleVector)~=Nplots
        disp('Warning: handle vector provided has inconsitent size for provided ClusteredSynergySetCollection, ignoring.')
        handleVector=[];
    end
else
    handleVector=[];
end
if isempty(handleVector)
    [a,b]=getFigStruct(Nplots);
     for i=1:Nplots
        handleVector(i)=subplot(b,a,i);
    end
end

if (nargin<4) || isempty(colorClusters)
   colorClusters=this.colors; 
end

if (nargin<5) || isempty(colorInd1)
   colorInd1={[0,0.4,1],[0,0.8,1],[0,0.8,0],[0.8,0.8,0.3],[0.8,0,0.3],[0.8,0,1],[0.5,0.5,0.5],[1,0.2,0.4],[0.3,0.4,0.2],[0.2,0.4,1]};
end

if (nargin<6) || isempty(markerInd2)
   markerInd2={'x','o','*','v','+','d','s'};
end
        
maxY=max(this.getContentAsSet.content(:));
minY=min(this.getContentAsSet.content(:));
allAvg=zeros(Nplots,Ndims);
for i=1:Nplots
    subplot(handleVector(i))
    hold on
    Nelements=size(this.content{i}.content,1);
    
    %Plot average of cluster
    stddev=std(this.content{i}.content,[],1);
    avg=mean(this.content{i}.content,1);
    allAvg(i,:)=avg;
    B=bar(avg);
    colormap(colorClusters{i})
    freezeColors
    
    %Get distance statistics
    dist=this.content{i}.distance;
    dist1=SynergySet([avg;this.content{i}.content],this.muscleList).distance;
    dist=dist1(1:Nelements);
    avgSim=mean(dist);
    stdSim=std(dist);
    loSim=min(dist);
    hiSim=max(dist);
    
    %Plot stdev bars
    %barwitherr(std(this.content{i}.content,[],1),mean(this.content{i}.content,1))
    for j=1:Ndims
       plot([j j],avg(j)+[-stddev(j),stddev(j)],'k')
       plot(j+[-.1 .1],(avg(j)-stddev(j))*[1 1],'k')
       plot(j+[-.1 .1],(avg(j)+stddev(j))*[1 1],'k')
    end
    
    %Plot individual ocurrences (does this help?)
    for j=1:Nelements
        if this.originalCollection.getCollectionDim>1
            [ind1,ind2]=ind2sub(this.originalCollection.getCollectionSize,this.indexInOriginalCollection{i}(j)); %Get synergy set in original collection
        else
            ind1=this.indexInOriginalCollection{i}(j);
            ind2=1;
        end
        newInd1=mod(ind1-1,length(colorInd1))+1;
        newInd2=mod(ind2-1,length(markerInd2))+1;
        plot([1:Ndims]+.3,this.content{i}.content(j,:),markerInd2{newInd2},'Color',colorInd1{newInd1})
    end
    
    %Add number of elements N=
    if Nelements>0
        text(1,maxY,['N=' num2str(Nelements)])
    else
        text(1,maxY,['N=0'])
    end
    
    %Add similarity stats
    text(1,-.1,['DTC = ' num2str(avgSim,3) ' \pm ' num2str(stdSim,3) '\circ']); %Distance to centroid
    text(1,-.25,['[' num2str(loSim,3) '\circ,' num2str(hiSim,3) '\circ]']);
    
    %Label axes properly
    set(gca,'XTick',[1:Ndims],'XTickLabel',this.muscleList)
    xlabel(['Cluster ' this.indexLabels{1}{i}])
    hold off
    
    %Set axes
    axis([.5 Ndims+.5 min([-.4,minY]) 1.1*maxY])
end

%Add some data in extra axes:
% if length(handleVector)==Nplots+1
%     subplot(handleVector(end))
%     hold on
%     dist=SynergySet(allAvg,this.muscleList).distanceMatrix;
%     
%     for i=1:size(dist,1)
%         str=[];
%         for j=1:size(dist,2)
%             str=[str, num2str(dist(i,j),3) ','];
%         end
%         text(1,maxY-.1*i,str)
%     end
% 
%     axis([.5 Ndims+.5 min([-.4,minY]) 1.1*maxY])
%     axis off
%     hold off
% end

subplot(handleVector(1))
dist=SynergySet(allAvg,this.muscleList).distance;
title(['Inter-centroid distance = ' num2str(mean(dist),3) ' \pm ' num2str(std(dist),3) '\circ, [' num2str(min(dist),3) ',' num2str(max(dist),3) ']'])
    
    figHandle=h;
    subplotHandles=handleVector;

end


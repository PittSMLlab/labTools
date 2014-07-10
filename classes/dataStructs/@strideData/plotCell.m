function [plotHandles]=plotCell(strides,field,ampNorm,plotHandles,reqElements,color,plotEvents) %Plot cellarray of stride data
%CHANGES FROM PREVIOUS VERSION:
%Different subplots for every element of the field (e.g. each muscle)
%No longer supports sync_norm in here. sync_norm needs to be implemented as
%a class function, that returns strided & synchronized data from strided &
%non-sync'd data.
%offset parameter no longer plays a role
%Length parameter is now calculated to be automatically the smaller power
%of two that is still larger than all strides (N is no longer needed.)
%No longer outputting ampCoefs or offset.

%Get a sample field:
eval(['justTheField{1}=strides{1}.' field ';']);
if nargin<7 || isempty(plotEvents)
    plotEvents=false;
end
if nargin<6 || isempty(color)
    color=[.7,.7,.7];
end

%% First determine how many things are to be plotted & get the data.

%Find the requested data:3 options. If reqElements is a cell, the length of the cell. If it is empty or not given, then all
%the elements, finally if reqElement is 'L' or 'R', just the element labels
%that start with that.
if nargin<5 || isempty(reqElements) %No requested elements, plotting all.
    relIdx=1:size(justTheField{1}.Data,2);
    relLabels=justTheField{1}.labels;
elseif isa(reqElements,'cell') && isa(reqElements{1},'char') %List of requested labels given/
    for i=1:length(reqElements)
        [flag(i),labelIdx(i)]=justTheField{1}.isaLabel(reqElements{i});
    end
    relIdx=labelIdx(flag==1); %In case some labels don't exist
    relLabels=reqElements(flag==1);
elseif isa(reqElements,'char') && length(reqElements)==1 %Either 'L' or 'R', plotting single side.
    labels=justTheField{1}.labels;
    relIdx=[];
    relLabels={};
    for i=1:length(labels)
        if strcmp(labels{i}(1),reqElements)
            relIdx(end+1)=i;
            relLabels{end+1}=labels{i};
        end
    end
end
Nplots=length(relIdx);

%Find length of all strides, and get data corresponding to the relevant
%labels.
for stride=1:length(strides)
   eval(['relData{stride}=strides{stride}.' field '.getDataAsTS(relLabels);']);
   if plotEvents
        events{stride}=strides{stride}.gaitEvents.getDataAsTS({'RHS','LHS','RTO','LTO'});
   end
   strideLength(stride)=size(relData{stride}.Data,1);
end
N=2^ceil(log2(max(strideLength)));

%Time normalize and put everything in a matrix
for stride=1:length(strides)
   allDataAsMatrix(:,:,stride)=relData{stride}.resampleN(N).getDataAsVector(relLabels);
end

%% Second, check if the plotHandles given (if any) are enough for those plots, otherwise get adequate plotHandles
if nargin<4 || length(plotHandles)~=Nplots
    if Nplots>16
        b=4;
        a=ceil(Nplots/b);
    else
        b=2;
        a=ceil(Nplots/b);
    end
    for i=1:Nplots
        plotHandles(i)=subplot(a,b,i);
    end
end

%% Third, do the plots & link axes in x. Also plot avg.
for i=1:Nplots
   subplot(plotHandles(i))
   hold on
   plot(repmat([0:N-1]'/N,1,length(strides)),squeeze(allDataAsMatrix(:,i,:)),'Color',color);
   if plotEvents
       %To Do
   end
   plot([0:N-1]'/N,mean(allDataAsMatrix(:,i,:),3),'k--');
   ylabel(relLabels{i})
   xlabel('Stride (%)')
   hold off
   if ampNorm
       axis tight
   else
       axis([0 1 min(allDataAsMatrix(:)) max(allDataAsMatrix(:))])
   end
end
linkaxes(plotHandles,'x')

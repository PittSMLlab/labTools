classdef strideData < processedLabData
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties (Dependent)
       isBad
       initialEvent
       originalTrial %returns string
    end
    
    methods
        %Constructor
        function this=strideData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,events,procEMG)
            if nargin<11
               markerData=[];
               EMGData=[];
               GRFData=[];
               beltSpeedSetData=[];
               beltSpeedReadData=[];
               accData=[];
               EEGData=[];
               footSwitches=[];
               events=[];
               procEMG=[];
            end
            %Check that metaData is a srideMetaData
            if ~isa(metaData,'strideMetaData') && ~isa(metaData,'derivedMetaData')
                ME=MException('strideData:Constructor','metaData is not of a strideMetaData object.');
                throw(ME)
            end
            this@processedLabData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches,events,procEMG);
            %Check that events are consistent or label the stride as 'bad'
            if ~isempty(events) && this.isBad
                warning('strideData:Constructor','Events are not consistent with a single stride.')
            end
        end
        
        %Modifiers and partial access:
        fakeStride(this,initEvent) %Generates a fake stride, with data from this stride, buy cutting and pasting phases in different order
        function [dsLR,duration]=getDoubleSupportLR(this)
            dsLR=getIntervalBtwEvents(this,'LHS','RTO');
            duration=dsLR.gaitEvents.timeRange;
        end
        function [dsRL,duration]=getDoubleSupportRL(this)
            dsRL=getIntervalBtwEvents(this,'RHS','LTO');
            duration=dsRL.gaitEvents.timeRange;
        end
        function [int,dur]=getSingleStanceL(this)
            int=getIntervalBtwEvents(this,'RTO','RHS');
            dur=int.gaitEvents.timeRange;
        end
        function [int,dur]=getSingleStanceR(this)
            int=getIntervalBtwEvents(this,'LTO','LHS');
            dur=int.gaitEvents.timeRange;
        end
        function [int,dur]=getSwingL(this)
            [int,dur]=getSingleStanceR(this);
        end
        function [int,dur]=getSwingR(this)
            [int,dur]=getSingleStanceL(this);
        end
        
        %Getters for dependent
        function initEv=get.initialEvent(this)
            if isempty(this.gaitEvents)
                initEv=[];
            else
                aux={'LHS','RHS','LTO','RTO'};
                for i=1:length(aux)
                    evStr=aux{i};
                    event=this.gaitEvents.getDataAsVector(evStr);
                    if event(1)
                        initEv=evStr;
                        break
                    end
                end
            end
        end
        
        function b=get.isBad(this)
            evList={'LHS','RHS','LTO','RTO'};
            for i=1:length(evList)
                eval([evList{i} '= this.gaitEvents.getDataAsVector( evList{i} );']);
            end
            aa=LHS+2*RTO+3*RHS+4*LTO; %This should get events in the sequence 1,2,3,4,1... with 0 for non-events
            bb=diff(aa(aa~=0)); %Keep only event samples
            b=any(mod(bb,4)~=1) || length(bb)<3; %Make sure the order of events is good
            
            
%             b=false;
%             aux={'LHS','RTO','RHS','LTO','LHS','RTO','RHS'};
%             initEv=this.initialEvent;
%             lastEvIdx=1;
%             auxIdx=find(strcmp(initEv,aux),1);
%             newAux=aux((auxIdx+1):(auxIdx+3));
%             %newAux=aux{[auxIdx+1:4,1:auxIdx-1]}; %This requires only the
%             %first four elements of aux.
%             for i=1:length(newAux)
%                 event=this.gaitEvents.getDataAsVector(newAux{i});
%                 idx=find(event==1,1);
%                 if ~(idx>lastEvIdx)
%                     b=true;
%                     break
%                 else
%                     lastEvIdx=idx;
%                 end
%             end
        end
        
        function t=get.originalTrial(this)
            t=this.metaData.parentMetaData.name;
        end
        
        function N=getMasterSampleLength(this) %0 if not time normalized, length of ALL time series otherwise.
           cname=class(this);
           auxLst=properties(cname);
           N=0;
           for i=1:length(auxLst)
               eval(['oldVal=this.' auxLst{i} ';']) %Should try to do this only if the property is not dependent, otherwise, I'm computing things I don't need
               if isa(oldVal,'labTimeSeries')
                   if oldVal.Nsamples~=N %Discrepancy
                       if N==0 %First discrepancy: does not really say anything
                           N=oldVal.Nsamples;
                       else %New discrepancy, it is not time normalized
                           N=0;
                           break;
                       end
                   end
               end
           end
        end
        
        %Modifiers
        function newThis=timeNormalize(this,N,newClass)
           newThis=[]; %Just to avoid Matlab saying this is not defined
           cname=class(this);
           if nargin<3
               metaData=strideMetaData(labDate.genIDFromClock,labDate.getCurrent,'strideData.timeNormalize','normalizedInterval',['Normalized ' this.metaData.description],'Auto-generated',this.metaData);
                eval(['newThis=' cname '(metaData);']); %Call empty constructor of same class
           else
               metaData=strideMetaData(labDate.genIDFromClock,labDate.getCurrent,'strideData.timeNormalize','normalizedInterval',['Normalized  ' this.metaData.description],'Auto-generated',this.metaData); %Should I call a different metaData constructor depending on newClass?
                eval(['newThis=' newClass '(metaData);']); %Call empty constructor of same class
           end
           auxLst=properties(cname);
           for i=1:length(auxLst)
               eval(['oldVal=this.' auxLst{i} ';']) %Should try to do this only if the property is not dependent, otherwise, I'm computing things I don't need
               if isa(oldVal,'labTimeSeries') && ~strcmp(auxLst{i},'EMGData')
                   newVal=oldVal.resampleN(N); %Calling labTS.resample (or one of the subclass' implementation), it should keep the time interval, which for strided data should 
               elseif strcmp(auxLst{i},'EMGData')
                   k=this.EMGData.Nsamples/this.markerData.Nsamples;
                   NN=2^ceil(log2(k*N));
                   newVal=oldVal.resampleN(NN);
               elseif ~isa(oldVal,'labMetaData') 
                   newVal=oldVal; %Not a labTS object, not splitting
               end
               try
                  eval(['newThis.' auxLst{i} '=newVal;']) %If this fails is because the property is not settable
               catch 
                  if isa(oldVal,'labTimeSeries')
                      disp(['Failed to set new labTS value' auxLst{i}]);
                  end
               end
           end
        end
        
        function newThis=alignEvents(this,events,spacing)
           newThis=[]; %Need to do. Current problem: sampling needs to be uniform, but when we alignEvents that can no longer be the case (because event times have natural variability, its alignment implies that we'll have non-uniform sampling  
        end
        
    end
    
    methods(Static)
        
        function [strideMat]=cell2mat(strides,field,N) %Cell array of strideData to matrix
            strideMat=[];
           if isa(strides,'cell') && all(cellisa(strides,'strideData'))
               auxLst=properties('strideData');
               if any(strcmp(auxLst,field))
                   eval(['testField=strides{1}.' field ';'])
                   if isa(testField,'labTimeSeries')
                       M=length(strides);
                       for i=1:M
                           eval(['testField=strides{i}.' field ';'])
                           strideMat(:,:,i)=testField.resampleN(N).getDataAsVector(testField.getLabels);
                       end
                   elseif ~isa(testField,'double')
                       for i=1:length(strides)
                           eval(['testField=strides{i}.' field ';'])
                           strideMat(:,:,i)=testField;
                       end
                   end
                       
               else
                   ME=MException('strideDataCell2mat:unknownField','The provided fieldname is not a property of strideData objects, or is not of labTS type.');
                   throw(ME);
               end
           else
               ME=MException('strideDataCell2mat:wrongInput','Input needs to be a cell array of strideData objects.');
               throw(ME);
           end
        end
        
        [plotHandles]=plotCell(strides,field,ampNorm,plotHandles,reqElements,color,plotEvents)
%         function [plotHandle,offset,ampCoefs]=plotCell(strides,field,N,sync_norm,ampNorm,plotHandle,side,color,offset,plotEv) %Plot cellarray of stride data
%             if nargin<10
%                 plotEv=0;
%             end
%             
%             subplot(plotHandle)
%             eval(['testField=strides{1}.' field ';'])
%             data=strideData.cell2mat(strides,field,N);
%             if numel(ampNorm)>1
%                 ampCoefs=ampNorm; %Should check that numel==size(data,2)
%                 ampNorm=1;
%             else
%                 ampCoefs=[];
%             end
%             if isa(testField,'labTimeSeries')
%                 eval(['labels=strides{1}.' field '.getLabels;']);
%                 if strcmp(field,'procEMGData')
%                     data=data*8;
%                 end
% 
%                 if nargin>6 && ~isempty(side) %Plot only selected side/labels
%                     indLabels=false(size(labels));
%                     for i=1:length(labels)
%                         if isa(side,'char') %Assuming it is only 'L' or 'R'
%                             if strcmp(labels{i}(1),side)
%                                 indLabels(i)=true; %Only the specified side labels
%                             end
%                         elseif isa(side,'cell') && isa(side{1},'char') %List of labels
%                             if any(strcmp(labels{i},side))
%                                 indLabels(i)=true; %Only the specified side labels
%                             end
%                         else
%                             indLabels(i)=false; %No labels
%                         end
%                     end
%                 else
%                     indLabels=true(size(labels)); %All labels
%                 end
%                 
%                 if nargin<7
%                     color=[.5,.5,.5];
%                 end
%                 %Do the plot:
%                 raw=data(:,indLabels==1,:); %Just one side muscles
%                 %auxMax=auxMax(:,indLabels==1,:); 
%                 hold on
%                 switch sync_norm
%                     case 0 %Do nothing
% 
%                     case 1 %Renormalize to swing/stance
%                         %To Do 
%                     case 2 %Renormalize to 4 phases
%                         %To Do
%                 end
%                 switch ampNorm
%                     case 0 %Do nothing
%                         if nargin>8 && ~isempty(offset)
%                             mOffset=offset;
%                         else
%                             mOffset=3*max(abs(raw(:)));
%                         end
%                         ampCoefs=0;
%                     case 1 %Normalize amplitude to [0,1] for EACH label/component of data
%                         if isempty(ampCoefs)
%                             ampCoefs=max(max(abs(raw),[],1),[],3);
%                             if any(ampCoefs==zeros(size(ampCoefs)))
%                                 ampCoefs(ampCoefs==0)=1/100000;
%                             end
%                         end
%                         raw=.9*raw./repmat(ampCoefs,size(raw,1),1,size(raw,3));
%                         mOffset=3;
%                 end
%                 for stride=1:size(raw,3)
%                     %Plot
%                     auxMusc=mOffset*repmat([0:size(raw,2)-1],size(raw,1),1);
%                     hh=plot([0:N-1]/N,auxMusc+raw(:,:,stride),'Color',color);
%                     uistack(hh,'bottom');
%                     if plotEv==1
%                         %Add events:
%                         auxN=[0:N-1]/N;
%                         events=strides{stride}.gaitEvents.resampleN(N).getDataAsVector({'LHS','RHS','LTO','RTO'});
%                         plot(auxN(events(:,1)==1),auxMusc(events(:,1)==1,:)+raw(events(:,1)==1,:,stride),'sy')
%                         plot(auxN(events(:,2)==1),auxMusc(events(:,2)==1,:)+raw(events(:,2)==1,:,stride),'sm')
%                         plot(auxN(events(:,3)==1),auxMusc(events(:,3)==1,:)+raw(events(:,3)==1,:,stride),'sk')
%                         plot(auxN(events(:,4)==1),auxMusc(events(:,4)==1,:)+raw(events(:,4)==1,:,stride),'sg')
%                     end
%                 end
%                 set(gca,'YTick',mOffset*[0:size(raw,2)-1],'YTickLabel',labels(indLabels==1));
%                 axis([0 1 -mOffset/2 mOffset*size(raw,2)-mOffset/2])
%                 xlabel('% stride')
%                 ax1 = gca;
%                 %Add secondary axes for scale: (fancy, matters only if amp is not normalized)
%                 ax2 = axes('Position',get(ax1,'Position'),...
%                    'XAxisLocation','top',...
%                    'YAxisLocation','right',...
%                    'Color','none',...
%                    'XColor','r','YColor','r');
%                 linkaxes([ax1,ax2],'xy')
%                 auxTick=[-mOffset/2:mOffset/4:(mOffset*size(raw,2)-mOffset/2)];
%                 %auxTick(1:4:end)=[];
%                 for i=1:length(auxTick)
%                     if mod(i,4)==1
%                         auxTickLabel{i}='';
%                     else
%                         auxTickLabel{i}= (mod(i-1,4)-2)*mOffset/4;
%                     end
%                 end
%                 set(ax2,'YTick',auxTick,'YTickLabel',auxTickLabel);
%                 set(ax2,'XTick',[]);
%                 hold off
%                 offset=mOffset;
%             end
%         end
        
        function [plotHandle,offset,ampCoefs]=plotCellAvg(strides,field,N,sync_norm,ampNorm,plotHandle,side,color,offset,plotEv) %Plot cellarray of stride data
            if nargin<10
                plotEv=0;
            end
            if nargin>5 && ~isempty(plotHandle)
                subplot(plotHandle)
            end
            eval(['testField=strides{1}.' field ';'])
            data=strideData.cell2mat(strides,field,N);
            if numel(ampNorm)>1
                ampCoefs=ampNorm; %Should check that numel==size(data,2)
                ampNorm=1;
            else
                ampCoefs=[];
            end
            if isa(testField,'labTimeSeries')
                eval(['labels=strides{1}.' field '.getLabels;']);
                if strcmp(field,'procEMGData')
                    data=data*8;
                end

                if nargin>6 && ~isempty(side)
                    indLabels=false(size(labels));
                    for i=1:length(labels)
                        if isa(side,'char') %Assuming it is only 'L' or 'R'
                            if strcmp(labels{i}(1),side)
                                indLabels(i)=true; %Only the specified side labels
                            end
                        elseif isa(side,'cell') && isa(side{1},'char') %List of labels
                            if any(strcmp(labels{i},side))
                                indLabels(i)=true; %Only the specified side labels
                            end
                        else
                            indLabels(i)=false; %No labels
                        end
                    end
                else
                    indLabels=true(size(labels)); %All labels
                end
                if nargin<7
                    color=[.5,.5,.5];
                end
                %Do the plot:
                raw=data(:,indLabels==1,:); %Just one side muscles
                %auxMax=auxMax(:,indLabels==1,:); 
                hold on
                switch sync_norm
                    case 0 %Do nothing

                    case 1 %Renormalize to swing/stance
                        %To Do 
                    case 2 %Renormalize to 4 phases
                        %To Do
                end
                switch ampNorm
                    case 0 %Do nothing
                        if nargin>8 && ~isempty(offset)
                            mOffset=offset;
                        else
                            mOffset=2*max(abs(raw(:)));
                        end
                        ampCoefs=0;
                    case 1 %Normalize amplitude to [0,1] for EACH label/component of data
                        if isempty(ampCoefs)
                            ampCoefs=mean(max(abs(raw),[],1),3);
                        end
                        raw=.9*raw./repmat(ampCoefs,size(raw,1),1,size(raw,3));
                        mOffset=2;
                end
                    %Plot
                    auxMusc=mOffset*repmat([0:size(raw,2)-1],size(raw,1),1);
                    plot([0:N-1]/N,auxMusc+mean(raw,3),'Color',[.5,.5,.8].*color,'LineWidth',2);
                    haa=plot([0:N-1]/N,auxMusc+mean(raw,3)+std(raw,[],3),'Color',color,'LineWidth',1);
                    uistack(haa,'bottom');
                    haa=plot([0:N-1]/N,auxMusc+mean(raw,3)-std(raw,[],3),'Color',color,'LineWidth',1);
                    uistack(haa,'bottom');
                if plotEv==1
                   %Add events 
                   events=strideData.cell2mat(strides,'gaitEvents',N);
                   eventLabels=strides{1}.gaitEvents.getLabels;
                   idx=strcmp(eventLabels,'LHS');
                   LHSev=round(sum([1:N]'.*mean(events(:,idx==1,:),3)));
                   idx=strcmp(eventLabels,'RHS');
                   RHSev=round(sum([1:N]'.*mean(events(:,idx==1,:),3)));
                   idx=strcmp(eventLabels,'LTO');
                   LTOev=round(sum([1:N]'.*mean(events(:,idx==1,:),3)));
                   idx=strcmp(eventLabels,'RTO');
                   RTOev=round(sum([1:N]'.*mean(events(:,idx==1,:),3)));
                   plot((LHSev-1)/N,auxMusc(LHSev,:)+mean(raw(LHSev,:,:),3),'s','Color',color);
                   plot((RHSev-1)/N,auxMusc(RHSev,:)+mean(raw(RHSev,:,:),3),'s','Color',color);
                   plot((LTOev-1)/N,auxMusc(LTOev,:)+mean(raw(LTOev,:,:),3),'s','Color',color);
                   plot((RTOev-1)/N,auxMusc(RTOev,:)+mean(raw(RTOev,:,:),3),'s','Color',color);
                end
                set(gca,'YTick',mOffset*[0:size(raw,2)-1],'YTickLabel',labels(indLabels==1));
                axis([0 1 -mOffset/2 mOffset*size(raw,2)-mOffset/2])
                xlabel('% stride')
                ax1 = gca;
                %Add secondary axes for scale: (fancy, matters only if amp is not normalized)
                ax2 = axes('Position',get(ax1,'Position'),...
                   'XAxisLocation','top',...
                   'YAxisLocation','right',...
                   'Color','none',...
                   'XColor','r','YColor','r');
                linkaxes([ax1,ax2],'xy')
                auxTick=[-mOffset/2:mOffset/4:(mOffset*size(raw,2)-mOffset/2)];
                %auxTick(1:4:end)=[];
                for i=1:length(auxTick)
                    if mod(i,4)==1
                        auxTickLabel{i}='';
                    else
                        auxTickLabel{i}= (mod(i-1,4)-2)*mOffset/4;
                    end
                end
                set(ax2,'YTick',auxTick,'YTickLabel',auxTickLabel);
                set(ax2,'XTick',[]);
                hold off
                offset=mOffset;
            end
        end
        
        %function avgStride=getCellAvg(strides,N) %Pseudo-code
            %for i=properties
            %   strideMat=cell2mat(strides,field,N) %If it is a labTS only
            %   avgFieldData=mean(strideMat,3);
            %   avgField=fieldConstructor(avgFieldTime,avgFieldData);
            %   avgStride.field=avgField; %If it is not a labTS, make an
            %   empty field or copy it from first stride
            %end
        %end
        
        %function [avgEventsTime,Labels]=plotAvgEvent
        %end
    end
    
    methods(Access=private)
        function interval=getIntervalBtwEvents(this,event1,event2)
           if strcmp(this.initialEvent,event1)
                t0=this.gaitEvents.Time(1);
            else
                t0=this.gaitEvents.Time(find(this.gaitEvents.getDataAsVector({event1})==1,1));
            end
            if strcmp(this.initialEvent,event2)
                t1=this.gaitEvents.Time(end)+this.gaitEvents.sampPeriod;
            else
                t1=this.gaitEvents.Time(find(this.gaitEvents.getDataAsVector({event2})==1,1));
            end
            if t1<=t0
                ME=MException('strideData:GetInterval','The requested interval does not exist as such on this stride.');
                throw(ME)
            end
            interval=this.split(t0,t1); 
        end
    end
    
end


classdef strideData < processedLabData
    %strideData  Represents data from a single gait stride
    %
    %   strideData extends processedLabData to handle data from
    %   individual stride cycles, including stride validation, phase
    %   extraction, and time normalization.
    %
    %strideData properties:
    %   isBad - logical flag indicating if stride has inconsistent
    %           events
    %   initialEvent - first gait event in the stride
    %   originalTrial - name of parent trial from which stride was
    %                   extracted
    %
    %strideData methods:
    %
    %   fakeStride - generates fake stride by reordering phases
    %   getDoubleSupportLR - extracts left-to-right double support
    %                        phase
    %   getDoubleSupportRL - extracts right-to-left double support
    %                        phase
    %   getSingleStanceL - extracts left single stance phase
    %   getSingleStanceR - extracts right single stance phase
    %   getSwingL - extracts left swing phase
    %   getSwingR - extracts right swing phase
    %   getMasterSampleLength - returns common sample length if time
    %                           normalized
    %   timeNormalize - resamples all data to uniform length
    %   alignEvents - aligns data to gait events (unimplemented)
    %
    %strideData static methods:
    %
    %   cell2mat - converts cell array of strides to matrix
    %   plotCell - plots cell array of stride data
    %   plotCellAvg - plots average and std of stride cell array
    %
    %See also: processedLabData, labData, strideMetaData

    %% Properties
    properties (Dependent)
        isBad
        initialEvent
        originalTrial % returns string
    end

    %% Constructor
    methods
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

        %% Phase Extraction Methods
        methods
            fakeStride(this, initEvent)

            [dsLR, duration] = getDoubleSupportLR(this)

            [dsRL, duration] = getDoubleSupportRL(this)

            [int, dur] = getSingleStanceL(this)

            [int, dur] = getSingleStanceR(this)

            [int, dur] = getSwingL(this)

            [int, dur] = getSwingR(this)
        end

        %% Dependent Property Getters
        methods
            function initEv = get.initialEvent(this)
                if isempty(this.gaitEvents)
                    initEv = [];
                else
                    aux = {'LHS', 'RHS', 'LTO', 'RTO'};
                    for i = 1:length(aux)
                        evStr = aux{i};
                        event = this.gaitEvents.getDataAsVector(evStr);
                        if event(1)
                            initEv = evStr;
                            break;
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

            function t = get.originalTrial(this)
                t = this.metaData.parentMetaData.name;
            end
        end

        %% Data Query Methods
        methods
            N = getMasterSampleLength(this)
        end

        %% Data Transformation Methods
        methods
            newThis = timeNormalize(this, N, newClass)

            newThis = alignEvents(this, events, spacing)
            end

            %% Static Methods
            methods (Static)
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

            %% Private Methods
            methods (Access = private)
                interval = getIntervalBtwEvents(this, event1, event2)
            end

        end


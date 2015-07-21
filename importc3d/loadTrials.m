function trials=loadTrials(trialMD,fileList,secFileList,info)
%loadTrials  generates rawTrialData objects for each trial of a
%given experiment.
%
%INPUTS:
%trialMD: cell array of trailMetaData objects where the cell index corresponds
%to the trial number
%fileList: list of .c3d files containing kinematic and force data for a given experiment
%secFileList: list of files containing EMG data for a given experiment
%info: structured array output from GetInfoGUI
%
%OUTPUT:
%trials: cell array of rawTrialData objects where the cell index corresponds
%to the trial number
%
%See also: rawTrialData

%orientationInfo(offset,foreaftAx,sideAx,updownAx,foreaftSign,sideSign,updownSign)
orientation=orientationInfo([0,0,0],'y','x','z',1,1,1); %check signs!

%Create list of expected/accepted muscles:
orderedMuscleList={'PER','TA','SOL','MG','LG','RF','VM','VL','BF','SEMB','SEMT','ADM','GLU','TFL','ILP','SAR','HIP'}; %This is the desired order
orderedEMGList={};
for j=1:length(orderedMuscleList)
    orderedEMGList{end+1}=['R' orderedMuscleList{j}];
    orderedEMGList{end+1}=['L' orderedMuscleList{j}];
end
        
for t=cell2mat(info.trialnums)
    %Import data from c3d, uses external toolbox BTK
    H=btkReadAcquisition([fileList{t} '.c3d']);
    [analogs,analogsInfo]=btkGetAnalogs(H);
    secondFile=false;
    if ~isempty(secFileList{t})
        H2=btkReadAcquisition([secFileList{t} '.c3d']);
        [analogs2,analogsInfo2]=btkGetAnalogs(H2);
        secondFile=true;
    end    
    
    %% GRFData
    if info.forces
        showWarning = false;%must define or else error is thrown when otherwise case is skipped
        relData=[];
        forceLabels ={};
        units={};
        fieldList=fields(analogs);
        for j=1:length(fieldList);
            %if strcmp(fieldList{j}(end-2),'F') || strcmp(fieldList{j}(end-2),'M') %Getting fields that end in F.. or M.. only
            if strcmp(fieldList{j}(1),'F') || strcmp(fieldList{j}(1),'M') || ~isempty(strfind(fieldList{j},'Force')) || ~isempty(strfind(fieldList{j},'Moment'))
                if ~strcmpi('x',fieldList{j}(end-1)) && ~strcmpi('y',fieldList{j}(end-1)) && ~strcmpi('z',fieldList{j}(end-1))
                    warning(['loadTrials:GRFs','Found force/moment data that does not correspond to any of the expected directions (x,y or z). Discarding channel ' fieldList{j}])
                else
                switch fieldList{j}(end)
                    case '1' %Forces/moments ending in '1' area assumed to be of left treadmill belt
                        forceLabels{end+1} = ['L',fieldList{j}(end-2:end-1)];
                        units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
                        relData=[relData,analogs.(fieldList{j})];
                    case '2' %Forces/moments ending in '2' area assumed to be of right treadmill belt
                        forceLabels{end+1} = ['R',fieldList{j}(end-2:end-1)];
                        units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
                        relData=[relData,analogs.(fieldList{j})];
                    case '4'%Forces/moments ending in '4' area assumed to be of handrail
                        forceLabels{end+1} = ['H',fieldList{j}(end-2:end-1)];
                        units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
                        relData=[relData,analogs.(fieldList{j})];
                    otherwise
                        showWarning=true;%%HH moved warning outside loop on 6/3/2015 to reduce command window output                        
                end
                analogs=rmfield(analogs,fieldList{j}); %Just to save memory space
                end
            end
        end    
        if showWarning
            warning(['loadTrials:GRFs','Found force/moment data in trial ' num2str(t) ' that does not correspond to any of the expected channels (L=1, R=2, H=4). Data discarded.'])
        end
        %Sanity check: offset calibration
                
        %Create labTimeSeries (data,t0,Ts,labels,orientation)
        if size(relData,2)<12 %we don't have at least 3 forces and 3 moments per belt
            warning('loadTrials:GRFs',['Did not find all GRFs for the two belts in trial ' num2str(t)])
        end
        GRFData=orientedLabTimeSeries(relData,0,1/analogsInfo.frequency,forceLabels,orientation);
        GRFData.DataInfo.Units=units;
    else
        GRFData=[];
    end
    clear relData*
    
    %% EMGData (from 2 files!) & Acceleration data
    if info.EMGs
        %Primary file (PC)
        relData=[];
        relDataTemp=[];
        fieldList=fields(analogs);
        idxList=[];
        for j=1:length(fieldList);
            if  ~isempty(strfind(fieldList{j},'EMG'))  %Getting fields that start with 'EMG' only
                relDataTemp=[relDataTemp,analogs.(fieldList{j})];
                idxList(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'EMG')+3:end));
                analogs=rmfield(analogs,fieldList{j}); %Just to save memory space
            end
        end
        emptyChannels1=cellfun(@(x) isempty(x),info.EMGList1);
        EMGList1=info.EMGList1(~emptyChannels1);
        relData(:,idxList)=relDataTemp; %Re-sorting to fix the 1,10,11,...,2,3 count that Matlab does
        relData=relData(:,~emptyChannels1);
        EMGList=EMGList1;
        
        %Secondary file (PC)
        relDataTemp2=[];
        idxList2=[];
        if secondFile
            fieldList=fields(analogs2);
            for j=1:length(fieldList);
                if  ~isempty(strfind(fieldList{j},'EMG'))  %Getting fields that start with 'EMG' only
                    relDataTemp2=[relDataTemp2,analogs2.(fieldList{j})];
                    idxList2(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'EMG')+3:end));
                    analogs2=rmfield(analogs2,fieldList{j}); %Just to save memory space
                end
            end
            emptyChannels2=cellfun(@(x) isempty(x),info.EMGList2);
            EMGList2=info.EMGList2(~emptyChannels2); %Just using the names for the channels that were actually in the file
            relData2(:,idxList2)=relDataTemp2; %Re-sorting to fix the 1,10,11,...,2,3 count that Matlab does
            relData2=relData2(:,~emptyChannels2);
            EMGList=[EMGList1,EMGList2];
        end
        
        %Check if names match with expectation, otherwise query user
        for k=1:length(EMGList)
            while sum(strcmpi(orderedEMGList,EMGList{k}))==0 && ~strcmpi(EMGList{k}(1:4),'sync')
                aux= inputdlg(['Did not recognize muscle name, please re-enter name for channel ' num2str(k) ' (was ' EMGList{k} '). Acceptable values are ' cell2mat(strcat(orderedEMGList,', ')) ' or ''sync''.'],'s');
                if k<=length(EMGList1)
                    info.EMGList1{idxList(k)}=aux{1}; %This is to keep the same message from being prompeted for each trial processed.
                else
                    info.EMGList2{idxList2(k-length(EMGList1))}=aux{1};
                end
                EMGList{k}=aux{1};
            end
        end
        
        %For some reasing the naming convention for analog pins is not kept
        %across Nexus versions:
        try
            refSync=analogs.Pin_3;
        catch
            try
                refSync=analogs.Raw_Pin_3;  
            catch
                refSync=analogs.Raw_Raw_Pin_3; 
            end
        end
        
        %Check for frequencies between the two PCs
        if secondFile
            if abs(analogsInfo.frequency-analogsInfo2.frequency)>eps
                warning('Sampling rates from the two computers are different, down-sampling one under the assumption that sampling rates are multiple of each other.')
                %Assuming that the sampling rates are multiples of one another
                if analogsInfo.frequency>analogsInfo2.frequency 
                    %First set is the up-sampled one, reducing
                    P=analogsInfo.frequency/analogsInfo2.frequency;
                    R=round(P);
                    relData=relData(1:R:end,:);
                    refSync=refSync(1:R:end);
                    EMGfrequency=analogsInfo2.frequency;
                else
                    P=round(analogsInfo2.frequency/analogsInfo.frequency);
                    R=round(P);
                    relData2=relData2(1:R:end,:);
                    EMGfrequency=analogsInfo.frequency;
                end
                if abs(R-P)>1e-7
                    error('loadTrials:unmatchedSamplingRatesForEMG','The different EMG files are sampled at different rates and they are not multiple of one another')
                end
            end
        else
            EMGfrequency=analogsInfo.frequency;
        end
        
        %Only keeping matrices of same size to one another:
        if secondFile
            [auxData, auxData2] = truncateToSameLength(relData,relData2);
            allData=[auxData,auxData2];
            clear auxData*
        else
            allData=relData;
        end
        
        %Pre-process:
        refAux=medfilt1(refSync,20);
        refAux=medfilt1(diff(refAux),10);
        clear auxData*
        syncIdx=strncmpi(EMGList,'Sync',4); %Compare first 4 chars in string list
        sync=allData(:,syncIdx);
        if ~isempty(sync) %Only proceeding with synchronization if there are sync signals 
        N=size(sync,1);
        aux=medfilt1(sync,20,[],1);
        aux=medfilt1(diff(aux),10,[],1);
        if secondFile
            [~,timeScaleFactor,lagInSamples,~] = matchSignals(aux(:,1),aux(:,2));
            newRelData2 = resampleShiftAndScale(relData2,timeScaleFactor,lagInSamples,1); %Aligning relData2 to relData1. There is still the need to find the overall delay of the EMG system with respect to forceplate data.
        end
        [~,timeScaleFactorA,lagInSamplesA,~] = matchSignals(refAux,aux(:,1));
        newRelData = resampleShiftAndScale(relData,1,lagInSamplesA,1);
        if secondFile
            newRelData2 = resampleShiftAndScale(newRelData2,1,lagInSamplesA,1);
        end
        
        %Only keeping matrices of same size to one another:
        if secondFile
            [auxData, auxData2] = truncateToSameLength(newRelData,newRelData2);
            clear newRelData*
            allData=[auxData,auxData2];
            clear auxData*
        else
            allData=newRelData;
        end
        
        %Finding gains through least-squares on high-pass filtered synch
        %signals (why using HPF for gains and not for synch?)
        refSync=idealHPF(refSync,0);
        [allData,refSync]=truncateToSameLength(allData,refSync);
        syncIdx=strncmpi(EMGList,'Sync',4); %Compare first 4 chars in string list
        sync=idealHPF(allData(:,syncIdx),0);
        gain1=refSync'/sync(:,1)';
        E1=sum((refSync(max([lagInSamplesA+1,1]):end)-sync(max([lagInSamplesA+1,1]):end,1)*gain1).^2)/sum(refSync.^2); %Computing error energy as % of original signal energy, only considering the time interval were signals were simultaneously recorded.
        if secondFile
            gain2=refSync'/sync(:,2)';
            E2=sum((refSync(max([lagInSamplesA+1+lagInSamples,1]):end)-sync(max([lagInSamplesA+1+lagInSamples,1]):end,2)*gain2).^2)/sum(refSync.^2);
        else
            E2=0;
            gain2=NaN;
            timeScaleFactor=NaN;
            lagInSamples=NaN;
        end

        %Analytic measure of alignment problems 
        disp(['Sync complete: mismatch signal energy (as %) was ' num2str(E1,3) ' and ' num2str(E2,3) '.'])
        disp(['Sync parameters were: gains= ' num2str(gain1,4) ', ' num2str(gain2,4) '; delays= ' num2str(lagInSamplesA/EMGfrequency,3) 's, ' num2str((lagInSamplesA+lagInSamples)/EMGfrequency,3) 's; sampling mismatch= ' num2str(1-timeScaleFactor,5)]);
        if E1>.01 || E2>.01 %Signal difference has at least 1% of original signal energy
            warning(['Time alignment doesnt seem to have worked: signal mismatch is too high in trial ' num2str(t) '.'])
            h=figure;
            subplot(2,2,[1:2])
            hold on
            title(['Trial ' num2str(t) ' Synchronization'])
            time=[0:length(refSync)-1]*1/EMGfrequency;
            plot(time,refSync)
            plot(time,sync(:,1)*gain1,'r')
            plot(time,sync(:,2)*gain2,'g')
            legend('refSync',['sync1, delay=' num2str(lagInSamplesA/EMGfrequency,3) 's'],['sync2, delay=' num2str((lagInSamplesA+lagInSamples)/EMGfrequency,3)  's'])
            hold off
            subplot(2,2,3)
            T=round(3*EMGfrequency); %To plot just 3 secs at the beginning and at the end
            if T<length(refSync)
                hold on
                plot(time(1:T),refSync(1:T))
                plot(time(1:T),sync(1:T,1)*gain1,'r')
                plot(time(1:T),sync(1:T,2)*gain2,'g')
                hold off
                subplot(2,2,4)
                hold on
                plot(time(end-T:end),refSync(end-T:end))
                plot(time(end-T:end),sync(end-T:end,1)*gain1,'r')
                plot(time(end-T:end),sync(end-T:end,2)*gain2,'g')
                hold off
            end
            s=inputdlg('Please confirm that you want to proceed like this (y/n)','str');
            switch s{1}
                case {'y','Y','yes'}
                     disp(['Using signals in a possibly unsynchronized way!.'])
                     close(h)
                case {'n','N','no'}
                    error('loadTrials:EMGCouldNotBeSynched','Could not synchronize EMG data, stopping data loading.')
            end
        end
        
        %Plot to CONFIRM VISUALLY if alignment worked:
        h=figure;
        subplot(2,2,[1:2])
        hold on
        title(['Trial ' num2str(t) ' Synchronization'])
        time=[0:length(refSync)-1]*1/EMGfrequency;
        plot(time,refSync)
        plot(time,sync(:,1)*gain1,'r')
        if secondFile
            plot(time,sync(:,2)*gain2,'g')
            legend('refSync',['sync1, delay=' num2str(lagInSamplesA/EMGfrequency,3) 's'],['sync2, delay=' num2str((lagInSamplesA+lagInSamples)/EMGfrequency,3)  's'])
        else           
            legend('refSync',['sync1, delay=' num2str(lagInSamplesA/EMGfrequency,3) 's'])
        end
        hold off
        subplot(2,2,3)
        T=round(3*EMGfrequency); %To plot just 3 secs at the beginning and at the end
        if T<length(refSync)
        hold on
         plot(time(1:T),refSync(1:T))
        plot(time(1:T),sync(1:T,1)*gain1,'r')
        if secondFile
        plot(time(1:T),sync(1:T,2)*gain2,'g')
        end
        %legend('refSync',['sync1, delay=' num2str(lagInSamplesA/analogsInfo.frequency,3) 's'],['sync2, delay=' num2str((lagInSamplesA+lagInSamples)/analogsInfo.frequency,3)  's'])
        hold off
        subplot(2,2,4)
        hold on
        plot(time(end-T:end),refSync(end-T:end))
        plot(time(end-T:end),sync(end-T:end,1)*gain1,'r')
        if secondFile
        plot(time(end-T:end),sync(end-T:end,2)*gain2,'g')
        end
        %legend('refSync',['sync1, delay=' num2str(lagInSamplesA/analogsInfo.frequency,3) 's'],['sync2, delay=' num2str((lagInSamplesA+lagInSamples)/analogsInfo.frequency,3)  's'])
        hold off
        end
        saveFig(h,'./',['Trial ' num2str(t) ' Synchronization'])
%         uiwait(h)
        else
            warning('No sync signals were present, using data as-is.')
        end
        
        
        %Sorting muscles (orderedEMGList was created previously) so that they are always stored in the same order
        orderedIndexes=zeros(length(orderedEMGList),1);
        for j=1:length(orderedEMGList)
            for k=1:length(EMGList)
                if strcmpi(orderedEMGList{j},EMGList{k})
                    orderedIndexes(j)=k;
                    break;
                end
            end
        end
        orderedIndexes=orderedIndexes(orderedIndexes~=0); %Avoiding missing muscles
        aux=zeros(length(EMGList),1);
        aux(orderedIndexes)=1;
        if any(aux==0) && ~all(strcmpi(EMGList(aux==0),'sync'))
            warning(['loadTrials: Not all of the provided muscles are in the ordered list, ignoring ' EMGList{aux==0}])
        end
        allData(allData==0)=NaN; %Eliminating samples that are exactly 0: these are unavailable samples
        EMGData=labTimeSeries(allData(:,orderedIndexes),0,1/EMGfrequency,EMGList(orderedIndexes)); %Throw away the synch signal
        clear allData* relData* auxData*
        
        %% AccData (from 2 files too!)
        %Primary file
        relData=[];
        idxList=[];
        fieldList=fields(analogs);
        for j=1:length(fieldList);
            if ~isempty(strfind(fieldList{j},'ACC'))  %Getting fields that start with 'ACC' only
                idxList(j)=str2num(fieldList{j}(strfind(fieldList{j},'ACC')+4:end));
                switch fieldList{j}(strfind(fieldList{j},'ACC')+3)
                    case 'X'
                        aux=1;
                    case 'Y'
                        aux=2;
                    case 'Z'
                        aux=3;
                end
                eval(['relData(:,idxList(j),aux)=analogs.' fieldList{j} ';']);
                analogs=rmfield(analogs,fieldList{j}); %Just to save memory space
            end
        end
        relData=permute(relData(:,~emptyChannels1,:),[1,3,2]);
        relData=relData(:,:);
        if EMGfrequency~=analogsInfo.frequency %The frequency was changed when downsampling EMG data
            P=analogsInfo.frequency/EMGfrequency;
            R=round(P);
            relData=relData(1:R:end,:);
        end
        %Fixing time alignment 
        if ~isempty(sync)
            relData = resampleShiftAndScale(relData,1,lagInSamplesA,1);
        end
        
        
        %Secondary file
        relData2=[];
        idxList2=[];
        if secondFile
            fieldList=fields(analogs2);
            for j=1:length(fieldList);
                if ~isempty(strfind(fieldList{j},'ACC'))  %Getting fields that start with 'EMG' only
                    idxList2(j)=str2num(fieldList{j}(strfind(fieldList{j},'ACC')+4:end));
                    switch fieldList{j}(strfind(fieldList{j},'ACC')+3)
                        case 'X'
                            aux=1;
                        case 'Y'
                            aux=2;
                        case 'Z'
                            aux=3;
                    end
                    eval(['relData2(:,idxList2(j),aux)=analogs2.' fieldList{j} ';']);
                    analogs2=rmfield(analogs2,fieldList{j}); %Just to save memory space
                end
            end
            relData2=permute(relData2(:,~emptyChannels2,:),[1,3,2]);
            relData2=relData2(:,:);
            if EMGfrequency~=analogsInfo2.frequency %The frequency was changed when downsampling EMG data
                P=analogsInfo2.frequency/EMGfrequency;
            	R=round(P);
                relData2=relData2(1:R:end,:);
            end
            %Fixing time alignment       
            if ~isempty(sync)
                    relData2 = resampleShiftAndScale(relData2,timeScaleFactor,lagInSamples,1); %Aligning relData2 to relData1. There is still the need to find the overall delay of the EMG system with respect to forceplate data.
                    relData2 = resampleShiftAndScale(relData2,1,lagInSamplesA,1);
                    [auxData, auxData2] = truncateToSameLength(relData,relData2);
                    clear relData*
                    allData=[auxData,auxData2];
                    clear auxData* 
            else
                    allData=[relData,relData2]; %No synch, two files
            end
        else
            allData=relData;
        end
        
        %Throwing away empty fields (same that were thrown on EMG data)
        
        % Assign names:
        ACCList={};
        for j=1:length(EMGList)
            ACCList{end+1}=[EMGList{j} 'x'];
            ACCList{end+1}=[EMGList{j} 'y'];
            ACCList{end+1}=[EMGList{j} 'z'];
        end
        
        accData=orientedLabTimeSeries(allData(1:13:end,:),0,13/EMGfrequency,ACCList,orientation); %Downsampling to ~150Hz, which is much closer to the original 148Hz sampling rate (where does this get upsampled? why?)
        % orientation is fake: orientation is local and unique to each sensor, which is affixed to a body segment.
        clear allData* relData* auxData*
    else
        EMGData=[];
        accData=[];
    end
    
    %% MarkerData
    clear analogs* %Save memory space, no longer need analog data, it was already loaded
    if info.kinematics
        [markers,markerInfo]=btkGetMarkers(H);
        relData=[];
        fieldList=fields(markers);
        markerList={};
        
        %Check marker labels are good in .c3d files        
        mustHaveLabels={'LHIP','RHIP','LANK','RANK','RHEE','LHEE','LTOE','RTOE','RKNE','LKNE'};
        labelPresent=false(1,length(mustHaveLabels));
        for i=1:length(fieldList)
            newFieldList{i}=findLabel(fieldList{i});
            labelPresent=labelPresent+ismember(mustHaveLabels,newFieldList{i});
        end
        
%         %if any of the must-have labels are not present, terminate script
%         %and throw warning.
%         if any(~labelPresent)
%             missingLabels=find(~labelPresent);
%             str=' ';
%             for j=missingLabels
%                 str=[str ', ' mustHaveLabels{j}];
%             end
%             ME=MException('loadTrials:markerDataError',['Marker data does not contain:' str '. Edit ''findLabel'' code to fix.']);
%             throw(ME)
%         end
        
        %atlernatively, 
        if any(~labelPresent)
            missingLabels=find(~labelPresent);
            potentialMatches=newFieldList(~ismember(newFieldList,mustHaveLabels));
            for j=missingLabels
                %generate menu
                choice = menu([{['WARNING: the marker label ' mustHaveLabels{j}]},{' was not found, but is necessary for'},...
                    {'future calculations.Please indicate which'},{[' marker corresponds to the ' mustHaveLabels{j} ' label:']}] ,potentialMatches);
                if choice==0
                    ME=MException('loadTrials:markerDataError','Operation terminated by user while finding names of necessary labels.');
                    throw(ME)
                else
                    %set the label corresponding to choice as one of the must-have labels
                    addMarkerPair(mustHaveLabels{j},potentialMatches{choice})
                end
            end
        end
        
        for j=1:length(fieldList);
            if length(fieldList{j})>2 && ~strcmp(fieldList{j}(1:2),'C_')  %Getting fields that do NOT start with 'C_' (they correspond to unlabeled markers in Vicon naming)
                relData=[relData,markers.(fieldList{j})];
                markerLabel=findLabel(fieldList{j});%make sure that the markers are always named the same after this point (ex - if left hip marker is labeled LGT, LHIP, or anyhting else it always becomes LHIP.)
                markerList{end+1}=[markerLabel 'x'];
                markerList{end+1}=[markerLabel 'y'];
                markerList{end+1}=[markerLabel 'z'];
            end
            markers=rmfield(markers,fieldList{j}); %Save memory
        end         
        relData(relData==0)=NaN;
        markerData=orientedLabTimeSeries(relData,0,1/markerInfo.frequency,markerList,orientation);
        clear relData
        markerData.DataInfo.Units=markerInfo.units.ALLMARKERS;
    else
        markerData=[];
    end
    
    %% Construct trialData
    
    %rawTrialData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches)
    trials{t}=rawTrialData(trialMD{t},markerData,EMGData,GRFData,[],[],accData,[],[]);
    
end
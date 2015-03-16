function trials=loadTrials(trialMD,fileList,secFileList,info)

%orientationInfo(offset,foreaftAx,sideAx,updownAx,foreaftSign,sideSign,updownSign)
orientation=orientationInfo([0,0,0],'y','x','z',1,1,1); %check signs!

for t=cell2mat(info.trialnums)
    %Import data from c3d, uses external toolbox BTK
    H=btkReadAcquisition([fileList{t} '.c3d']);
    [analogs,analogsInfo]=btkGetAnalogs(H);
    if info.EMGs
        H2=btkReadAcquisition([secFileList{t} '.c3d']);
        [analogs2,analogsInfo2]=btkGetAnalogs(H2);
    end    
    
    %% GRFData
    if info.forces
        relData=[];
        forceLabels ={};
        units={};
        fieldList=fields(analogs);
        for j=1:length(fieldList);
            if strcmp(fieldList{j}(1),'F') || strcmp(fieldList{j}(1),'M') %Getting fields that start with M or F only
                switch fieldList{j}(3)
                    case '1' %Forces/moments ending in '1' area assumed to be of left treadmill belt
                        forceLabels{end+1} = ['L',fieldList{j}(1:2)];
                        units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
                        relData=[relData,analogs.(fieldList{j})];
                    case '2' %Forces/moments ending in '2' area assumed to be of right treadmill belt
                        forceLabels{end+1} = ['R',fieldList{j}(1:2)];
                        units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
                        relData=[relData,analogs.(fieldList{j})];
                    case '3'
                        % we don't want these for now
                    case '4'%Forces/moments ending in '4' area assumed to be of handrail
                        forceLabels{end+1} = ['H',fieldList{j}(1:2)];
                        units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
                        relData=[relData,analogs.(fieldList{j})];
                    otherwise
                        %do nothing
                end
            end
        end    
        %Sanity check: offset calibration
        
        
        %Create labTimeSeries (data,t0,Ts,labels,orientation)
        GRFData=orientedLabTimeSeries(relData,0,1/analogsInfo.frequency,forceLabels,orientation);
        GRFData.DataInfo.Units=units;
    else
        GRFData=[];
    end
    
    %% EMGData (from 2 files!) & Acceleration data
    if info.EMGs
        %Primary file (PC)
        relData=[];
        fieldList=fields(analogs);
        idxList=[];
        for j=1:length(fieldList);
            if length(fieldList{j})>2 && strcmp(fieldList{j}(1:3),'EMG')  %Getting fields that start with 'EMG' only
                relData=[relData,analogs.(fieldList{j})];
                idxList(end+1)=str2num(fieldList{j}(4:end));
            end
        end
        EMGList(1:16)=info.EMGList1;
        relData(:,idxList)=relData; %Re-sorting to fix the 1,10,11,...,2,3 count that Matlab does
        
        %Secondary file (PC)
        relData2=[];
        fieldList=fields(analogs2);
        idxList2=[];
        for j=1:length(fieldList);
            if length(fieldList{j})>2 && strcmp(fieldList{j}(1:3),'EMG')  %Getting fields that start with 'EMG' only
                relData2=[relData2,analogs2.(fieldList{j})];
                idxList2(end+1)=str2num(fieldList{j}(4:end));
            end
        end
        EMGList(17:32)=info.EMGList2; %This is the actual ordered in which the muscles were recorded
        relData2(:,idxList2)=relData2; %Re-sorting to fix the 1,10,11,...,2,3 count that Matlab does
        
        %Only keeping matrices of same size to one another:
        [auxData, auxData2] = truncateToSameLength(relData,relData2);
        
        
        %Align signals:
        refSync=analogs.Pin_3;
        refAux=medfilt1(refSync,20);
        refAux=medfilt1(diff(refAux),10);
        allData=[auxData,auxData2];
        syncIdx=strncmpi(EMGList,'Sync',4); %Compare first 4 chars in string list
        sync=allData(:,syncIdx);
        N=size(sync,1);
        aux1=medfilt1(sync(:,1),20);
        aux2=medfilt1(sync(:,2),20);
        aux1=medfilt1(diff(aux1),10);
        aux2=medfilt1(diff(aux2),10);
        [alignedSignal,timeScaleFactor,lagInSamples,gain] = matchSignals(aux1,aux2);
        newRelData2 = resampleShiftAndScale(relData2,timeScaleFactor,lagInSamples,1); %Aligning relData2 to relData1. There is still the need to find the overall delay of the EMG system with respect to forceplate data.
        [~,timeScaleFactorA,lagInSamplesA,gainA] = matchSignals(refAux,aux1);
        newRelData = resampleShiftAndScale(relData,1,lagInSamplesA,1);
        newRelData2 = resampleShiftAndScale(newRelData2,1,lagInSamplesA,1);
        
        %Only keeping matrices of same size to one another:
        [auxData, auxData2] = truncateToSameLength(newRelData,newRelData2);
        allData=[auxData,auxData2];
        refSync=idealHPF(analogs.Pin_3,0);
        [allData,refSync]=truncateToSameLength(allData,refSync);
        syncIdx=strncmpi(EMGList,'Sync',4); %Compare first 4 chars in string list
        sync=idealHPF(allData(:,syncIdx),0);
        gain1=refSync'/sync(:,1)';
        gain2=refSync'/sync(:,2)';
        
        %Analytic measure of alignment problems
        E1=sum((refSync-sync(:,1)*gain1).^2)/sum(refSync.^2);
        E2=sum((refSync-sync(:,2)*gain2).^2)/sum(refSync.^2);
        if E1>.01 || E2>.01 %Signal difference has at least 1% of original signal energy
            warning(['Time alignment doesnt seem to have worked: signal mismatch is too high in trial ' num2str(t) '. Using signals in an unsynchronized way(!).'])
            newRelData= relData;
            newRelData2= relData2;
            [auxData, auxData2] = truncateToSameLength(newRelData,newRelData2);
            allData=[auxData,auxData2];
            [allData,refSync]=truncateToSameLength(allData,refSync);
            syncIdx=strncmpi(EMGList,'Sync',4); %Compare first 4 chars in string list
            sync=idealHPF(allData(:,syncIdx),0);
            gain1=refSync'/sync(:,1)';
            gain2=refSync'/sync(:,2)';
            lagInSamplesA=0;
            lagInSamples=0;
        else
            disp(['Sync complete: mismatch signal energy (as %) was ' num2str(E1) ' and ' num2str(E2) '.'])
        end
        
        %Plot to CONFIRM VISUALLY if alignment worked:
        h=figure;
        hold on
        title(['Trial ' num2str(t) ' Synchronization'])
        plot([0:length(refSync)-1]*1/analogsInfo.frequency,refSync)
        plot([0:length(sync)-1]*1/analogsInfo.frequency,sync(:,1)*gain1,'r')
        plot([0:length(sync)-1]*1/analogsInfo.frequency,sync(:,2)*gain2,'g')
        legend('refSync',['sync1, delay=' num2str(lagInSamplesA/analogsInfo.frequency) 's'],['sync2, delay=' num2str((lagInSamplesA+lagInSamples)/analogsInfo.frequency)  's'])
        hold off
        saveFig(h,'./',['Trial ' num2str(t) ' Synchronization'])
%         uiwait(h)
        

        
        %Sorting muscles so that they are always stored in the same order
        orderedMuscleList={'PER','TA','SOL','MG','LG','RF','VM','VL','BF','SEMB','SEMT','ADM','GLU','TFL','ILP','SAR','HIP'}; %This is the desired order
        orderedEMGList={};
        for j=1:length(orderedMuscleList)
            orderedEMGList{end+1}=['R' orderedMuscleList{j}];
            orderedEMGList{end+1}=['L' orderedMuscleList{j}];
        end
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
        if any(aux==0)
            warning(['loadTrials: Not all of the provided muscles are in the ordered list, ignoring ' EMGList{aux==0}])
        end
        allData(allData==0)=NaN; %Eliminating samples that are exactly 0: these are unavailable samples
        EMGData=labTimeSeries(allData(:,orderedIndexes),0,1/analogsInfo.frequency,EMGList(orderedIndexes)); %Throw away the synch signal
        
        %AccData (from 2 files too!)
        %Primary file
        relData=[];
        idxList=[];
        fieldList=fields(analogs);
        for j=1:length(fieldList);
            if length(fieldList{j})>2 && strcmp(fieldList{j}(1:3),'ACC')  %Getting fields that start with 'EMG' only
                idxList(j)=str2num(fieldList{j}(5:end));
                switch fieldList{j}(4)
                    case 'X'
                        aux=1;
                    case 'Y'
                        aux=2;
                    case 'Z'
                        aux=3;
                end
                eval(['relData(:,3*(idxList(j)-1)+aux)=analogs.' fieldList{j} ';']);
            end
        end
        ACCList={};
        for j=1:length(EMGList)
            ACCList{end+1}=[EMGList{j} 'x'];
            ACCList{end+1}=[EMGList{j} 'y'];
            ACCList{end+1}=[EMGList{j} 'z'];
        end
        %Secondary file
        relData2=[];
        fieldList=fields(analogs2);
        idxList2=[];
        for j=1:length(fieldList);
            if length(fieldList{j})>2 && strcmp(fieldList{j}(1:3),'ACC')  %Getting fields that start with 'EMG' only
                idxList2(j)=str2num(fieldList{j}(5:end));
                switch fieldList{j}(4)
                    case 'X'
                        aux=1;
                    case 'Y'
                        aux=2;
                    case 'Z'
                        aux=3;
                end
                eval(['relData2(:,3*(idxList2(j)-1)+aux)=analogs2.' fieldList{j} ';']);
            end
        end
        
        %Fixing time alignment
        newRelData2 = resampleShiftAndScale(relData2,timeScaleFactor,lagInSamples,1); %Aligning relData2 to relData1. There is still the need to find the overall delay of the EMG system with respect to forceplate data.
        newRelData = resampleShiftAndScale(relData,1,lagInSamplesA,1);
        newRelData2 = resampleShiftAndScale(newRelData2,1,lagInSamplesA,1);
        [auxData, auxData2] = truncateToSameLength(newRelData,newRelData2);
        allData=[auxData,auxData2];
       
        accData=orientedLabTimeSeries(allData(1:13:end,:),0,13/analogsInfo.frequency,ACCList,orientation); %Downsampling to ~150Hz, which is much closer to the original 148Hz sampling rate (where does this get upsampled? why?)
        % orientation is fake: orientation is local and unique to each sensor, which is affixed to a body segment.
    else
        EMGData=[];
        accData=[];
    end
    
    %% MarkerData
    if info.kinematics
        [markers,markerInfo]=btkGetMarkers(H);
        relData=[];
        fieldList=fields(markers);
        markerList={};        
        for j=1:length(fieldList);
            if length(fieldList{j})>2 && ~strcmp(fieldList{j}(1:2),'C_')  %Getting fields that do NOT start with 'C_' (they correspond to unlabeled markers in Vicon naming)
                relData=[relData,markers.(fieldList{j})];
                markerLabel=findLabel(fieldList{j});%make sure that the markers are always named the same after this point (ex - if left hip marker is labeled LGT, LHIP, or anyhting else it always becomes LHIP.)
                markerList{end+1}=[markerLabel 'x'];
                markerList{end+1}=[markerLabel 'y'];
                markerList{end+1}=[markerLabel 'z'];
            end
        end         
        relData(relData==0)=NaN;
        markerData=orientedLabTimeSeries(relData,0,1/markerInfo.frequency,markerList,orientation);
        markerData.DataInfo.Units=markerInfo.units.ALLMARKERS;
    else
        markerData=[];
    end
    
    %% Construct trialData
    
    %rawTrialData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches)
    trials{t}=rawTrialData(trialMD{t},markerData,EMGData,GRFData,[],[],accData,[],[]);
    
end
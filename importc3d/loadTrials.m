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
                    case '1'
                        forceLabels{end+1} = ['L',fieldList{j}(1:2)];
                        units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
                        eval(['relData=[relData,analogs.' fieldList{j} '];']);
                    case '2'
                        forceLabels{end+1} = ['R',fieldList{j}(1:2)];
                        units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
                        eval(['relData=[relData,analogs.' fieldList{j} '];']);
                    case '3'
                        % we don't want these for now
                    case '4'
                        forceLabels{end+1} = ['H',fieldList{j}(1:2)];
                        units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
                        eval(['relData=[relData,analogs.' fieldList{j} '];']);
                    otherwise
                        %do nothing
                end
            end
        end        
        GRFData=orientedLabTimeSeries(relData,0,1/analogsInfo.frequency,forceLabels,orientation);
        GRFData.DataInfo.Units=units;
    else
        GRFData=[];
    end
    
    %% EMGData (from 2 files!)
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
        
        if size(relData,1)>size(relData2,1) %Fixing possible differences in length by padding zeros
            relData2(end+1:size(relData,1),:)=0;
        elseif size(relData2,1)>size(relData,1)
            relData(end+1:size(relData2,1),:)=0;
        end
        
        syncIdx=strncmpi(EMGList,'Sync',4); %Compare first 4 chars in string list
        allData=[relData,relData2];
        sync=allData(:,syncIdx);
        
        %Time align from sync signals
        refSync=GRFData.Data(:,3);
        refSync=refSync-mode(refSync);
        refSync=abs(refSync)/max(abs(refSync));
        sync=bsxfun(@minus,sync,mode(sync,1));
        sync=bsxfun(@rdivide,abs(sync),max(abs(sync),[],1));
        
        if abs(analogsInfo.frequency-analogsInfo2.frequency)<.001 %Make sure samp freqs are the same to .001 Hz tolerance
            if length(refSync)>size(sync,1)
                sync(end+1:length(refSync),:)=0;
            elseif size(sync,1)>length(refSync)
                refSync(end+1:size(sync,1))=0; 
            end
            [acor,lag] = xcorr(refSync,sync(:,1),'unbiased');
            I=find(lag==0);
            winSize=10;
            acor(1:I-winSize/2 * round(analogsInfo.frequency))=0; acor(I+winSize/2 *round(analogsInfo.frequency):end)=0; %This is to avoid bias when dividing by small numbers: looking for max in a 2 sec window around 0.
            [~,I1] = max(abs(acor));
            timeDiff1 = lag(I1)/analogsInfo.frequency;
            
            [acor,lag] = xcorr(refSync,sync(:,2),'unbiased');
            I=find(lag==0);
            acor(1:I-winSize/2 * round(analogsInfo.frequency))=0; acor(I+winSize/2 * round(analogsInfo.frequency):end)=0; %This is to avoid bias when dividing by small numbers: looking for max in a 2 sec window around 0.
            [~,I2] = max(abs(acor));
            timeDiff2 = lag(I2)/analogsInfo.frequency;
            h=figure;
            hold on
            plot([0:length(refSync)-1]*1/analogsInfo.frequency,refSync)
            plot(timeDiff1+[0:length(sync(:,1))-1]*1/analogsInfo.frequency,sync(:,1),'r')
            plot(timeDiff2+[0:length(sync(:,2))-1]*1/analogsInfo2.frequency,sync(:,2),'g')
            legend('refSync','sync1','sync2')
            hold off
            uiwait(h)
        else
            disp('Not syncing.')
            timeDiff1=0;
            timeDiff2=0;
        end
        
        %Re-align EMG data based on timeDiff found
        I1
        I2
        relData=relData()
        
        
        %Sorting muscles so that they are always stored in the same order
        orderedMuscleList={'BF','SEMB','SEMT','PER','TA','SOL','MG','LG','GLU','TFL','ILP','ADM','RF','VM','VL'}; %This is the desired order
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
        EMGData=labTimeSeries(allData(:,orderedIndexes),timeDiff,1/analogsInfo.frequency,EMGList(orderedIndexes)); %Throw away the synch signal
        
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
        
        if size(relData,1)>size(relData2,1) %Fixing possible differences in length by padding zeros
            relData2(end+1:size(relData,1),:)=0;
        elseif size(relData2,1)>size(relData,1)
            relData(end+1:size(relData2,1),:)=0;
        end
        
        allData=[relData,relData2];        
        accData=orientedLabTimeSeries(allData,0,13/analogsInfo.frequency,ACCList,orientation); %Downsampling to ~150Hz, which is much closer to the original 148Hz sampling rate (where does this get upsampled? why?)
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
        %Possibly change this in the future to make sure that the markers
        %are always named the same after this point (ex - if left hip
        %marker is labeled LGT, LHIP, or anyhting else it always becomes
        %LHIP.)
        for j=1:length(fieldList);
            if length(fieldList{j})>2 && ~strcmp(fieldList{j}(1:2),'C_')  %Getting fields that do NOT start with 'C_' (they correspond to unlabeled markers in Vicon naming)
                eval(['relData=[relData,markers.' fieldList{j} '];']);
                markerLabel=findLabel(fieldList{j});
                markerList{end+1}=[markerLabel 'x'];
                markerList{end+1}=[markerLabel 'y'];
                markerList{end+1}=[markerLabel 'z'];
            end
        end         
        markerData=orientedLabTimeSeries(relData,0,1/markerInfo.frequency,markerList,orientation);
        markerData.DataInfo.Units=markerInfo.units.ALLMARKERS;
    else
        markerData=[];
    end
    
    %% Construct trialData
    
    %rawTrialData(metaData,markerData,EMGData,GRFData,beltSpeedSetData,beltSpeedReadData,accData,EEGData,footSwitches)
    trials{t}=rawTrialData(trialMD{t},markerData,EMGData,GRFData,[],[],accData,[],[]);
    
end
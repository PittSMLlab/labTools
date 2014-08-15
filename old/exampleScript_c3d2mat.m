%c3d2mat example script
%In order to use it, this script must be modified adequately.

rawDataStr='/Datos/Documentos/PhD/lab/rawData/';
fileList={};
trialMD={};
%filename=[rawDataStr 'Pilot-Pablo/Pilot test session 1/Pilot-Baselin01'];
%fileList{end+1}=filename;
%trialMD{end+1}=trialMetaData('Base01',[],'pai','','SlowBaseline','No obs.',4,filename);
filename=[rawDataStr 'Pilot-Pablo/Pilot test session 1/Pilot-Baseline02'];
fileList{end+1}=filename;
trialMD{end+1}=trialMetaData('Exp0001PilotBase02',labDate(11,'mar',2014),'pai','','Slow500Baseline','No obs.',4,filename);
filename=[rawDataStr 'Pilot-Pablo/Pilot test session 1/Pilot-Baseline03'];
fileList{end+1}=filename;
trialMD{end+1}=trialMetaData('Exp0001PilotBase03',labDate(11,'mar',2014),'pai','','Fast1000Baseline','No obs.',5,filename);
filename=[rawDataStr 'Pilot-Pablo/Pilot test session 1/Pilot-Baseline04'];
fileList{end+1}=filename;
trialMD{end+1}=trialMetaData('Exp0001PilotBase04',labDate(11,'mar',2014),'pai','','Mid750Baseline','No obs.',1,filename);
filename=[rawDataStr 'Pilot-Pablo/Pilot test session 1/Pilot-Adaptation01'];
fileList{end+1}=filename;
trialMD{end+1}=trialMetaData('Exp0001PilotAdap01',labDate(11,'mar',2014),'pai','','1000_500Split','PC froze, lost some EMG data.',2,filename);
%filename=[rawDataStr 'Pilot-Pablo/Pilot test session 1/Pilot-Adaptation02'];
%fileList{end+1}=filename;
%trialMD{end+1}=trialMetaData('Exp0001PilotAdap02',labDate(11,'mar',2014),'pai','','1000_500Split','No obs.',2,filename);
filename=[rawDataStr 'Pilot-Pablo/Pilot test session 1/Pilot-Adaptation03'];
fileList{end+1}=filename;
trialMD{end+1}=trialMetaData('Exp0001PilotAdap03',labDate(11,'mar',2014),'pai','','1000_500Split','No obs.',2,filename);
filename=[rawDataStr 'Pilot-Pablo/Pilot test session 1/Pilot-Adaptation04'];
fileList{end+1}=filename;
trialMD{end+1}=trialMetaData('Exp0001PilotAdap04',labDate(11,'mar',2014),'pai','','1000_500Split','No obs.',2,filename);
filename=[rawDataStr 'Pilot-Pablo/Pilot test session 1/Pilot-Post01'];
fileList{end+1}=filename;
trialMD{end+1}=trialMetaData('Exp0001PilotPost01',labDate(11,'mar',2014),'pai','','Mid750Post','PC froz,lost EMG.',3,filename);
filename=[rawDataStr 'Pilot-Pablo/Pilot test session 1/Pilot-Post02'];
fileList{end+1}=filename;
trialMD{end+1}=trialMetaData('Exp0001PilotPost02',labDate(11,'mar',2014),'pai','','Mid750Post','PC froz,lost EMG.',3,filename);
filename=[rawDataStr 'Pilot-Pablo/Pilot test session 1/Pilot-Post03'];
fileList{end+1}=filename;
trialMD{end+1}=trialMetaData('Exp0001PilotPost03',labDate(11,'mar',2014),'pai','','Mid750Post','No obs.',3,filename);

%Load to trials
for i=1:length(fileList)
    %Import data from c3d, uses external toolbox BTK
    H=btkReadAcquisition([fileList{i} '.c3d']);
    [analogs,analogsInfo]=btkGetAnalogs(H);
    
    %GRFData
    relData=[];
    fieldList=fields(analogs);
    for j=1:length(fieldList);
        if strcmp(fieldList{j}(1),'F') || strcmp(fieldList{j}(1),'M') %Getting fields that start with M or F only
            eval(['relData=[relData,analogs.' fieldList{j} '];']);
        end
    end
    orientation=orientationInfo([0,0,0],'x','y','z',1,1,1);
    GRFData=orientedLabTimeSeries(relData,0,1/analogsInfo.frequency,{'LFx','LFy','LFz','LMx','LMy','LMz','RFx','RFy','RFz','RMx','RMy','RMz','HFx','HFy','HFz','HMx','HMy','HMz'},orientation);
    
    %EMGData
    relData=[];
    fieldList=fields(analogs);
    idxList=[];
    for j=1:length(fieldList);
        if length(fieldList{j})>2 && strcmp(fieldList{j}(1:3),'EMG')  %Getting fields that start with 'EMG' only
            eval(['relData=[relData,analogs.' fieldList{j} '];']);
            idxList(end+1)=str2num(fieldList{j}(4:end));
        end
    end
    MuscleList={'BF';'SEMB';'SEMT';'TA';'PER';'MG';'LG';'SOL';'ILP';'GLU';'RF';'VM';'VL';'TFL';'ADL';'Sync'};
    EMGList={};
    for j=1:length(MuscleList)
       EMGList{end+1}=['R' MuscleList{j}];
       EMGList{end+1}=['L' MuscleList{j}];
    end
    EMGData=labTimeSeries(relData(:,[1,9:16,2:8,17,25:32,18:22]),0,1/analogsInfo.frequency,EMGList([1:30]));
    
    %AccData
    relData=[];
    fieldList=fields(analogs);
    idxList=[];
    for j=1:length(fieldList);
        if length(fieldList{j})>2 && strcmp(fieldList{j}(1:3),'ACC')  %Getting fields that start with 'EMG' only
            eval(['relData=[relData,analogs.' fieldList{j} '];']);
        end
    end
    ACCList={};
    for j=1:length(MuscleList)
       ACCList{end+1}=[EMGList{j} 'x'];
       ACCList{end+2}=[EMGList{j} 'y'];
       ACCList{end+3}=[EMGList{j} 'z'];
    end
    orientation=orientationInfo([0,0,0],'x','y','z',1,1,1); %This is fake: orientation is local and unique to each sensor, which is affixed to a body segment.
    accData=orientedLabTimeSeries(relData(1:13:end,[1:3,25:48,4:24,49:52,73:96,53:72]),0,13/analogsInfo.frequency,ACCList,orientation); %Downsampling to ~150Hz, which is much closer to the original 148Hz sampling rate (where does this get upsampled? why?)
    
    %MarkerData
    [markers,markerInfo]=btkGetMarkers(H);
    relData=[];
    fieldList=fields(markers);
    markerList={};
    for j=1:length(fieldList);
        if length(fieldList{j})>2 && ~strcmp(fieldList{j}(1:2),'C_')  %Getting fields that do NOT start with 'C_' (they correspond to unlabeled markers in Vicon naming)
            eval(['relData=[relData,markers.' fieldList{j} '];']);
            markerList{end+1}=[fieldList{j} 'x'];
            markerList{end+1}=[fieldList{j} 'y'];
            markerList{end+1}=[fieldList{j} 'z'];
        end
    end
    orientation=orientationInfo([0,0,0],'y','x','z',1,1,1); %Need to check signs!
    markerData=orientedLabTimeSeries(relData,0,1/markerInfo.frequency,markerList,orientation);
    
    %Construct trialData
    trials{i}=rawTrialData(trialMD{i},markerData,EMGData,GRFData,[],[],accData,[],[]);
end

%% Create experiment object
trialsInCondition{1}=[3];
trialsInCondition{2}=[4,5,6];
trialsInCondition{3}=[7,8,9];
trialsInCondition{4}=[1];
trialsInCondition{5}=2;

expMD=experimentMetaData('Exp0001',labDate(11,'mar',2014),'pai','Synergies','BBBAP21 protocol','Some trials lost EMG',{'750 Base','1000_500 Adapt','750 Post','500 Base','1000 Base'},trialsInCondition,9);%(ID,date,experimenter,type,desc,obs,conds,trialLst,Ntrials)
sub=subjectData(labDate(18,'feb',2014),'M','R','R','1.75','80','28','0000'); %(DOB,sex,dLeg,dArm,hgt,wgt,age,ID)
expData=experimentData(expMD,sub,trials);

%% Save data
sub0RAW=expData;
save /Datos/Documentos/PhD/lab/synergies/matData/sub0RAW.mat sub0RAW -v7.3
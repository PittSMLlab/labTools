function [ACCList, allData,analogsInfo]=getEMGworksdataAcc(infoEMGList2 ,secFileList,fileList, NexusfileList,emptyChannels1,emptyChannels2,EMGList)
% % get EMG from EMGworks
%
% %needed inputs:   EMGList1  EMGList2  secFileList{t}   fileList analogs
% % outputs: EMGList relData relData2
%
% %
% % fileList='/Users/dulcemariscal/Box/11_Research_Projects/EMGworksSync/EMGworks/eMGworks01/DumbTester7/EMGtrial_PC1/RenameTrials/Trial02';
% % secFileList='/Users/dulcemariscal/Box/11_Research_Projects/EMGworksSync/EMGworks/eMGworks01/DumbTester7/EMGtrial_PC2/RenameTrials/Trial02';
% % info.EMGList1={'LTA','LPER','LRF','LVL','LVM','LADM','LHIP','LTFL','LGLU','LMG','LLG','LSOL','LBF','LSEMT','LSEMB','sync1'};
% % info.EMGList2={'RTA','RPER','RRF','RVL','RVM','RADM','RHIP','RTFL','RGLU','RMG','RLG','RSOL','RBF','RSEMT','RSEMB','sync2'};
% % secondFile=1;
if ~isempty(infoEMGList2)
    secondFile=true;
end

idx1=str2num(NexusfileList(strfind(NexusfileList,'Trial')+5:end));

%% File 1
%files=what('./');
%RawfileList=files.mat;
%
%indexTrial=find(strcmp(['Trial0', num2str(t),'.mat'],RawfileList));
% load(RawfileList{indexTrial})
if idx1<10
    load([fileList, '/Trial0', num2str(idx1), '.mat'])
else
    load([fileList, '/Trial', num2str(idx1), '.mat'])
end

% Data=Data(:,1:2:end);

analogs=[];
analogsInfo=[];
for j=1:length(Channels)
    B(j) = convertCharsToStrings(Channels(j,:));
    B(j) = regexprep(B(j),'\W*[: .]',' ');
    B(j) = regexprep(B(j),'\s','_');
    B(j) =deblank(B(j));
    C(j) = cellstr(B(j));
    analogs.(B{j})=Data(j,:)';
end

relData=[];
relDataTemp=[];
fieldList=fields(analogs);
idxList=[];
for j=1:length(fieldList)
    
    if  contains(fieldList{j},'acc','IgnoreCase', true) % || ~isempty(strfind(fieldList{j},'Acc'))Getting fields that start with 'EMG' onl
        
        if j<37
            idxList(j)=str2num(fieldList{j}(strfind(fieldList{j},'sensor')+7:strfind(fieldList{j},'sensor')+7));
            
        else
            idxList(j)=str2num(fieldList{j}(strfind(fieldList{j},'sensor')+7:strfind(fieldList{j},'sensor')+8));
        end
        switch fieldList{j}(strfind(fieldList{j},'ACC')+4)
            case 'X'
                aux=1;
            case 'Y'
                aux=2;
            case 'Z'
                aux=3;
                
        end
        eval(['relData(:,idxList(j),aux)=analogs.' fieldList{j} ';']);
        analogs=rmfield(analogs,fieldList{j}); %Just to save memory space
        analogsInfo.frequency=Fs(j);
        
    elseif contains(fieldList{j},'adapter','IgnoreCase', true)
        
        idxList(j)=str2num(fieldList{j}(strfind(fieldList{j},'Adapter')+8:strfind(fieldList{j},'Adapter')+9));
        switch fieldList{j}(strfind(fieldList{j},'Analog_16')+10)
            case 'A'
                aux=1;
            case 'B'
                aux=2;
            case 'C'
                aux=3;
                
        end
        
        eval(['relData(:,idxList(j),aux)=analogs.' fieldList{j} ';']);
        analogs=rmfield(analogs,fieldList{j}); %Just to save memory space
 
        
    end
    
    
end
relData=permute(relData(:,~emptyChannels1,:),[1,3,2]);
relData=relData(:,:);
allData=relData;

%% File 2
if secondFile
    %  secFileList{t}
    % files=what('./');
    % RawfileList=files.mat;
    % %
    % indexTrial=find(strcmp(['Trial0', num2str(t),'.mat'],RawfileList));
    % load(RawfileList{indexTrial})
    if idx1<10
        load([secFileList, '/Trial0', num2str(idx1), '.mat'])
    else
        load([secFileList, '/Trial', num2str(idx1), '.mat'])
    end
    % load([secFileList '.mat'])
    % Data=Data(:,1:2:end);
    
    analogs2=[];
    analogsInfo2=[];
    for j=1:length(Channels)
        B(j) = convertCharsToStrings(Channels(j,:));
        B(j) = regexprep(B(j),'\W*[: .]',' ');
        B(j) = regexprep(B(j),'\s','_');
        B(j) =deblank(B(j));
        C(j) = cellstr(B(j));
        analogs2.(B{j})=Data(j,:)';
    end
    
    relData2=[];
    idxList2=[];
    
    fieldList=fields(analogs2);
    for j=1:length(fieldList)
        
        if  contains(fieldList{j},'acc','IgnoreCase', true) % || ~isempty(strfind(fieldList{j},'Acc'))Getting fields that start with 'EMG' onl
            
            if j<37
                idxList2(j)=str2num(fieldList{j}(strfind(fieldList{j},'sensor')+7:strfind(fieldList{j},'sensor')+7));
                
            else
                idxList2(j)=str2num(fieldList{j}(strfind(fieldList{j},'sensor')+7:strfind(fieldList{j},'sensor')+8));
            end
            switch fieldList{j}(strfind(fieldList{j},'ACC')+4)
                case 'X'
                    aux=1;
                case 'Y'
                    aux=2;
                case 'Z'
                    aux=3;
            end
            eval(['relData2(:,idxList2(j),aux)=analogs2.' fieldList{j} ';']);
            analogs2=rmfield(analogs2,fieldList{j}); %Just to save memory space
        elseif contains(fieldList{j},'adapter','IgnoreCase', true)
            idxList2(j)=str2num(fieldList{j}(strfind(fieldList{j},'Adapter')+8:strfind(fieldList{j},'Adapter')+9));
            
            switch fieldList{j}(strfind(fieldList{j},'Analog_16')+10)
                case 'A'
                    aux=1;
                case 'B'
                    aux=2;
                case 'C'
                    aux=3;
                    
            end
            
            eval(['relData2(:,idxList2(j),aux)=analogs2.' fieldList{j} ';']);
            analogs2=rmfield(analogs2,fieldList{j}); %Just to save memory space
        end
        
        
    end
    relData2=permute(relData2(:,~emptyChannels2,:),[1,3,2]);
    relData2=relData2(:,:);
    allData=[relData,relData2];
end



ACCList={};
for j=1:length(EMGList)
    ACCList{end+1}=[EMGList{j} 'x'];
    ACCList{end+1}=[EMGList{j} 'y'];
    ACCList{end+1}=[EMGList{j} 'z'];
end

end
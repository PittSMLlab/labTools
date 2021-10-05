function [analogsNexus, EMGList, relData, relData2,secondFile,analogsInfo2,emptyChannels1,emptyChannels2,EMGList1,EMGList2]=getEMGworksdata(infoEMGList1 ,infoEMGList2 ,secFileList,fileList, NexusfileList)
% get EMG from EMGworks

%needed inputs:   EMGList1  EMGList2  secFileList{t}   fileList analogs 
% outputs: EMGList relData relData2


if ~isempty(infoEMGList2)
secondFile=true;
end

 idx1=str2num(NexusfileList(strfind(NexusfileList,'Trial')+5:end));

%% File 1


if idx1<10
load([fileList, '/Trial0', num2str(idx1), '.mat'])
else
load([fileList, '/Trial', num2str(idx1), '.mat'])
end

r=2; %rate of downsampling the data 
% Data=Data(:,1:r:end); %Downsampling of the data 

analogs=[];
analogsInfo=[];
for j=1:length(Channels)
B(j) = convertCharsToStrings(Channels(j,:));
B(j) = regexprep(B(j),'\W*[: .]',' ');
B(j) = regexprep(B(j),'\s','_');
B(j) =deblank(B(j));
C(j) = cellstr(B(j));
if contains(B(j),'_(IM)')
   B(j) = strrep(B(j),'_(IM)','');
elseif contains(B(j),'_IM__')
    B(j) = strrep(B(j),'_IM__','');
end
analogs.(B{j})=Data(j,:)';
end

relData=[];
relDataTemp=[];
fieldList=fields(analogs);
idxList=[];
for j=1:length(fieldList)
if  ~isempty(strfind(fieldList{j},'EMG'))  %Getting fields that start with 'EMG' only
    relDataTemp=[relDataTemp,analogs.(fieldList{j})];
    if ~isempty(str2num(fieldList{j}(strfind(fieldList{j},'EMG')+4:end)))
         idxList(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'EMG')+4:end));    
    elseif  ~isempty(str2num(fieldList{j}(strfind(fieldList{j},'EMG')+3:end)))
         idxList(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'EMG')+3:end));
    else
         idxList(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'EMG')+3:end-1));
    end
    analogs=rmfield(analogs,fieldList{j}); %Just to save memory space
    analogsInfo.frequency=Fs(j)/r;
    analogsInfo.units.(fieldList{j})='V';
elseif  ~isempty(strfind(fieldList{j},'Analog_16_A'))
    relDataTemp=[relDataTemp,analogs.(fieldList{j})];
    idxList(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'Analog_16')+7:end-2));
    analogs=rmfield(analogs,fieldList{j}); %Just to save memory space
    analogsInfo.frequency= Fs(j)/r;
    analogsInfo.units.(fieldList{j})='V';
elseif  ~isempty(strfind(fieldList{j},'Analog16_A'))
    relDataTemp=[relDataTemp,analogs.(fieldList{j})];
    idxList(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'Analog16')+6:end-2));
    analogs=rmfield(analogs,fieldList{j}); %Just to save memory space
    analogsInfo.frequency= Fs(j)/r;
    analogsInfo.units.(fieldList{j})='V';
end
end
emptyChannels1=cellfun(@(x) isempty(x),infoEMGList1);
EMGList1=infoEMGList1(~emptyChannels1);
relData(:,idxList)=relDataTemp; %Re-sorting to fix the 1,10,11,...,2,3 count that Matlab does
relData=relData(:,~emptyChannels1);
EMGList=EMGList1;
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
% Data=Data(:,1:r:end);

analogs2=[];
analogsInfo2=[];
for j=1:length(Channels)
    B(j) = convertCharsToStrings(Channels(j,:));
    B(j) = regexprep(B(j),'\W*[: .]',' ');
    B(j) = regexprep(B(j),'\s','_');
    B(j) =deblank(B(j));
    C(j) = cellstr(B(j));
    if contains(B(j),'_(IM)')
        B(j) = strrep(B(j),'_(IM)','');
    elseif contains(B(j),'_IM__')
        B(j) = strrep(B(j),'_IM__','');
    end
    analogs2.(B{j})=Data(j,:)';
end
fieldList=fields(analogs2);
relDataTemp2=[];
idxList2=[];
for j=1:length(fieldList);
    if  ~isempty(strfind(fieldList{j},'EMG'))  %Getting fields that start with 'EMG' only
        relDataTemp2=[relDataTemp2,analogs2.(fieldList{j})];
        if ~isempty(str2num(fieldList{j}(strfind(fieldList{j},'EMG')+4:end)))
            idxList2(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'EMG')+4:end));
        elseif  ~isempty(str2num(fieldList{j}(strfind(fieldList{j},'EMG')+3:end)))
            idxList2(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'EMG')+3:end));
        else
            idxList2(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'EMG')+3:end-1));
        end
%         idxList2(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'EMG')+4:end));
        analogs2=rmfield(analogs2,fieldList{j}); %Just to save memory space
        analogsInfo2.frequency= Fs(j)/r;
        analogsInfo2.units.(fieldList{j})='V';
    elseif  ~isempty(strfind(fieldList{j},'Analog_16_A'))
        relDataTemp2=[relDataTemp2,analogs2.(fieldList{j})];
        idxList2(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'Analog_16')+7:end-2));
        analogs2=rmfield(analogs2,fieldList{j}); %Just to save memory space
        analogsInfo2.frequency=Fs(j)/r;
        analogsInfo2.units.(fieldList{j})='V';
    elseif  ~isempty(strfind(fieldList{j},'Analog16_A'))
        relDataTemp2=[relDataTemp2,analogs2.(fieldList{j})];
        idxList2(end+1)=str2num(fieldList{j}(strfind(fieldList{j},'Analog16')+6:end-2));
        analogs2=rmfield(analogs2,fieldList{j}); %Just to save memory space
        analogsInfo2.frequency= Fs(j)/r;
        analogsInfo2.units.(fieldList{j})='V';
    
    end
end
emptyChannels2=cellfun(@(x) isempty(x),infoEMGList2);
EMGList2=infoEMGList2(~emptyChannels2); %Just using the names for the channels that were actually in the file
relData2(:,idxList2)=relDataTemp2; %Re-sorting to fix the 1,10,11,...,2,3 count that Matlab does
relData2=relData2(:,~emptyChannels2);
EMGList=[EMGList1,EMGList2];
end


%%
H=btkReadAcquisition([NexusfileList '.c3d']);
[analogsNexus,analogsInfoNexus]=btkGetAnalogs(H);
analogsInfoNexus=analogsInfo;


end
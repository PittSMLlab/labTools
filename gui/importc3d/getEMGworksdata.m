function [analogsNexus,EMGList,relData,relData2,secondFile,analogsInfo2, ...
    emptyChannels1,emptyChannels2,EMGList1, ...
    EMGList2] = getEMGworksdata(infoEMGList1,infoEMGList2 ,secFileList, ...
    fileList, NexusfileList)
%GETEMGWORKSDATA Load EMG channels exported by EMGworks for one trial.
%
%   Reads TrialNN.mat from the EMGworks folder(s) (NN is the two-digit
% trial number parsed from NEXUSFILELIST), keeps the EMG (and
% Analog_16 adapter) channels, and orders them by sensor number. A
% second EMGworks folder (second PC) is read when SECFILELIST is
% non-empty. The Nexus C3D of the trial is also read for its analog
% channels.
%
% Inputs:
%   infoEMGList1  - cell of EMG labels for PC 1 (empty entries mark
%                  unused sensors)
%   infoEMGList2  - same for PC 2
%   secFileList   - folder of the second EMGworks export; empty if none
%   fileList      - folder of the first EMGworks export
%   NexusfileList - trial file path without '.c3d', ending in 'TrialNN'
%
% Outputs:
%   analogsNexus   - analog channels of the Nexus C3D (btkGetAnalogs)
%   EMGList        - labels of the channels returned (PC 1, then PC 2)
%   relData        - PC 1 EMG samples, one column per used sensor
%   relData2       - PC 2 EMG samples ([] if no second file)
%   secondFile     - true if a second EMGworks folder was read
%   analogsInfo2   - info (frequency, units) of the PC 2 channels
%   emptyChannels1 - logical, unused sensors of PC 1
%   emptyChannels2 - logical, unused sensors of PC 2
%   EMGList1       - labels of the used PC 1 sensors
%   EMGList2       - labels of the used PC 2 sensors
%
% Toolbox Dependencies: None
%
% See also GETEMGWORKSDATAACC, LOADTRIALS, BTKGETANALOGS.

%% Check for a second file
if isempty(secFileList)
    secondFile = false;
else
    secondFile = true;
end

idx1 = str2num(NexusfileList(strfind(NexusfileList,'Trial')+5:end));

%% File 1


if idx1 < 10
    load([fileList, '/Trial0', num2str(idx1), '.mat'])
else
    load([fileList, '/Trial', num2str(idx1), '.mat'])
end

downsampleFactor = 2; %rate of downsampling the data
% Data=Data(:,1:r:end); %Downsampling of the data

analogs = [];
analogsInfo = [];
for jj = 1:length(Channels)
    B(jj) = convertCharsToStrings(Channels(jj,:));
    B(jj) = regexprep(B(jj),'\W*[: .]',' ');
    B(jj) = regexprep(B(jj),'\s','_');
    B(jj) = deblank(B(jj));
    C(jj) = cellstr(B(jj));
    if contains(B(jj),'_(IM)')
        B(jj) = strrep(B(jj),'_(IM)','');
    elseif contains(B(jj),'_IM__')
        B(jj) = strrep(B(jj),'_IM__','');
    end
    analogs.(B{jj}) = Data(jj,:)';
end

relData = [];
relDataTemp = [];
fieldList = fields(analogs);
idxList = [];
for jj = 1:length(fieldList)
    %Getting fields that start with 'EMG' only
    if  ~isempty(strfind(fieldList{jj},'EMG'))
        relDataTemp = [relDataTemp,analogs.(fieldList{jj})];
        if ~isempty(str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                'EMG')+4:end)))
            idxList(end+1) = ...
                str2num(fieldList{jj}(strfind(fieldList{jj},'EMG')+4:end));
        elseif  ~isempty(str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                'EMG')+3:end)))
            idxList(end+1) = ...
                str2num(fieldList{jj}(strfind(fieldList{jj},'EMG')+3:end));
        else
            idxList(end+1) = ...
                str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                'EMG')+3:end-1));
        end
        analogs = rmfield(analogs,fieldList{jj}); %Just to save memory space
        analogsInfo.frequency = Fs(jj)/downsampleFactor;
        analogsInfo.units.(fieldList{jj}) = 'V';
    elseif  ~isempty(strfind(fieldList{jj},'Analog_16_A'))
        relDataTemp = [relDataTemp,analogs.(fieldList{jj})];
        idxList(end+1) = ...
            str2num(fieldList{jj}(strfind(fieldList{jj}, ...
            'Analog_16')+7:end-2));
        analogs = rmfield(analogs,fieldList{jj}); %Just to save memory space
        analogsInfo.frequency = Fs(jj)/downsampleFactor;
        analogsInfo.units.(fieldList{jj}) = 'V';
    elseif  ~isempty(strfind(fieldList{jj},'Analog16_A'))
        relDataTemp = [relDataTemp,analogs.(fieldList{jj})];
        idxList(end+1) = ...
            str2num(fieldList{jj}(strfind(fieldList{jj}, ...
            'Analog16')+6:end-2));
        analogs = rmfield(analogs,fieldList{jj}); %Just to save memory space
        analogsInfo.frequency = Fs(jj)/downsampleFactor;
        analogsInfo.units.(fieldList{jj}) = 'V';
    elseif  ~isempty(strfind(fieldList{jj},'Analog_A16'))
        relDataTemp = [relDataTemp,analogs.(fieldList{jj})];
        idxList(end+1) = ...
            str2num((fieldList{jj}(strfind(fieldList{jj}, ...
            'Analog_A16')+8:end)));
        analogs = rmfield(analogs,fieldList{jj}); %Just to save memory space
        analogsInfo.frequency = Fs(jj)/downsampleFactor;
        analogsInfo.units.(fieldList{jj}) = 'V';
    end
end
emptyChannels1 = cellfun(@(x) isempty(x),infoEMGList1);
EMGList1 = infoEMGList1(~emptyChannels1);
%Re-sorting to fix the 1,10,11,...,2,3 count that Matlab does
relData(:,idxList) = relDataTemp;
relData = relData(:,~emptyChannels1);
EMGList = EMGList1;
%% File 2
analogsInfo2 = [];
emptyChannels2 = [];
EMGList2 = [];
relData2 = [];
if secondFile
    %  secFileList{t}
    % files=what('./');
    % RawfileList=files.mat;
    % %
    % indexTrial=find(strcmp(['Trial0', num2str(t),'.mat'],RawfileList));
    % load(RawfileList{indexTrial})
    if idx1 < 10
        load([secFileList, '/Trial0', num2str(idx1), '.mat'])
    else
        load([secFileList, '/Trial', num2str(idx1), '.mat'])
    end
    % load([secFileList '.mat'])
    % Data=Data(:,1:r:end);

    analogs2 = [];
    % analogsInfo2=[];
    for jj = 1:length(Channels)
        B(jj) = convertCharsToStrings(Channels(jj,:));
        B(jj) = regexprep(B(jj),'\W*[: .]',' ');
        B(jj) = regexprep(B(jj),'\s','_');
        B(jj) = deblank(B(jj));
        C(jj) = cellstr(B(jj));
        if contains(B(jj),'_(IM)')
            B(jj) = strrep(B(jj),'_(IM)','');
        elseif contains(B(jj),'_IM__')
            B(jj) = strrep(B(jj),'_IM__','');
        end
        analogs2.(B{jj}) = Data(jj,:)';
    end
    fieldList = fields(analogs2);
    relDataTemp2 = [];
    idxList2 = [];
    for jj = 1:length(fieldList);
        %Getting fields that start with 'EMG' only
        if  ~isempty(strfind(fieldList{jj},'EMG'))
            relDataTemp2 = [relDataTemp2,analogs2.(fieldList{jj})];
            if ~isempty(str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                    'EMG')+4:end)))
                idxList2(end+1) = ...
                    str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                    'EMG')+4:end));
            elseif  ~isempty(str2num( ...
                    fieldList{jj}(strfind(fieldList{jj},'EMG')+3:end)))
                idxList2(end+1) = ...
                    str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                    'EMG')+3:end));
            else
                idxList2(end+1) = ...
                    str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                    'EMG')+3:end-1));
            end
            %         idxList2(end+1)=str2num( ...
            %    fieldList{j}(strfind(fieldList{j},'EMG')+4:end));
            %Just to save memory space
            analogs2 = rmfield(analogs2,fieldList{jj});
            analogsInfo2.frequency = Fs(jj)/downsampleFactor;
            analogsInfo2.units.(fieldList{jj}) = 'V';
        elseif  ~isempty(strfind(fieldList{jj},'Analog_16_A'))
            relDataTemp2 = [relDataTemp2,analogs2.(fieldList{jj})];
            idxList2(end+1) = ...
                str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                'Analog_16')+7:end-2));
            %Just to save memory space
            analogs2 = rmfield(analogs2,fieldList{jj});
            analogsInfo2.frequency = Fs(jj)/downsampleFactor;
            analogsInfo2.units.(fieldList{jj}) = 'V';
        elseif  ~isempty(strfind(fieldList{jj},'Analog16_A'))
            relDataTemp2 = [relDataTemp2,analogs2.(fieldList{jj})];
            idxList2(end+1) = ...
                str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                'Analog16')+6:end-2));
            %Just to save memory space
            analogs2 = rmfield(analogs2,fieldList{jj});
            analogsInfo2.frequency = Fs(jj)/downsampleFactor;
            analogsInfo2.units.(fieldList{jj}) = 'V';
        elseif  ~isempty(strfind(fieldList{jj},'Analog_A16'))
            relDataTemp2 = [relDataTemp2,analogs2.(fieldList{jj})];
            idxList2(end+1) = ...
                str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                'Analog_A')+8:end));
            %Just to save memory space
            analogs2 = rmfield(analogs2,fieldList{jj});
            analogsInfo2.frequency = Fs(jj)/downsampleFactor;
            analogsInfo2.units.(fieldList{jj}) = 'V';

        end
    end
    emptyChannels2 = cellfun(@(x) isempty(x),infoEMGList2);
    %Just using the names for the channels that were actually in the file
    EMGList2 = infoEMGList2(~emptyChannels2);
    %Re-sorting to fix the 1,10,11,...,2,3 count that Matlab does
    relData2(:,idxList2) = relDataTemp2;
    relData2 = relData2(:,~emptyChannels2);
    EMGList = [EMGList1,EMGList2];
end


%%
H = btkReadAcquisition([NexusfileList '.c3d']);
[analogsNexus,analogsInfoNexus] = btkGetAnalogs(H);
analogsInfoNexus = analogsInfo;


end
function [ACCList,allData,analogsInfo] = getEMGworksdataAcc( ...
    infoEMGList2,secFileList,fileList,NexusfileList, ...
    emptyChannels1,emptyChannels2,EMGList)
%GETEMGWORKSDATAACC retrieve accelerometer data from 'EMGworks' software
%
%INPUTS: EMGList1, EMGList2, secFileList{t}, fileList, analogs
%OUTPUTS: EMGList,relData,relData2

% fileList = ['/Users/dulcemariscal/Box/11_Research_Projects/' ...
%     'EMGworksSync/EMGworks/eMGworks01/DumbTester7/' ...
%     'EMGtrial_PC1/RenameTrials/Trial02'];
% secFileList = ['/Users/dulcemariscal/Box/11_Research_Projects/' ...
%     'EMGworksSync/EMGworks/eMGworks01/DumbTester7/' ...
%     'EMGtrial_PC2/RenameTrials/Trial02'];
% info.EMGList1 = {'LTA','LPER','LRF','LVL','LVM','LADM','LHIP','LTFL', ...
%     'LGLU','LMG','LLG','LSOL','LBF','LSEMT','LSEMB','sync1'};
% info.EMGList2 = {'RTA','RPER','RRF','RVL','RVM','RADM','RHIP','RTFL', ...
%     'RGLU','RMG','RLG','RSOL','RBF','RSEMT','RSEMB','sync2'};
% secondFile = 1;
% TODO: source? Last field index whose sensor number has one digit.
lastOneDigitSensorField = 36;
if ~isempty(infoEMGList2)
    secondFile = true;
end

idx1 = str2num(NexusfileList(strfind(NexusfileList,'Trial')+5:end));

%% File 1
%files=what('./');
%RawfileList=files.mat;
%
%indexTrial=find(strcmp(['Trial0', num2str(t),'.mat'],RawfileList));
% load(RawfileList{indexTrial})
if idx1 < 10
    load([fileList, '/Trial0', num2str(idx1), '.mat'])
else
    load([fileList, '/Trial', num2str(idx1), '.mat'])
end

% Data=Data(:,1:2:end);

analogs = [];
analogsInfo = [];
for jj = 1:length(Channels)
    B(jj) = convertCharsToStrings(Channels(jj,:));
    B(jj) = regexprep(B(jj),'\W*[: .]',' ');
    B(jj) = regexprep(B(jj),'\s','_');
    B(jj) = deblank(B(jj));
    C(jj) = cellstr(B(jj));
    analogs.(B{jj}) = Data(jj,:)';
end

relData = [];
relDataTemp = [];
fieldList = fields(analogs);
idxList = [];
for jj = 1:length(fieldList)

    % Alternative test: ~isempty(strfind(fieldList{j},'Acc'))
    if  contains(fieldList{jj},'acc','IgnoreCase', true)

        if jj <= lastOneDigitSensorField
            idxList(jj) = ...
                str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                'sensor')+7:strfind(fieldList{jj},'sensor')+7));

        else
            idxList(jj) = ...
                str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                'sensor')+7:strfind(fieldList{jj},'sensor')+8));
        end
        switch fieldList{jj}(strfind(fieldList{jj},'ACC')+4)
            case 'X'
                aux = 1;
            case 'Y'
                aux = 2;
            case 'Z'
                aux = 3;

        end

        if ~exist('aux')
            switch fieldList{jj}(end)
                case 'X'
                    aux = 1;
                case 'Y'
                    aux = 2;
                case 'Z'
                    aux = 3;

            end
        end
        eval(['relData(:,idxList(jj),aux)=analogs.' fieldList{jj} ';']);
        analogs = rmfield(analogs,fieldList{jj}); %Just to save memory space
        analogsInfo.frequency = Fs(jj);

    elseif contains(fieldList{jj},'adapter','IgnoreCase', true)

        idxList(jj) = ...
            str2num(fieldList{jj}(strfind(fieldList{jj}, ...
            'Adapter')+8:strfind(fieldList{jj},'Adapter')+9));
        switch fieldList{jj}(strfind(fieldList{jj},'Analog_16')+10)
            case 'A'
                aux = 1;
            case 'B'
                aux = 2;
            case 'C'
                aux = 3;

        end

        if  ~exist('aux')
            switch fieldList{jj}(end)
                case 'A'
                    aux = 1;
                case 'B'
                    aux = 2;
                case 'C'
                    aux = 3;

            end
        end

        eval(['relData(:,idxList(jj),aux)=analogs.' fieldList{jj} ';']);
        analogs = rmfield(analogs,fieldList{jj}); %Just to save memory space
    end
end
relData = permute(relData(:,~emptyChannels1,:),[1,3,2]);
relData = relData(:,:);
allData = relData;

%% File 2
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
    % Data=Data(:,1:2:end);

    analogs2 = [];
    analogsInfo2 = [];
    for jj = 1:length(Channels)
        B(jj) = convertCharsToStrings(Channels(jj,:));
        B(jj) = regexprep(B(jj),'\W*[: .]',' ');
        B(jj) = regexprep(B(jj),'\s','_');
        B(jj) = deblank(B(jj));
        C(jj) = cellstr(B(jj));
        analogs2.(B{jj}) = Data(jj,:)';
    end

    relData2 = [];
    idxList2 = [];

    fieldList = fields(analogs2);
    for jj = 1:length(fieldList)

        % Alternative test: ~isempty(strfind(fieldList{j},'Acc'))
        if  contains(fieldList{jj},'acc','IgnoreCase', true)

            if jj <= lastOneDigitSensorField
                idxList2(jj) = ...
                    str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                    'sensor')+7:strfind(fieldList{jj},'sensor')+7));

            else
                idxList2(jj) = ...
                    str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                    'sensor')+7:strfind(fieldList{jj},'sensor')+8));
            end
            switch fieldList{jj}(strfind(fieldList{jj},'ACC')+4)
                case 'X'
                    aux = 1;
                case 'Y'
                    aux = 2;
                case 'Z'
                    aux = 3;
            end

            if ~exist('aux')
                switch fieldList{jj}(end)
                    case 'X'
                        aux = 1;
                    case 'Y'
                        aux = 2;
                    case 'Z'
                        aux = 3;

                end
            end
            eval(['relData2(:,idxList2(jj),aux)=analogs2.' fieldList{jj} ...
                ';']);
            %Just to save memory space
            analogs2 = rmfield(analogs2,fieldList{jj});
        elseif contains(fieldList{jj},'adapter','IgnoreCase', true)
            idxList2(jj) = ...
                str2num(fieldList{jj}(strfind(fieldList{jj}, ...
                'Adapter')+8:strfind(fieldList{jj},'Adapter')+9));

            switch fieldList{jj}(strfind(fieldList{jj},'Analog_16')+10)
                case 'A'
                    aux = 1;
                case 'B'
                    aux = 2;
                case 'C'
                    aux = 3;

            end

            if  ~exist('aux')
                switch fieldList{jj}(end)
                    case 'A'
                        aux = 1;
                    case 'B'
                        aux = 2;
                    case 'C'
                        aux = 3;

                end
            end
            eval(['relData2(:,idxList2(jj),aux)=analogs2.' fieldList{jj} ...
                ';']);
            %Just to save memory space
            analogs2 = rmfield(analogs2,fieldList{jj});
        end


    end
    relData2 = permute(relData2(:,~emptyChannels2,:),[1,3,2]);
    relData2 = relData2(:,:);
    allData = [relData,relData2];
end



ACCList = {};
for jj = 1:length(EMGList)
    ACCList{end+1} = [EMGList{jj} 'x'];
    ACCList{end+1} = [EMGList{jj} 'y'];
    ACCList{end+1} = [EMGList{jj} 'z'];
end

end


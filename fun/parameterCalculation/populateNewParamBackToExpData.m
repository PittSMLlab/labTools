function [expData] = populateNewParamBackToExpData(expData,adaptData)
%When new parameters are calculated in adaptData only (current use case
%is with EMG norm parameters). Populate them back into the exp data so
%that the expData and the adapt data is consistent, this will also be
%used in recompute parameters to ensure the EMG norm parameter will not
%be lost.
%
%
% [OUTPUTARGS]
%   - adaptData: adaptataionData object with the new EMG norm parameters
%       added. It's up to the caller fnction to save the file.
%
% [INPUTARGS]
%   - expData: an experimentData object where the params data will be
%       populated back
%   - adaptData: an adaptationData object with the new params
%       calculated.
%
% See also:
%   labTools\fun\parameterCalculation\appendEMGNormParameters.m
%   labTools\gui\importc3d\loadSubject.m
%   labTools\classes\dataStructs\@experimentData\recomputeParameters.m
%   labTools\classes\dataStructs\@experimentData\flushAndRecomputeParameters.m
%
% $Author: Shuqi Liu $	$Date: 2026/04/02 13:43:01 $	$Revision: 0.1 $
% Copyright: Sensorimotor Learning Laboratory 2026

trials = find(~cellfun(@isempty,expData.data));
trialCol = ismember(adaptData.data.labels,'trial');
for t = trials
    %find columes containing new data (do not touch data that's already
    %there + do not populate a fakeparam which is always in
    %experimentalParams, otherwise the fakeparam will be repeated and cause parameter
    % collision downstream when trying to create adaptData using adaptData = expData.makeDataObj([]);
    newDataCol = ~ismember(adaptData.data.labels,[expData.data{t}.adaptParams.labels;expData.data{t}.experimentalParams.labels]);
    newData = adaptData.data.Data(adaptData.data.Data(:,trialCol) == t,newDataCol);
    newLabels = adaptData.data.labels(newDataCol);
    newDescp = adaptData.data.description(newDataCol);
    expData.data{t}.adaptParams = expData.data{t}.adaptParams.appendData(newData, newLabels, newDescp);
    %repopulate the information as well.
    if isempty(expData.data{t}.adaptParams.DataInfo.UserData)
        %if used to be empty, just replace with what's in adaptData
        expData.data{t}.adaptParams.DataInfo.UserData = adaptData.data.DataInfo.UserData;
    else%if used have info, try to preserve or replace it.
        newUserData = adaptData.data.DataInfo.UserData;
        if isstruct(expData.data{t}.adaptParams.DataInfo.UserData)
            %used to have info and is already a struct, existing fields
            %use the new info from the adaptData, additional fields,
            %try to keep it.
            %look for additional fields that used to be in expData but
            %not in new adaptData. Note here repeated fields will honor the adaptData and
            %ignore the expData's userinfo
            uniqueToOld = setdiff(fieldnames(expData.data{t}.adaptParams.DataInfo.UserData),...
                fieldnames(newUserData));
            for fd = uniqueToOld %add in the additional info
                newUserData.(fd{1}) = expData.data{t}.adaptParams.DataInfo.UserData.(fd{1});
            end
        else %not a struct just save all old info into one field.
            newUserData.prevUserData = expData.data{t}.adaptParams.DataInfo.UserData;
        end
        expData.data{t}.adaptParams.DataInfo.UserData = newUserData;
    end
end
end

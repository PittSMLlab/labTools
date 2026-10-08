function expData = populateNewParamBackToExpData(expData, adaptData)
%POPULATENEWPARAMBACKTOEXPDATA Back-populate new parameters into expData.
%
%   Copies parameters that exist in adaptData but not yet in expData back
% into each trial's adaptParams field. The primary use case is
% synchronizing EMG normalization parameters that were appended to
% adaptData after the initial processing run. Also propagates DataInfo
% UserData from adaptData, merging any additional fields unique to the
% existing trial. Parameters already present in adaptParams or
% experimentalParams for a given trial are skipped to avoid downstream
% collisions when makeDataObj later rebuilds adaptData from expData
% (e.g., fakeParam is always in experimentalParams and must not be
% duplicated).
%
% Inputs:
%   expData   - experimentData object; each trial's adaptParams will
%               be updated with new parameters from adaptData
%   adaptData - adaptationData object containing the new parameters
%               to back-populate (e.g., after EMG normalization)
%
% Outputs:
%   expData - updated experimentData object with new parameters
%             appended to each trial's adaptParams
%
% Toolbox Dependencies:
%   None
%
% See also APPENDEMGNORMPARAMETERS, LOADSUBJECT,
%   EXPERIMENTDATA.RECOMPUTEPARAMETERS,
%   EXPERIMENTDATA.FLUSHANDRECOMPUTEPARAMETERS.
%
% Author: Shuqi Liu, 2026-04-02

arguments
    expData   (1,1)
    adaptData (1,1)
end

%% Identify Trials and Trial Column Index
trials   = find(~cellfun(@isempty, expData.data));
trialCol = ismember(adaptData.data.labels, 'trial');

%% Populate New Parameters Per Trial
for tr = trials
    trialAdapt     = expData.data{tr}.adaptParams;
    trialExpParams = expData.data{tr}.experimentalParams;

    % Identify parameters in adaptData not already in this trial
    newDataCol = ~ismember(adaptData.data.labels, ...
        [trialAdapt.labels; trialExpParams.labels]);
    newData         = adaptData.data.Data( ...
        adaptData.data.Data(:, trialCol) == tr, newDataCol);
    newLabels       = adaptData.data.labels(newDataCol);
    newDescriptions = adaptData.data.description(newDataCol);
    trialAdapt = trialAdapt.appendData( ...
        newData, newLabels, newDescriptions);

    % Propagate DataInfo UserData from adaptData
    if isempty(trialAdapt.DataInfo.UserData)
        % No existing UserData: take adaptData's UserData as is
        trialAdapt.DataInfo.UserData = adaptData.data.DataInfo.UserData;
    else
        % Merge: adaptData fields take precedence; preserve fields
        % unique to the existing expData trial
        newUserData = adaptData.data.DataInfo.UserData;
        if isstruct(trialAdapt.DataInfo.UserData)
            uniqueFields = setdiff( ...
                fieldnames(trialAdapt.DataInfo.UserData), ...
                fieldnames(newUserData));
            for fld = uniqueFields'
                newUserData.(fld{1}) = ...
                    trialAdapt.DataInfo.UserData.(fld{1});
            end
        else
            % Not a struct: preserve existing info in a single field
            newUserData.prevUserData = trialAdapt.DataInfo.UserData;
        end
        trialAdapt.DataInfo.UserData = newUserData;
    end

    expData.data{tr}.adaptParams = trialAdapt;
end

end


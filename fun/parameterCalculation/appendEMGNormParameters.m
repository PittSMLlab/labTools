function adaptData = appendEMGNormParameters(adaptData, ...
    muscleLabels, normalizationRefCond, biasRemovalCond)
%APPENDEMGNORMPARAMETERS Compute and append EMG norm parameters.
%
%   Computes L2-norm EMG parameters and appends them to an
% adaptationData object. Parameter families are computed for each
% muscle individually, per leg, and across both legs, in both
% percentage and raw voltage units, with and without bias removal:
%   - Per-muscle L2 norm
%   - Per-leg and bilateral L2 norm and average norm (weighted by
%     non-NaN muscle count)
%   - Per-muscle asymmetry norm (fast minus slow)
%   - Bilateral asymmetry L2 norm and average norm
%
%   Existing 'Norm*' and '*L2norm*' labels are removed and regenerated
% to avoid stale parameters from prior runs.
%
% Inputs:
%   adaptData            - adaptationData object to update
%   muscleLabels         - cell array of unique muscle name strings
%                          without the fast/slow prefix (e.g.,
%                          {'BF','GLU','TA'}). If empty or omitted,
%                          falls back to
%                          adaptData.data.DataInfo.UserData.muscleLabels;
%                          returns without change if neither is found.
%   normalizationRefCond - condition name used to normalize EMG; 100%
%                          is the max and 0% is the min of the nanmean
%                          of the last 40 strides (excluding the last
%                          5) of this condition. Falls back to UserData
%                          or auto-detected baseline if empty or
%                          omitted.
%   biasRemovalCond      - condition name for bias removal. If
%                          provided, overrides the default trial-type-
%                          based bias removal in removeBiasV4. Pass []
%                          or omit to use the default behavior.
%                          Optional.
%
% Outputs:
%   adaptData - updated adaptationData object with new EMG norm
%               parameters appended
%
% Toolbox Dependencies:
%   None
%
% $Author: Shuqi Liu $	$Date: 2026/04/02 11:44:22 $	$Revision: 0.1 $
% See also REMOVEBIAS, REMOVEBIASNV4, LOADSUBJECT,
%   POPULATENEWPARAMBACKTOEXPDATA.

arguments
    adaptData            (1,1)
    muscleLabels                 = {}
    normalizationRefCond (1,:) char = ''
    biasRemovalCond              = []
end

%% Resolve muscleLabels
if isempty(muscleLabels)
    if ~isfield(adaptData.data.DataInfo.UserData, 'muscleLabels')
        warning(['muscleLabels was not provided and not available in ' ...
            'adaptData.data.DataInfo.UserData. EMGNorm calculation ' ...
            'was not possible. Returning with no change made in params.'])
        return
    else
        muscleLabels = adaptData.data.DataInfo.UserData.muscleLabels;
        fprintf(['No muscleLabels provided, will use what is ' ...
            'available in adaptData.data.DataInfo.UserData: %s\n'], ...
            strjoin(muscleLabels))
    end
end

%% Resolve normalizationRefCond
if isempty(normalizationRefCond)
    if isfield(adaptData.data.DataInfo.UserData, 'normalizationRefCond')
        normalizationRefCond = ...
            adaptData.data.DataInfo.UserData.normalizationRefCond;
        fprintf(['No normalizationRefCond provided, will use what is ' ...
            'available in adaptData.data.DataInfo.UserData: %s\n'], ...
            normalizationRefCond)
    else
        warning(['No normalizationRefCond provided and could not ' ...
            'find one in adaptData.data.DataInfo.UserData. Will ' ...
            'search for a baseline condition (OGBase, TMBase, ...).'])
        ordersToTry = {'OG', 'TM', 'NIM', 'TR', 'TS', ...
            adaptData.trialTypes{find( ...
            ~cellfun(@isempty, adaptData.trialTypes), 1)}};
        for ord = ordersToTry
            normalizationRefCond = ...
                adaptData.metaData.getConditionsThatMatchV2( ...
                'base', ord{1});
            if ~isempty(normalizationRefCond)
                break
            end
        end
    end
end

%% Resolve biasRemovalCond
if isempty(biasRemovalCond)
    if isfield(adaptData.data.DataInfo.UserData, 'biasRemovalCond')
        biasRemovalCond = ...
            adaptData.data.DataInfo.UserData.biasRemovalCond;
        fprintf(['No biasRemovalCond provided, will use what is ' ...
            'available in adaptData.data.DataInfo.UserData: %s\n'], ...
            biasRemovalCond)
    else
        warning(['No biasRemovalCond provided and also not found in ' ...
            'adaptData.data.DataInfo.UserData. Will use default ' ...
            'bias removal method.'])
        biasRemovalCond = [];
    end
else
    if ischar(biasRemovalCond)
        % Repeat for all trial types; removeBiasV4 indexes by type.
        biasRemovalCond = repmat({biasRemovalCond}, 1, 10);
    elseif iscell(biasRemovalCond)
        biasRemovalCond = repmat(biasRemovalCond(1), 1, 10);
    else
        warning(['biasRemovalCond must be a char or cell. Invalid ' ...
            'input type provided. Will use default.'])
        biasRemovalCond = [];
    end
end

%% Normalize Data to Reference Condition
% Last 40 strides excluding last 5, averaged by nanmean.
refEp = defineEpochs({normalizationRefCond}, {normalizationRefCond}, ...
    -40, 0, 5, 'nanmean');

% Remove stale normalized labels before regenerating.
staleNorm  = adaptData.data.getLabelsThatMatch('^Norm');
keepLabels = adaptData.data.labels( ...
    ~ismember(adaptData.data.labels, staleNorm));
adaptData  = adaptData.reduce(keepLabels);

staleL2    = adaptData.data.getLabelsThatMatch('.*L2norm.*');
keepLabels = adaptData.data.labels( ...
    ~ismember(adaptData.data.labels, staleL2));
adaptData  = adaptData.reduce(keepLabels);

% Build label prefixes for EMG parameters (e.g., 'fBF_s', 'sBF_s').
newLabelPrefix = adaptData.data.labels( ...
    startsWith(adaptData.data.labels, strcat('f', muscleLabels, '_s')) | ...
    startsWith(adaptData.data.labels, strcat('s', muscleLabels, '_s')));
newLabelPrefix = unique(cellfun( ...
    @(x) x(1:end-2), newLabelPrefix, 'UniformOutput', false));

fprintf('\nNormalizing the data using %s\n', normalizationRefCond);
%this function call will create new parameters as NormsTA_s 1 etc. for all
%muscles with the linearly stretched data and raw unit data is in sTA_s
%1
adaptData = adaptData.normalizeToBaselineEpoch(newLabelPrefix, refEp);

% adaptData = adaptData.removeBadStrides;

%at this point, the raw data is in format sTA_s 1, the normalized data is in
%NormsTA_s 1. A total of length(newLabelPrefix) x 12 new labels will be
%created.
rawDataLabelPrefix        = newLabelPrefix;
normalizedDataLabelPrefix = strcat('Norm', newLabelPrefix);

clear newLabelPrefix keepLabels staleNorm staleL2
adaptDataOriginal = adaptData;

%% Compute Norm Parameters
nStrides   = size(adaptData.data.Data, 1);
nAlloc     = 200; % arbitrarily large pre-allocation
newData    = nan(nStrides, nAlloc);
newLabels  = cell(1, nAlloc);
newDescp   = cell(1, nAlloc);
newDataCol = 1;

for doRemoveBias = [false, true]
    if doRemoveBias
        %Bias removal can be done manually or by calling remove bias. They
        %don't get the same results, checked that the TMBase we get from
        %calling the getEpochData TMBase is not the same as the base we get
        %rom callig removeBiasV4. Some values are the same, some are not,
        %didn't figure out why. For now wil rely on calling removebias
        adaptData   = adaptDataOriginal.removeBias(biasRemovalCond);
        labelSuffix = 'Unbiased';
        descpSuffix = ['Before any parameter computation, the data ' ...
            'is first unbiased by subtracting the ' ...
            normalizationRefCond ' baseline.'];
    else
        adaptData   = adaptDataOriginal;
        labelSuffix = '';
        descpSuffix = '';
    end

    %% Per-Muscle L2 Norm
    nPrefixes = numel(normalizedDataLabelPrefix);
    nLabels   = numel(adaptData.data.labels);
    % bothLegsColsIdx(mscl, :): binary mask for that muscle's columns
    bothLegsColsIdx         = nan(nPrefixes, nLabels);
    bothLegsColsIdx_rawUnit = nan(nPrefixes, nLabels);
    allnanMuslcesByStride   = false(nStrides, nPrefixes);

    for mscl = 1:nPrefixes
        dataColIdx = cellfun(@(x) ~isempty(x), regexp( ...
            adaptData.data.labels, ...
            ['^' normalizedDataLabelPrefix{mscl} '[ ]?\d+$']));
        bothLegsColsIdx(mscl, :) = dataColIdx;
        curdata = adaptData.data.Data(:, dataColIdx);
        %record #of muscles that are all nan, compute it only once bc
        %normalized vs raw should have the same nan content, will have 1 at
        %a stride for a given muscle i that is all nan at that stride
        allnanMuslcesByStride(:, mscl) = all(isnan(curdata), 2);
        %make nan zero to compute the norm, unless the whole 12 sub
        %interval is nan in which case the norm should also be nan.
        %now compute a by muscle norm, take L2 norm, over dim=2 (per rows)
        curdata(isnan(curdata)) = 0;
        newData(:, newDataCol) = vecnorm(curdata, 2, 2);
        newData(allnanMuslcesByStride(:, mscl), newDataCol) = nan;
        newLabels{newDataCol} = [ ...
            normalizedDataLabelPrefix{mscl} ...
            '_L2normPercentUnit' labelSuffix];
        newDescp{newDataCol} = ['L2norm of: ' ...
            normalizedDataLabelPrefix{mscl} ' in percentage unit after ' ...
            'stretching each stride to 100%=max and 0%=min of nanmean ' ...
            'of last 40 strides of ' normalizationRefCond '. NaN ' ...
            'treated as 0. ' descpSuffix];
        newDataCol = newDataCol + 1;

        dataColIdx = cellfun(@(x) ~isempty(x), regexp( ...
            adaptData.data.labels, ...
            ['^' rawDataLabelPrefix{mscl} '[ ]?\d+$']));
        bothLegsColsIdx_rawUnit(mscl, :) = dataColIdx;
        curdata = adaptData.data.Data(:, dataColIdx);
        curdata(isnan(curdata)) = 0;
        newData(:, newDataCol) = vecnorm(curdata, 2, 2);
        newData(allnanMuslcesByStride(:, mscl), newDataCol) = nan;
        newLabels{newDataCol} = [ ...
            rawDataLabelPrefix{mscl} '_L2normRawUnit' labelSuffix];
        newDescp{newDataCol} = ['L2norm of: ' rawDataLabelPrefix{mscl} ...
            ' in original voltage unit. NaN treated as 0. ' descpSuffix];
        newDataCol = newDataCol + 1;
    end

    %% Both-Legs L2 Norm
    curdata = adaptData.data.Data(:, any(bothLegsColsIdx, 1));
    allMsNanStride = all(isnan(curdata), 2);
    curdata(isnan(curdata)) = 0;
    newData(:, newDataCol) = vecnorm(curdata, 2, 2);
    newData(allMsNanStride, newDataCol) = nan;
    newLabels{newDataCol} = ['BothLegEMGL2normPercentUnit' labelSuffix];
    newDescp{newDataCol}  = ['L2norm of all muscles flattened as a 1D ' ...
        'vector in percentage unit (100%=max, 0%=min of nanmean of ' ...
        'last 40 strides of ' normalizationRefCond '). NaN treated as ' ...
        '0. ' descpSuffix];
    newDataCol = newDataCol + 1;

    newData(:, newDataCol) = newData(:, newDataCol-1) ./ ...
        sum(~allnanMuslcesByStride, 2);
    newLabels{newDataCol} = ['BothLegEMGL2normPercentUnitAvg' labelSuffix];
    newDescp{newDataCol}  = ['L2norm of all muscles divided by number ' ...
        'of non-NaN contributing muscles. A muscle is excluded from ' ...
        'the denominator only if all its sub-intervals are NaN. In ' ...
        'percentage unit. ' descpSuffix];
    newDataCol = newDataCol + 1;

    curdata = adaptData.data.Data(:, any(bothLegsColsIdx_rawUnit, 1));
    allMsNanStride = all(isnan(curdata), 2);
    curdata(isnan(curdata)) = 0;
    newData(:, newDataCol) = vecnorm(curdata, 2, 2);
    newData(allMsNanStride, newDataCol) = nan;
    newLabels{newDataCol} = ['BothLegEMGL2normRawUnit' labelSuffix];
    newDescp{newDataCol}  = ['L2norm of all muscles flattened as a 1D ' ...
        'vector in raw voltage unit. NaN treated as 0. ' descpSuffix];
    newDataCol = newDataCol + 1;

    newData(:, newDataCol) = newData(:, newDataCol-1) ./ ...
        sum(~allnanMuslcesByStride, 2);
    newLabels{newDataCol} = ['BothLegEMGL2normRawUnitAvg' labelSuffix];
    newDescp{newDataCol}  = ['L2norm of all muscles divided by number ' ...
        'of non-NaN contributing muscles in raw voltage unit. ' ...
        descpSuffix];
    newDataCol = newDataCol + 1;

    newData(:, newDataCol) = sum(~allnanMuslcesByStride, 2);
    newLabels{newDataCol} = ['BothLegEMGL2normNumMuscles' labelSuffix];
    newDescp{newDataCol}  = ['Number of non-NaN muscles contributing ' ...
        'to the both-legs norm. A muscle is excluded only if all its ' ...
        'sub-intervals are NaN. ' labelSuffix];
    newDataCol = newDataCol + 1;

    %% Per-Leg L2 Norm
    for lg = {'slow', 'fast'}
        legChar  = lg{1}(1);    % 's' or 'f'
        legName  = lg{1};       % 'slow' or 'fast'
        normMask = startsWith(normalizedDataLabelPrefix, ['Norm' legChar]);
        rawMask  = startsWith(rawDataLabelPrefix, legChar);

        curdata = adaptData.data.Data(:, ...
            any(bothLegsColsIdx(normMask, :), 1));
        allMsNanStride = all(isnan(curdata), 2);
        curdata(isnan(curdata)) = 0;
        newData(:, newDataCol) = vecnorm(curdata, 2, 2);
        newData(allMsNanStride, newDataCol) = nan;
        newLabels{newDataCol} = [legName 'LegEMGL2normPercentUnit' ...
            labelSuffix];
        newDescp{newDataCol}  = ['L2norm of ' legName ' leg muscles in ' ...
            'percentage unit. NaN treated as 0. ' descpSuffix];
        newDataCol = newDataCol + 1;

        newData(:, newDataCol) = newData(:, newDataCol-1) ./ ...
            sum(~allnanMuslcesByStride(:, normMask), 2);
        newLabels{newDataCol} = [legName 'LegEMGL2normPercentUnitAvg' ...
            labelSuffix];
        newDescp{newDataCol}  = ['L2norm of ' legName ' leg muscles ' ...
            'divided by number of non-NaN contributing muscles in ' ...
            'percentage unit. ' descpSuffix];
        newDataCol = newDataCol + 1;

        curdata = adaptData.data.Data(:, ...
            any(bothLegsColsIdx_rawUnit(rawMask, :), 1));
        allMsNanStride = all(isnan(curdata), 2);
        curdata(isnan(curdata)) = 0;
        newData(:, newDataCol) = vecnorm(curdata, 2, 2);
        newData(allMsNanStride, newDataCol) = nan;
        newLabels{newDataCol} = [legName 'LegEMGL2normRawUnit' labelSuffix];
        newDescp{newDataCol}  = ['L2norm of ' legName ' leg muscles in ' ...
            'raw voltage unit. NaN treated as 0. ' descpSuffix];
        newDataCol = newDataCol + 1;

        % Denominator is the same for raw and normalized units.
        newData(:, newDataCol) = newData(:, newDataCol-1) ./ ...
            sum(~allnanMuslcesByStride(:, normMask), 2);
        newLabels{newDataCol} = [legName 'LegEMGL2normRawUnitAvg' ...
            labelSuffix];
        newDescp{newDataCol}  = ['L2norm of ' legName ' leg muscles ' ...
            'divided by number of non-NaN contributing muscles in raw ' ...
            'voltage unit. ' descpSuffix];
        newDataCol = newDataCol + 1;

        newData(:, newDataCol) = ...
            sum(~allnanMuslcesByStride(:, normMask), 2);
        newLabels{newDataCol} = [legName 'LegEMGL2normNumMuscles' ...
            labelSuffix];
        newDescp{newDataCol}  = ['Number of non-NaN muscles ' ...
            'contributing to the ' legName ' leg norm. A muscle is ' ...
            'excluded only if all its sub-intervals are NaN. ' labelSuffix];
        newDataCol = newDataCol + 1;
    end

    %% Per-Muscle Asymmetry Norm
    allmusclesAsym            = [];
    allmusclesAsym_rawUnit    = [];
    allnanAsymMuslcesByStride = false(nStrides, numel(muscleLabels));

    kk = 1;
    for mscl = muscleLabels
        muscleName = mscl{1};

        %first identify the prefix for this muscle, then look for match in
        %all labels that start with the prefix and ends with digits
        %(look for match that starts with NormfTA_s and end with digits.
        fastNormPrefix = normalizedDataLabelPrefix{ ...
            contains(normalizedDataLabelPrefix, ['f' muscleName])};
        fastCol = cellfun(@(x) ~isempty(x), regexp( ...
            adaptData.data.labels, ['^' fastNormPrefix '[ ]?\d+$']));
        fastdata = adaptData.data.Data(:, fastCol);

        slowNormPrefix = normalizedDataLabelPrefix{ ...
            contains(normalizedDataLabelPrefix, ['s' muscleName])};
        slowCol = cellfun(@(x) ~isempty(x), regexp( ...
            adaptData.data.labels, ['^' slowNormPrefix '[ ]?\d+$']));
        slowdata = adaptData.data.Data(:, slowCol);

        if ~isempty(fastdata) && ~isempty(slowdata)
            asymdata = fastdata - slowdata;
            allnanAsymMuslcesByStride(:, kk) = ...
                all(isnan(asymdata), 2);
            allmusclesAsym = [allmusclesAsym, asymdata]; %#ok<AGROW>
            asymdata(isnan(asymdata)) = 0;
            newData(:, newDataCol) = vecnorm(asymdata, 2, 2);
            newData(allnanAsymMuslcesByStride(:, kk), ...
                newDataCol) = nan;
            newLabels{newDataCol} = [muscleName 'AsymL2normPercentUnit' ...
                labelSuffix];
            newDescp{newDataCol}  = ['L2norm of fast-slow asymmetry of ' ...
                muscleName ' in percentage unit. NaN treated as 0. ' ...
                descpSuffix];
            newDataCol = newDataCol + 1;
        end

        %look for match that start with fTA_s and ends with digits
        fastRawPrefix = rawDataLabelPrefix{ ...
            startsWith(rawDataLabelPrefix, ['f' muscleName])};
        fastCol = cellfun(@(x) ~isempty(x), regexp( ...
            adaptData.data.labels, ['^' fastRawPrefix '[ ]?\d+$']));
        fastdata = adaptData.data.Data(:, fastCol);

        slowRawPrefix = rawDataLabelPrefix{ ...
            startsWith(rawDataLabelPrefix, ['s' muscleName])};
        slowCol = cellfun(@(x) ~isempty(x), regexp( ...
            adaptData.data.labels, ['^' slowRawPrefix '[ ]?\d+$']));
        slowdata = adaptData.data.Data(:, slowCol);

        if ~isempty(fastdata) && ~isempty(slowdata)
            asymdata = fastdata - slowdata;
            allmusclesAsym_rawUnit = ...
                [allmusclesAsym_rawUnit, asymdata]; %#ok<AGROW>
            asymdata(isnan(asymdata)) = 0;
            newData(:, newDataCol) = vecnorm(asymdata, 2, 2);
            newData(allnanAsymMuslcesByStride(:, kk), ...
                newDataCol) = nan;
            newLabels{newDataCol} = [muscleName 'AsymL2normRawUnit' ...
                labelSuffix];
            newDescp{newDataCol}  = ['L2norm of fast-slow asymmetry of ' ...
                muscleName ' in raw voltage unit. ' descpSuffix];
            newDataCol = newDataCol + 1;
        end

        kk = kk + 1;
    end

    %% Both-Legs Asymmetry Norm
    allMsNanStride = all(isnan(allmusclesAsym), 2);
    allmusclesAsym(isnan(allmusclesAsym)) = 0;
    newData(:, newDataCol) = vecnorm(allmusclesAsym, 2, 2);
    newData(allMsNanStride, newDataCol) = nan;
    newLabels{newDataCol} = ['BothLegsAsymL2normPercentUnit' labelSuffix];
    newDescp{newDataCol}  = ['L2norm of fast-slow asymmetry across all ' ...
        'muscles in percentage unit. NaN treated as 0. ' descpSuffix];
    newDataCol = newDataCol + 1;

    newData(:, newDataCol) = newData(:, newDataCol-1) ./ ...
        sum(~allnanAsymMuslcesByStride, 2);
    newLabels{newDataCol} = ['BothLegsAsymL2normPercentUnitAvg' ...
        labelSuffix];
    newDescp{newDataCol}  = ['L2norm of fast-slow asymmetry across all ' ...
        'muscles divided by number of non-NaN contributing muscles in ' ...
        'percentage unit. ' descpSuffix];
    newDataCol = newDataCol + 1;

    allMsNanStride = all(isnan(allmusclesAsym_rawUnit), 2);
    allmusclesAsym_rawUnit(isnan(allmusclesAsym_rawUnit)) = 0;
    newData(:, newDataCol) = vecnorm(allmusclesAsym_rawUnit, 2, 2);
    newData(allMsNanStride, newDataCol) = nan;
    newLabels{newDataCol} = ['BothLegsAsymL2normRawUnit' labelSuffix];
    newDescp{newDataCol}  = ['L2norm of fast-slow asymmetry across all ' ...
        'muscles in raw voltage unit. NaN treated as 0. ' descpSuffix];
    newDataCol = newDataCol + 1;

    newData(:, newDataCol) = newData(:, newDataCol-1) ./ ...
        sum(~allnanAsymMuslcesByStride, 2);
    newLabels{newDataCol} = ['BothLegsAsymL2normRawUnitAvg' labelSuffix];
    newDescp{newDataCol}  = ['L2norm of fast-slow asymmetry across all ' ...
        'muscles divided by number of non-NaN contributing muscles in ' ...
        'raw voltage unit. ' descpSuffix];
    newDataCol = newDataCol + 1;

    newData(:, newDataCol) = sum(~allnanAsymMuslcesByStride, 2);
    newLabels{newDataCol} = ['BothLegsAsymL2normNumMuscle' labelSuffix];
    newDescp{newDataCol}  = ['Number of non-NaN muscles contributing ' ...
        'to the bilateral asymmetry norm. A muscle is excluded only if ' ...
        'all its sub-intervals are NaN. ' labelSuffix];
    newDataCol = newDataCol + 1;
end

%% Append Parameters to adaptData
newData(:, newDataCol:end)   = [];
newLabels(:, newDataCol:end) = [];
newDescp(:, newDataCol:end)  = [];

%set up the adaptData to return, make sure it's the original with only
%additions of the norm parameters + normalized data per interval (e.g.,
%NormsVL_s 1), without any manipulations like removeBias, removeBadStrides.
% A totla of muscles x 12 + 208 (norm)
%parameters will be created. (e.g., 28 muscle x 12 + 208 = 544). Or if
%this is in a flushAndRecompute, then the net new parameters are 0.
adaptData      = adaptDataOriginal;
adaptData.data = adaptData.data.appendData(newData, newLabels, newDescp);

adaptData.data.DataInfo.UserData                      = struct();
adaptData.data.DataInfo.UserData.muscleLabels         = muscleLabels;
adaptData.data.DataInfo.UserData.normalizationRefCond = ...
    normalizationRefCond;
adaptData.data.DataInfo.UserData.biasRemovalCond      = biasRemovalCond;

end


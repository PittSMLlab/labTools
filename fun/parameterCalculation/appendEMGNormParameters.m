function adaptData = appendEMGNormParameters(adaptData, muscleLabels, normalizationRefCond, biasRemovalCond)
    %Compute and append EMGnorm parameters to the adaptationData object. The
    %following parameters will be added:
    %   - L2norm of 1) each muscle, 2) all msucles in 1 leg, 3) all muscles in both
    %   legs, 4) asymmetry per muscle, 5) asymmetry for the whole leg.
    %   6) an average norm parameter for the norm per leg or for both legs, and 
    %   asym norm for the whole leg will also be computating by taking
    %   norm/#muscles. The # of muscles representing non-nan  contributing muscles 
    %   (e.g., if 1 muscle is all nan for a stride, the
    %   average will = norm / (total #muscles - 1).
    %   - all the parameters above will be computed in the original voltage unit
    %   - in percentage unit after normalizing data to normalizationRefCond
    %   - after bias removal in original voltage unit
    %   - after bias removal in percentage unit.
    % 
    % Examples: 
    % adaptData = appendEMGNormParameters(adaptData,{'BF','GLU','TA'},...
    %    'OGBase','TMBase');
    % 
    % [Prerequisite]
    % This requires the normalization trial to be available
    %   with EMG parameters properly calculated such that we can run the linear
    %   stretchning properly by referencing the min/max from the reference trial
    %   (e.g., TMBase or OGBase).
    %
    % [OUTPUTARGS]
    %   - adaptData: adaptataionData object with the new EMG norm parameters
    %       added. It's up to the caller fnction to save the file.
    %
    % [INPUTARGS]
    %   - adaptData: adaptData object to add parameters
    %   - muscleLabels: cell array of strings that represent the
    %       muscleLabels, contains unique muscle names only without f/s. e.g., 
    %       {'BF'	'GLU'	'LG'	'MG'	'PER'	'SEMT'	'SOL'	'TA'	'VL'
    %       'VM'}. OPTIONAL, if not provided, will look for one in
    %       adaptData.data.DataInfo.UserData, and if not provided and also not available
    %       in the metaData, will throw a warning and make no change.
    %       note only the muscles provided in the list will have norm per
    %       muscle calculated and the whole leg norm assumes these are all
    %       the muscles available
    %   - normalizationRefCond: string representing the conditon name that will
    %       be used to normalize the EMG data, i.e., all EMG data will be stretched
    %       in reference to the last 40 stirdes (excluding the last 5) of this refcondition such that 100%
    %       = max of the ref condition, 0 = min of the ref condition.
    %   - biasRemovalCond: OPTIONAL. string representing the condition name to
    %       use to compute bias removed EMG norm. if provided, will remove bias using the providec condition and
    %       ignore the trial type (e.g., if provided 'OGBase' will remove
    %       OGBase for all types of trials including TM, etc.)
    %       If not provided, will use default bias removal behavior which looks
    %       for trial type specific baseline (see
    %       labTools\classes\dataStructs\@adaptationData\removeBiasV4.m)
    %       
    % See also: 
    %   labTools\classes\dataStructs\@adaptationData\removeBiasV4.m
    %   labTools\gui\importc3d\loadSubject.m
    %
    % $Author: Shuqi Liu $	$Date: 2026/04/02 11:44:22 $	$Revision: 0.1 $
    % Copyright: Sensorimotor Learning Laboratory 2026

    % Set up muscle labels, use what's in the adaptData or the info file
    if nargin < 2 || isempty(muscleLabels)
        %muscelLabels not provided, look for it in the userdata. This is
        %required, if not found will return without doing anything.
        if ~isfield(adaptData.data.DataInfo.UserData,'muscleLabels')
            warning('muscleLabels was not provided and not available in the adaptData.data.DataInfo.UserData. EMGNorm calculation was not possible. Returning with no change made in params.')
            return
        else %use the one from userdata
            muscleLabels = adaptData.data.DataInfo.UserData.muscleLabels;
            fprintf('No muscleLabels provided, will use what is available in the adaptData.data.DataInfo.UserData: %s\n',strjoin(muscleLabels))
        end
    end   
    
    if nargin < 3 || isempty(normalizationRefCond)
        %normalizationRefCond not provided, look for it in the userdata
        if isfield(adaptData.data.DataInfo.UserData,'normalizationRefCond')
            normalizationRefCond = adaptData.data.DataInfo.UserData.normalizationRefCond;
            fprintf('No normalizationRefCond provided, will use what is available in the adaptData.data.DataInfo.UserData: %s\n',normalizationRefCond)
        else 
            %if no normalizationRefCond provided, look for one now.
            warning('No normalizationRefCond provided and could not find one the adaptData.data.Datainfo.UserData. Will look for OGBase, then TMBase, then NIMBase, then TRBase, then TSBase, if none present, will look for trial1 type base');
            ordersToTry = {'OG','TM','NIM','TR','TS',...
                adaptData.trialTypes{find(~cellfun(@isempty,adaptData.trialTypes),1)}};
            
            for o = ordersToTry
                normalizationRefCond = adaptData.metaData.getConditionsThatMatchV2('base', o{1});
                if ~isempty(normalizationRefCond)
                    break %found a match break
                end
            end
        end
    end

    if nargin < 4 || isempty(biasRemovalCond)
        %biasRemovalCond not provided, look for it in the userdata
        if isfield(adaptData.data.DataInfo.UserData,'normalizationRefCond')
            biasRemovalCond = adaptData.data.DataInfo.UserData.biasRemovalCond;
            fprintf('No biasRemovalCond provided, will use what is available in the adaptData.data.DataInfo.UserData: %s\n',normalizationRefCond)
        else 
            warning('No biasRemovalCond provided and also not found in the adaptData.data.DataInfo.UserData. Will use default bias removal method.')
            biasRemovalCond = []; %not found, use default (will remove trial type specific baseline
        end
    else
        if isstr(biasRemovalCond)
            biasRemovalCond = repmat({biasRemovalCond},1,10); %repeat the same condition for arbitrary # of times to cover all trial types 
            %the trial types can be: TM, OG, TM, TR, NIM (that's what we know so
            %far, and the code in removeBiasV4 will call
            %removebias(biasCond{typeIdx})
        elseif iscell(biasRemovalCond) %if it's cell will repeat the 1st entry multiple times
            biasRemovalCond = repmat(biasRemovalCond(1),1,10); 
        else %if some odd type is given
            warning('biasRemovalCond has to be a cell or string only. Unvalid input type. Will use default.')
            biasRemovalCond = [];
        end
        %else it's alreayd a cell just use it
    end
        
    %% Load data and normalize the data
    %get last 40 excluding the last 5, and average across strides by nanmean
    refEp = defineEpochs({normalizationRefCond}, {normalizationRefCond},-40,0,5,'nanmean');
    
    % In case there is already old parameters that
    %have normalized data, named as Normxx, remove them so that new clean normalized parameters can be created
    %as a replacement. This will happen whenever we save the normalized
    %data either individually or as a group
    ss = adaptData.data.getLabelsThatMatch('^Norm');
    s2 = adaptData.data.labels(~ismember(adaptData.data.labels,ss));
    adaptData = adaptData.reduce(s2);

    %check for any labels that already contains the name L2norm (they had
    %norm generated already), throw them away and regenerate. 
    %This would happen if we call recompute without calling flush and recompute
    ss =adaptData.data.getLabelsThatMatch('.*L2norm.*');
    s2 = adaptData.data.labels(~ismember(adaptData.data.labels,ss));
    adaptData = adaptData.reduce(s2);
    
    %build the label prefix for the EMG parameters.
    newLabelPrefix = adaptData.data.labels(startsWith(adaptData.data.labels,strcat('f',muscleLabels,'_s')) | ...
        startsWith(adaptData.data.labels,strcat('s',muscleLabels,'_s')));
    newLabelPrefix = unique(cellfun(@(x) x(1:end-2), newLabelPrefix,'UniformOutput',false));
    
    fprintf('\nNormalizing the data using %s\n', normalizationRefCond);
    %this function call will create new parameters as NormsTA_s 1 etc. for all
    %muscles with the linearly stretched data and raw unit data is in sTA_s
    %1
    adaptData = adaptData.normalizeToBaselineEpoch(newLabelPrefix,refEp);
    
    % adaptData = adaptData.removeBadStrides;
    
    %at this point, the raw data is in format sTA_s 1, the normalized data
    %is in NormsTA_s 1. A total of length(newLabelPrefix) x 12 new labels will be created. 
    rawDataLabelPrefix = newLabelPrefix; %save the old prefix to extract the voltage data
    normalizedDataLabelPrefix = strcat('Norm',newLabelPrefix);
    
    clear l1 l2 newLabelPrefix s2 ss
    adaptDataOriginal = adaptData;

    %% Compute norm parameters
    % use an array to collect all other data that's not by muscle.
    newData = nan(size(adaptData.data.Data,1),200); %allocate an arbitrarily large array
    newLabels = cell(1,200);
    newDescp = cell(1,200);
    newDataCol = 1;
    
    % Extract data for biased and non-biased data
    for rmBiase = [0,1]
        if rmBiase
            %Bias removal can be done manually or by calling remove bias. They don't
            %get the same results, checked that the TMBase we get from calling the
            %getEpochData TMBase is not the same as the base we get rom callig
            %removeBiasV4. Some values are the same, some are not, didn't figure out
            %why. For now wil rely on calling removebias
            adaptData = adaptDataOriginal.removeBias(biasRemovalCond);
            labelSuffix = 'Unbiased';
            descpSuffix = ['Before any parameter computation, the data is first unbiased by tasking current data - ' normalizationRefCond];
        else
            adaptData = adaptDataOriginal;
            labelSuffix = '';
            descpSuffix = '';
        end
    
        %% For each muscle, get L2 norm in original unit + in percentage unit
        bothLegsColsIdx = nan(numel(normalizedDataLabelPrefix),numel(adaptData.data.labels)); %for each muscle, store the binary array of where the corresponding column of data is
        bothLegsColsIdx_rawUnit = nan(numel(normalizedDataLabelPrefix),numel(adaptData.data.labels));
        allnanMuslcesByStride = false(size(adaptData.data.Data,1),numel(normalizedDataLabelPrefix)); %stride x muscles
        for i = 1:numel(normalizedDataLabelPrefix)
            %Finding the columns of the data
            dataColIdx=(cellfun(@(x) ~isempty(x),regexp(adaptData.data.labels,['^' normalizedDataLabelPrefix{i} '[ ]?\d+$'])));
            bothLegsColsIdx(i,:) = dataColIdx;
            curdata = adaptData.data.Data(:,dataColIdx);
            %record #of muscles that are all nan, compute it only once bc normalized vs raw should have the same nan content, will have 1
            %at a stride for a given muscle i that is all nan at that stride
            allnanMuslcesByStride(:,i) = all(isnan(curdata),2);
            curdata(isnan(curdata))=0; %nan are made zero to computer the norm
            %make nan zero to compute the norm, unless the whole 12 sub
            %interval is nan in which case the norm should also be nan.
            %now compute a by muscle norm, take L2 norm, over dim=2 (per rows)
            newData(:,newDataCol) = vecnorm(curdata,2,2);
            %set the strides that had nans in all 12 subintervals to nan.
            newData(allnanMuslcesByStride(:,i),newDataCol) = nan; 
            newLabels{newDataCol} = [normalizedDataLabelPrefix{i},'_L2normPercentUnit' labelSuffix];
            newDescp{newDataCol} = ['L2norm of: ', normalizedDataLabelPrefix{i}, ' in the precentge unit '...
                'after stretching each stride to have 100% = max of nanmean of last 40 strides of' normalizationRefCond ' and 0 = min of ' normalizationRefCond ...
                'for every stride (specific OGBase 0-100% calculation see your refEp definition). Then the norm is' ...
                'computed from the vecnorm of the 12 subintervasl of the current strides. nan values are treated as 0.' ...
                descpSuffix];
            newDataCol = newDataCol + 1;
            
            %do the same for the raw unit
            dataColIdx=(cellfun(@(x) ~isempty(x),regexp(adaptData.data.labels,['^' rawDataLabelPrefix{i} '[ ]?\d+$'])));
            bothLegsColsIdx_rawUnit(i,:) = dataColIdx;
            curdata = adaptData.data.Data(:,dataColIdx);
            curdata(isnan(curdata))=0; %nan are made zero to computer the norm 
            %now compute a by muscle norm
            newData(:,newDataCol) = vecnorm(curdata,2,2);
            %set the strides that had nans in all 12 subintervals to nan,
            %assume if it's nan in percentage unit will also be nan in the
            %raw unit.
            newData(allnanMuslcesByStride(:,i),newDataCol) = nan; 
            newLabels{newDataCol} =  [rawDataLabelPrefix{i},'_L2normRawUnit' labelSuffix];
            newDescp{newDataCol} = ['L2norm of: ', rawDataLabelPrefix{i}, ' in the original voltage unit for every stride, the norm is' ...
                'computed from the vecnorm of the 12 subintervasl of the current strides. nan values are treated as 0.' descpSuffix];
            newDataCol = newDataCol + 1;
        end
          
        %% compute the norm for the both legs and the avg norm (norm weighted by number of non-nan contributing muscles)
        curdata = adaptData.data.Data(:,any(bothLegsColsIdx,1));
        %find strides where all muscle are nan.
        allMsNanStride = all(isnan(curdata),2); %all nans across a column, set that stride to nan.
        curdata(isnan(curdata))=0; %nan are made zero to computer the norm 
        newData(:,newDataCol) = vecnorm(curdata,2,2);
        newData(allMsNanStride,newDataCol) = nan; %set strides that had all nans per muscles as nan.
        newLabels{newDataCol} = ['BothLegEMGL2normPercentUnit' labelSuffix];
        newDescp{newDataCol} = ['L2norm of all muscles after they are flattend as a 1D vector.' ...
            'in the percentage unit after stretching each stride to have 100% = max of nanmean of last 40 strides of ' normalizationRefCond ...
            ' and 0 = min of ' normalizationRefCond '(specific OGBase 0-100% calculation see your refEp definition). Nan values are treated as 0.' descpSuffix];
        newDataCol = newDataCol + 1;
        
        %do the norm weight by non-nan muscles
        newData(:,newDataCol) = newData(:,newDataCol-1)./sum(~allnanMuslcesByStride,2);
        newLabels{newDataCol} = ['BothLegEMGL2normPercentUnitAvg' labelSuffix];
        newDescp{newDataCol}  = ['L2norm of all muscles after they are flattend as a 1D vector divided by number of muscles that contribute to the norm.' ...
            'At any stride, if all data for a muscle is nan, the denominator will decrease by 1 (e.g., if only 19 muscles have non-nan entries, will take vecnom/19' ...
            'This ignores muscles that contain some non-nan and some nan values, they are counted as countributing muscles (this is unlikely, we would often have nans for every sub-intervals of a strides)' ...
            'The data is in the percentage unit after stretching each stride to have 100% = max of nanmean of last 40 strides of ' normalizationRefCond ...
            ' and 0 = min of ' normalizationRefCond '(specific OGBase 0-100% calculation see your refEp definition). Nan values are treated as 0.' descpSuffix];
        newDataCol = newDataCol + 1;
        
        curdata = adaptData.data.Data(:,any(bothLegsColsIdx_rawUnit,1));
        allMsNanStride = all(isnan(curdata),2); %all nans across a column, set that stride to nan.
        curdata(isnan(curdata))=0; %nan are made zero to computer the norm 
        newData(:,newDataCol) = vecnorm(curdata,2,2);
        newData(allMsNanStride,newDataCol) = nan; %set strides that had all nans per muscles as nan.
        newLabels{newDataCol}  = ['BothLegEMGL2normRawUnit' labelSuffix];
        newDescp{newDataCol}  = ['L2norm of all muscles after they are flattend as a 1D vector.' ...
            'in the raw voltage unit. Nan values are treated as 0.' descpSuffix];
        newDataCol = newDataCol + 1;
        
        newData(:,newDataCol) = newData(:,newDataCol-1)./sum(~allnanMuslcesByStride,2);
        newLabels{newDataCol}  = ['BothLegEMGL2normRawUnitAvg' labelSuffix];
        newDescp{newDataCol}  = ['L2norm of all muscles after they are flattend as a 1D vector divided by number of muscles that contribute to the norm.' ...
            'At any stride, if all data for a muscle is nan, the denominator will decrease by 1 (e.g., if only 19 muscles have non-nan entries, will take vecnom/19' ...
            'This ignores muscles that contain some non-nan and some nan values, they are counted as countributing muscles ' ...
            '(this is unlikely, we would often have nans for every sub-intervals of a strides)' ...
            'in the raw voltage unit. Nan values are treated as 0.' descpSuffix];
        newDataCol = newDataCol + 1;

        %record non-nans
        newData(:,newDataCol) = sum(~allnanMuslcesByStride,2);
        newLabels{newDataCol} = ['BothLegEMGL2normNumMuscles' labelSuffix];
        newDescp{newDataCol}  = ['number of non-nan muscles that contributed to the norm for both legs at a given stride. ',...
            'A muscle is only counted as not countributed if the whole 12 subintervals were nan.' labelSuffix];
        newDataCol = newDataCol + 1;
        
        %% Get the norm per leg
        for legs = {'slow','fast'}
            curdata = adaptData.data.Data(:,any(bothLegsColsIdx(startsWith(normalizedDataLabelPrefix,legs{1}(1)),:),1));
            allMsNanStride = all(isnan(curdata),2); %all nans across a column, set that stride to nan.
            curdata(isnan(curdata))=0; %nan are made zero to computer the norm 
            newData(:,newDataCol) = vecnorm(curdata,2,2);
            newData(allMsNanStride,newDataCol) = nan; %set strides that had all nans per muscles as nan.
            newLabels{newDataCol}  = [legs{1} 'LegEMGL2normPercentUnit'  labelSuffix];
            newDescp{newDataCol}  = ['L2norm of ' legs{1} ' leg muscles after they are flattend as a 1D vector.' ...
                'The data is in the percentage unit after stretching each stride to have 100% = max of nanmean of last 40 strides of ' normalizationRefCond ...
                ' and 0 = min of ' normalizationRefCond '(specific OGBase 0-100% calculation see your refEp definition). Nan values are treated as 0.' descpSuffix];
            newDataCol = newDataCol + 1;

            newData(:,newDataCol) = newData(:,newDataCol-1)./sum(~allnanMuslcesByStride(:,startsWith(normalizedDataLabelPrefix,legs{1}(1))),2);
            newLabels{newDataCol}  = [legs{1} 'LegEMGL2normPercentUnitAvg'  labelSuffix];
            newDescp{newDataCol}  = ['L2norm of ' legs{1} ' muscles after they are flattend as a 1D vector divided by number of muscles that contribute to the norm.' ...
                'At any stride, if all data for a muscle is nan, the denominator will decrease by 1 (e.g., if only 8 muscles have non-nan entries, will take vecnom/8' ...
                'This ignores muscles that contain some non-nan and some nan values, they are counted as countributing muscles ' ...
                '(this is unlikely, we would often have nans for every sub-intervals of a strides)' ...
                'The data is in the percentage unit after stretching each stride to have 100% = max of nanmean of last 40 strides of ' normalizationRefCond ...
                ' and 0 = min of ' normalizationRefCond '(specific OGBase 0-100% calculation see your refEp definition). Nan values are treated as 0.' descpSuffix];
            newDataCol = newDataCol + 1;
            
            curdata = adaptData.data.Data(:,any(bothLegsColsIdx_rawUnit(startsWith(rawDataLabelPrefix,legs{1}(1)),:),1));
            allMsNanStride = all(isnan(curdata),2); %all nans across a column, set that stride to nan.
            curdata(isnan(curdata))=0; %nan are made zero to computer the norm 
            newData(:,newDataCol) = vecnorm(curdata,2,2);
            newData(allMsNanStride,newDataCol) = nan; %set strides that had all nans per muscles as nan.
            newLabels{newDataCol}  = [legs{1} 'LegEMGL2normRawUnit' labelSuffix];
            newDescp{newDataCol}  = ['L2norm of ' legs{1} ' leg muscles after they are flattend as a 1D vector.' ...
                'in the raw voltage unit. Nan values are treated as 0.' descpSuffix];
            newDataCol = newDataCol + 1;
            
            %denominator is the same regardless of norm or raw voltage unit
            newData(:,newDataCol) = newData(:,newDataCol-1)./sum(~allnanMuslcesByStride(:,startsWith(normalizedDataLabelPrefix,legs{1}(1))),2);
            newLabels{newDataCol}  = [legs{1} 'LegEMGL2normRawUnitAvg' labelSuffix];
            newDescp{newDataCol}  = ['L2norm of ' legs{1} ' muscles after they are flattend as a 1D vector divided by number of muscles that contribute to the norm.' ...
                'At any stride, if all data for a muscle is nan, the denominator will decrease by 1 (e.g., if only 8 muscles have non-nan entries, will take vecnom/8' ...
                'This ignores muscles that contain some non-nan and some nan values, they are counted as countributing muscles ' ...
                '(this is unlikely, we would often have nans for every sub-intervals of a strides)' ...
                'in the raw voltage unit. Nan values are treated as 0.' descpSuffix];
            newDataCol = newDataCol + 1;

            %record the # of non-nan muscles to make it super clear how the
            %avg was calculated
            newData(:,newDataCol) = sum(~allnanMuslcesByStride(:,startsWith(normalizedDataLabelPrefix,legs{1}(1))),2);
            newLabels{newDataCol} = [legs{1} 'LegEMGL2normNumMuscles' labelSuffix];
            newDescp{newDataCol}  = ['Number of non-nan muscles that contributed to the norm for ' legs{1} ,...
                ' leg at a given stride. ',...
                'A muscle is only counted as not countributed if the whole 12 subintervals were nan.' labelSuffix];
            newDataCol = newDataCol + 1;
        end
        
        %% Get asym norm per muscle
        %first identify pairs of match
        allmusclesAsym = [];
        allmusclesAsym_rawUnit = [];
        
        allnanAsymMuslcesByStride = false(size(adaptData.data.Data,1),numel(muscleLabels)); %stride x muscles
        i = 1;
        for m = muscleLabels
            %first identify the prefix for this muscle, then look for match in
            %all labels that start with the prefix and ends with digits
            %(look for match that starts with NormfTA_s and end with digits.
            fastCol=cellfun(@(x) ~isempty(x),regexp(adaptData.data.labels,...
                ['^' normalizedDataLabelPrefix{contains(normalizedDataLabelPrefix,['f' m{1}])} '[ ]?\d+$']));
            fastdata = adaptData.data.Data(:,fastCol);
            
            slowCol = cellfun(@(x) ~isempty(x),regexp(adaptData.data.labels,...
                ['^' normalizedDataLabelPrefix{contains(normalizedDataLabelPrefix,['s' m{1}])} '[ ]?\d+$']));
            slowdata = adaptData.data.Data(:,slowCol);
            if ~isempty(fastdata) && ~isempty(slowdata)
                asymdata = fastdata - slowdata; %strides x 12
                allnanAsymMuslcesByStride(:,i) = all(isnan(asymdata),2);
                allmusclesAsym=[allmusclesAsym,asymdata]; %concatenate horizontally to get strides x n where n = 12x# of muscles with both legs recorded where asym can be computed
                asymdata(isnan(asymdata))=0; %nan are made zero to computer the norm 
                newData(:,newDataCol) = vecnorm(asymdata,2,2); %l2 norm over columns
                newData(allnanAsymMuslcesByStride(:,i),newDataCol) = nan;  %if all muscles are nan for a given stride, set norm to nan
                newDescp{newDataCol} = ['L2 norm of Asymmetry of ' m{1} ' between fast-slow leg in the percentage unit'...
                    'The data is in the percentage unit after stretching each stride to have 100% = max of nanmean of last 40 strides of ' normalizationRefCond ...
                    ' and 0 = min of ' normalizationRefCond '(specific OGBase 0-100% calculation see your refEp definition). Nan values are treated as 0.' descpSuffix];
                newLabels{newDataCol} = [m{1} 'AsymL2normPercentUnit' labelSuffix];
                newDataCol = newDataCol+1;
            end
        
            %look for match that start with fTA_s and ends with digits
            fastCol=cellfun(@(x) ~isempty(x),regexp(adaptData.data.labels,...
                ['^' rawDataLabelPrefix{startsWith(rawDataLabelPrefix,['f' m{1}])} '[ ]?\d+$']));
            fastdata = adaptData.data.Data(:,fastCol);
    
            slowCol = cellfun(@(x) ~isempty(x),regexp(adaptData.data.labels,...
                ['^' rawDataLabelPrefix{startsWith(rawDataLabelPrefix,['s' m{1}])} '[ ]?\d+$']));
            slowdata = adaptData.data.Data(:,slowCol);
            if ~isempty(fastdata) && ~isempty(slowdata)
                asymdata = fastdata - slowdata; %strides x 12
                allmusclesAsym_rawUnit=[allmusclesAsym_rawUnit,asymdata]; %concatenate horizontally to get strides x n where n = 12x# of muscles with both legs recorded where asym can be computed
                asymdata(isnan(asymdata))=0; %nan are made zero to computer the norm 
                newData(:,newDataCol) = vecnorm(asymdata,2,2); %l2 norm over columns
                newData(allnanAsymMuslcesByStride(:,i),newDataCol) = nan;  %if all muscles are nan for a given stride, set norm to nan
                newDescp{newDataCol} = ['L2 norm of Asymmetry of ' m{1} ' between fast-slow leg in the raw voltage unit' descpSuffix];
                newLabels{newDataCol} = [m{1} 'AsymL2normRawUnit' labelSuffix];
                newDataCol = newDataCol+1;
            end
            i = i + 1; %increment the counter
        end
        
        %% get the whole leg asym norm
        allMsNanStride = all(isnan(allmusclesAsym),2); %all nans across a column, set that stride to nan.
        allmusclesAsym(isnan(allmusclesAsym))=0; %nan are made zero to computer the norm 
        newData(:,newDataCol) = vecnorm(allmusclesAsym,2,2); %l2 norm over columns
        newData(allMsNanStride,newDataCol) = nan; %set strides that had all nans per muscles as nan.
        newLabels{newDataCol} = ['BothLegsAsymL2normPercentUnit' labelSuffix];
        newDescp{newDataCol} = ['L2 norm of Asymmetry of all muscles between fast-slow leg in the percentage unit'...
            'fter they are flattend as a 1D vector.' ...
            'The data is in the percentage unit by stretching each stride to have 100% = max of nanmean of last 40 strides of ' normalizationRefCond ...
            ' and 0 = min of ' normalizationRefCond '(specific OGBase 0-100% calculation see your refEp definition). Nan values are treated as 0.' descpSuffix];
        newDataCol = newDataCol+1;
        
        %get the whole leg asym avg norm, weighted by # of contributing muscles
        newData(:,newDataCol) = newData(:,newDataCol-1)./sum(~allnanAsymMuslcesByStride,2); %get total non-nan muscles count per stride
        newLabels{newDataCol}  = ['BothLegsAsymL2normPercentUnitAvg' labelSuffix];
        newDescp{newDataCol}  = ['L2norm of Asymmetry of all muscles between fast-slow leg in the percentage unit, '...
            'after they are flattend as a 1D vector, divided by number of muscles that contribute to the norm.' ...
                'At any stride, if all data for a muscle is nan, the denominator will decrease by 1 (e.g., if only 8 muscles have non-nan entries, will take vecnom/8' ...
                'This ignores muscles that contain some non-nan and some nan values, they are counted as countributing muscles ' ...
                '(this is unlikely, we would often have nans for every sub-intervals of a strides)' ...
                'The data is in the percentage unit by stretching each stride to have 100% = max of nanmean of last 40 strides of ' normalizationRefCond ...
                ' and 0 = min of ' normalizationRefCond '(specific OGBase 0-100% calculation see your refEp definition). Nan values are treated as 0.' descpSuffix];
        newDataCol = newDataCol + 1;
        
        %get whole leg asym norm in raw unit
        allMsNanStride = all(isnan(allmusclesAsym_rawUnit),2); %all nans across a column, set that stride to nan.
        allmusclesAsym_rawUnit(isnan(allmusclesAsym_rawUnit))=0; %nan are made zero to computer the norm 
        newData(:,newDataCol) = vecnorm(allmusclesAsym_rawUnit,2,2); %l2 norm over columns
        newData(allMsNanStride,newDataCol) = nan; %set strides that had all nans per muscles as nan.
        newLabels{newDataCol} = ['BothLegsAsymL2normRawUnit' labelSuffix];
        newDescp{newDataCol} = ['L2 norm of Asymmetry of all muscles between fast-slow leg in the raw voltage unit' descpSuffix];
        newDataCol = newDataCol+1;
        
        %get the whole leg avg norm, weighted by # of contributing muscles
        newData(:,newDataCol) = newData(:,newDataCol-1)./sum(~allnanAsymMuslcesByStride,2); %get total non-nan muscles count per stride
        newLabels{newDataCol}  = ['BothLegsAsymL2normRawUnitAvg' labelSuffix];
        newDescp{newDataCol}  = ['L2norm of Asymmetry of all muscles between fast-slow leg in the raw voltage unit, '...
            'after they are flattend as a 1D vector, divided by number of muscles that contribute to the norm.' ...
                'At any stride, if all data for a muscle is nan, the denominator will decrease by 1 (e.g., if only 8 muscles have non-nan entries, will take vecnom/8' ...
                'This ignores muscles that contain some non-nan and some nan values, they are counted as countributing muscles ' ...
                '(this is unlikely, we would often have nans for every sub-intervals of a strides)' ...
                 descpSuffix];
        newDataCol = newDataCol + 1;

        %record # of non-nan muscles for reproducibility
        newData(:,newDataCol) = sum(~allnanAsymMuslcesByStride,2);
        newLabels{newDataCol} = ['BothLegsAsymL2normNumMuscle' labelSuffix];
        newDescp{newDataCol}  = ['Number of non-nan muscles that contributed to the norm for the asym ',...
            'for all muscles between 2 legs at a given stride. ',...
            'A muscle is only counted as not countributed if the whole 12 subintervals were nan.' labelSuffix];
        newDataCol = newDataCol + 1;
    end
    
    %% Extracted all parameters, now remove the extra empty space and append the parameters
    newData(:,newDataCol:end) = [];
    newLabels(:,newDataCol:end) = [];
    newDescp(:,newDataCol:end) = [];
    
    %set up the adaptData to return, make sure it's the original with only
    %additions of the norm parameters + normalized data per interval (e.g.,
    %NormsVL_s 1), without any manipulations like removeBias, removeBadStrides.
    % A totla of muscles x 12 + 208 (norm)
    %parameters will be created. (e.g., 28 muscle x 12 + 208 = 544). Or if
    %this is in a flushAndRecompute, then the net new parameters are 0.
    adaptData = adaptDataOriginal; 
    
    %popuate new data
    adaptData.data=adaptData.data.appendData(newData,newLabels,newDescp);
    
    adaptData.data.DataInfo.UserData = struct();
    adaptData.data.DataInfo.UserData.muscleLabels = muscleLabels;
    adaptData.data.DataInfo.UserData.normalizationRefCond = normalizationRefCond;
    adaptData.data.DataInfo.UserData.biasRemovalCond = biasRemovalCond;
end
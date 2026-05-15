function [GRFData, analogs] = processGRFData(analogs, analogsInfo, ...
    info, tr)
%PROCESSGRFDATA Load and calibrate ground reaction force data from C3D.
%
%   Extracts force and moment channels from the analog struct returned
% by btkGetAnalogs, assigns force-plate label prefixes, performs an
% offset calibration sanity check against the raw pin signals, and
% packages the result into an orientedLabTimeSeries. Returns an empty
% GRFData when info.forces is false.
%
%   The analogs struct is returned with all Force/Moment fields removed
% (via rmfield) to free memory for subsequent EMG and marker extraction.
%
% Inputs:
%   analogs     - struct of analog channels from btkGetAnalogs
%   analogsInfo - struct with .frequency and .units fields from
%                 btkGetAnalogs
%   info        - session info struct; uses info.forces and
%                 info.backwardCheck
%   tr          - trial number (used in warning messages)
%
% Outputs:
%   GRFData - orientedLabTimeSeries of GRF data, or [] when
%             info.forces is false
%   analogs - input struct with Force/Moment fields removed
%
% Toolbox Dependencies:
%   Statistics and Machine Learning Toolbox (zscore)
%
% See also LOADTRIALS, ORIENTEDLABTIMESERIES.

arguments
    analogs     (1,1) struct
    analogsInfo (1,1) struct
    info        (1,1) struct
    tr          (1,1) double
end

% orientationInfo(offset, foreaftAx, sideAx, updownAx, foreaftSign,
%     sideSign, updownSign);
% check signs! this is used in biomechanics calculations
orientation = orientationInfo([0 0 0], 'y', 'x', 'z', 1, 1, 1);

% -----------------------------------------------------------------------
%  Named constants
% -----------------------------------------------------------------------
% Tolerance for the offset check: forces in N, scaled to N.mm for moments
grfOffsetTol             = 10;    % N or N.m
% Multiplier on the 1st-percentile of nonzero samples used as a rough
% activity threshold in the offset calibration (empirical)
prctileThreshMultiplier  = 4;
% Zero-threshold = offsetThreshMultiplier × tolerance; must not be < 2×
% (comment preserved from original)
offsetThreshMultiplier   = 4;
% Raw pin histogram parameters for mode-based offset estimation
pinHistBinWidth          = 0.001; % histogram bin width (V)
pinHistMin               = -1;    % ADC lower bound (V)
pinHistMax               =  1;    % ADC upper bound (V)
% -----------------------------------------------------------------------

%% Process Ground Reaction Force (GRF) Data
if info.forces          % if there is force data in the trial, ...
    % Must be defined to prevent errors when 'otherwise' skipped
    showWarning = false;
    relData     = [];
    forceLabels = {};
    units       = {};
    fieldList   = fieldnames(analogs);

    % Collect all raw analog channels for offset calibration
    rawMask       = startsWith(fieldList, 'Raw');
    rawFieldNames = fieldList(rawMask);
    rawCells = cellfun(@(f) analogs.(f), rawFieldNames, 'UniformOutput', false);
    raws = [rawCells{:}];
    raws = zscore(raws);

    % Fixed force plate label prefixes for channels 3-7;
    % channels 1 and 2 are belt-dependent (see below)
    fpPrefixMap = containers.Map( ...
        {'3', '4', '5', '6', '7'}, {'H', 'FP4', 'FP5', 'FP6', 'FP7'});

    % For each force, moment, center of pressure (COP) channel, ...
    for jj = 1:length(fieldList)

        % Skip fields that are not force or moment channels
        isForceOrMoment = ...
            strcmp(fieldList{jj}(1), 'F')    || ...
            strcmp(fieldList{jj}(1), 'M')    || ...
            contains(fieldList{jj}, 'Force') || ...
            contains(fieldList{jj}, 'Moment');
        if ~isForceOrMoment
            continue;
        end

        % Skip and warn for channels without a valid axis label
        hasValidAxis = ...
            strcmpi('x', fieldList{jj}(end-1)) || ...
            strcmpi('y', fieldList{jj}(end-1)) || ...
            strcmpi('z', fieldList{jj}(end-1));
        if ~hasValidAxis
            warning('processGRFData:GRFs', ...
                ['Found force/moment data that does not correspond ' ...
                'to any expected direction (x, y, or z). ' ...
                'Discarding channel %s.'], fieldList{jj});
            continue;
        end

        % Resolve the force plate label prefix from the channel
        % suffix digit. Channels 1 and 2 are belt-dependent:
        % normal walking assigns channel 1 to Left and channel 2
        % to Right; backward walking swaps this assignment.
        % Channels 3-7 use fixed prefixes from the lookup table.
        chSuffix = fieldList{jj}(end);
        if strcmp(chSuffix, '1')        % belt FP: left or right
            if info.backwardCheck == 1
                prefix = 'R';           % backward: ch1 = right
            else
                prefix = 'L';           % normal:   ch1 = left
            end
        elseif strcmp(chSuffix, '2')    % belt FP: right or left
            if info.backwardCheck == 1
                prefix = 'L';           % backward: ch2 = left
            else
                prefix = 'R';           % normal:   ch2 = right
            end
        elseif isKey(fpPrefixMap, chSuffix)
            prefix = fpPrefixMap(chSuffix);
        else
            % Unrecognized channel suffix; set warning flag and
            % remove field to keep analogs clean, then skip the
            % label/data append. Warning is deferred outside the
            % loop to reduce command window output (HH, 6/3/2015)
            showWarning = true;
            analogs     = rmfield(analogs, fieldList{jj});
            continue;
        end

        % Append label, units, and data for this valid channel,
        % then remove the field to free memory
        forceLabels{end+1} = [prefix fieldList{jj}(end-2:end-1)];
        units{end+1}       = analogsInfo.units.(fieldList{jj});
        relData            = [relData analogs.(fieldList{jj})];
        analogs            = rmfield(analogs, fieldList{jj});
    end
    if showWarning
        warning('processGRFData:GRFs', ...
            ['Found force/moment data in trial %d that does not ' ...
            'correspond to any expected channel ' ...
            '(L=1, R=2, H=4). Data discarded.'], tr);
    end

    % Sanity check: offset calibration — verify that force values
    % from analog pins have zero mode and correct scale/units.
    try
        % map=[1:6,8:13,46:51]; % Forces and moments to
        % corresponding pin in. Not current. Pablo, 22/11/2019.
        list = {'LFx', 'LFy', 'LFz', 'LMx', 'LMy', 'LMz', ...
            'RFx', 'RFy', 'RFz', 'RMx', 'RMy', 'RMz', ...
            'HFx', 'HFy', 'HFz', 'HMx', 'HMy', 'HMz'};
        offset                 = nan(size(list));
        gain                   = nan(size(list));
        trueOffset             = nan(size(list));
        differenceInForceUnits = nan(size(list));
        m                      = nan(size(list));
        unitsLabel             = '';  % default if no channel passes check
        for jj = 1:length(list)
            k = find(strcmp(forceLabels, list{jj}));
            if ~isempty(k)
                analogFieldNames = fieldnames(analogs);
                % idx=num2str(map(k)); % Hardcoded map of input
                % pins to forces/moments. Outdated.
                [~, rawPinColIdx] = max(abs(relData(:, k)' * raws));
                pinSuffix    = rawFieldNames{rawPinColIdx}(end);
                pinFieldMask = ~cellfun(@isempty, ...
                    regexp(analogFieldNames, ['Pin_' pinSuffix '$']));
                raw  = analogs.(analogFieldNames{pinFieldMask});
                proc = relData(:, k);
                % figure; plot(raw,proc,'.') % Finally found
                % where c3d2mat plots were coming from
                rel = find(proc ~= 0);
                if ~isempty(rel)
                    % prctileThreshMultiplier × 1st-percentile of
                    % nonzero samples; used as an activity threshold
                    m(jj)  = prctileThreshMultiplier * ...
                        prctile(abs(proc(rel)), 1);
                    coef   = polyfit(raw(rel), proc(rel), 1);
                    % Could be rounded to 2 sig. figs.
                    gain(jj)   = coef(1);
                    offset(jj) = -coef(2) / coef(1);
                    % histcounts requires bin edges, not centers;
                    % shift center vector by half a bin width to
                    % form edges for equivalent binning behavior.
                    % find(..., 1) picks the lowest-valued bin
                    % center deterministically when counts are tied.
                    binCenters = pinHistMin:pinHistBinWidth:pinHistMax;
                    binWidth   = binCenters(2) - binCenters(1);
                    edges      = (binCenters(1) - binWidth/2) : ...
                        binWidth : (binCenters(end) + binWidth/2);
                    Hh              = histcounts(raw, edges);
                    trueOffset(jj)  = ...
                        binCenters(find(Hh == max(Hh), 1));
                    differenceInForceUnits(jj) = ...
                        gain(jj) * (trueOffset(jj) - offset(jj));
                end
                switch list{jj}(2)
                    case 'F'    % forces
                        toleranceScaled = grfOffsetTol;
                        unitsLabel      = 'N';
                    case 'M'    % moments (in N.mm)
                        toleranceScaled = grfOffsetTol * 1000;
                        unitsLabel      = 'N.mm';
                    otherwise
                        error('');
                end
                if differenceInForceUnits(jj) > toleranceScaled
                    % figure % Commented out by MGR 01/24/24
                    % hold on
                    % plot(raw(rel),proc(rel),'.')
                    % plot([-0.01 0.01], ...
                    %     ([-0.01 0.01]+offset(jj))*gain(jj))
                    % hold off
                    % a=questdlg(['When loading ' list{jj} ...
                    %   ' there appears to be a non-zero mode ' ...
                    %   '(offset). Calculated offset is ' ...
                    %   num2str(differenceInForceUnits(jj)) ' ' ...
                    %   unitsLabel '. Please confirm that you want ' ...
                    %   'to subtract this offset.']);
                    a = 'No';
                    switch a
                        case 'Yes'
                            relData(:, k) = ...
                                gain(jj) * (raw - trueOffset(jj));
                            % Threshold at offsetThreshMultiplier ×
                            % tolerance; should never be less than 2×
                            relData(abs(relData(:, k)) < ...
                                offsetThreshMultiplier * ...
                                toleranceScaled, k) = 0;
                        case 'No'
                            % nop
                        otherwise
                            error('');
                    end
                end
            end
        end
    catch ME
        warning('processGRFData:GRFs', ...
            ['Could not perform offset check for trial ' ...
            num2str(tr) '. Proceeding with data as is. ' ...
            'Error: ' ME.message]);
    end

    % Create 'labTimeSeries' object
    % (data, t0, Ts, labels, orientation)
    % If fewer than three forces and moments per TM FP, warn
    if size(relData, 2) < 12
        warning('processGRFData:GRFs', ...
            ['Did not find all GRFs for the two belts ' ...
            'in trial ' num2str(tr)]);
    end
    GRFData = orientedLabTimeSeries(relData, 0, ...
        1/analogsInfo.frequency, forceLabels, orientation);
    GRFData.DataInfo.Units = unitsLabel;
else
    GRFData = [];
end

end

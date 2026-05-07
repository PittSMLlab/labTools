function out = computeForceParameters_OGFP(strideEvents, GRFData, ...
    slowleg, fastleg, BW, trialData, markerData)
%COMPUTEFORCEPARAMETERS_OGFP Compute AP GRF parameters from overground force plates.
%
%   Computes anterior-posterior (AP) ground reaction force parameters for
% trials recorded with overground force plates (OG/NIM). Forces are
% low-pass filtered at 20 Hz and AP offsets are estimated and removed
% per leg. For each stride, the function identifies which force plate
% contains a valid full-stance waveform (double-peaked vertical force
% exceeding a body-weight threshold) and extracts average braking and
% propulsion from that plate. The same parameters are also computed
% summed across all force plates and per-plate individually.
% Handrail use is flagged per stride via the HFy/HFz channels.
%
% Inputs:
%   strideEvents - struct of stride event times with fields tSHS, tFTO,
%                  tFHS, tSTO, tSHS2, tFTO2, tFHS2, tSTO2
%   GRFData      - labTimeSeries of ground reaction forces
%   slowleg      - slow-leg identifier, 'L' or 'R' (char)
%   fastleg      - fast-leg identifier, 'R' or 'L' (char)
%   BW           - participant body weight (kg)
%   trialData    - processedTrialData object supplying metaData
%   markerData   - labTimeSeries of marker data (used for optional COM
%                  computation; pass empty if unavailable)
%
% Outputs:
%   out - parameterSeries of AP GRF parameters per stride, including
%         braking/propulsion averages and peaks for the best single
%         force plate, summed across plates, and per-plate, plus
%         vertical and ML force means, and handrail use flag
%
% Toolbox Dependencies:
%   None
%
% See also COMPUTEFORCEPARAMETERS, COMPUTELEGFORCEPARAMETERS,
%   DETERMINETMANGLE, PARAMETERSERIES.

arguments
    strideEvents (1,1) struct
    GRFData
    slowleg      (1,:) char
    fastleg      (1,:) char
    BW           (1,1) double
    trialData
    markerData
end

%% Initialize Trial Metadata
trial = trialData.metaData.description;

gravityAcc   = 9.81;  % gravitational acceleration (m/s^2)
shoeWeightKg = 3.4;   % Nimbus shoe pair mass (two shoes; update if shoes change)
inTMAngle    = 8.5;   % incline angle (deg) assumed for 'IN' trial type

% Normalize forces to body weight (add shoe mass for Nimbus trials)
if strcmpi(trialData.metaData.type, 'NIM')
    normalizer = gravityAcc * (BW + shoeWeightKg);
else
    normalizer = gravityAcc * BW;
end

bwThMin  = 0.8;  % min vertical GRF threshold as fraction of BW
earlyFrac = 0.2;  % early-stance phase fraction
endFrac   = 0.2;  % end-of-stance phase fraction
strideDiv = 8;    % divisor for stride sub-window indexing
trialNum = str2double(trialData.metaData.rawDataFilename(end-1:end));
flipB = 1;

if iscell(trial)
    trial = trial{1};
end


ang = determineTMAngle(trialData.metaData);
if strcmp(trialData.metaData.type, 'IN')
    ang = inTMAngle;
end
flipIT = 2.*(ang >= 0)-1; %This will be -1 when it was a decline study, 1 otherwise
filtered = GRFData.lowPassFilter(20);
filteredF = filtered;
filteredS = filtered;


%% Remove AP Force Offsets
% New 8/5/2016 CJS: It came to my attenion that one of the decline subjects
% (LD30) one of the force plates was not properly zeroed.  Here I am
% manually shifting the forces.  I am assuming that the vertical forces have
% been properly been shifted during the c3d2mat process, otherwise the
% events are wrong and these lines of code will not save you. rats

%figure; plot(filtered.getDataAsTS([s 'Fy']).Data, 'b'); hold on; plot(filtered.getDataAsTS([f 'Fy']).Data, 'r');
fFy = filtered.getDataAsTS([fastleg 'Fy']);
sFy = filtered.getDataAsTS([slowleg 'Fy']);

fastLegOffsetData = nan(length(strideEvents.tSHS)-1, 1);
slowLegOffsetData = nan(length(strideEvents.tSHS)-1, 1);
if filtered.isaLabel('HFx')
    handrailData = filtered.getDataAsTS({'HFy', 'HFz'});
elseif filtered.isaLabel('XFx')
    handrailData = filtered.getDataAsTS({'XFy', 'XFz'});
    warning('Handrail data was not found labeled as ''HFx'', using ''XFx'' instead (not sure if that IS the handrail!). This is probably an issue with force channel numbering mismatch while loading (c3d2mat).');
else
    handrailData = [];
    warning('Found no handrail force data.');
end

% adding the force-plates data overground

% forces = GRFData.labels(~contains(GRFData.labels , 'M'))
% forces = forces(~contains(forces , 'H')) %Remove the handrail from the data
%
% if strcmpi(trialData.metaData.type,'OG') || strcmpi(trialData.metaData.type,'NIM')
%     Allz = forces(contains(forces , 'z'));
%     Ally = forces(contains(forces , 'y'));
% %     Allz = {'FP4Fz','FP5Fz','FP6Fz','FP7Fz','LFz','RFz'};
% %     Ally = {'FP4Fy','FP5Fy','FP6Fy','FP7Fy','LFy','RFy'};
% else
%     Allz = {'LFz','RFz'};
%     Ally = {'LFy','RFy'};
% end

Allz = {'FP4Fz', 'FP5Fz', 'FP6Fz', 'FP7Fz', 'LFz', 'RFz'};
Ally = {'FP4Fy', 'FP5Fy', 'FP6Fy', 'FP7Fy', 'LFy', 'RFy'};
ogfpyNames = {'FP4Fy', 'FP5Fy', 'FP6Fy', 'FP7Fy'};
ogfpzNames = {'FP4Fz', 'FP5Fz', 'FP6Fz', 'FP7Fz'};


for fp = 1:length(Ally)
    if filtered.isaLabel(Ally{fp})
        ogfp.(Ally{fp}) = filtered.getDataAsTS(Ally{fp});
        fastLegOffsetDataogfp.(Ally{fp}) = nan(length(strideEvents.tSHS)-1, 1);
        slowLegOffsetDataogfp.(Ally{fp}) = nan(length(strideEvents.tSHS)-1, 1);
    else
        ogfp.(Ally{fp}) = [];
        fastLegOffsetDataogfp.(Ally{fp}) = nan(length(strideEvents.tSHS)-1, 1);
        slowLegOffsetDataogfp.(Ally{fp}) = nan(length(strideEvents.tSHS)-1, 1);
    end
end

for st = 1:length(strideEvents.tSHS)-1
    SHS = strideEvents.tSHS(st);
    FTO = strideEvents.tFTO(st);
    FHS = strideEvents.tFHS(st);
    STO = strideEvents.tSTO(st);
    FTO2 = strideEvents.tFTO2(st);
    SHS2 = strideEvents.tSHS2(st);

    if ~(isnan(FTO) || isnan(FHS) || FTO > FHS)
        fastLegOffsetData(st) = median(fFy.split(FTO, FHS).Data, 'omitnan');
    end
    if ~(isnan(STO) || isnan(SHS2))
        slowLegOffsetData(st) = median(sFy.split(STO, SHS2).Data, 'omitnan');
    end

    for fp = 1:length(Ally)
        if filtered.isaLabel(Ally{fp})
            fastLegOffsetDataogfp.(Ally{fp})(st) = median(ogfp.(Ally{fp}).split(FTO, FHS).Data, 'omitnan');
            slowLegOffsetDataogfp.(Ally{fp})(st) = median(ogfp.(Ally{fp}).split(STO, SHS2).Data, 'omitnan');
        end
    end
end
fastLegOffset = round(median(fastLegOffsetData, 'omitnan'), 3);
slowLegOffset = round(median(slowLegOffsetData, 'omitnan'), 3);
disp(['Fast Leg Offset: ' num2str(fastLegOffset) ', Slow Leg Offset: ' num2str(slowLegOffset)]);

filtered.Data(:, find(strcmp(filtered.getLabels(), [fastleg 'Fy']))) = filtered.getDataAsVector([fastleg 'Fy']) - fastLegOffset;
filtered.Data(:, find(strcmp(filtered.getLabels(), [slowleg 'Fy']))) = filtered.getDataAsVector([slowleg 'Fy']) - slowLegOffset;


for fp = 1:length(Ally)

    fastLegOffsetogfp.(Ally{fp}) = round(median(fastLegOffsetDataogfp.(Ally{fp}), 'omitnan'), 3);
    filteredF.Data(:, find(strcmp(filteredF.getLabels(), Ally{fp}))) = filteredF.getDataAsVector(Ally{fp}) - fastLegOffsetogfp.(Ally{fp});

    slowLegOffsetogfp.(Ally{fp}) = round(median(slowLegOffsetDataogfp.(Ally{fp}), 'omitnan'), 3);
    filteredS.Data(:, find(strcmp(filteredS.getLabels(), Ally{fp}))) = filteredS.getDataAsVector(Ally{fp}) - slowLegOffsetogfp.(Ally{fp});

end


%figure; plot(filtered.getDataAsTS([slowleg 'Fy']).Data, 'b'); hold on; plot(filtered.getDataAsTS([fastleg 'Fy']).Data, 'r');line([0 5*10^5], [0, 0])

%% Pre-Allocate Output Arrays
inclineAPFactor = 0.5;  % AP gravity component for inclined treadmill trials
levelOfInterest = inclineAPFactor .* flipIT .* cosd(90 - abs(ang)); %The actual angle of the incline

lenny = length(strideEvents.tSHS)-1;
impactS_all = NaN(1, lenny); impactF_all = NaN(1, lenny);
SB_all = NaN(1, lenny); SP_all = NaN(1, lenny); SZ_all = NaN(1, lenny); SX_all = NaN(1, lenny);
FB_all = NaN(1, lenny); FP_all = NaN(1, lenny); FZ_all = NaN(1, lenny); FX_all = NaN(1, lenny);
HandrailHolding = NaN(1, lenny);
SBmax_all = NaN(1, lenny); SPmax_all = NaN(1, lenny); SZmax_all = NaN(1, lenny); SXmax_all = NaN(1, lenny);
impactSmax_all = NaN(1, lenny); impactFmax_all = NaN(1, lenny);
FBmax_all = NaN(1, lenny); FPmax_all = NaN(1, lenny); FZmax_all = NaN(1, lenny); FXmax_all = NaN(1, lenny);

for fp = 1:length(Ally)
    impactS_ogfp.(Ally{fp}) = NaN(1, lenny); impactF_ogfp.(Ally{fp}) = NaN(1, lenny);
    SB_ogfp.(Ally{fp}) = NaN(1, lenny); SP_ogfp.(Ally{fp}) = NaN(1, lenny); SZ_ogfp.(Ally{fp}) = NaN(1, lenny); SX_ogfp.(Ally{fp}) = NaN(1, lenny);
    FB_ogfp.(Ally{fp}) = NaN(1, lenny); FP_ogfp.(Ally{fp}) = NaN(1, lenny); FZ_ogfp.(Ally{fp}) = NaN(1, lenny); FX_ogfp.(Ally{fp}) = NaN(1, lenny);
    SBmax_ogfp.(Ally{fp}) = NaN(1, lenny); SPmax_ogfp.(Ally{fp}) = NaN(1, lenny); SZmax_ogfp.(Ally{fp}) = NaN(1, lenny); SXmax_ogfp.(Ally{fp}) = NaN(1, lenny);
    impactSmax_ogfp.(Ally{fp}) = NaN(1, lenny); impactFmax_ogfp.(Ally{fp}) = NaN(1, lenny);
    FBmax_ogfp.(Ally{fp}) = NaN(1, lenny); FPmax_ogfp.(Ally{fp}) = NaN(1, lenny); FZmax_ogfp.(Ally{fp}) = NaN(1, lenny); FXmax_ogfp.(Ally{fp}) = NaN(1, lenny);
end

%% Compute Per-Stride Force Parameters
slowCount = 0; fastCount = 0;
slowCountForce = 0; slowCountNoForce = 0;
fastCountForce = 0; fastCountNoForce = 0;

for st = 1:length(strideEvents.tSHS)-1
    % NOTE: stance splits use event variables from the PREVIOUS iteration;
    % the current-stride events are assigned after these lines. Do not
    % reorder without understanding the downstream effect on each stride.
    filteredSlowStance       = filteredS.split(SHS, STO);
    filteredFastStance       = filteredF.split(FHS, FTO2);
    filteredSlowSingleStance = filteredS.split(FTO, FHS);
    filteredFastSingleStance = filteredF.split(STO, SHS2);

    % Getting the events
    SHS = strideEvents.tSHS(st); FTO = strideEvents.tFTO(st); FHS = strideEvents.tFHS(st); STO = strideEvents.tSTO(st); SHS2 = strideEvents.tSHS2(st); FTO2 = strideEvents.tFTO2(st);

    if isnan(SHS) || isnan(STO) % make sure the slow events are not empty
        striderSyAll = []; striderSzAll = [];
        for fp = 1:length(Ally)
            striderSyOgfp.(Ally{fp}) = [];
            striderSyOgfpSS.(Ally{fp}) = [];

            striderSyOgfp.(Allz{fp}) = [];
            striderSyOgfpSS.(Allz{fp}) = [];
        end
        striderSyOgfpSum = []; striderSzOgfpSum = [];
        existSlowF(st) = 0;

    else %FILTERING
        striderSyOgfpSum = 0; striderSzOgfpSum = 0;

        for fp = 1:length(Ally)
            % getting each force-plate value during stance
            striderSyOgfp.(Ally{fp}) = flipIT.*filteredSlowStance.getDataAsVector(Ally{fp})/normalizer;
            striderSzOgfp.(Allz{fp}) = flipIT.*filteredSlowStance.getDataAsVector(Allz{fp})/normalizer;

            % getting each force-plate value during single stance
            striderSyOgfpSS.(Ally{fp}) = flipIT.*filteredSlowSingleStance.getDataAsVector(Ally{fp})/normalizer;
            striderSzOgfpSS.(Allz{fp}) = flipIT.*filteredSlowSingleStance.getDataAsVector(Allz{fp})/normalizer;
            % adding all forces together
            striderSyOgfpSum = striderSyOgfpSum + striderSyOgfpSS.(Ally{fp});
            striderSzOgfpSum = striderSzOgfpSum + striderSzOgfpSS.(Allz{fp});
            %                         figure()
            %                         plot(striderSyOgfp.(Ally{fp}))
        end

        if abs(min(striderSzOgfpSum)) > bwThMin
            sumL = floor(length(striderSyOgfpSum)/2);
            if max(striderSyOgfpSum(1:sumL)) > max(striderSyOgfpSum(sumL:end))
                striderSyOgfpSum = -striderSyOgfpSum;
            end
        else
            striderSyOgfpSum = []; striderSzOgfpSum = [];
        end

        if abs(min(striderSzOgfpSum)) > 0.1 % checking if the force is avaliable
            slowCountForce = slowCountForce + 1;
            existSlowF(st) = 1;
        else
            slowCountNoForce = slowCountNoForce + 1;
            existSlowF(st) = 0;
        end

        slowDivider = floor(length(striderSzOgfp.('LFz'))/strideDiv);
        goodCounter = 0; ogfpySlow = [];
        for fp = 1:length(Allz)
            if isempty(striderSzOgfp.(Allz{fp})) == 0
                %                 mini1st.(Allz{fp}) = abs(min(striderSzOgfp.(Allz{fp})(1:end)));
                mini1st.(Allz{fp}) = abs(min(striderSzOgfp.(Allz{fp})(slowDivider:slowDivider*3)));
                mini2nd.(Allz{fp}) = abs(min(striderSzOgfp.(Allz{fp})(slowDivider*5:slowDivider*7)));

                if mini1st.(Allz{fp}) >= bwThMin && mini2nd.(Allz{fp}) >= bwThMin && abs(striderSzOgfp.(Allz{fp})(1)) <= earlyFrac && abs(striderSzOgfp.(Allz{fp})(end)) <= endFrac
                    ogfpySlow = Ally{fp}; ogfpzSlow = Allz{fp}; goodCounter = goodCounter + 1;
                end
            end
        end


        if good_counter == 1 && isempty(OGFPy_slow) == 0 % check if a stride has a good for at least on one of the force-plates

            striderSy_all = flipIT.*filteredSlowStance.getDataAsVector(OGFPy_slow)/Normalizer;
            striderSz_all = flipIT.*filteredSlowStance.getDataAsVector(OGFPz_slow)/Normalizer;


            if isempty(striderSy_all)
                striderSz_all = [];
            elseif max(striderSy_all(slow_divider:slow_divider*3)) > max(striderSy_all(slow_divider*5:slow_divider*7))
                striderSy_all = -striderSy_all;
                striderSy_OGFP_SS.(OGFPy_slow) = -striderSy_OGFP_SS.(OGFPy_slow);

                if strcmp(trialData.metaData.name,'adaptation') && mean(striderSy_all, 'omitnan') < 0
                    striderSy_all = -striderSy_all;
                    striderSy_OGFP_SS.(OGFPy_slow) = -striderSy_OGFP_SS.(OGFPy_slow);
                end
            end
        else
            striderSy_all = []; striderSz_all = [];
        end
    end

    if isnan(FHS) || isnan(FTO2) % make sure the slow events are not empty
        striderFy_all = []; striderFz_all = [];
        for fp = 1:length(Ally)
            striderFy_OGFP.(Ally{fp}) = [];
        end
        striderFy_OGFP_sum = []; striderFz_OGFP_sum = [];
        exist_FastF(st) = 0;
    else %FILTERING
        striderFy_OGFP_sum = 0; striderFz_OGFP_sum = 0;

        for fp = 1:length(Ally)

            striderFy_OGFP.(Ally{fp}) = flipIT.*filteredFastStance.getDataAsVector(Ally{fp})/Normalizer;
            striderFz_OGFP.(Allz{fp}) = flipIT.*filteredFastStance.getDataAsVector(Allz{fp})/Normalizer;

            striderFy_OGFP_SS.(Ally{fp}) = flipIT.*filteredFastSingleStance.getDataAsVector(Ally{fp})/Normalizer;
            striderFz_OGFP_SS.(Allz{fp}) = flipIT.*filteredFastSingleStance.getDataAsVector(Allz{fp})/Normalizer;

            striderFy_OGFP_sum = striderFy_OGFP_sum + striderFy_OGFP_SS.(Ally{fp});
            striderFz_OGFP_sum = striderFz_OGFP_sum + striderFz_OGFP_SS.(Allz{fp});

            %             [alignedTS,originalDurations] = stridedTSToAlignedTS(filteredFastStance,100)
            %
            %             filteredFastStance.stridedTSToAlignedTS(100);
            %             filteredFastStance.align(gaitEvents,{'FHS','SHS2'},[15,30]);
        end

        if abs(min(striderFz_OGFP_sum)) > 0.1 % checking if the force is avaliable
            FastCount_force = FastCount_force + 1;
            exist_FastF(st) = 1;

            sum_l = floor(length(striderFy_OGFP_sum)/2);
            if max(striderFy_OGFP_sum(1:sum_l)) > max(striderFy_OGFP_sum(sum_l:end))
                striderFy_OGFP_sum = -striderFy_OGFP_sum;
            end
        else
            FastCount_no_force = FastCount_no_force + 1;
            exist_FastF(st) = 0;
            striderFy_OGFP_sum = []; striderFz_OGFP_sum = [];
        end

        midway_fast = floor(length(striderFz_OGFP.('LFz'))/divideri);
        good_counter = 0; OGFPy_fast = [];
        for fp = 1:length(Allz)
            if isempty(striderFz_OGFP.(Allz{fp})) == 0
                %                 mini_1st.(Allz{fp}) = abs(min(striderFz_OGFP.(Allz{fp})(1:end)));
                mini_1st.(Allz{fp}) = abs(min(striderFz_OGFP.(Allz{fp})(midway_fast:midway_fast*3)));
                mini_2nd.(Allz{fp}) = abs(min(striderFz_OGFP.(Allz{fp})(midway_fast*5:midway_fast*7)));

                if mini_1st.(Allz{fp}) >= bw_th_min && mini_2nd.(Allz{fp}) >= bw_th_min && abs(striderFz_OGFP.(Allz{fp})(1)) <= early_th && abs(striderFz_OGFP.(Allz{fp})(end)) <= end_th
                    OGFPy_fast = Ally{fp}; OGFPz_fast = Allz{fp}; good_counter = good_counter + 1;
                end
            end
        end

        if good_counter == 1 && isempty(OGFPy_fast) == 0

            striderFy_all = flipIT.*filteredFastStance.getDataAsVector(OGFPy_fast)/Normalizer;
            striderFz_all = flipIT.*filteredFastStance.getDataAsVector(OGFPz_fast)/Normalizer;
            if isempty(striderFy_all)
                striderFz_all = [];
            elseif max(striderFy_all(midway_fast:midway_fast*3)) > max(striderFy_all(midway_fast*5:midway_fast*7))
                striderFy_all = -striderFy_all;
                striderFy_OGFP_SS.(OGFPy_fast) = -striderFy_OGFP_SS.(OGFPy_fast);
            end
        else
            striderFy_all = []; striderFz_all = [];
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Check if the participant is holding the handrail %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ~isempty(handrailData)
        HandrailHolding(st) = 0.05 < sqrt(mean(sum(handrailData.split(SHS, SHS2).Data.^2, 2), 'omitnan'))/Normalizer;
    else
        HandrailHolding(st) = NaN;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% computing the parameters for the force plate that a good stance occures %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isempty(striderSy_all) || all(striderSy_all==striderSy_all(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
        %This does nothing, as vars are initialized as nan:
    else
        if std(striderSy_all, 'omitnan')<0.01 && mean(striderSy_all, 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

        else
            ns_all = find((striderSy_all-LevelofInterest)<0.1);%1:65
            ps_all = find((striderSy_all-LevelofInterest)>0);

            %             if strcmp(trialData.metaData.name,'adaptation')
            %                 ns_all(find(ns_all>=0.5*length(striderSy_all)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            %                 ps_all(find(ps_all<=0.5*length(striderSy_all)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %
            %                 ns_all(find(ns_all<=0.05*length(striderSy_all)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            %                 ps_all(find(ps_all>=0.95*length(striderSy_all)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %
            %             else


            ns_all(find(ns_all >= 0.5*length(striderSy_all))) = []; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            ps_all(find(ps_all <= 0.5*length(striderSy_all))) = []; % 2/14/2018 -- This is to prevent the impulse from being identified.

            ns_all(find(ns_all <= 0.12*length(striderSy_all))) = []; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            ps_all(find(ps_all >= 0.95*length(striderSy_all))) = []; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %             end

            ImpactMagS_all = find((striderSy_all-LevelofInterest)==max(striderSy_all(1:75)-LevelofInterest, [], 'omitnan'));%no longer percent of stride
            if isempty(ImpactMagS_all)%~=1
                postImpactS_all = ns_all(find(ns_all>ImpactMagS_all(end), 1, 'first'));
                if isempty(postImpactS_all)%~=1
                    ps_all(find(ps_all < postImpactS_all)) = [];
                    ns_all(find(ns_all < postImpactS_all)) = [];
                end
            end

            if isempty(ns_all)

            else
                SB_all(st) = FlipB.*(mean(striderSy_all(ns_all)-LevelofInterest, 'omitnan'));
                SBmax_all(st) = FlipB.*(min(striderSy_all(ns_all)-LevelofInterest, [], 'omitnan'));
            end
            if isempty(ps_all)

            else
                SP_all(st) = mean(striderSy_all(ps_all)-LevelofInterest, 'omitnan');
                SPmax_all(st) = max(striderSy_all(ps_all)-LevelofInterest, [], 'omitnan');
            end

            if exist('postImpactS_all')==0 || isempty(postImpactS_all)==1
                %                     impactS(st)=NaN;
                %                     impactSmax(st)=NaN;
            else
                impactS_all(st) = mean(striderSy_all(find((striderSy_all(SHS-SHS+1: postImpactS_all)-LevelofInterest)>0)), 'omitnan')-LevelofInterest;
                if isempty(striderSy_all(find((striderSy_all(SHS-SHS+1: postImpactS_all)-LevelofInterest)>0)))
                    %impactSmax(st)=NaN;
                else
                    impactSmax_all(st) = max(striderSy_all(find((striderSy_all(SHS-SHS+1: postImpactS_all)-LevelofInterest)>0)), [], 'omitnan')-LevelofInterest;
                end
            end

            i_slow = i_slow+1;
            OGFPy_slowi(i_slow) = {OGFPy_slow};
            OGFPz_slowi(i_slow) = {OGFPz_slow};
            str_striderSy.([OGFPy_slow num2str(i_slow)]) = striderSy_all;
            str_striderSz.([OGFPz_slow num2str(i_slow)]) = striderSz_all;





            %             figure (trialData.metaData.condition*10-8)
            %             hold on
            %             plot(striderSy_all-LevelofInterest,'b')
            %             if isempty(SBmax_all(st)) == 0 && isempty(SPmax_all(st)) == 0
            %                 if  isempty(find(striderSy_all-LevelofInterest == SBmax_all(st))) || isempty(find(striderSy_all-LevelofInterest == SPmax_all(st)))
            %                 else
            %                     SBmax_ind(i_slow) = find(striderSy_all-LevelofInterest == SBmax_all(st));
            %                     plot(SBmax_ind(i_slow),SBmax_all(st),'k*')
            %                     SPmax_ind(i_slow) = find(striderSy_all-LevelofInterest == SPmax_all(st));
            %                     plot(SPmax_ind(i_slow),SPmax_all(st),'k*')
            %                 end
            %             end
            %             title(['Slow Ground reaction Forces with Peaks' '     ' trialData.metaData.name])

            %             if isempty(striderSy_OGFP_SS.(OGFPy_slow)) == 0
            %             if  isempty(find(striderSy_all == striderSy_OGFP_SS.(OGFPy_slow)(1)))
            %             else
            %                 slow_SS_ind(i_slow) = find(striderSy_all == striderSy_OGFP_SS.(OGFPy_slow)(1));
            %                 plot(slow_SS_ind(i_slow):slow_SS_ind(i_slow)+length(striderSy_OGFP_SS.(OGFPy_slow))-1,striderSy_OGFP_SS.(OGFPy_slow),'r*')
            %                 hold off
            %                 title(['Slow Single Stance Overlapped' '     ' trialData.metaData.name])
            %                 saveas(gcf,['SlowOverlapped_' trialData.metaData.name],'png')
            %             end
            %             end
            %             figure (trialData.metaData.condition*10-7)
            %             plot(str_striderSz.([OGFPz_slowi{i_slow} num2str(i_slow)]),'Color',[1,0,0])
            %             for yo=1:8
            %                 line([yo*slow_divider yo*slow_divider], get(gca, 'ylim'),'Color',[0 0 0])
            %             end

        end
        SZ_all(st) = -1*mean(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'z']), 'omitnan')/Normalizer;
        SX_all(st) = mean(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'x']), 'omitnan')/Normalizer;
        SZmax_all(st) = -1*min(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'z']), [], 'omitnan')/Normalizer;
        SXmax_all(st) = min(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'x']), [], 'omitnan')/Normalizer;
    end

    %%Now for the fast leg...
    if isempty(striderFy_all) || all(striderFy_all==striderFy_all(1)) || isempty(FTO) || isempty(STO)

    else
        if std(striderFy_all, 'omitnan')<0.01 && mean(striderFy_all, 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

        else
            nf_all = find((striderFy_all-LevelofInterest)<0.1);%1:65
            pf_all = find((striderFy_all-LevelofInterest)>0);

            %             if strcmp(trialData.metaData.name,'adaptation')
            %                 nf_all(find(nf_all>=0.5*length(striderFy_all)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            %                 pf_all(find(pf_all<=0.5*length(striderFy_all)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %
            %                 nf_all(find(nf_all<=0.12*length(striderFy_all)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            %                 pf_all(find(pf_all>=0.95*length(striderFy_all)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %
            %             else


            nf_all(find(nf_all >= 0.5*length(striderFy_all))) = []; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            pf_all(find(pf_all <= 0.5*length(striderFy_all))) = []; % 2/14/2018 -- This is to prevent the impulse from being identified.

            nf_all(find(nf_all <= 0.12*length(striderFy_all))) = []; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            pf_all(find(pf_all >= 0.95*length(striderFy_all))) = []; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %             end

            ImpactMagF_all = find((striderFy_all-LevelofInterest)==max(striderFy_all(1:75)-LevelofInterest, [], 'omitnan'));%1:15
            if isempty(ImpactMagF_all)%~=1
                postImpactF_all = nf_all(find(nf_all>ImpactMagF_all(end), 1, 'first'));
                if isempty(postImpactF_all)%~=1
                    pf_all(find(pf_all < postImpactF_all)) = [];
                    nf_all(find(nf_all < postImpactF_all)) = [];
                end
            end

            if isempty(pf_all)

            else
                FP_all(st) = mean(striderFy_all(pf_all)-LevelofInterest, 'omitnan');
                FPmax_all(st) = max(striderFy_all(pf_all)-LevelofInterest, [], 'omitnan');
            end
            if isempty(nf_all)

            else
                FB_all(st) = FlipB.*(mean(striderFy_all(nf_all)-LevelofInterest, 'omitnan'));
                FBmax_all(st) = FlipB.*(min(striderFy_all(nf_all)-LevelofInterest, [], 'omitnan'));
            end

            if exist('postImpactF_all')==0 || isempty(postImpactF_all)==1

            else
                impactF_all(st) = mean(striderFy_all(find((striderFy_all(FHS-FHS+1: postImpactF_all)-LevelofInterest)>0)), 'omitnan')-LevelofInterest;
                if isempty(striderFy_all(find((striderFy_all(FHS-FHS+1: postImpactF_all)-LevelofInterest)>0)))

                else
                    impactFmax_all(st) = max(striderFy_all(find((striderFy_all(FHS-FHS+1: postImpactF_all)-LevelofInterest)>0)), [], 'omitnan')-LevelofInterest;
                end
            end

            i_fast = i_fast+1;
            OGFPy_fasti(i_fast) = {OGFPy_fast};
            OGFPz_fasti(i_fast) = {OGFPz_fast};
            str_striderFy.([OGFPy_fast num2str(i_fast)]) = striderFy_all;
            str_striderFz.([OGFPz_fast num2str(i_fast)]) = striderFz_all;

            %             figure (trialData.metaData.condition*10-6)
            %             hold on
            %             plot(striderFy_all-LevelofInterest,'r')
            %             if isempty(FBmax_all(st)) == 0 && isempty(FPmax_all(st)) == 0
            %                 if  isempty(find(striderFy_all-LevelofInterest == FBmax_all(st))) || isempty(find(striderFy_all-LevelofInterest == FPmax_all(st)))
            %                 else
            %                     FBmax_ind(i_fast) = find(striderFy_all-LevelofInterest == FBmax_all(st));
            %                     plot(FBmax_ind(i_fast),FBmax_all(st),'k*')
            %                     FPmax_ind(i_fast) = find(striderFy_all-LevelofInterest == FPmax_all(st));
            %                     plot(FPmax_ind(i_fast),FPmax_all(st),'k*')
            %                 end
            %             end
            %             title(['Fast Ground reaction Forces with Peaks' '     ' trialData.metaData.name])
            %             hold on
            %             plot(striderFy_all,'b')
            %             if  isempty(find(striderFy_all == striderFy_OGFP_SS.(OGFPy_fast)(1)))
            %             else
            %                 fast_SS_ind(i_fast) = find(striderFy_all == striderFy_OGFP_SS.(OGFPy_fast)(1));
            %                 plot(fast_SS_ind(i_fast):fast_SS_ind(i_fast)+length(striderFy_OGFP_SS.(OGFPy_fast))-1,striderFy_OGFP_SS.(OGFPy_fast),'r*')
            %                 hold off
            %                 title(['Fast Single Stance Overlapped' '     ' trialData.metaData.name])
            %                 saveas(gcf,['FastOverlapped_' trialData.metaData.name],'png')
            %             end
        end
        FZ_all(st) = -1*mean(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'z']), 'omitnan')/Normalizer; %%[OGFPy_fast(1:end-1) 'z']
        FX_all(st) = mean(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'x']), 'omitnan')/Normalizer;
        FZmax_all(st) = -1*min(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'z']), [], 'omitnan')/Normalizer;
        FXmax_all(st) = max(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'x']), [], 'omitnan')/Normalizer;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% computing the parameters for adding all forces toghether %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isempty(striderSy_OGFP_sum) || all(striderSy_OGFP_sum==striderSy_OGFP_sum(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
        %This does nothing, as vars are initialized as nan:
        SBmax_OGFP_sum(st) = NaN;
        SPmax_OGFP_sum(st) = NaN;
    else
        if std(striderSy_OGFP_sum, 'omitnan')<0.01 && mean(striderSy_OGFP_sum, 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

        else
            ns_OGFP_sum = find((striderSy_OGFP_sum-LevelofInterest) < 0);%1:65
            ps_OGFP_sum = find((striderSy_OGFP_sum-LevelofInterest) > 0);

            %             ImpactMagS_OGFP_sum = find((striderSy_OGFP_sum-LevelofInterest)==max(striderSy_OGFP_sum(1:75)-LevelofInterest, [], 'omitnan'));%no longer percent of stride
            %             if isempty(ImpactMagS_OGFP_sum)~=1
            %                 postImpactS_OGFP_sum = ns_OGFP_sum(find(ns_OGFP_sum>ImpactMagS_OGFP_sum(end), 1, 'first'));
            %                 if isempty(postImpactS_OGFP_sum)~=1
            %                     ps_OGFP_sum(find(ps_OGFP_sum<postImpactS_OGFP_sum))=[];
            %                     ns_OGFP_sum(find(ns_OGFP_sum<postImpactS_OGFP_sum))=[];
            %                 end
            %             end

            if isempty(ns_OGFP_sum)
                SBmax_OGFP_sum(st) = NaN;
            else
                SB_OGFP_sum(st) = FlipB.*(mean(striderSy_OGFP_sum(ns_OGFP_sum)-LevelofInterest, 'omitnan'));
                SBmax_OGFP_sum(st) = FlipB.*(min(striderSy_OGFP_sum(ns_OGFP_sum)-LevelofInterest, [], 'omitnan'));
            end
            if isempty(ps_OGFP_sum)
                SPmax_OGFP_sum(st) = NaN;
            else
                SP_OGFP_sum(st) = mean(striderSy_OGFP_sum(ps_OGFP_sum)-LevelofInterest, 'omitnan');
                SPmax_OGFP_sum(st) = max(striderSy_OGFP_sum(ps_OGFP_sum)-LevelofInterest, [], 'omitnan');
            end

            if exist('postImpactS_OGFP_sum')==0 || isempty(postImpactS_OGFP_sum)==1 || isnan(SHS)
                %                     impactS(st)=NaN;
                %                     impactSmax(st)=NaN;
                impactSmax_OGFP_sum(st) = NaN;
            else
                impactS_OGFP_sum(st) = mean(striderSy_OGFP_sum(find((striderSy_OGFP_sum(SHS-SHS+1: postImpactS_OGFP_sum)-LevelofInterest)>0)), 'omitnan')-LevelofInterest;
                if isempty(striderSy_OGFP_sum(find((striderSy_OGFP_sum(SHS-SHS+1: postImpactS_OGFP_sum)-LevelofInterest)>0)))
                    %impactSmax(st)=NaN;
                else
                    impactSmax_OGFP_sum(st) = max(striderSy_OGFP_sum(find((striderSy_OGFP_sum(SHS-SHS+1: postImpactS_OGFP_sum)-LevelofInterest)>0)), [], 'omitnan')-LevelofInterest;
                end
            end

            %             figure(trialData.metaData.condition*10-5)
            %             hold on
            %             plot(striderSz_OGFP_sum)
            %             figure (trialData.metaData.condition*10-4)
            %             hold on
            %             plot(striderSy_OGFP_sum)

        end
    end

    %%Now for the fast leg...
    if isempty(striderFy_OGFP_sum) || all(striderFy_OGFP_sum==striderFy_OGFP_sum(1)) || isempty(FTO) || isempty(STO)
        FBmax_OGFP_sum(st) = NaN;
        FPmax_OGFP_sum(st) = NaN;
    else
        if std(striderFy_OGFP_sum, 'omitnan')<0.01 && mean(striderFy_OGFP_sum, 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

        else
            nf_OGFP_sum = find((striderFy_OGFP_sum-LevelofInterest) < 0);%1:65
            pf_OGFP_sum = find((striderFy_OGFP_sum-LevelofInterest) > 0);
            %             ImpactMagF_OGFP_sum=find((striderFy_OGFP_sum-LevelofInterest)==max(striderFy_OGFP_sum(1:75)-LevelofInterest, [], 'omitnan'));%1:15
            %             if isempty(ImpactMagF_OGFP_sum)~=1
            %                 postImpactF_OGFP_sum=nf_OGFP_sum(find(nf_OGFP_sum>ImpactMagF_OGFP_sum(end), 1, 'first'));
            %                 if isempty(postImpactF_OGFP_sum)~=1
            %                     pf_OGFP_sum(find(pf_OGFP_sum<postImpactF_OGFP_sum))=[];
            %                     nf_OGFP_sum(find(nf_OGFP_sum<postImpactF_OGFP_sum))=[];
            %                 end
            %             end

            if isempty(pf_OGFP_sum)
                FPmax_OGFP_sum(st) = NaN;
            else
                FP_OGFP_sum(st) = mean(striderFy_OGFP_sum(pf_OGFP_sum)-LevelofInterest, 'omitnan');
                FPmax_OGFP_sum(st) = max(striderFy_OGFP_sum(pf_OGFP_sum)-LevelofInterest, [], 'omitnan');
            end
            if isempty(nf_OGFP_sum)
                FBmax_OGFP_sum(st) = NaN;
            else
                FB_OGFP_sum(st) = FlipB.*(mean(striderFy_OGFP_sum(nf_OGFP_sum)-LevelofInterest, 'omitnan'));
                FBmax_OGFP_sum(st) = FlipB.*(min(striderFy_OGFP_sum(nf_OGFP_sum)-LevelofInterest, [], 'omitnan'));
            end

            if exist('postImpactF_OGFP_sum')==0 || isempty(postImpactF_OGFP_sum)==1 || isnan(FHS)==1
                impactFmax_OGFP_sum(st) = NaN;
            else
                impactF_OGFP_sum(st) = mean(striderFy_OGFP_sum(find((striderFy_OGFP_sum(FHS-FHS+1: postImpactF_OGFP_sum)-LevelofInterest)>0)), 'omitnan')-LevelofInterest;
                if isempty(striderFy_OGFP_sum(find((striderFy_OGFP_sum(FHS-FHS+1: postImpactF_OGFP_sum)-LevelofInterest)>0)))

                else
                    impactFmax_OGFP_sum(st) = max(striderFy_OGFP_sum(find((striderFy_OGFP_sum(FHS-FHS+1: postImpactF_OGFP_sum)-LevelofInterest)>0)), [], 'omitnan')-LevelofInterest;
                end
            end

        end

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% computing the parameters for each of the overground force-plates %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    for fp = 1:length(Ally)
        if isempty(striderSy_OGFP.(Ally{fp})) || all(striderSy_OGFP.(Ally{fp})==striderSy_OGFP.(Ally{fp})(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
            %This does nothing, as vars are initialized as nan:
        else
            if std(striderSy_OGFP.(Ally{fp}), 'omitnan')<0.01 && mean(striderSy_OGFP.(Ally{fp}), 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

            else
                ns_OGFP.(Ally{fp}) = find((striderSy_OGFP.(Ally{fp})-LevelofInterest) < 0);%1:65
                ps_OGFP.(Ally{fp}) = find((striderSy_OGFP.(Ally{fp})-LevelofInterest) > 0);

                ImpactMagS_OGFP.(Ally{fp}) = find((striderSy_OGFP.(Ally{fp})-LevelofInterest)==max(striderSy_OGFP.(Ally{fp})(1:75)-LevelofInterest, [], 'omitnan'));%no longer percent of stride
                if isempty(ImpactMagS_OGFP.(Ally{fp})) ~= 1
                    postImpactS_OGFP.(Ally{fp}) = ns_OGFP.(Ally{fp})(find(ns_OGFP.(Ally{fp}) > ImpactMagS_OGFP.(Ally{fp})(end), 1, 'first'));
                    if isempty(postImpactS_OGFP.(Ally{fp}))~=1
                        ps_OGFP.(Ally{fp})(find(ps_OGFP.(Ally{fp}) < postImpactS_OGFP.(Ally{fp}))) = [];
                        ns_OGFP.(Ally{fp})(find(ns_OGFP.(Ally{fp}) < postImpactS_OGFP.(Ally{fp}))) = [];
                    end
                end

                if isempty(ns_OGFP.(Ally{fp}))

                else
                    SB_OGFP.(Ally{fp})(st) = FlipB.*(mean(striderSy_OGFP.(Ally{fp})(ns_OGFP.(Ally{fp}))-LevelofInterest, 'omitnan'));
                    SBmax_OGFP.(Ally{fp})(st) = FlipB.*(min(striderSy_OGFP.(Ally{fp})(ns_OGFP.(Ally{fp}))-LevelofInterest, [], 'omitnan'));
                end
                if isempty(ps_OGFP.(Ally{fp}))

                else
                    SP_OGFP.(Ally{fp})(st) = mean(striderSy_OGFP.(Ally{fp})(ps_OGFP.(Ally{fp}))-LevelofInterest, 'omitnan');
                    SPmax_OGFP.(Ally{fp})(st) = max(striderSy_OGFP.(Ally{fp})(ps_OGFP.(Ally{fp}))-LevelofInterest, [], 'omitnan');
                end

                if exist(['postImpactS_OGFP.' Ally{fp}])==0 || isempty(postImpactS_OGFP.(Ally{fp}))==1
                    %                     impactS(st)=NaN;
                    %                     impactSmax(st)=NaN;
                else
                    impactS_OGFP.(Ally{fp})(st) = mean(striderSy_OGFP.(Ally{fp})(find((striderSy_OGFP.(Ally{fp})(SHS-SHS+1: postImpactS_OGFP.(Ally{fp}))-LevelofInterest)>0)), 'omitnan')-LevelofInterest;
                    if isempty(striderSy_OGFP.(Ally{fp})(find((striderSy_OGFP.(Ally{fp})(SHS-SHS+1: postImpactS_OGFP.(Ally{fp}))-LevelofInterest)>0)))
                        %impactSmax(st)=NaN;
                    else
                        impactSmax_OGFP.(Ally{fp})(st) = max(striderSy_OGFP.(Ally{fp})(find((striderSy_OGFP.(Ally{fp})(SHS-SHS+1: postImpactS_OGFP.(Ally{fp}))-LevelofInterest)>0)), [], 'omitnan')-LevelofInterest;
                    end
                end
            end
            SZ_OGFP.(Ally{fp})(st) = -1*mean(filteredSlowStance.getDataAsVector([Ally{fp}(1:end-1) 'z']), 'omitnan')/Normalizer;
            SX_OGFP.(Ally{fp})(st) = mean(filteredSlowStance.getDataAsVector([Ally{fp}(1:end-1) 'x']), 'omitnan')/Normalizer;
            SZmax_OGFP.(Ally{fp})(st) = -1*min(filteredSlowStance.getDataAsVector([Ally{fp}(1:end-1) 'z']), [], 'omitnan')/Normalizer;
            SXmax_OGFP.(Ally{fp})(st) = min(filteredSlowStance.getDataAsVector([Ally{fp}(1:end-1) 'x']), [], 'omitnan')/Normalizer;
        end

        %%Now for the fast leg...
        if isempty(striderFy_OGFP.(Ally{fp})) || all(striderFy_OGFP.(Ally{fp})==striderFy_OGFP.(Ally{fp})(1)) || isempty(FTO) || isempty(STO)

        else
            if std(striderFy_OGFP.(Ally{fp}), 'omitnan')<0.01 && mean(striderFy_OGFP.(Ally{fp}), 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

            else
                nf_OGFP.(Ally{fp}) = find((striderFy_OGFP.(Ally{fp})-LevelofInterest) < 0);%1:65
                pf_OGFP.(Ally{fp}) = find((striderFy_OGFP.(Ally{fp})-LevelofInterest) > 0);
                ImpactMagF_OGFP.(Ally{fp}) = find((striderFy_OGFP.(Ally{fp})-LevelofInterest)==max(striderFy_OGFP.(Ally{fp})(1:75)-LevelofInterest, [], 'omitnan'));%1:15
                if isempty(ImpactMagF_OGFP.(Ally{fp}))~=1
                    postImpactF_OGFP.(Ally{fp}) = nf_OGFP.(Ally{fp})(find(nf_OGFP.(Ally{fp}) > ImpactMagF_OGFP.(Ally{fp})(end), 1, 'first'));
                    if isempty(postImpactF_OGFP.(Ally{fp}))~=1
                        pf_OGFP.(Ally{fp})(find(pf_OGFP.(Ally{fp}) < postImpactF_OGFP.(Ally{fp}))) = [];
                        nf_OGFP.(Ally{fp})(find(nf_OGFP.(Ally{fp}) < postImpactF_OGFP.(Ally{fp}))) = [];
                    end
                end

                if isempty(pf_OGFP.(Ally{fp}))

                else
                    FP_OGFP.(Ally{fp})(st) = mean(striderFy_OGFP.(Ally{fp})(pf_OGFP.(Ally{fp}))-LevelofInterest, 'omitnan');
                    FPmax_OGFP.(Ally{fp})(st) = max(striderFy_OGFP.(Ally{fp})(pf_OGFP.(Ally{fp}))-LevelofInterest, [], 'omitnan');
                end
                if isempty(nf_OGFP.(Ally{fp}))

                else
                    FB_OGFP.(Ally{fp})(st) = FlipB.*(mean(striderFy_OGFP.(Ally{fp})(nf_OGFP.(Ally{fp}))-LevelofInterest, 'omitnan'));
                    FBmax_OGFP.(Ally{fp})(st) = FlipB.*(min(striderFy_OGFP.(Ally{fp})(nf_OGFP.(Ally{fp}))-LevelofInterest, [], 'omitnan'));
                end

                if exist(['postImpactF_OGFP.' Ally{fp}])==0 || isempty(postImpactF_OGFP.(Ally{fp}))==1

                else
                    impactF_OGFP.(Ally{fp})(st) = mean(striderFy_OGFP.(Ally{fp})(find((striderFy_OGFP.(Ally{fp})(FHS-FHS+1: postImpactF_OGFP.(Ally{fp}))-LevelofInterest)>0)), 'omitnan')-LevelofInterest;
                    if isempty(striderFy_OGFP.(Ally{fp})(find((striderFy_OGFP.(Ally{fp})(FHS-FHS+1: postImpactF_OGFP.(Ally{fp}))-LevelofInterest)>0)))

                    else
                        impactFmax_OGFP.(Ally{fp})(st) = max(striderFy_OGFP.(Ally{fp})(find((striderFy_OGFP.(Ally{fp})(FHS-FHS+1: postImpactF_OGFP.(Ally{fp}))-LevelofInterest)>0)), [], 'omitnan')-LevelofInterest;
                    end
                end
            end
            FZ_OGFP.(Ally{fp})(st) = -1*mean(filteredFastStance.getDataAsVector([Ally{fp}(1:end-1) 'z']), 'omitnan')/Normalizer;
            FX_OGFP.(Ally{fp})(st) = mean(filteredFastStance.getDataAsVector([Ally{fp}(1:end-1) 'x']), 'omitnan')/Normalizer;
            FZmax_OGFP.(Ally{fp})(st) = -1*min(filteredFastStance.getDataAsVector([Ally{fp}(1:end-1) 'z']), [], 'omitnan')/Normalizer;
            FXmax_OGFP.(Ally{fp})(st) = max(filteredFastStance.getDataAsVector([Ally{fp}(1:end-1) 'x']), [], 'omitnan')/Normalizer;
        end
    end
end
% title(['Fast Single Stance Overlapped' '     ' trialData.metaData.name])
% saveas(gcf,['FastOverlapped_' trialData.metaData.name],'png')
% SlowCount_force
% SlowCount_no_force
% SlowCount_force/(SlowCount_force+SlowCount_no_force)
% FastCount_force
% FastCount_no_force
% FastCount_force/(FastCount_force+FastCount_no_force)

% figure (trialData.metaData.condition*10-3)
% hold on
% for i = 1:i_slow
%     %     if i<= i_slow/2
%     %         plot(str_striderSy.([OGFPy_slowi{i} num2str(st)]),'Color',(255-i)/255*[i/255,i/255,1])
%     %     elseif i > i_slow/2 && i_slow < 2*255
%     %         plot(str_striderSy.([OGFPy_slowi{i} num2str(st)]),'Color',(255-i_slow+i)/255*[1,i/255,i/255])
%     %     else
%     %         plot(str_striderSy.([OGFPy_slowi{i} num2str(st)]),'Color',[0,0,0])
%     %     end
%     if trialNum == 1 || trialNum == 4 || trialNum == 8 || trialNum == 11 %i<= i_slow/2
%         plot(str_striderSy.([OGFPy_slowi{i} num2str(st)]),'Color',[0,0,1])
%     elseif trialNum == 3 || trialNum == 6 || trialNum == 10 || trialNum == 13
%         plot(str_striderSy.([OGFPy_slowi{i} num2str(st)]),'Color',[1,0,0])
%     else
%         plot(str_striderSy.([OGFPy_slowi{i} num2str(st)]),'Color',[0,0,0])
%     end
%
% end
% hold off
% %legend(OGFPy_slowi)
% title(['Slow AP' '     ' trialData.metaData.name])
% saveas(gcf,['Slow AP_' trialData.metaData.name],'png')
%
%
% figure (trialData.metaData.condition*10-2)
% hold on
% for i = 1:i_slow
%     if i<= i_slow/2
%         plot(str_striderSz.([OGFPz_slowi{i} num2str(st)]),'k')
%     else
%         plot(str_striderSz.([OGFPz_slowi{i} num2str(st)]),'k')
%     end
% end
% hold off
% %legend(OGFPy_slowi)
% title(['Slow Z' '     ' trialData.metaData.name])
% saveas(gcf,['Slow Z_' trialData.metaData.name],'png')
%
% figure (trialData.metaData.condition*10-1)
% hold on
% for i = 1:i_fast
%     if trialNum == 1 || trialNum == 4 || trialNum == 8 || trialNum == 11 %i<= i_fast/2
%         plot(str_striderFy.([OGFPy_fasti{i} num2str(st)]),'b')
%     elseif trialNum == 3 || trialNum == 6 || trialNum == 10 || trialNum == 13
%         plot(str_striderFy.([OGFPy_fasti{i} num2str(st)]),'r')
%     else
%         plot(str_striderFy.([OGFPy_fasti{i} num2str(st)]),'k')
%     end
% end
% hold off
% title(['Fast AP' '     ' trialData.metaData.name])
% saveas(gcf,['Fast AP_' trialData.metaData.name],'png')
%
%
% figure (trialData.metaData.condition*10)
% hold on
% for i = 1:i_fast
%     if i<= i_fast/2
%         plot(str_striderFz.([OGFPz_fasti{i} num2str(st)]),'b')
%     else
%         plot(str_striderFz.([OGFPz_fasti{i} num2str(st)]),'r')
%     end
% end
% hold off
% %legend(OGFPy_fasti)
% title(['Fast Z' '     ' trialData.metaData.name])
% saveas(gcf,['Fast Z_' trialData.metaData.name],'png')


% figure (trialData.metaData.condition*4-3)
% hold on
% plot(striderSy_all)
% hold off
% title('Slow AP')
% saveas(gcf,['Slow AP' num2str(trialData.metaData.condition)],'png')
%
% figure (trialData.metaData.condition*4-2)
% hold on
% plot(striderSz)
% hold off
% title('Slow Z')
% saveas(gcf,['Slow Z' num2str(trialData.metaData.condition)],'png')
%
% figure (trialData.metaData.condition*4-1)
% hold on
% plot(striderFy_all)
% hold off
% title('Fast AP')
% saveas(gcf,['Fast AP' num2str(trialData.metaData.condition)],'png')
%
% figure (trialData.metaData.condition*4)
% hold on
% plot(striderFz)
% hold off
% title('Fast Z')
% saveas(gcf,['Fast Z' num2str(trialData.metaData.condition)],'png')


%% Compute Optional COM Parameters
if false %~isempty(markerData.getLabelsThatMatch('HAT'))
    [ outCOM ] = computeCOM(strideEvents, markerData, BW, slowleg, fastleg, impactS, expData, gaitEvents, flipIT );
else
    outCOM.Data = [];
    outCOM.labels = [];
    outCOM.description = [];
end

%% Compute Optional COP Parameters (Not Yet Implemented)
% if ~isempty(markerData.getLabelsThatMatch('LCOP'))
%     [outCOP] = computeCOPParams( strideEvents, markerData, BW, slowleg, fastleg, impactS, expData, gaitEvents );
% else
outCOP.Data = [];
outCOP.labels = [];
outCOP.description = [];
% end

%% Assemble and Return Output
% data_OGFP_sum = [[impactS_OGFP_sum NaN]' [SB_OGFP_sum NaN]' [SP_OGFP_sum NaN]' [impactF_OGFP_sum NaN]' [FB_OGFP_sum NaN]' [FP_OGFP_sum NaN]' [FB_OGFP_sum-SB_OGFP_sum NaN]' [FP_OGFP_sum-SP_OGFP_sum NaN]'...
%     [impactSmax_OGFP_sum NaN]' [SBmax_OGFP_sum NaN]' [SPmax_OGFP_sum NaN]' [impactFmax_OGFP_sum NaN]' [FBmax_OGFP_sum NaN]' [FPmax_OGFP_sum NaN]'];
%
% labels_OGFP_sum = {'FyImpactS_OGFP_sum', 'FyBS_OGFP_sum', 'FyPS_OGFP_sum', 'FyImpactF_OGFP_sum', 'FyBF_OGFP_sum', 'FyPF_OGFP_sum','FyBSym_OGFP_sum', 'FyPSym_OGFP_sum', 'FyImpactSmax_OGFP_sum', 'FyBSmax_OGFP_sum', 'FyPSmax_OGFP_sum', 'FyImpactFmax_OGFP_sum', 'FyBFmax_OGFP_sum', 'FyPFmax_OGFP_sum'};
% % Carly's paper looks at the maximum breaking and propulsion forces for the fast and the slow side which will be  'FyBSmax', 'FyPSmax', 'FyBFmax', 'FyPFmax'
%
% description_OGFP_sum = {'GRF-FYs average signed impact force', 'GRF-FYs average signed braking', 'GRF-FYs average signed propulsion',...
%     'GRF-FYf average signed impact force', 'GRF-FYf average signed braking', 'GRF-FYf average signed propulsion', ...
%     'GRF-FYs average signed Symmetry braking', 'GRF-FYs average signed Symmetry propulsion',...
%     'GRF-FYs max signed impact force', 'GRF-FYs max signed braking', 'GRF-FYs max signed propulsion',...
%     'GRF-FYf max signed impact force', 'GRF-FYf max signed braking', 'GRF-FYf max signed propulsion'};


%data_OGFP_sum = [[SBmax_OGFP_sum NaN]' [SPmax_OGFP_sum NaN]' [FBmax_OGFP_sum NaN]' [FPmax_OGFP_sum NaN]'];

%labels_OGFP_sum = {'FyBSmax_OGFP_sum', 'FyPSmax_OGFP_sum', 'FyBFmax_OGFP_sum', 'FyPFmax_OGFP_sum'};
% Carly's paper looks at the maximum breaking and propulsion forces for the fast and the slow side which will be  'FyBSmax', 'FyPSmax', 'FyBFmax', 'FyPFmax'

%description_OGFP_sum = {'GRF-FYs max signed braking', 'GRF-FYs max signed propulsion','GRF-FYf max signed braking', 'GRF-FYf max signed propulsion'};

data_all = [[impactS_all NaN]' [SB_all NaN]' [SP_all NaN]' [impactF_all NaN]' [FB_all NaN]' [FP_all NaN]' [FB_all-SB_all NaN]' [FP_all-SP_all NaN]' [SX_all NaN]' [SZ_all NaN]' [FX_all NaN]' [FZ_all NaN]' ...
    [impactSmax_all NaN]' [SBmax_all NaN]' [SPmax_all NaN]' [impactFmax_all NaN]' [FBmax_all NaN]' [FPmax_all NaN]' [SXmax_all NaN]' [SZmax_all NaN]' [FXmax_all NaN]' [FZmax_all NaN]' [exist_SlowF NaN]' [exist_FastF NaN]'];

labels_all = {'FyImpactS_all', 'FyBS_all', 'FyPS_all', 'FyImpactF_all', 'FyBF_all', 'FyPF_all','FyBSym_all', 'FyPSym_all', 'FxS_all', 'FzS_all', 'FxF_all', 'FzF_all', 'FyImpactSmax_all', 'FyBSmax_all', 'FyPSmax_all', 'FyImpactFmax_all', 'FyBFmax_all', 'FyPFmax_all', 'FxSmax_all', 'FzSmax_all', 'FxFmax_all', 'FzFmax_all','exist_SlowF','exist_FastF'};
% Carly's paper looks at the maximum breaking and propulsion forces for the fast and the slow side which will be  'FyBSmax', 'FyPSmax', 'FyBFmax', 'FyPFmax'

description_all = {'GRF-FYs average signed impact force', 'GRF-FYs average signed braking', 'GRF-FYs average signed propulsion',...
    'GRF-FYf average signed impact force', 'GRF-FYf average signed braking', 'GRF-FYf average signed propulsion', ...
    'GRF-FYs average signed Symmetry braking', 'GRF-FYs average signed Symmetry propulsion',...
    'GRF-Fxs average force', 'GRF-Fzs average force', 'GRF-Fxf average force', 'GRF-Fzf average force', ...
    'GRF-FYs max signed impact force', 'GRF-FYs max signed braking', 'GRF-FYs max signed propulsion',...
    'GRF-FYf max signed impact force', 'GRF-FYf max signed braking', 'GRF-FYf max signed propulsion', ...
    'GRF-Fxs max force', 'GRF-Fzs max force', 'GRF-Fxf max force', 'GRF-Fzf max force', 'Slow stance force more than 10% of the bw exists on one of the FP', 'Fast stance force more than 10% of the bw exist on one of the FP'};


% data_all = [data_all data_OGFP_sum];
% labels_all = [labels_all labels_OGFP_sum];
% description_all = [description_all description_OGFP_sum];


data_OGFP = [];
labels_OGFP = [];
description_OGFP = [];

for fp = 1:length(Ally)

    data_OGFP_temp = [[SBmax_OGFP.(Ally{fp}) NaN]' [SPmax_OGFP.(Ally{fp}) NaN]' [FBmax_OGFP.(Ally{fp}) NaN]' [FPmax_OGFP.(Ally{fp}) NaN]'];
    labels_OGFP_temp = {['FyBSmax_' Ally{fp}], ['FyPSmax_' Ally{fp}], ['FyBFmax_' Ally{fp}], ['FyPFmax_' Ally{fp}]};
    description_OGFP_temp = {[Ally{fp} 'GRF-FYs max signed braking'], [Ally{fp} 'GRF-FYs max signed propulsion'], [Ally{fp} 'GRF-FYf max signed braking'], [Ally{fp} 'GRF-FYf max signed propulsion']};

    %     data_OGFP = [data_OGFP data_OGFP_temp];
    %     labels_OGFP = [labels_OGFP labels_OGFP_temp];
    %     description_OGFP = [description_OGFP description_OGFP_temp];

    wannaAddOGFP = 1;
    if wannaAddOGFP == 1
        data_all = [data_all data_OGFP_temp];
        labels_all = [labels_all labels_OGFP_temp];
        description_all = [description_all description_OGFP_temp];
    end

end

if isempty(markerData.getLabelsThatMatch('Hat'))
    data_all = [data_all outCOM.Data outCOP.Data];
    labels_all = [labels_all outCOM.labels outCOP.labels];
    description_all = [description_all outCOM.description outCOP.description];
end

%out = parameterSeries(data_OGFP,labels_OGFP,[],description_OGFP);
out = parameterSeries(data_all, labels_all, [], description_all);

%% Labels and descriptions:
% aux={'impactS',               'GRF-FYs average signed impact force';...
%     'SB',                   'mid hip position at SHS. NOT: average hip pos of stride (should be nearly constant on treadmill - implemented for OG bias removal) (in mm)';...
%     'SP',           'distance between ankle markers at SHS2 (in mm)';...
%     'impactF',           'distance between ankle markers at FHS (in mm)';...
%     'FB',        'sAnkle position, with respect to fAnkle at STO (in mm)';...
%     'FB-SB',        'fAnkle position with respect to sAnkle at FTO (in mm)';...
%     'FP-SP',                'ankle placement of slow leg at SHS2 (realtive to avg hip marker) (in mm)';...
% 	'SX',                'ankle placement of slow leg at SHS (realtive to avg hip marker) (in mm)';...
%     'SZ',                'ankle placement of fast leg at FHS (in mm)';...
%     'FX',                 'alphaFast-alphaSlow';...
%     'FZ',                 '(alphaFast-alphaSlow)/(SLf+SLs)';...
%     'HandrailHolding',             'slow leg angle (hip to ankle with respect to vertical) at SHS2 (in deg)';...
%     'impactSmax',             'fast leg angle at FHS (in deg)';...
%     'SBmax',                 'ankle placement of slow leg at STO (relative avg hip marker) (in mm)';...
%     'SPmax',                 'ankle placement of fast leg at FTO2 (in mm)';...
% 	'impactFmax',                    'ankle postion of the slow leg @FHS (in mm)';...
%     'FBmax',                    'ankle position of Fast leg @SHS (in mm)';...
%     'FPmax',                     'Xdiff Fast - Slow';...
%     'SXmax',                     'Xdiff/(SLf+SLs)';...
% 	'SZmax',                 'Ratio of FTO/FHS';...
%     'FXmax',                 'Ratio of STO/SHS';...
%     'FZmax',              'Ratio of fank@SHS/FHS';...
%     };
%
% paramLabels=aux(:,1);
% description=aux(:,2);
% % Assign parameters to data matrix
% data = nan(lenny,length(paramLabels));
% for i=1:length(paramLabels)
%     eval(['data(:,i)=' paramLabels{i} ';'])
% end
% % Create parameterSeries
% out=parameterSeries(data,paramLabels,[],description);

end


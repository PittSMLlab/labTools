function out = computeForceParameters_OGFP_aligned(strideEvents, GRFData, slowleg, fastleg, BW, trialData, markerData)
%COMPUTEFORCEPARAMETERS_OGFP_ALIGNED Compute AP GRF parameters using stride-aligned force traces.
%
%   Variant of COMPUTEFORCEPARAMETERS_OGFP that time-normalizes each
% stance-phase GRF waveform to a fixed grid before extracting parameters.
% Forces are low-pass filtered at 20 Hz. For each stride, the AP force
% trace is aligned to 100 points across stance and braking/propulsion
% parameters are derived from the aligned trace. TM incline angle is
% used to apply a sign flip for decline trials. Handrail use is flagged
% per stride via the HFy/HFz channels. NIM trials apply shoe-weight
% correction to the body-weight normalizer.
%
% Inputs:
%   strideEvents - struct of stride event times with fields tSHS, tFTO,
%                  tFHS, tSTO, tSHS2, tFTO2, tFHS2, tSTO2
%   GRFData      - labTimeSeries of ground reaction forces
%   slowleg      - slow-leg identifier, 'L' or 'R' (char)
%   fastleg      - fast-leg identifier, 'R' or 'L' (char)
%   BW           - participant body weight (kg)
%   trialData    - processedTrialData object supplying metaData and
%                  gaitEvents
%   markerData   - labTimeSeries of marker data (currently unused;
%                  retained for call-site compatibility)
%
% Outputs:
%   out - parameterSeries of stride-aligned AP GRF parameters per
%         stride, including braking/propulsion averages for the best
%         single force plate, summed across plates, and per-plate
%
% Toolbox Dependencies:
%   None
%
% See also COMPUTEFORCEPARAMETERS_OGFP, COMPUTELEGFORCEPARAMETERS,
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

if strcmpi(trialData.metaData.type,'NIM')
    Normalizer=9.81*(BW+3.4); %3.4 kg is the weight of the two Nimbus shoes, if we ever change the shoes this needs to be modified
%% Initialize Trial Metadata and Constants
trial = trialData.metaData.description;

gravityAcc      = 9.81;  % gravitational acceleration (m/s^2)
shoeWeightKg    = 3.4;   % Nimbus shoe pair mass (two shoes; update if shoes change)
inTMAngle       = 8.5;   % incline angle (deg) assumed for 'IN' trial type
bwThMin         = 0.8;   % min vertical GRF threshold as fraction of BW
earlyFrac       = 0.2;   % early-stance phase fraction
endFrac         = 0.2;   % end-of-stance phase fraction
strideDiv       = 8;     % divisor for stride sub-window indexing
inclineAPFactor = 0.5;   % AP gravity component for inclined treadmill trials
endCutFrames    = 150;   % frames trimmed from end of aligned data
% Frame budgets approximate full stride cycle at typical TM speeds
slowFramesSlow  = 800;   % frame budget for slow-speed trials (slow leg)
slowFramesFast  = 600;   % frame budget for fast-speed trials (slow leg)
fastFramesSlow  = 800;   % frame budget for slow-speed trials (fast leg)
fastFramesFast  = 600;   % frame budget for fast-speed trials (fast leg)
defaultFrames   = 700;   % frame budget for base/post/default trial types

else
    normalizer = gravityAcc * BW;
end

flipB = 1;
trialNum = str2double(trialData.metaData.rawDataFilename(end-1:end));

if iscell(trial)
    trial = trial{1};
end

ang = determineTMAngle(trialData.metaData);
if strcmpi(trialData.metaData.type, 'IN')
    ang = 8.5;
end
flipIT = 2.*(ang >= 0) - 1;  % -1 for decline trials, 1 otherwise

%% Low-Pass Filter and Detect Force Plates
filtered = GRFData.substituteNaNs.lowPassFilter(20);
gaitEvents = trialData.gaitEvents;
filteredF = filtered;
filteredS = filtered;

% adding the force-plates data overground

forces = GRFData.labels(~contains(GRFData.labels , 'M'));
forces = forces(~contains(forces , 'H')); %Remove the handrail from the data

if strcmpi(trialData.metaData.type,'OG') || strcmpi(trialData.metaData.type,'NIM')
    Allz = forces(contains(forces , 'z'));
    Ally = forces(contains(forces , 'y'));
    %     Allz = {'FP4Fz','FP5Fz','FP6Fz','FP7Fz','LFz','RFz'};
    %     Ally = {'FP4Fy','FP5Fy','FP6Fy','FP7Fy','LFy','RFy'};
else
    Allz = {'LFz', 'RFz'};
    Ally = {'LFy', 'RFy'};
end

h_fast = [];
h_slow = [];

%
%     if strcmp(fastleg,'R')
%         slowleg = 'L';
%         f = 'R';
%         s = 'L';
%     else
%         slowleg = 'R';
%         f = 'L';
%         s = 'R';
%     end
%
% eventTypes={[s,'HS'],[f,'TO'],[f,'HS'],[s,'TO']};
%
%
% arrayedEvents=labTimeSeries.getArrayedEvents(gaitEvents,[slowleg 'HS']);
% alignmentVector=[2,4,2,4];
% labTimeSeries.discretize(gaitEvents,eventTypes,alignmentVector,[]);

%% Remove Anterior-Posterior Force Offsets
% NOTE: computes median AP force during single-stance as a per-stride
% baseline, then subtracts the grand median; added after LD30 decline data
% revealed an improperly zeroed force plate (CJS 8/5/2016). Assumes
% vertical forces were correctly zeroed during c3d2mat import.

%figure; plot(filtered.getDataAsTS([s 'Fy']).Data, 'b'); hold on; plot(filtered.getDataAsTS([f 'Fy']).Data, 'r');
fFy = filtered.getDataAsTS([fastleg 'Fy']);
sFy = filtered.getDataAsTS([slowleg 'Fy']);

fastLegOffsetData=nan(length(strideEvents.tSHS)-1, 1);
slowLegOffsetData=nan(length(strideEvents.tSHS)-1, 1);
if filtered.isaLabel('HFx')
    handrailData=filtered.getDataAsTS({'HFy', 'HFz'});
elseif filtered.isaLabel('XFx')
    handrailData=filtered.getDataAsTS({'XFy', 'XFz'});
    warning('Handrail data was not found labeled as ''HFx'', using ''XFx'' instead (not sure if that IS the handrail!). This is probably an issue with force channel numbering mismatch while loading (c3d2mat).')
else
    handrailData=[];
    warning('Found no handrail force data.')
end

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
    SHS=strideEvents.tSHS(st);
    FTO=strideEvents.tFTO(st);
    FHS=strideEvents.tFHS(st);
    STO=strideEvents.tSTO(st);
    FTO2=strideEvents.tFTO2(st);
    SHS2=strideEvents.tSHS2(st);

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
fastLegOffset=round(median(fastLegOffsetData, 'omitnan'), 3);
slowLegOffset=round(median(slowLegOffsetData, 'omitnan'), 3);
disp(['Fast Leg Offset: ' num2str(fastLegOffset) ', Slow Leg Offset: ' num2str(slowLegOffset)]);

filtered.Data(:, find(strcmp(filtered.getLabels(), [fastleg 'Fy']))) = filtered.getDataAsVector([fastleg 'Fy']) - fastLegOffset;
filtered.Data(:, find(strcmp(filtered.getLabels(), [slowleg 'Fy']))) = filtered.getDataAsVector([slowleg 'Fy']) - slowLegOffset;


for fp = 1:length(Ally)

    fastLegOffsetogfp.(Ally{fp}) = round(median(fastLegOffsetDataogfp.(Ally{fp}), 'omitnan'), 3);
    filteredF.Data(:, find(strcmp(filteredF.getLabels(),Ally{fp}))) = filteredF.getDataAsVector(Ally{fp}) - fastLegOffsetogfp.(Ally{fp});

    slowLegOffsetogfp.(Ally{fp}) = round(median(slowLegOffsetDataogfp.(Ally{fp}), 'omitnan'), 3);
    filteredS.Data(:, find(strcmp(filteredS.getLabels(),Ally{fp}))) = filteredS.getDataAsVector(Ally{fp}) - slowLegOffsetogfp.(Ally{fp});

end


LevelofInterest = 0.5.*flipIT.*cosd(90-abs(ang)); %The actual angle of the incline
%figure; plot(filtered.getDataAsTS([slowleg 'Fy']).Data, 'b'); hold on; plot(filtered.getDataAsTS([fastleg 'Fy']).Data, 'r');line([0 5*10^5], [0, 0])

%% Align Stance-Phase Data
%levelOfInterest = flipIT.*cosd(90-abs(ang));

lenny=length(strideEvents.tSHS)-1;
impactS_align=NaN(1, lenny); impactF_align=NaN(1, lenny);
SB_align=NaN(1, lenny); SP_align=NaN(1, lenny); SZ_align=NaN(1, lenny); SX_align=NaN(1, lenny);
FB_align=NaN(1, lenny); FP_align=NaN(1, lenny); FZ_align=NaN(1, lenny); FX_align=NaN(1, lenny);
HandrailHolding=NaN(1, lenny);
SBmax_align=NaN(1, lenny); SPmax_align=NaN(1, lenny); SZmax_align=NaN(1, lenny); SXmax_align=NaN(1, lenny);
impactSmax_align=NaN(1, lenny); impactFmax_align=NaN(1, lenny);
FBmax_align=NaN(1, lenny); FPmax_align=NaN(1, lenny); FZmax_align=NaN(1, lenny); FXmax_align=NaN(1, lenny);

for fp = 1:length(Ally)
    impactS_OGFP.(Ally{fp}) = NaN(1, lenny); impactF_OGFP.(Ally{fp}) = NaN(1, lenny);
    SB_OGFP.(Ally{fp}) = NaN(1, lenny); SP_OGFP.(Ally{fp}) = NaN(1, lenny); SZ_OGFP.(Ally{fp}) = NaN(1, lenny); SX_OGFP.(Ally{fp}) = NaN(1, lenny);
    FB_OGFP.(Ally{fp}) = NaN(1, lenny); FP_OGFP.(Ally{fp}) = NaN(1, lenny); FZ_OGFP.(Ally{fp}) = NaN(1, lenny); FX_OGFP.(Ally{fp}) = NaN(1, lenny);
    SBmax_OGFP.(Ally{fp}) = NaN(1, lenny); SPmax_OGFP.(Ally{fp}) = NaN(1, lenny); SZmax_OGFP.(Ally{fp}) = NaN(1, lenny); SXmax_OGFP.(Ally{fp}) = NaN(1, lenny);
    impactSmax_OGFP.(Ally{fp}) = NaN(1, lenny); impactFmax_OGFP.(Ally{fp}) = NaN(1, lenny);
    FBmax_OGFP.(Ally{fp}) = NaN(1, lenny); FPmax_OGFP.(Ally{fp}) = NaN(1, lenny); FZmax_OGFP.(Ally{fp}) = NaN(1, lenny);FXmax_OGFP.(Ally{fp}) = NaN(1, lenny);
end

endcutting = 150;
    slow_frames = 600+endcutting;
    fast_frames = 600+endcutting;
elseif strcmp(trialData.metaData.name,'adaptation')
    slow_frames = 800+endcutting;
    fast_frames = 600+endcutting;
elseif strcmp(trialData.metaData.name,'TM base') || strcmp(trialData.metaData.name,'TM post')
    slow_frames = 700+endcutting;
    fast_frames = 700+endcutting;
if strcmp(trialData.metaData.name, 'TM slow')
    slowFrames = slowFramesSlow + endCutFrames;
    fastFrames = fastFramesSlow + endCutFrames;
elseif strcmp(trialData.metaData.name, 'TM fast')
else
    slow_frames = 700+endcutting;
    fast_frames = 700+endcutting;
end


if strcmp(trialData.metaData.type,'OG') || strcmp(trialData.metaData.type,'NIM')
    filteredSlow_align = FilteredS.align(gaitEvents, {[slowleg 'HS'], [fastleg 'TO'], [fastleg 'HS']}, [floor(0.2*slow_frames), floor(0.4*slow_frames), floor(0.4*slow_frames)]);
    filteredSlow_align.Data = filteredSlow_align.Data(1:slow_frames-endcutting, :, :);
    filteredFast_align = FilteredF.align(gaitEvents, {[fastleg 'HS'], [slowleg 'TO'], [slowleg 'HS']}, [floor(0.2*fast_frames), floor(0.5*fast_frames), floor(0.3*fast_frames)]);
    filteredFast_align.Data = filteredFast_align.Data(1:fast_frames-endcutting, :, :);
else
    filteredSlow_align = filteredS.align(gaitEvents, {[slowleg 'HS'], [fastleg 'TO'], [fastleg 'HS']}, [floor(0.2*slowFrames), floor(0.4*slowFrames), floor(0.4*slowFrames)]);
    filteredSlow_align.Data = [filteredSlow_align.Data(slowFrames-19:end, :, :); filteredSlow_align.Data(1:slowFrames-40-endCutFrames, :, :)];

    filteredFast_align = filteredF.align(gaitEvents, {[fastleg 'HS'], [slowleg 'TO'], [slowleg 'HS']}, [floor(0.2*fastFrames), floor(0.4*fastFrames), floor(0.4*fastFrames)]);
    filteredFast_align.Data = [filteredFast_align.Data(fastFrames-19:end, :, :); filteredFast_align.Data(1:fastFrames-40-endCutFrames, :, :)];
end

%% Compute Stride-by-Stride Parameters
slowCount = 0; fastCount = 0;
slowCountForce = 0; slowCountNoForce = 0;
fastCountForce = 0; fastCountNoForce = 0;

for st = 1:min([length(strideEvents.tSHS)-1, length(filteredSlow_align.Data(1, 1, :)), length(filteredFast_align.Data(1, 1, :))])
    % get the filtered data for the slow and fast stance phases
    filteredSlowStance = FilteredS.split(SHS, STO);
    filteredFastStance = FilteredF.split(FHS, FTO2);

    % get the filtered data for the slow and fast single stance phases
    filteredSlowSingleStance = FilteredS.split(FTO, FHS);
    filteredFastSingleStance = FilteredF.split(STO, SHS2);

    % Getting the events
    SHS=strideEvents.tSHS(st); FTO=strideEvents.tFTO(st); FHS=strideEvents.tFHS(st); STO=strideEvents.tSTO(st); SHS2=strideEvents.tSHS2(st); FTO2=strideEvents.tFTO2(st);

    if isnan(SHS) || isnan(STO) % make sure the slow events are not empty
        striderSyAlign = []; striderSzAlign = [];
        for fp = 1:length(Ally)
            striderSyOgfp.(Ally{fp}) = [];
            striderSyOgfpAlign.(Ally{fp}) = [];
            striderSyOgfpSS.(Ally{fp}) = [];

            striderSyOgfp.(Allz{fp}) = [];
            striderSyOgfpAlign.(Allz{fp}) = [];
            striderSyOgfpSS.(Allz{fp}) = [];

            striderSzOgfp.(Ally{fp}) = [];
            striderSzOgfpAlign.(Ally{fp}) = [];
            striderSzOgfpSS.(Ally{fp}) = [];

            striderSzOgfp.(Allz{fp}) = [];
            striderSzOgfpAlign.(Allz{fp}) = [];
            striderSzOgfpSS.(Allz{fp}) = [];
        end
        striderSyOgfpSum = []; striderSzOgfpSum = [];
        existSlowF(st) = 0;

    else %FILTERING
        striderSyOgfpSum = 0; striderSzOgfpSum = 0;

        for fp = 1:length(Ally)
            % getting each force-plate value during stance
            striderSyOgfp.(Ally{fp}) = flipIT.*filteredSlowStance.getDataAsVector(Ally{fp})/normalizer;
            striderSzOgfp.(Allz{fp}) = flipIT.*filteredSlowStance.getDataAsVector(Allz{fp})/normalizer;

            striderSyOgfpAlign.(Ally{fp}) = flipIT.*filteredSlow_align.getPartialDataAsATS(Ally{fp}).Data(:, 1, st)/normalizer;
            striderSzOgfpAlign.(Allz{fp}) = flipIT.*filteredSlow_align.getPartialDataAsATS(Allz{fp}).Data(:, 1, st)/normalizer;

            % getting each force-plate value during single stance
            striderSyOgfpSS.(Ally{fp}) = flipIT.*filteredSlowSingleStance.getDataAsVector(Ally{fp})/normalizer;
            striderSzOgfpSS.(Allz{fp}) = flipIT.*filteredSlowSingleStance.getDataAsVector(Allz{fp})/normalizer;
            % adding all forces together
            striderSyOgfpSum = striderSyOgfpSum + striderSyOgfpSS.(Ally{fp});
            striderSzOgfpSum = striderSzOgfpSum + striderSzOgfpSS.(Allz{fp});

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

        slowDivider = floor(length(striderSzOgfpAlign.('LFz'))/strideDiv);
        goodCounter = 0; ogfpySlow = [];
        for fp = 1:length(Allz)
            if isempty(striderSzOgfpAlign.(Allz{fp})) == 0

                mini1st.(Allz{fp}) = abs(min(striderSzOgfpAlign.(Allz{fp})(slowDivider:slowDivider*3)));
                mini2nd.(Allz{fp}) = abs(min(striderSzOgfpAlign.(Allz{fp})(slowDivider*5:slowDivider*7)));

                if mini1st.(Allz{fp}) >= bwThMin && mini2nd.(Allz{fp}) >= bwThMin && abs(striderSzOgfpAlign.(Allz{fp})(1)) <= earlyFrac && abs(striderSzOgfpAlign.(Allz{fp})(end)) <= endFrac
                    ogfpySlow = Ally{fp}; ogfpzSlow = Allz{fp}; goodCounter = goodCounter + 1;
                end
            end
        end



        if goodCounter == 1 && isempty(ogfpySlow) == 0 % check if a stride has a good for at least on one of the force-plates

            %striderSyAlign = flipIT.*filteredSlowStance.getDataAsVector(ogfpySlow)/normalizer;
            %striderSzAlign = flipIT.*filteredSlowStance.getDataAsVector(ogfpzSlow)/normalizer;

            striderSy_align = flipIT.*filteredSlow_align.getPartialDataAsATS(OGFPy_slow).Data(:, 1, st)/Normalizer;
            striderSz_align = flipIT.*filteredSlow_align.getPartialDataAsATS(OGFPz_slow).Data(:, 1, st)/Normalizer;

            slow_divider = floor(length(striderSy_align)/divideri);
            if isempty(striderSy_align)
                striderSz_align = [];
            elseif max(striderSy_align(slow_divider:slow_divider*3)) > max(striderSy_align(slow_divider*5:slow_divider*7))
                striderSy_align = -striderSy_align;
                striderSy_OGFP_SS.(OGFPy_slow) = -striderSy_OGFP_SS.(OGFPy_slow);

                if strcmpi(trialData.metaData.type,'IN') && strcmpi(trialData.metaData.name,'adaptation') && mean(striderSy_align, 'omitnan') < 0
                    striderSy_align = -striderSy_align;
                    striderSy_OGFP_SS.(OGFPy_slow) = -striderSy_OGFP_SS.(OGFPy_slow);
                elseif max(striderSy_align(1:slow_divider*4)) > max(striderSy_align(slow_divider*4:end))
                    striderSy_align = -striderSy_align;
                    striderSy_OGFP_SS.(OGFPy_slow) = -striderSy_OGFP_SS.(OGFPy_slow);
                end
            end
        else
            striderSyAlign=[]; striderSzAlign = [];
        end
    end

    if isnan(FHS) || isnan(FTO2) % make sure the slow events are not empty
        striderFyAlign = []; striderFzAlign = [];
        for fp = 1:length(Ally)
            striderFyOgfp.(Ally{fp}) = [];
            striderFyOgfpAlign.(Ally{fp}) = [];
            striderFyOgfpSS.(Ally{fp}) = [];

            striderFyOgfp.(Allz{fp}) = [];
            striderFyOgfpAlign.(Allz{fp}) = [];
            striderFyOgfpSS.(Allz{fp}) = [];

            striderFzOgfp.(Ally{fp}) = [];
            striderFzOgfpAlign.(Ally{fp}) = [];
            striderFzOgfpSS.(Ally{fp}) = [];

            striderFzOgfp.(Allz{fp}) = [];
            striderFzOgfpAlign.(Allz{fp}) = [];
            striderFzOgfpSS.(Allz{fp}) = [];
        end
        striderFyOgfpSum = []; striderFzOgfpSum = [];
        existFastF(st) = 0;
    else %FILTERING
        striderFyOgfpSum = 0; striderFzOgfpSum = 0;

        for fp = 1:length(Ally)

            striderFyOgfp.(Ally{fp}) = flipIT.*filteredFastStance.getDataAsVector(Ally{fp})/normalizer;
            striderFzOgfp.(Allz{fp}) = flipIT.*filteredFastStance.getDataAsVector(Allz{fp})/normalizer;

            striderFyOgfpAlign.(Ally{fp}) = flipIT.*filteredFast_align.getPartialDataAsATS(Ally{fp}).Data(:, 1, st)/normalizer;
            striderFzOgfpAlign.(Allz{fp}) = flipIT.*filteredFast_align.getPartialDataAsATS(Allz{fp}).Data(:, 1, st)/normalizer;

            striderFyOgfpSS.(Ally{fp}) = flipIT.*filteredFastSingleStance.getDataAsVector(Ally{fp})/normalizer;
            striderFzOgfpSS.(Allz{fp}) = flipIT.*filteredFastSingleStance.getDataAsVector(Allz{fp})/normalizer;

            striderFyOgfpSum = striderFyOgfpSum + striderFyOgfpSS.(Ally{fp});
            striderFzOgfpSum = striderFzOgfpSum + striderFzOgfpSS.(Allz{fp});

        end

        if abs(min(striderFzOgfpSum)) > 0.1 % checking if the force is avaliable
            fastCountForce = fastCountForce + 1;
            existFastF(st) = 1;

            sumL = floor(length(striderFyOgfpSum)/2);
            if max(striderFyOgfpSum(1:sumL)) > max(striderFyOgfpSum(sumL:end))
                striderFyOgfpSum = -striderFyOgfpSum;
            end
        else
            fastCountNoForce = fastCountNoForce + 1;
            existFastF(st) = 0;
            striderFyOgfpSum = []; striderFzOgfpSum = [];
        end

        midwayFast = floor(length(striderFzOgfpAlign.('LFz'))/strideDiv);
        goodCounter = 0; ogfpyFast = [];
        for fp = 1:length(Allz)
            if isempty(striderFzOgfpAlign.(Allz{fp})) == 0

                mini1st.(Allz{fp}) = abs(min(striderFzOgfpAlign.(Allz{fp})(midwayFast:midwayFast*3)));
                mini2nd.(Allz{fp}) = abs(min(striderFzOgfpAlign.(Allz{fp})(midwayFast*5:midwayFast*7)));

                if mini1st.(Allz{fp}) >= bwThMin && mini2nd.(Allz{fp}) >= bwThMin && abs(striderFzOgfpAlign.(Allz{fp})(1)) <= earlyFrac && abs(striderFzOgfpAlign.(Allz{fp})(end)) <= endFrac
                    ogfpyFast = Ally{fp}; ogfpzFast = Allz{fp}; goodCounter = goodCounter + 1;
                end
            end
        end

        if goodCounter == 1 && isempty(ogfpyFast) == 0

            %             striderFyAlign = flipIT.*filteredFastStance.getDataAsVector(ogfpyFast)/normalizer;
            %             striderFzAlign = flipIT.*filteredFastStance.getDataAsVector(ogfpzFast)/normalizer;

            striderFy_align = flipIT.*filteredFast_align.getPartialDataAsATS(OGFPy_fast).Data(:, 1, st)/Normalizer;
            striderFz_align = flipIT.*filteredFast_align.getPartialDataAsATS(OGFPz_fast).Data(:, 1, st)/Normalizer;

            if isempty(striderFy_align)
                striderFz_align = [];
            elseif max(striderFy_align(midway_fast:midway_fast*3)) > max(striderFy_align(midway_fast*5:midway_fast*7))
                striderFy_align = -striderFy_align;
                striderFy_OGFP_SS.(OGFPy_fast) = -striderFy_OGFP_SS.(OGFPy_fast);

                if strcmpi(trialData.metaData.type,'IN') && strcmpi(trialData.metaData.name,'adaptation') && mean(striderFy_align, 'omitnan') < 0
                    striderFy_align = -striderFy_align;
                    striderFy_OGFP_SS.(OGFPy_fast) = -striderFy_OGFP_SS.(OGFPy_fast);
                elseif max(striderFy_align(1:midway_fast*4)) > max(striderFy_align(midway_fast*4:end))
                    striderFy_align = -striderFy_align;
                    striderFy_OGFP_SS.(OGFPy_fast) = -striderFy_OGFP_SS.(OGFPy_fast);
                end
            end
        else
            striderFyAlign = []; striderFzAlign = [];
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Check if the participant is holding the handrail %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ~isempty(handrailData)
        HandrailHolding(st)= 0.05 < sqrt(mean(sum(handrailData.split(SHS, SHS2).Data.^2, 2), 'omitnan'))/normalizer;
    else
        HandrailHolding(st)=NaN;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% computing the parameters for the force plate that a good stance occures %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isempty(striderSyAlign) || all(striderSyAlign==striderSyAlign(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
        %This does nothing, as vars are initialized as nan:
    else
        if std(striderSyAlign, 'omitnan')<0.01 && mean(striderSyAlign, 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

        else
            ns_align = find((striderSyAlign-levelOfInterest)<0.1);%1:65
            ps_align = find((striderSyAlign-levelOfInterest)>0);

            %             if strcmp(trialData.metaData.name,'adaptation')
            %                 ns_align(find(ns_align>=0.2*length(striderSyAlign)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            %                 ps_align(find(ps_align<=0.5*length(striderSyAlign)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %
            %                 ns_align(find(ns_align<=0.05*length(striderSyAlign)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            %                 ps_align(find(ps_align>=0.95*length(striderSyAlign)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %
            %             else


            ns_align(find(ns_align>=0.5*length(striderSyAlign)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            ps_align(find(ps_align<=0.5*length(striderSyAlign)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.

            ns_align(find(ns_align<=0.12*length(striderSyAlign)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            ps_align(find(ps_align>=0.95*length(striderSyAlign)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %             end

            ImpactMagS_align = find((striderSyAlign-levelOfInterest)==max(striderSyAlign(1:75)-levelOfInterest, [], 'omitnan'));%no longer percent of stride
            if isempty(ImpactMagS_align)%~=1
                postImpactS_align = ns_align(find(ns_align>ImpactMagS_align(end), 1, 'first'));
                if isempty(postImpactS_align)%~=1
                    ps_align(find(ps_align<postImpactS_align))=[];
                    ns_align(find(ns_align<postImpactS_align))=[];
                end
            end

            if isempty(ns_align)

            else
                SB_align(st) = flipB.*(mean(striderSyAlign(ns_align)-levelOfInterest, 'omitnan'));
                SBmax_align(st) = flipB.*(min(striderSyAlign(ns_align)-levelOfInterest, [], 'omitnan'));
            end

            if isempty(ps_align)

            else
                SP_align(st)=mean(striderSyAlign(ps_align)-levelOfInterest, 'omitnan');
                SPmax_align(st)=max(striderSyAlign(ps_align)-levelOfInterest, [], 'omitnan');
            end

            if exist('postImpactS_align')==0 || isempty(postImpactS_align)==1
                %                     impactS(st)=NaN;
                %                     impactSmax(st)=NaN;
            else
                impactS_align(st)=mean(striderSyAlign(find((striderSyAlign(SHS-SHS+1: postImpactS_align)-levelOfInterest)>0)), 'omitnan')-levelOfInterest;
                if isempty(striderSyAlign(find((striderSyAlign(SHS-SHS+1: postImpactS_align)-levelOfInterest)>0)))
                    %impactSmax(st)=NaN;
                else
                    impactSmax_align(st)=max(striderSyAlign(find((striderSyAlign(SHS-SHS+1: postImpactS_align)-levelOfInterest)>0)), [], 'omitnan')-levelOfInterest;
                end
            end

            slowCount = slowCount+1;
            ogfpySlowi(slowCount) = {ogfpySlow};
            ogfpzSlowi(slowCount) = {ogfpzSlow};
            str_striderSy.([ogfpySlow num2str(slowCount)]) = striderSyAlign;
            str_striderSz.([ogfpzSlow num2str(slowCount)]) = striderSzAlign;





            %             h_slow = figure (trialData.metaData.condition*10-9)
            %             hold on
            %             plot(striderSyAlign-levelOfInterest,'b')
            %             if isempty(SBmax_align(st)) == 0 && isempty(SPmax_align(st)) == 0
            %                 if  isempty(find(striderSyAlign-levelOfInterest == SBmax_align(st))) || isempty(find(striderSyAlign-levelOfInterest == SPmax_align(st)))
            %                 else
            %                     SBmax_ind(slowCount) = find(striderSyAlign-levelOfInterest == SBmax_align(st));
            %                     plot(SBmax_ind(slowCount),SBmax_align(st),'k*')
            %                     SPmax_ind(slowCount) = find(striderSyAlign-levelOfInterest == SPmax_align(st));
            %                     plot(SPmax_ind(slowCount),SPmax_align(st),'k*')
            %                 end
            %             end
            %             title(['Slow Ground reaction Forces with Peaks' '     ' trialData.metaData.name])

            %             if isempty(striderSyOgfpSS.(ogfpySlow)) == 0
            %             if  isempty(find(striderSyAlign == striderSyOgfpSS.(ogfpySlow)(1)))
            %             else
            %                 slow_SS_ind(slowCount) = find(striderSyAlign == striderSyOgfpSS.(ogfpySlow)(1));
            %                 plot(slow_SS_ind(slowCount):slow_SS_ind(slowCount)+length(striderSyOgfpSS.(ogfpySlow))-1,striderSyOgfpSS.(ogfpySlow),'r*')
            %                 hold off
            %                 title(['Slow Single Stance Overlapped' '     ' trialData.metaData.name])
            %                 saveas(gcf,['SlowOverlapped_' trialData.metaData.name],'png')
            %             end
            %             end
            %             figure (trialData.metaData.condition*10-7)
            %             plot(str_striderSz.([ogfpzSlowi{slowCount} num2str(slowCount)]),'Color',[1,0,0])
            %             for yo=1:8
            %                 line([yo*slowDivider yo*slowDivider], get(gca, 'ylim'),'Color',[0 0 0])
            %             end

        end
        %         SZ_align(st)=-1*mean(filteredSlowStance.getDataAsVector([ogfpySlow(1:end-1) 'z']), 'omitnan')/normalizer;
        %         SX_align(st)=mean(filteredSlowStance.getDataAsVector([ogfpySlow(1:end-1) 'x']), 'omitnan')/normalizer;
        %         SZmax_align(st)=-1*min(filteredSlowStance.getDataAsVector([ogfpySlow(1:end-1) 'z']), [], 'omitnan')/normalizer;
        %         SXmax_align(st)=min(filteredSlowStance.getDataAsVector([ogfpySlow(1:end-1) 'x']), [], 'omitnan')/normalizer;

        SZ_align(st)=-1*mean(filteredSlow_align.getPartialDataAsATS([OGFPy_slow(1:end-1) 'z']).Data(:, 1, st), 'omitnan')/Normalizer;
        SX_align(st)=mean(filteredSlow_align.getPartialDataAsATS([OGFPy_slow(1:end-1) 'x']).Data(:, 1, st), 'omitnan')/Normalizer;
        SZmax_align(st)=-1*min(filteredSlow_align.getPartialDataAsATS([OGFPy_slow(1:end-1) 'z']).Data(:, 1, st), [], 'omitnan')/Normalizer;
        SXmax_align(st)=min(filteredSlow_align.getPartialDataAsATS([OGFPy_slow(1:end-1) 'x']).Data(:, 1, st), [], 'omitnan')/Normalizer;



    end

    %%Now for the fast leg...
    if isempty(striderFyAlign) || all(striderFyAlign==striderFyAlign(1)) || isempty(FTO) || isempty(STO)

    else
        if std(striderFyAlign, 'omitnan')<0.01 && mean(striderFyAlign, 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

        else
            nf_align=find((striderFyAlign-levelOfInterest)<0.1);%1:65
            pf_align=find((striderFyAlign-levelOfInterest)>0);

            %             if strcmp(trialData.metaData.name,'adaptation')
            %                 nf_align(find(nf_align>=0.5*length(striderFyAlign)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            %                 pf_align(find(pf_align<=0.5*length(striderFyAlign)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %
            %                 nf_align(find(nf_align<=0.12*length(striderFyAlign)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            %                 pf_align(find(pf_align>=0.95*length(striderFyAlign)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %
            %             else


            nf_align(find(nf_align>=0.5*length(striderFyAlign)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            pf_align(find(pf_align<=0.5*length(striderFyAlign)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.

            nf_align(find(nf_align<=0.12*length(striderFyAlign)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            pf_align(find(pf_align>=0.95*length(striderFyAlign)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %             end

            ImpactMagF_align=find((striderFyAlign-levelOfInterest)==max(striderFyAlign(1:75)-levelOfInterest, [], 'omitnan'));%1:15
            if isempty(ImpactMagF_align)%~=1
                postImpactF_align=nf_align(find(nf_align>ImpactMagF_align(end), 1, 'first'));
                if isempty(postImpactF_align)%~=1
                    pf_align(find(pf_align<postImpactF_align))=[];
                    nf_align(find(nf_align<postImpactF_align))=[];
                end
            end

            if isempty(pf_align)

            else
                FP_align(st)=mean(striderFyAlign(pf_align)-levelOfInterest, 'omitnan');
                FPmax_align(st)=max(striderFyAlign(pf_align)-levelOfInterest, [], 'omitnan');
            end
            if isempty(nf_align)

            else
                FB_align(st)=flipB.*(mean(striderFyAlign(nf_align)-levelOfInterest, 'omitnan'));
                FBmax_align(st)=flipB.*(min(striderFyAlign(nf_align)-levelOfInterest, [], 'omitnan'));
            end

            if exist('postImpactF_align')==0 || isempty(postImpactF_align)==1

            else
                impactF_align(st)=mean(striderFyAlign(find((striderFyAlign(FHS-FHS+1: postImpactF_align)-levelOfInterest)>0)), 'omitnan')-levelOfInterest;
                if isempty(striderFyAlign(find((striderFyAlign(FHS-FHS+1: postImpactF_align)-levelOfInterest)>0)))

                else
                    impactFmax_align(st)=max(striderFyAlign(find((striderFyAlign(FHS-FHS+1: postImpactF_align)-levelOfInterest)>0)), [], 'omitnan')-levelOfInterest;
                end
            end

            i_fast = i_fast+1;
            OGFPy_fasti(i_fast) = {OGFPy_fast};
            OGFPz_fasti(i_fast) = {OGFPz_fast};
            str_striderFy.([OGFPy_fast num2str(i_fast)]) = striderFy_align;
            str_striderFz.([OGFPz_fast num2str(i_fast)]) = striderFz_align;

            %             h_fast = figure (trialData.metaData.condition*10-7)
            %             hold on
            %             plot(striderFyAlign-levelOfInterest,'r')
            %             if isempty(FBmax_align(st)) == 0 && isempty(FPmax_align(st)) == 0
            %                 if  isempty(find(striderFyAlign-levelOfInterest == FBmax_align(st))) || isempty(find(striderFyAlign-levelOfInterest == FPmax_align(st)))
            %                 else
            %                     FBmax_ind(fastCount) = find(striderFyAlign-levelOfInterest == FBmax_align(st));
            %                     plot(FBmax_ind(fastCount),FBmax_align(st),'k*')
            %                     FPmax_ind(fastCount) = find(striderFyAlign-levelOfInterest == FPmax_align(st));
            %                     plot(FPmax_ind(fastCount),FPmax_align(st),'k*')
            %                 end
            %             end
            %             title(['Fast Ground reaction Forces with Peaks' '     ' trialData.metaData.name])
            %             hold on
            %             plot(striderFyAlign,'b')
            %             if  isempty(find(striderFyAlign == striderFyOgfpSS.(ogfpyFast)(1)))
            %             else
            %                 fast_SS_ind(fastCount) = find(striderFyAlign == striderFyOgfpSS.(ogfpyFast)(1));
            %                 plot(fast_SS_ind(fastCount):fast_SS_ind(fastCount)+length(striderFyOgfpSS.(ogfpyFast))-1,striderFyOgfpSS.(ogfpyFast),'r*')
            %                 hold off
            %                 title(['Fast Single Stance Overlapped' '     ' trialData.metaData.name])
            %                 saveas(gcf,['FastOverlapped_' trialData.metaData.name],'png')
            %             end
        end
        %         FZ_align(st)=-1*mean(filteredFastStance.getDataAsVector([ogfpyFast(1:end-1) 'z']), 'omitnan')/normalizer; %%[ogfpyFast(1:end-1) 'z']
        %         FX_align(st)=mean(filteredFastStance.getDataAsVector([ogfpyFast(1:end-1) 'x']), 'omitnan')/normalizer;
        %         FZmax_align(st)=-1*min(filteredFastStance.getDataAsVector([ogfpyFast(1:end-1) 'z']), [], 'omitnan')/normalizer;
        %         FXmax_align(st)=max(filteredFastStance.getDataAsVector([ogfpyFast(1:end-1) 'x']), [], 'omitnan')/normalizer;

        FZ_align(st)=-1*mean(filteredFast_align.getPartialDataAsATS([OGFPy_fast(1:end-1) 'z']).Data(:, 1, st), 'omitnan')/Normalizer;
        FX_align(st)=mean(filteredFast_align.getPartialDataAsATS([OGFPy_fast(1:end-1) 'x']).Data(:, 1, st), 'omitnan')/Normalizer;
        FZmax_align(st)=-1*min(filteredFast_align.getPartialDataAsATS([OGFPy_fast(1:end-1) 'z']).Data(:, 1, st), [], 'omitnan')/Normalizer;
        FXmax_align(st)=min(filteredFast_align.getPartialDataAsATS([OGFPy_fast(1:end-1) 'x']).Data(:, 1, st), [], 'omitnan')/Normalizer;

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% computing the parameters for adding all forces toghether %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isempty(striderSyOgfpSum) || all(striderSyOgfpSum==striderSyOgfpSum(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
        %This does nothing, as vars are initialized as nan:
        SBmaxOgfpSum(st) = NaN;
        SPmaxOgfpSum(st) = NaN;
    else
        if std(striderSyOgfpSum, 'omitnan')<0.01 && mean(striderSyOgfpSum, 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

        else
            nsOgfpSum = find((striderSyOgfpSum-levelOfInterest)<0);%1:65
            psOgfpSum = find((striderSyOgfpSum-levelOfInterest)>0);

            %             impactMagSOgfpSum = find((striderSyOgfpSum-levelOfInterest)==max(striderSyOgfpSum(1:75)-levelOfInterest, [], 'omitnan'));%no longer percent of stride
            %             if isempty(impactMagSOgfpSum)~=1
            %                 postImpactSOgfpSum = nsOgfpSum(find(nsOgfpSum>impactMagSOgfpSum(end), 1, 'first'));
            %                 if isempty(postImpactSOgfpSum)~=1
            %                     psOgfpSum(find(psOgfpSum<postImpactSOgfpSum))=[];
            %                     nsOgfpSum(find(nsOgfpSum<postImpactSOgfpSum))=[];
            %                 end
            %             end

            if isempty(nsOgfpSum)
                SBmaxOgfpSum(st) = NaN;
            else
                SBogfpSum(st) = flipB.*(mean(striderSyOgfpSum(nsOgfpSum)-levelOfInterest, 'omitnan'));
                SBmaxOgfpSum(st) = flipB.*(min(striderSyOgfpSum(nsOgfpSum)-levelOfInterest, [], 'omitnan'));
            end
            if isempty(psOgfpSum)
                SPmaxOgfpSum(st)= NaN;
            else
                SPogfpSum(st)=mean(striderSyOgfpSum(psOgfpSum)-levelOfInterest, 'omitnan');
                SPmaxOgfpSum(st)=max(striderSyOgfpSum(psOgfpSum)-levelOfInterest, [], 'omitnan');
            end

            if exist('postImpactSOgfpSum')==0 || isempty(postImpactSOgfpSum)==1 || isnan(SHS)
                %                     impactS(st)=NaN;
                %                     impactSmax(st)=NaN;
                impactSmaxOgfpSum(st)= NaN;
            else
                impactSOgfpSum(st)=mean(striderSyOgfpSum(find((striderSyOgfpSum(SHS-SHS+1: postImpactSOgfpSum)-levelOfInterest)>0)), 'omitnan')-levelOfInterest;
                if isempty(striderSyOgfpSum(find((striderSyOgfpSum(SHS-SHS+1: postImpactSOgfpSum)-levelOfInterest)>0)))
                    %impactSmax(st)=NaN;
                else
                    impactSmaxOgfpSum(st)=max(striderSyOgfpSum(find((striderSyOgfpSum(SHS-SHS+1: postImpactSOgfpSum)-levelOfInterest)>0)), [], 'omitnan')-levelOfInterest;
                end
            end

            %             figure(trialData.metaData.condition*10-5)
            %             hold on
            %             plot(striderSzOgfpSum)
            %             figure (trialData.metaData.condition*10-4)
            %             hold on
            %             plot(striderSyOgfpSum)

        end
    end

    %%Now for the fast leg...
    if isempty(striderFyOgfpSum) || all(striderFyOgfpSum==striderFyOgfpSum(1)) || isempty(FTO) || isempty(STO)
        FBmaxOgfpSum(st) = NaN;
        FPmaxOgfpSum(st) = NaN;
    else
        if std(striderFyOgfpSum, 'omitnan')<0.01 && mean(striderFyOgfpSum, 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

        else
            nfOgfpSum=find((striderFyOgfpSum-levelOfInterest)<0);%1:65
            pfOgfpSum=find((striderFyOgfpSum-levelOfInterest)>0);
            %             impactMagFOgfpSum=find((striderFyOgfpSum-levelOfInterest)==max(striderFyOgfpSum(1:75)-levelOfInterest, [], 'omitnan'));%1:15
            %             if isempty(impactMagFOgfpSum)~=1
            %                 postImpactFOgfpSum=nfOgfpSum(find(nfOgfpSum>impactMagFOgfpSum(end), 1, 'first'));
            %                 if isempty(postImpactFOgfpSum)~=1
            %                     pfOgfpSum(find(pfOgfpSum<postImpactFOgfpSum))=[];
            %                     nfOgfpSum(find(nfOgfpSum<postImpactFOgfpSum))=[];
            %                 end
            %             end

            if isempty(pfOgfpSum)
                FPmaxOgfpSum(st)= NaN;
            else
                FPogfpSum(st)=mean(striderFyOgfpSum(pfOgfpSum)-levelOfInterest, 'omitnan');
                FPmaxOgfpSum(st)=max(striderFyOgfpSum(pfOgfpSum)-levelOfInterest, [], 'omitnan');
            end
            if isempty(nfOgfpSum)
                FBmaxOgfpSum(st)= NaN;
            else
                FBogfpSum(st)=flipB.*(mean(striderFyOgfpSum(nfOgfpSum)-levelOfInterest, 'omitnan'));
                FBmaxOgfpSum(st)=flipB.*(min(striderFyOgfpSum(nfOgfpSum)-levelOfInterest, [], 'omitnan'));
            end

            if exist('postImpactFOgfpSum')==0 || isempty(postImpactFOgfpSum)==1 || isnan(FHS)==1
                impactFmaxOgfpSum(st) = NaN;
            else
                impactFOgfpSum(st)=mean(striderFyOgfpSum(find((striderFyOgfpSum(FHS-FHS+1: postImpactFOgfpSum)-levelOfInterest)>0)), 'omitnan')-levelOfInterest;
                if isempty(striderFyOgfpSum(find((striderFyOgfpSum(FHS-FHS+1: postImpactFOgfpSum)-levelOfInterest)>0)))

                else
                    impactFmaxOgfpSum(st)=max(striderFyOgfpSum(find((striderFyOgfpSum(FHS-FHS+1: postImpactFOgfpSum)-levelOfInterest)>0)), [], 'omitnan')-levelOfInterest;
                end
            end

        end

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% computing the parameters for each of the overground force-plates %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    for fp = 1:length(Ally)
        if isempty(striderSyOgfp.(Ally{fp})) || all(striderSyOgfp.(Ally{fp})==striderSyOgfp.(Ally{fp})(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
            %This does nothing, as vars are initialized as nan:
        else
            if std(striderSyOgfp.(Ally{fp}), 'omitnan')<0.01 && mean(striderSyOgfp.(Ally{fp}), 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

            else
                ns_OGFP.(Ally{fp}) = find((striderSy_OGFP.(Ally{fp})-LevelofInterest)<0);%1:65
                ps_OGFP.(Ally{fp}) = find((striderSy_OGFP.(Ally{fp})-LevelofInterest)>0);

                ImpactMagS_OGFP.(Ally{fp}) = find((striderSy_OGFP.(Ally{fp})-LevelofInterest)==max(striderSy_OGFP.(Ally{fp})(1:75)-LevelofInterest, [], 'omitnan'));%no longer percent of stride
                if isempty(ImpactMagS_OGFP.(Ally{fp})) ~= 1
                    postImpactS_OGFP.(Ally{fp})=ns_OGFP.(Ally{fp})(find(ns_OGFP.(Ally{fp}) > ImpactMagS_OGFP.(Ally{fp})(end), 1, 'first'));
                    if isempty(postImpactS_OGFP.(Ally{fp}))~=1
                        ps_OGFP.(Ally{fp})(find(ps_OGFP.(Ally{fp})<postImpactS_OGFP.(Ally{fp})))=[];
                        ns_OGFP.(Ally{fp})(find(ns_OGFP.(Ally{fp})<postImpactS_OGFP.(Ally{fp})))=[];
                    end
                end

                if isempty(ns_ogfp.(Ally{fp}))

                else
                    SB_ogfp.(Ally{fp})(st)=flipB.*(mean(striderSyOgfp.(Ally{fp})(ns_ogfp.(Ally{fp}))-levelOfInterest, 'omitnan'));
                    SBmax_ogfp.(Ally{fp})(st)=flipB.*(min(striderSyOgfp.(Ally{fp})(ns_ogfp.(Ally{fp}))-levelOfInterest, [], 'omitnan'));
                end
                if isempty(ps_ogfp.(Ally{fp}))

                else
                    SP_ogfp.(Ally{fp})(st)=mean(striderSyOgfp.(Ally{fp})(ps_ogfp.(Ally{fp}))-levelOfInterest, 'omitnan');
                    SPmax_ogfp.(Ally{fp})(st)=max(striderSyOgfp.(Ally{fp})(ps_ogfp.(Ally{fp}))-levelOfInterest, [], 'omitnan');
                end

                if exist(['postImpactS_ogfp.' Ally{fp}])==0 || isempty(postImpactS_ogfp.(Ally{fp}))==1
                    %                     impactS(st)=NaN;
                    %                     impactSmax(st)=NaN;
                else
                    impactS_ogfp.(Ally{fp})(st)=mean(striderSyOgfp.(Ally{fp})(find((striderSyOgfp.(Ally{fp})(SHS-SHS+1: postImpactS_ogfp.(Ally{fp}))-levelOfInterest)>0)), 'omitnan')-levelOfInterest;
                    if isempty(striderSyOgfp.(Ally{fp})(find((striderSyOgfp.(Ally{fp})(SHS-SHS+1: postImpactS_ogfp.(Ally{fp}))-levelOfInterest)>0)))
                        %impactSmax(st)=NaN;
                    else
                        impactSmax_ogfp.(Ally{fp})(st)=max(striderSyOgfp.(Ally{fp})(find((striderSyOgfp.(Ally{fp})(SHS-SHS+1: postImpactS_ogfp.(Ally{fp}))-levelOfInterest)>0)), [], 'omitnan')-levelOfInterest;
                    end
                end
            end
            SZ_OGFP.(Ally{fp})(st)=-1*mean(filteredSlowStance.getDataAsVector([Ally{fp}(1:end-1) 'z']), 'omitnan')/Normalizer;
            SX_OGFP.(Ally{fp})(st)=mean(filteredSlowStance.getDataAsVector([Ally{fp}(1:end-1) 'x']), 'omitnan')/Normalizer;
            SZmax_OGFP.(Ally{fp})(st)=-1*min(filteredSlowStance.getDataAsVector([Ally{fp}(1:end-1) 'z']), [], 'omitnan')/Normalizer;
            SXmax_OGFP.(Ally{fp})(st)=min(filteredSlowStance.getDataAsVector([Ally{fp}(1:end-1) 'x']), [], 'omitnan')/Normalizer;
        end

        %%Now for the fast leg...
        if isempty(striderFyOgfp.(Ally{fp})) || all(striderFyOgfp.(Ally{fp})==striderFyOgfp.(Ally{fp})(1)) || isempty(FTO) || isempty(STO)

        else
            if std(striderFyOgfp.(Ally{fp}), 'omitnan')<0.01 && mean(striderFyOgfp.(Ally{fp}), 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

            else
                nf_OGFP.(Ally{fp}) = find((striderFy_OGFP.(Ally{fp})-LevelofInterest)<0);%1:65
                pf_OGFP.(Ally{fp}) = find((striderFy_OGFP.(Ally{fp})-LevelofInterest)>0);
                ImpactMagF_OGFP.(Ally{fp}) = find((striderFy_OGFP.(Ally{fp})-LevelofInterest)==max(striderFy_OGFP.(Ally{fp})(1:75)-LevelofInterest, [], 'omitnan'));%1:15
                if isempty(ImpactMagF_OGFP.(Ally{fp}))~=1
                    postImpactF_OGFP.(Ally{fp}) = nf_OGFP.(Ally{fp})(find(nf_OGFP.(Ally{fp})>ImpactMagF_OGFP.(Ally{fp})(end), 1, 'first'));
                    if isempty(postImpactF_OGFP.(Ally{fp}))~=1
                        pf_OGFP.(Ally{fp})(find(pf_OGFP.(Ally{fp}) < postImpactF_OGFP.(Ally{fp})))=[];
                        nf_OGFP.(Ally{fp})(find(nf_OGFP.(Ally{fp}) < postImpactF_OGFP.(Ally{fp})))=[];
                    end
                end

                if isempty(pf_ogfp.(Ally{fp}))

                else
                    FP_ogfp.(Ally{fp})(st)=mean(striderFyOgfp.(Ally{fp})(pf_ogfp.(Ally{fp}))-levelOfInterest, 'omitnan');
                    FPmax_ogfp.(Ally{fp})(st)=max(striderFyOgfp.(Ally{fp})(pf_ogfp.(Ally{fp}))-levelOfInterest, [], 'omitnan');
                end
                if isempty(nf_ogfp.(Ally{fp}))

                else
                    FB_ogfp.(Ally{fp})(st)=flipB.*(mean(striderFyOgfp.(Ally{fp})(nf_ogfp.(Ally{fp}))-levelOfInterest, 'omitnan'));
                    FBmax_ogfp.(Ally{fp})(st)=flipB.*(min(striderFyOgfp.(Ally{fp})(nf_ogfp.(Ally{fp}))-levelOfInterest, [], 'omitnan'));
                end

                if exist(['postImpactF_ogfp.' Ally{fp}])==0 || isempty(postImpactF_ogfp.(Ally{fp}))==1

                else
                    impactF_ogfp.(Ally{fp})(st)=mean(striderFyOgfp.(Ally{fp})(find((striderFyOgfp.(Ally{fp})(FHS-FHS+1: postImpactF_ogfp.(Ally{fp}))-levelOfInterest)>0)), 'omitnan')-levelOfInterest;
                    if isempty(striderFyOgfp.(Ally{fp})(find((striderFyOgfp.(Ally{fp})(FHS-FHS+1: postImpactF_ogfp.(Ally{fp}))-levelOfInterest)>0)))

                    else
                        impactFmax_ogfp.(Ally{fp})(st)=max(striderFyOgfp.(Ally{fp})(find((striderFyOgfp.(Ally{fp})(FHS-FHS+1: postImpactF_ogfp.(Ally{fp}))-levelOfInterest)>0)), [], 'omitnan')-levelOfInterest;
                    end
                end
            end
            FZ_OGFP.(Ally{fp})(st)=-1*mean(filteredFastStance.getDataAsVector([Ally{fp}(1:end-1) 'z']), 'omitnan')/Normalizer;
            FX_OGFP.(Ally{fp})(st)=mean(filteredFastStance.getDataAsVector([Ally{fp}(1:end-1) 'x']), 'omitnan')/Normalizer;
            FZmax_OGFP.(Ally{fp})(st)=-1*min(filteredFastStance.getDataAsVector([Ally{fp}(1:end-1) 'z']), [], 'omitnan')/Normalizer;
            FXmax_OGFP.(Ally{fp})(st)=max(filteredFastStance.getDataAsVector([Ally{fp}(1:end-1) 'x']), [], 'omitnan')/Normalizer;
        end
    end
end
% title(['Fast Single Stance Overlapped' '     ' trialData.metaData.name])
% saveas(gcf,['FastOverlapped_' trialData.metaData.name],'png')
% slowCountForce
% slowCountNoForce
% slowCountForce/(slowCountForce+slowCountNoForce)
% fastCountForce
% fastCountNoForce
% fastCountForce/(fastCountForce+fastCountNoForce)

% figure (trialData.metaData.condition*10-3)
% hold on
% for i = 1:slowCount
%     %     if i<= slowCount/2
%     %         plot(str_striderSy.([ogfpySlowi{i} num2str(st)]),'Color',(255-i)/255*[i/255,i/255,1])
%     %     elseif i > slowCount/2 && slowCount < 2*255
%     %         plot(str_striderSy.([ogfpySlowi{i} num2str(st)]),'Color',(255-slowCount+i)/255*[1,i/255,i/255])
%     %     else
%     %         plot(str_striderSy.([ogfpySlowi{i} num2str(st)]),'Color',[0,0,0])
%     %     end
%     if trialNum == 1 || trialNum == 4 || trialNum == 8 || trialNum == 11 %i<= slowCount/2
%         plot(str_striderSy.([ogfpySlowi{i} num2str(st)]),'Color',[0,0,1])
%     elseif trialNum == 3 || trialNum == 6 || trialNum == 10 || trialNum == 13
%         plot(str_striderSy.([ogfpySlowi{i} num2str(st)]),'Color',[1,0,0])
%     else
%         plot(str_striderSy.([ogfpySlowi{i} num2str(st)]),'Color',[0,0,0])
%     end
%
% end
% hold off
% %legend(ogfpySlowi)
% title(['Slow AP' '     ' trialData.metaData.name])
% saveas(gcf,['Slow AP_' trialData.metaData.name],'png')
%
%
% figure (trialData.metaData.condition*10-2)
% hold on
% for i = 1:slowCount
%     if i<= slowCount/2
%         plot(str_striderSz.([ogfpzSlowi{i} num2str(st)]),'k')
%     else
%         plot(str_striderSz.([ogfpzSlowi{i} num2str(st)]),'k')
%     end
% end
% hold off
% %legend(ogfpySlowi)
% title(['Slow Z' '     ' trialData.metaData.name])
% saveas(gcf,['Slow Z_' trialData.metaData.name],'png')
%
% figure (trialData.metaData.condition*10-1)
% hold on
% for i = 1:fastCount
%     if trialNum == 1 || trialNum == 4 || trialNum == 8 || trialNum == 11 %i<= fastCount/2
%         plot(str_striderFy.([ogfpyFasti{i} num2str(st)]),'b')
%     elseif trialNum == 3 || trialNum == 6 || trialNum == 10 || trialNum == 13
%         plot(str_striderFy.([ogfpyFasti{i} num2str(st)]),'r')
%     else
%         plot(str_striderFy.([ogfpyFasti{i} num2str(st)]),'k')
%     end
% end
% hold off
% title(['Fast AP' '     ' trialData.metaData.name])
% saveas(gcf,['Fast AP_' trialData.metaData.name],'png')
%
%
% figure (trialData.metaData.condition*10)
% hold on
% for i = 1:fastCount
%     if i<= fastCount/2
%         plot(str_striderFz.([ogfpzFasti{i} num2str(st)]),'b')
%     else
%         plot(str_striderFz.([ogfpzFasti{i} num2str(st)]),'r')
%     end
% end
% hold off
% %legend(ogfpyFasti)
% title(['Fast Z' '     ' trialData.metaData.name])
% saveas(gcf,['Fast Z_' trialData.metaData.name],'png')


% figure (trialData.metaData.condition*4-3)
% hold on
% plot(striderSyAlign)
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
% plot(striderFyAlign)
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

% if isempty(h_slow) || isempty(h_fast)

% else

% saveas(h_slow,['Aligned_Slow_v2' trialData.metaData.name],'png')
% saveas(h_fast,['Aligned_Fast_v2' trialData.metaData.name],'png')
% end

%% COM:
if false %~isempty(markerData.getLabelsThatMatch('HAT'))
    [ outCOM ] = computeCOM(strideEvents, markerData, BW, slowleg, fastleg, impactS, expData, gaitEvents, flipIT );
else
    outCOM.Data=[];
    outCOM.labels=[];
    outCOM.description=[];
end

%% COP: not ready for real life
% if ~isempty(markerData.getLabelsThatMatch('LCOP'))
%     [outCOP] = computeCOPParams( strideEvents, markerData, BW, slowleg, fastleg, impactS, expData, gaitEvents );
% else
outCOP.Data=[];
outCOP.labels=[];
outCOP.description=[];
% end

%% Compile
% dataOgfpSum = [[impactSOgfpSum NaN]' [SBogfpSum NaN]' [SPogfpSum NaN]' [impactFOgfpSum NaN]' [FBogfpSum NaN]' [FPogfpSum NaN]' [FBogfpSum-SBogfpSum NaN]' [FPogfpSum-SPogfpSum NaN]'...
%     [impactSmaxOgfpSum NaN]' [SBmaxOgfpSum NaN]' [SPmaxOgfpSum NaN]' [impactFmaxOgfpSum NaN]' [FBmaxOgfpSum NaN]' [FPmaxOgfpSum NaN]'];
%
% labelsOgfpSum = {'FyImpactS_OGFP_sum', 'FyBS_OGFP_sum', 'FyPS_OGFP_sum', 'FyImpactF_OGFP_sum', 'FyBF_OGFP_sum', 'FyPF_OGFP_sum','FyBSym_OGFP_sum', 'FyPSym_OGFP_sum', 'FyImpactSmax_OGFP_sum', 'FyBSmax_OGFP_sum', 'FyPSmax_OGFP_sum', 'FyImpactFmax_OGFP_sum', 'FyBFmax_OGFP_sum', 'FyPFmax_OGFP_sum'};
% % Carly's paper looks at the maximum breaking and propulsion forces for the fast and the slow side which will be  'FyBSmax', 'FyPSmax', 'FyBFmax', 'FyPFmax'
%
% descriptionOgfpSum = {'GRF-FYs average signed impact force', 'GRF-FYs average signed braking', 'GRF-FYs average signed propulsion',...
%     'GRF-FYf average signed impact force', 'GRF-FYf average signed braking', 'GRF-FYf average signed propulsion', ...
%     'GRF-FYs average signed Symmetry braking', 'GRF-FYs average signed Symmetry propulsion',...
%     'GRF-FYs max signed impact force', 'GRF-FYs max signed braking', 'GRF-FYs max signed propulsion',...
%     'GRF-FYf max signed impact force', 'GRF-FYf max signed braking', 'GRF-FYf max signed propulsion'};


%dataOgfpSum = [[SBmaxOgfpSum NaN]' [SPmaxOgfpSum NaN]' [FBmaxOgfpSum NaN]' [FPmaxOgfpSum NaN]'];

%labelsOgfpSum = {'FyBSmax_OGFP_sum', 'FyPSmax_OGFP_sum', 'FyBFmax_OGFP_sum', 'FyPFmax_OGFP_sum'};
% Carly's paper looks at the maximum breaking and propulsion forces for the fast and the slow side which will be  'FyBSmax', 'FyPSmax', 'FyBFmax', 'FyPFmax'

%descriptionOgfpSum = {'GRF-FYs max signed braking', 'GRF-FYs max signed propulsion','GRF-FYf max signed braking', 'GRF-FYf max signed propulsion'};

data_align = [[impactS_align NaN]' [SB_align NaN]' [SP_align NaN]' [impactF_align NaN]' [FB_align NaN]' [FP_align NaN]' [FB_align-SB_align NaN]' [FP_align-SP_align NaN]' [(FB_align-SB_align)./(FB_align+SB_align) NaN]' [(FP_align-SP_align)./(FP_align+SP_align) NaN]' [SX_align NaN]' [SZ_align NaN]' [FX_align NaN]' [FZ_align NaN]' ...
    [impactSmax_align NaN]' [SBmax_align NaN]' [SPmax_align NaN]' [impactFmax_align NaN]' [FBmax_align NaN]' [FPmax_align NaN]' [SXmax_align NaN]' [SZmax_align NaN]' [FXmax_align NaN]' [FZmax_align NaN]'];

labels_align = {'FyImpactS_align', 'FyBS_align', 'FyPS_align', 'FyImpactF_align', 'FyBF_align', 'FyPF_align','FyBSym_align', 'FyPSym_align','FyBSym_norm_align', 'FyPSym_norm_align', 'FxS_align', 'FzS_align', 'FxF_align', 'FzF_align', 'FyImpactSmax_align', 'FyBSmax_align', 'FyPSmax_align', 'FyImpactFmax_align', 'FyBFmax_align', 'FyPFmax_align', 'FxSmax_align', 'FzSmax_align', 'FxFmax_align', 'FzFmax_align'};
% Carly's paper looks at the maximum breaking and propulsion forces for the fast and the slow side which will be  'FyBSmax', 'FyPSmax', 'FyBFmax', 'FyPFmax'

description_align = {'GRF-FYs average signed impact force', 'GRF-FYs average signed braking', 'GRF-FYs average signed propulsion',...
    'GRF-FYf average signed impact force', 'GRF-FYf average signed braking', 'GRF-FYf average signed propulsion', ...
    'GRF-FYs average signed Symmetry braking', 'GRF-FYs average signed Symmetry propulsion',...
    'GRF-FYs average signed Symmetry braking normalized by sum', 'GRF-FYs average signed Symmetry propulsion normalized by sum',...
    'GRF-Fxs average force', 'GRF-Fzs average force', 'GRF-Fxf average force', 'GRF-Fzf average force', ...
    'GRF-FYs max signed impact force', 'GRF-FYs max signed braking', 'GRF-FYs max signed propulsion',...
    'GRF-FYf max signed impact force', 'GRF-FYf max signed braking', 'GRF-FYf max signed propulsion', ...
    'GRF-Fxs max force', 'GRF-Fzs max force', 'GRF-Fxf max force', 'GRF-Fzf max force'};


% data_align = [data_align dataOgfpSum];
% labels_align = [labels_align labelsOgfpSum];
% description_align = [description_align descriptionOgfpSum];

dataOgfp = [];
labelsOgfp = [];
descriptionOgfp = [];

for fp = 1:length(Ally)

    data_OGFP_temp = [[SBmax_OGFP.(Ally{fp}) NaN]' [SPmax_OGFP.(Ally{fp}) NaN]' [FBmax_OGFP.(Ally{fp}) NaN]' [FPmax_OGFP.(Ally{fp}) NaN]'];
    labels_OGFP_temp = {['FyBSmax_align_' Ally{fp}], ['FyPSmax_align_' Ally{fp}], ['FyBFmax_align_' Ally{fp}], ['FyPFmax_align_' Ally{fp}]};
    description_OGFP_temp = {[Ally{fp} 'GRF-FYs max signed braking'], [Ally{fp} 'GRF-FYs max signed propulsion'], [Ally{fp} 'GRF-FYf max signed braking'], [Ally{fp} 'GRF-FYf max signed propulsion']};

    %     dataOgfp = [dataOgfp dataOgfpTemp];
    %     labelsOgfp = [labelsOgfp labelsOgfpTemp];
    %     descriptionOgfp = [descriptionOgfp descriptionOgfpTemp];

    wannaAddOGFP = 1;
    if wannaAddOGFP == 1
        data_align = [data_align dataOgfpTemp];
        labels_align = [labels_align labelsOgfpTemp];
        description_align = [description_align descriptionOgfpTemp];
    end

end

if isempty(markerData.getLabelsThatMatch('Hat'))
    data_align = [data_align outCOM.Data outCOP.Data];
    labels_align=[labels_align outCOM.labels outCOP.labels];
    description_align=[description_align outCOM.description outCOP.description];
end

%out = parameterSeries(dataOgfp,labelsOgfp,[],descriptionOgfp);
out = parameterSeries(data_align, labels_align, [], description_align);

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


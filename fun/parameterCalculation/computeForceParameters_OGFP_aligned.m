function [out] = computeForceParameters_OGFP_aligned(strideEvents, GRFData, slowleg, fastleg, BW, trialData, markerData)
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

%~~~~~~~ Here is where I am putting real stuffs ~~~~~~~~
trial=trialData.metaData.description;
%If I want all the forces to be unitless then set this to 9.81*BW, else set it
%to 1*BW

if strcmpi(trialData.metaData.type,'NIM')
    Normalizer=9.81*(BW+3.4); %3.4 kg is the weight of the two Nimbus shoes, if we ever change the shoes this needs to be modified
else
    normalizer = gravityAcc * BW;
end

bw_th_min = 0.8;
early_th = 0.2;
end_th = 0.2;
divideri = 8;
flipB = 1;
trialNum = str2double(trialData.metaData.rawDataFilename(end-1:end));

if iscell(trial)
    trial = trial{1};
end

ang = determineTMAngle(trialData.metaData);
if strcmpi(trialData.metaData.type, 'IN')
    ang = 8.5;
end
flipIT= 2.*(ang >= 0)-1; %This will be -1 when it was a decline study, 1 otherwise
Filtered = GRFData.substituteNaNs.lowPassFilter(20);
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

%~~~~~~~~~~~~~~~~ REMOVE ANY OFFSETS IN THE DATA~~~~~~~~~~~~~~~~~~~~~~~~~~~
%New 8/5/2016 CJS: It came to my attenion that one of the decline subjects
%(LD30) one of the force plates was not properly zeroed.  Here I am
%manually shifting the forces.  I am assuming that the vertical forces have
%been properly been shifted during the c3d2mat process, otherwise the
%events are wrong and these lines of code will not save you. rats

%figure; plot(Filtered.getDataAsTS([s 'Fy']).Data, 'b'); hold on; plot(Filtered.getDataAsTS([f 'Fy']).Data, 'r');
fFy = Filtered.getDataAsTS([fastleg 'Fy']);
sFy = Filtered.getDataAsTS([slowleg 'Fy']);

FastLegOffSetData=nan(length(strideEvents.tSHS)-1, 1);
SlowLegOffSetData=nan(length(strideEvents.tSHS)-1, 1);
if Filtered.isaLabel('HFx')
    handrailData=Filtered.getDataAsTS({'HFy', 'HFz'});
elseif Filtered.isaLabel('XFx')
    handrailData=Filtered.getDataAsTS({'XFy', 'XFz'});
    warning('Handrail data was not found labeled as ''HFx'', using ''XFx'' instead (not sure if that IS the handrail!). This is probably an issue with force channel numbering mismatch while loading (c3d2mat).')
else
    handrailData=[];
    warning('Found no handrail force data.')
end

for fp = 1:length(Ally)
    if Filtered.isaLabel(Ally{fp})
        OGFP.(Ally{fp}) = Filtered.getDataAsTS(Ally{fp});
        FastLegOffSetData_OGFP.(Ally{fp}) = nan(length(strideEvents.tSHS)-1, 1);
        SlowLegOffSetData_OGFP.(Ally{fp}) = nan(length(strideEvents.tSHS)-1, 1);
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
        if Filtered.isaLabel(Ally{fp})
            FastLegOffSetData_OGFP.(Ally{fp})(st) = median(OGFP.(Ally{fp}).split(FTO, FHS).Data, 'omitnan');
            SlowLegOffSetData_OGFP.(Ally{fp})(st) = median(OGFP.(Ally{fp}).split(STO, SHS2).Data, 'omitnan');
        end
    end
end
display(['Fast Leg Offset: ' num2str(FastLegOffSet) ', Slow Leg Offset: ' num2str(SlowLegOffSet)]);
fastLegOffset=round(median(fastLegOffsetData, 'omitnan'), 3);
slowLegOffset=round(median(slowLegOffsetData, 'omitnan'), 3);

Filtered.Data(:, find(strcmp(Filtered.getLabels, [fastleg 'Fy']))) = Filtered.getDataAsVector([fastleg 'Fy']) - FastLegOffSet;
Filtered.Data(:, find(strcmp(Filtered.getLabels, [slowleg 'Fy']))) = Filtered.getDataAsVector([slowleg 'Fy']) - SlowLegOffSet;


for fp = 1:length(Ally)

    FastLegOffSet_OGFP.(Ally{fp}) = round(median(FastLegOffSetData_OGFP.(Ally{fp}), 'omitnan'), 3);
    FilteredF.Data(:, find(strcmp(FilteredF.getLabels,Ally{fp}))) = FilteredF.getDataAsVector(Ally{fp}) - FastLegOffSet_OGFP.(Ally{fp});

    SlowLegOffSet_OGFP.(Ally{fp}) = round(median(SlowLegOffSetData_OGFP.(Ally{fp}), 'omitnan'), 3);
    FilteredS.Data(:, find(strcmp(FilteredS.getLabels,Ally{fp}))) = FilteredS.getDataAsVector(Ally{fp}) - SlowLegOffSet_OGFP.(Ally{fp});

end


%figure; plot(Filtered.getDataAsTS([slowleg 'Fy']).Data, 'b'); hold on; plot(Filtered.getDataAsTS([fastleg 'Fy']).Data, 'r');line([0 5*10^5], [0, 0])
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
LevelofInterest = 0.5.*flipIT.*cosd(90-abs(ang)); %The actual angle of the incline
%LevelofInterest = flipIT.*cosd(90-abs(ang)); %The actual angle of the incline


% pre-defining variables
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
    filteredSlow_align = FilteredS.align(gaitEvents, {[slowleg 'HS'], [fastleg 'TO'], [fastleg 'HS']}, [floor(0.2*slow_frames), floor(0.4*slow_frames), floor(0.4*slow_frames)]);
    filteredSlow_align.Data = [filteredSlow_align.Data(slow_frames-19:end, :, :); filteredSlow_align.Data(1:slow_frames-40-endcutting, :, :)];

    filteredFast_align = FilteredF.align(gaitEvents, {[fastleg 'HS'], [slowleg 'TO'], [slowleg 'HS']}, [floor(0.2*fast_frames), floor(0.4*fast_frames), floor(0.4*fast_frames)]);
    filteredFast_align.Data = [filteredFast_align.Data(fast_frames-19:end, :, :); filteredFast_align.Data(1:fast_frames-40-endcutting, :, :)];
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
            striderSy_OGFP.(Ally{fp}) = flipIT.*filteredSlowStance.getDataAsVector(Ally{fp})/Normalizer;
            striderSz_OGFP.(Allz{fp}) = flipIT.*filteredSlowStance.getDataAsVector(Allz{fp})/Normalizer;

            striderSy_OGFP_align.(Ally{fp}) = flipIT.*filteredSlow_align.getPartialDataAsATS(Ally{fp}).Data(:, 1, st)/Normalizer;
            striderSz_OGFP_align.(Allz{fp}) = flipIT.*filteredSlow_align.getPartialDataAsATS(Allz{fp}).Data(:, 1, st)/Normalizer;

            % getting each force-plate value during single stance
            striderSy_OGFP_SS.(Ally{fp}) = flipIT.*filteredSlowSingleStance.getDataAsVector(Ally{fp})/Normalizer;
            striderSz_OGFP_SS.(Allz{fp}) = flipIT.*filteredSlowSingleStance.getDataAsVector(Allz{fp})/Normalizer;
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

        if abs(min(striderSz_OGFP_sum)) > 0.1 % checking if the force is avaliable
            SlowCount_force = SlowCount_force + 1;
            exist_SlowF(st) = 1;
        else
            slowCountNoForce = slowCountNoForce + 1;
            existSlowF(st) = 0;
        end

        slowDivider = floor(length(striderSzOgfpAlign.('LFz'))/strideDiv);
        goodCounter = 0; ogfpySlow = [];
        for fp = 1:length(Allz)
            if isempty(striderSzOgfpAlign.(Allz{fp})) == 0

                mini_1st.(Allz{fp}) = abs(min(striderSz_OGFP_align.(Allz{fp})(slow_divider:slow_divider*3)));
                mini_2nd.(Allz{fp}) = abs(min(striderSz_OGFP_align.(Allz{fp})(slow_divider*5:slow_divider*7)));

                if mini_1st.(Allz{fp}) >= bw_th_min && mini_2nd.(Allz{fp}) >= bw_th_min && abs(striderSz_OGFP_align.(Allz{fp})(1)) <= early_th && abs(striderSz_OGFP_align.(Allz{fp})(end)) <= end_th
                    OGFPy_slow = Ally{fp}; OGFPz_slow = Allz{fp}; good_counter = good_counter + 1;
                end
            end
        end



        if good_counter == 1 && isempty(OGFPy_slow) == 0 % check if a stride has a good for at least on one of the force-plates

            %striderSy_align = flipIT.*filteredSlowStance.getDataAsVector(OGFPy_slow)/Normalizer;
            %striderSz_align = flipIT.*filteredSlowStance.getDataAsVector(OGFPz_slow)/Normalizer;

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

            striderFy_OGFP.(Ally{fp}) = flipIT.*filteredFastStance.getDataAsVector(Ally{fp})/Normalizer;
            striderFz_OGFP.(Allz{fp}) = flipIT.*filteredFastStance.getDataAsVector(Allz{fp})/Normalizer;

            striderFy_OGFP_align.(Ally{fp}) = flipIT.*filteredFast_align.getPartialDataAsATS(Ally{fp}).Data(:, 1, st)/Normalizer;
            striderFz_OGFP_align.(Allz{fp}) = flipIT.*filteredFast_align.getPartialDataAsATS(Allz{fp}).Data(:, 1, st)/Normalizer;

            striderFy_OGFP_SS.(Ally{fp}) = flipIT.*filteredFastSingleStance.getDataAsVector(Ally{fp})/Normalizer;
            striderFz_OGFP_SS.(Allz{fp}) = flipIT.*filteredFastSingleStance.getDataAsVector(Allz{fp})/Normalizer;

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

                mini_1st.(Allz{fp}) = abs(min(striderFz_OGFP_align.(Allz{fp})(midway_fast:midway_fast*3)));
                mini_2nd.(Allz{fp}) = abs(min(striderFz_OGFP_align.(Allz{fp})(midway_fast*5:midway_fast*7)));

                if mini_1st.(Allz{fp}) >= bw_th_min && mini_2nd.(Allz{fp}) >= bw_th_min && abs(striderFz_OGFP_align.(Allz{fp})(1)) <= early_th && abs(striderFz_OGFP_align.(Allz{fp})(end)) <= end_th
                    OGFPy_fast = Ally{fp}; OGFPz_fast = Allz{fp}; good_counter = good_counter + 1;
                end
            end
        end

        if goodCounter == 1 && isempty(ogfpyFast) == 0

            %             striderFy_align = flipIT.*filteredFastStance.getDataAsVector(OGFPy_fast)/Normalizer;
            %             striderFz_align = flipIT.*filteredFastStance.getDataAsVector(OGFPz_fast)/Normalizer;

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

    if isempty(striderSy_align) || all(striderSy_align==striderSy_align(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
        %This does nothing, as vars are initialized as nan:
    else
        if std(striderSy_align, 'omitnan')<0.01 && mean(striderSy_align, 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

        else
            ns_align = find((striderSyAlign-levelOfInterest)<0.1);%1:65
            ps_align = find((striderSyAlign-levelOfInterest)>0);

            %             if strcmp(trialData.metaData.name,'adaptation')
            %                 ns_align(find(ns_align>=0.2*length(striderSy_align)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            %                 ps_align(find(ps_align<=0.5*length(striderSy_align)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %
            %                 ns_align(find(ns_align<=0.05*length(striderSy_align)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            %                 ps_align(find(ps_align>=0.95*length(striderSy_align)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %
            %             else


            ns_align(find(ns_align>=0.5*length(striderSy_align)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            ps_align(find(ps_align<=0.5*length(striderSy_align)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.

            ns_align(find(ns_align<=0.12*length(striderSy_align)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            ps_align(find(ps_align>=0.95*length(striderSy_align)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %             end

            ImpactMagS_align = find((striderSy_align-LevelofInterest)==max(striderSy_align(1:75)-LevelofInterest, [], 'omitnan'));%no longer percent of stride
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
                impactS_align(st)=mean(striderSy_align(find((striderSy_align(SHS-SHS+1: postImpactS_align)-LevelofInterest)>0)), 'omitnan')-LevelofInterest;
                if isempty(striderSy_align(find((striderSy_align(SHS-SHS+1: postImpactS_align)-LevelofInterest)>0)))
                    %impactSmax(st)=NaN;
                else
                    impactSmax_align(st)=max(striderSy_align(find((striderSy_align(SHS-SHS+1: postImpactS_align)-LevelofInterest)>0)), [], 'omitnan')-LevelofInterest;
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
            %                     SBmax_ind(i_slow) = find(striderSy_align-LevelofInterest == SBmax_align(st));
            %                     plot(SBmax_ind(i_slow),SBmax_align(st),'k*')
            %                     SPmax_ind(i_slow) = find(striderSy_align-LevelofInterest == SPmax_align(st));
            %                     plot(SPmax_ind(i_slow),SPmax_align(st),'k*')
            %                 end
            %             end
            %             title(['Slow Ground reaction Forces with Peaks' '     ' trialData.metaData.name])

            %             if isempty(striderSy_OGFP_SS.(OGFPy_slow)) == 0
            %             if  isempty(find(striderSy_align == striderSy_OGFP_SS.(OGFPy_slow)(1)))
            %             else
            %                 slow_SS_ind(i_slow) = find(striderSy_align == striderSy_OGFP_SS.(OGFPy_slow)(1));
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
        %         SZ_align(st)=-1*mean(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'z']), 'omitnan')/Normalizer;
        %         SX_align(st)=mean(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'x']), 'omitnan')/Normalizer;
        %         SZmax_align(st)=-1*min(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'z']), [], 'omitnan')/Normalizer;
        %         SXmax_align(st)=min(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'x']), [], 'omitnan')/Normalizer;

        SZ_align(st)=-1*mean(filteredSlow_align.getPartialDataAsATS([OGFPy_slow(1:end-1) 'z']).Data(:, 1, st), 'omitnan')/Normalizer;
        SX_align(st)=mean(filteredSlow_align.getPartialDataAsATS([OGFPy_slow(1:end-1) 'x']).Data(:, 1, st), 'omitnan')/Normalizer;
        SZmax_align(st)=-1*min(filteredSlow_align.getPartialDataAsATS([OGFPy_slow(1:end-1) 'z']).Data(:, 1, st), [], 'omitnan')/Normalizer;
        SXmax_align(st)=min(filteredSlow_align.getPartialDataAsATS([OGFPy_slow(1:end-1) 'x']).Data(:, 1, st), [], 'omitnan')/Normalizer;



    end

    %%Now for the fast leg...
    if isempty(striderFy_align) || all(striderFy_align==striderFy_align(1)) || isempty(FTO) || isempty(STO)

    else
        if std(striderFy_align, 'omitnan')<0.01 && mean(striderFy_align, 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

        else
            nf_align=find((striderFy_align-LevelofInterest)<0.1);%1:65
            pf_align=find((striderFy_align-LevelofInterest)>0);

            %             if strcmp(trialData.metaData.name,'adaptation')
            %                 nf_align(find(nf_align>=0.5*length(striderFy_align)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            %                 pf_align(find(pf_align<=0.5*length(striderFy_align)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %
            %                 nf_align(find(nf_align<=0.12*length(striderFy_align)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            %                 pf_align(find(pf_align>=0.95*length(striderFy_align)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %
            %             else


            nf_align(find(nf_align>=0.5*length(striderFy_align)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            pf_align(find(pf_align<=0.5*length(striderFy_align)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.

            nf_align(find(nf_align<=0.12*length(striderFy_align)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
            pf_align(find(pf_align>=0.95*length(striderFy_align)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
            %             end

            ImpactMagF_align=find((striderFy_align-LevelofInterest)==max(striderFy_align(1:75)-LevelofInterest, [], 'omitnan'));%1:15
            if isempty(ImpactMagF_align)%~=1
                postImpactF_align=nf_align(find(nf_align>ImpactMagF_align(end), 1, 'first'));
                if isempty(postImpactF_align)%~=1
                    pf_align(find(pf_align<postImpactF_align))=[];
                    nf_align(find(nf_align<postImpactF_align))=[];
                end
            end

            if isempty(pf_align)

            else
                FP_align(st)=mean(striderFy_align(pf_align)-LevelofInterest, 'omitnan');
                FPmax_align(st)=max(striderFy_align(pf_align)-LevelofInterest, [], 'omitnan');
            end
            if isempty(nf_align)

            else
                FB_align(st)=FlipB.*(mean(striderFy_align(nf_align)-LevelofInterest, 'omitnan'));
                FBmax_align(st)=FlipB.*(min(striderFy_align(nf_align)-LevelofInterest, [], 'omitnan'));
            end

            if exist('postImpactF_align')==0 || isempty(postImpactF_align)==1

            else
                impactF_align(st)=mean(striderFy_align(find((striderFy_align(FHS-FHS+1: postImpactF_align)-LevelofInterest)>0)), 'omitnan')-LevelofInterest;
                if isempty(striderFy_align(find((striderFy_align(FHS-FHS+1: postImpactF_align)-LevelofInterest)>0)))

                else
                    impactFmax_align(st)=max(striderFy_align(find((striderFy_align(FHS-FHS+1: postImpactF_align)-LevelofInterest)>0)), [], 'omitnan')-LevelofInterest;
                end
            end

            i_fast = i_fast+1;
            OGFPy_fasti(i_fast) = {OGFPy_fast};
            OGFPz_fasti(i_fast) = {OGFPz_fast};
            str_striderFy.([OGFPy_fast num2str(i_fast)]) = striderFy_align;
            str_striderFz.([OGFPz_fast num2str(i_fast)]) = striderFz_align;

            %             h_fast = figure (trialData.metaData.condition*10-7)
            %             hold on
            %             plot(striderFy_align-LevelofInterest,'r')
            %             if isempty(FBmax_align(st)) == 0 && isempty(FPmax_align(st)) == 0
            %                 if  isempty(find(striderFy_align-LevelofInterest == FBmax_align(st))) || isempty(find(striderFy_align-LevelofInterest == FPmax_align(st)))
            %                 else
            %                     FBmax_ind(i_fast) = find(striderFy_align-LevelofInterest == FBmax_align(st));
            %                     plot(FBmax_ind(i_fast),FBmax_align(st),'k*')
            %                     FPmax_ind(i_fast) = find(striderFy_align-LevelofInterest == FPmax_align(st));
            %                     plot(FPmax_ind(i_fast),FPmax_align(st),'k*')
            %                 end
            %             end
            %             title(['Fast Ground reaction Forces with Peaks' '     ' trialData.metaData.name])
            %             hold on
            %             plot(striderFy_align,'b')
            %             if  isempty(find(striderFy_align == striderFy_OGFP_SS.(OGFPy_fast)(1)))
            %             else
            %                 fast_SS_ind(i_fast) = find(striderFy_align == striderFy_OGFP_SS.(OGFPy_fast)(1));
            %                 plot(fast_SS_ind(i_fast):fast_SS_ind(i_fast)+length(striderFy_OGFP_SS.(OGFPy_fast))-1,striderFy_OGFP_SS.(OGFPy_fast),'r*')
            %                 hold off
            %                 title(['Fast Single Stance Overlapped' '     ' trialData.metaData.name])
            %                 saveas(gcf,['FastOverlapped_' trialData.metaData.name],'png')
            %             end
        end
        %         FZ_align(st)=-1*mean(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'z']), 'omitnan')/Normalizer; %%[OGFPy_fast(1:end-1) 'z']
        %         FX_align(st)=mean(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'x']), 'omitnan')/Normalizer;
        %         FZmax_align(st)=-1*min(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'z']), [], 'omitnan')/Normalizer;
        %         FXmax_align(st)=max(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'x']), [], 'omitnan')/Normalizer;

        FZ_align(st)=-1*mean(filteredFast_align.getPartialDataAsATS([OGFPy_fast(1:end-1) 'z']).Data(:, 1, st), 'omitnan')/Normalizer;
        FX_align(st)=mean(filteredFast_align.getPartialDataAsATS([OGFPy_fast(1:end-1) 'x']).Data(:, 1, st), 'omitnan')/Normalizer;
        FZmax_align(st)=-1*min(filteredFast_align.getPartialDataAsATS([OGFPy_fast(1:end-1) 'z']).Data(:, 1, st), [], 'omitnan')/Normalizer;
        FXmax_align(st)=min(filteredFast_align.getPartialDataAsATS([OGFPy_fast(1:end-1) 'x']).Data(:, 1, st), [], 'omitnan')/Normalizer;

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% computing the parameters for adding all forces toghether %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isempty(striderSy_OGFP_sum) || all(striderSy_OGFP_sum==striderSy_OGFP_sum(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
        %This does nothing, as vars are initialized as nan:
        SBmax_OGFP_sum(st) = NaN;
        SPmax_OGFP_sum(st) = NaN;
    else
        if std(striderSy_OGFP_sum, 'omitnan')<0.01 && mean(striderSy_OGFP_sum, 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

        else
            ns_OGFP_sum = find((striderSy_OGFP_sum-LevelofInterest)<0);%1:65
            ps_OGFP_sum = find((striderSy_OGFP_sum-LevelofInterest)>0);

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
                SPmax_OGFP_sum(st)= NaN;
            else
                SP_OGFP_sum(st)=mean(striderSy_OGFP_sum(ps_OGFP_sum)-LevelofInterest, 'omitnan');
                SPmax_OGFP_sum(st)=max(striderSy_OGFP_sum(ps_OGFP_sum)-LevelofInterest, [], 'omitnan');
            end

            if exist('postImpactS_OGFP_sum')==0 || isempty(postImpactS_OGFP_sum)==1 || isnan(SHS)
                %                     impactS(st)=NaN;
                %                     impactSmax(st)=NaN;
                impactSmax_OGFP_sum(st)= NaN;
            else
                impactS_OGFP_sum(st)=mean(striderSy_OGFP_sum(find((striderSy_OGFP_sum(SHS-SHS+1: postImpactS_OGFP_sum)-LevelofInterest)>0)), 'omitnan')-LevelofInterest;
                if isempty(striderSy_OGFP_sum(find((striderSy_OGFP_sum(SHS-SHS+1: postImpactS_OGFP_sum)-LevelofInterest)>0)))
                    %impactSmax(st)=NaN;
                else
                    impactSmax_OGFP_sum(st)=max(striderSy_OGFP_sum(find((striderSy_OGFP_sum(SHS-SHS+1: postImpactS_OGFP_sum)-LevelofInterest)>0)), [], 'omitnan')-LevelofInterest;
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
            nf_OGFP_sum=find((striderFy_OGFP_sum-LevelofInterest)<0);%1:65
            pf_OGFP_sum=find((striderFy_OGFP_sum-LevelofInterest)>0);
            %             ImpactMagF_OGFP_sum=find((striderFy_OGFP_sum-LevelofInterest)==max(striderFy_OGFP_sum(1:75)-LevelofInterest, [], 'omitnan'));%1:15
            %             if isempty(ImpactMagF_OGFP_sum)~=1
            %                 postImpactF_OGFP_sum=nf_OGFP_sum(find(nf_OGFP_sum>ImpactMagF_OGFP_sum(end), 1, 'first'));
            %                 if isempty(postImpactF_OGFP_sum)~=1
            %                     pf_OGFP_sum(find(pf_OGFP_sum<postImpactF_OGFP_sum))=[];
            %                     nf_OGFP_sum(find(nf_OGFP_sum<postImpactF_OGFP_sum))=[];
            %                 end
            %             end

            if isempty(pf_OGFP_sum)
                FPmax_OGFP_sum(st)= NaN;
            else
                FP_OGFP_sum(st)=mean(striderFy_OGFP_sum(pf_OGFP_sum)-LevelofInterest, 'omitnan');
                FPmax_OGFP_sum(st)=max(striderFy_OGFP_sum(pf_OGFP_sum)-LevelofInterest, [], 'omitnan');
            end
            if isempty(nf_OGFP_sum)
                FBmax_OGFP_sum(st)= NaN;
            else
                FB_OGFP_sum(st)=FlipB.*(mean(striderFy_OGFP_sum(nf_OGFP_sum)-LevelofInterest, 'omitnan'));
                FBmax_OGFP_sum(st)=FlipB.*(min(striderFy_OGFP_sum(nf_OGFP_sum)-LevelofInterest, [], 'omitnan'));
            end

            if exist('postImpactF_OGFP_sum')==0 || isempty(postImpactF_OGFP_sum)==1 || isnan(FHS)==1
                impactFmax_OGFP_sum(st) = NaN;
            else
                impactF_OGFP_sum(st)=mean(striderFy_OGFP_sum(find((striderFy_OGFP_sum(FHS-FHS+1: postImpactF_OGFP_sum)-LevelofInterest)>0)), 'omitnan')-LevelofInterest;
                if isempty(striderFy_OGFP_sum(find((striderFy_OGFP_sum(FHS-FHS+1: postImpactF_OGFP_sum)-LevelofInterest)>0)))

                else
                    impactFmax_OGFP_sum(st)=max(striderFy_OGFP_sum(find((striderFy_OGFP_sum(FHS-FHS+1: postImpactF_OGFP_sum)-LevelofInterest)>0)), [], 'omitnan')-LevelofInterest;
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

                if isempty(ns_OGFP.(Ally{fp}))

                else
                    SB_OGFP.(Ally{fp})(st)=FlipB.*(mean(striderSy_OGFP.(Ally{fp})(ns_OGFP.(Ally{fp}))-LevelofInterest, 'omitnan'));
                    SBmax_OGFP.(Ally{fp})(st)=FlipB.*(min(striderSy_OGFP.(Ally{fp})(ns_OGFP.(Ally{fp}))-LevelofInterest, [], 'omitnan'));
                end
                if isempty(ps_OGFP.(Ally{fp}))

                else
                    SP_OGFP.(Ally{fp})(st)=mean(striderSy_OGFP.(Ally{fp})(ps_OGFP.(Ally{fp}))-LevelofInterest, 'omitnan');
                    SPmax_OGFP.(Ally{fp})(st)=max(striderSy_OGFP.(Ally{fp})(ps_OGFP.(Ally{fp}))-LevelofInterest, [], 'omitnan');
                end

                if exist(['postImpactS_OGFP.' Ally{fp}])==0 || isempty(postImpactS_OGFP.(Ally{fp}))==1
                    %                     impactS(st)=NaN;
                    %                     impactSmax(st)=NaN;
                else
                    impactS_OGFP.(Ally{fp})(st)=mean(striderSy_OGFP.(Ally{fp})(find((striderSy_OGFP.(Ally{fp})(SHS-SHS+1: postImpactS_OGFP.(Ally{fp}))-LevelofInterest)>0)), 'omitnan')-LevelofInterest;
                    if isempty(striderSy_OGFP.(Ally{fp})(find((striderSy_OGFP.(Ally{fp})(SHS-SHS+1: postImpactS_OGFP.(Ally{fp}))-LevelofInterest)>0)))
                        %impactSmax(st)=NaN;
                    else
                        impactSmax_OGFP.(Ally{fp})(st)=max(striderSy_OGFP.(Ally{fp})(find((striderSy_OGFP.(Ally{fp})(SHS-SHS+1: postImpactS_OGFP.(Ally{fp}))-LevelofInterest)>0)), [], 'omitnan')-LevelofInterest;
                    end
                end
            end
            SZ_OGFP.(Ally{fp})(st)=-1*mean(filteredSlowStance.getDataAsVector([Ally{fp}(1:end-1) 'z']), 'omitnan')/Normalizer;
            SX_OGFP.(Ally{fp})(st)=mean(filteredSlowStance.getDataAsVector([Ally{fp}(1:end-1) 'x']), 'omitnan')/Normalizer;
            SZmax_OGFP.(Ally{fp})(st)=-1*min(filteredSlowStance.getDataAsVector([Ally{fp}(1:end-1) 'z']), [], 'omitnan')/Normalizer;
            SXmax_OGFP.(Ally{fp})(st)=min(filteredSlowStance.getDataAsVector([Ally{fp}(1:end-1) 'x']), [], 'omitnan')/Normalizer;
        end

        %%Now for the fast leg...
        if isempty(striderFy_OGFP.(Ally{fp})) || all(striderFy_OGFP.(Ally{fp})==striderFy_OGFP.(Ally{fp})(1)) || isempty(FTO) || isempty(STO)

        else
            if std(striderFy_OGFP.(Ally{fp}), 'omitnan')<0.01 && mean(striderFy_OGFP.(Ally{fp}), 'omitnan')<0.01 %This is to get rid of places where there is only noise and no data

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

                if isempty(pf_OGFP.(Ally{fp}))

                else
                    FP_OGFP.(Ally{fp})(st)=mean(striderFy_OGFP.(Ally{fp})(pf_OGFP.(Ally{fp}))-LevelofInterest, 'omitnan');
                    FPmax_OGFP.(Ally{fp})(st)=max(striderFy_OGFP.(Ally{fp})(pf_OGFP.(Ally{fp}))-LevelofInterest, [], 'omitnan');
                end
                if isempty(nf_OGFP.(Ally{fp}))

                else
                    FB_OGFP.(Ally{fp})(st)=FlipB.*(mean(striderFy_OGFP.(Ally{fp})(nf_OGFP.(Ally{fp}))-LevelofInterest, 'omitnan'));
                    FBmax_OGFP.(Ally{fp})(st)=FlipB.*(min(striderFy_OGFP.(Ally{fp})(nf_OGFP.(Ally{fp}))-LevelofInterest, [], 'omitnan'));
                end

                if exist(['postImpactF_OGFP.' Ally{fp}])==0 || isempty(postImpactF_OGFP.(Ally{fp}))==1

                else
                    impactF_OGFP.(Ally{fp})(st)=mean(striderFy_OGFP.(Ally{fp})(find((striderFy_OGFP.(Ally{fp})(FHS-FHS+1: postImpactF_OGFP.(Ally{fp}))-LevelofInterest)>0)), 'omitnan')-LevelofInterest;
                    if isempty(striderFy_OGFP.(Ally{fp})(find((striderFy_OGFP.(Ally{fp})(FHS-FHS+1: postImpactF_OGFP.(Ally{fp}))-LevelofInterest)>0)))

                    else
                        impactFmax_OGFP.(Ally{fp})(st)=max(striderFy_OGFP.(Ally{fp})(find((striderFy_OGFP.(Ally{fp})(FHS-FHS+1: postImpactF_OGFP.(Ally{fp}))-LevelofInterest)>0)), [], 'omitnan')-LevelofInterest;
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
% plot(striderSy_align)
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
% plot(striderFy_align)
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


% data_align = [data_align data_OGFP_sum];
% labels_align = [labels_align labels_OGFP_sum];
% description_align = [description_align description_OGFP_sum];

data_OGFP = [];
labels_OGFP = [];
description_OGFP = [];

for fp = 1:length(Ally)

    data_OGFP_temp = [[SBmax_OGFP.(Ally{fp}) NaN]' [SPmax_OGFP.(Ally{fp}) NaN]' [FBmax_OGFP.(Ally{fp}) NaN]' [FPmax_OGFP.(Ally{fp}) NaN]'];
    labels_OGFP_temp = {['FyBSmax_align_' Ally{fp}], ['FyPSmax_align_' Ally{fp}], ['FyBFmax_align_' Ally{fp}], ['FyPFmax_align_' Ally{fp}]};
    description_OGFP_temp = {[Ally{fp} 'GRF-FYs max signed braking'], [Ally{fp} 'GRF-FYs max signed propulsion'], [Ally{fp} 'GRF-FYf max signed braking'], [Ally{fp} 'GRF-FYf max signed propulsion']};

    %     data_OGFP = [data_OGFP data_OGFP_temp];
    %     labels_OGFP = [labels_OGFP labels_OGFP_temp];
    %     description_OGFP = [description_OGFP description_OGFP_temp];

    wannaAddOGFP = 1;
    if wannaAddOGFP == 1
        data_align = [data_align data_OGFP_temp];
        labels_align = [labels_align labels_OGFP_temp];
        description_align = [description_align description_OGFP_temp];
    end

end

if isempty(markerData.getLabelsThatMatch('Hat'))
    data_align = [data_align outCOM.Data outCOP.Data];
    labels_align=[labels_align outCOM.labels outCOP.labels];
    description_align=[description_align outCOM.description outCOP.description];
end

%out = parameterSeries(data_OGFP,labels_OGFP,[],description_OGFP);
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


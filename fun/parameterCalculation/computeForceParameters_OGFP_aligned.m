function [out] = computeForceParameters_OGFP_aligned(strideEvents,GRFData,slowleg, fastleg,BW, trialData, markerData)
% CJS 2017: Here I am including the code that I have been using for the incline decline analysis.
% This code is a bit eccentric in the way that identifies the inclination for the TM.

%~~~~~~~ Here is where I am putting real stuffs ~~~~~~~~
trial=trialData.metaData.description;
%If I want all the forces to be unitless then set this to 9.81*BW, else set it
%to 1*BW

if strcmpi(trialData.metaData.type,'NIM') 
    Normalizer=9.81*(BW+3.4); %3.4 kg is the weight of the two Nimbus shoes, if we ever change the shoes this needs to be modified
else
    Normalizer=9.81*BW;
end

bw_th_min = 0.8;
early_th = 0.2;
end_th = 0.2;
divideri = 8;
trialNum = str2double(trialData.metaData.rawDataFilename(end-1:end));
FlipB=1; %7/21/2016, nevermind, making 1 8/1/2016

if iscell(trial)
    trial=trial{1};
end


[ ang ] = DetermineTMAngle( trialData.metaData );
if strcmpi(trialData.metaData.type, 'IN')
    ang = 8.5;
end
flipIT= 2.*(ang >= 0)-1; %This will be -1 when it was a decline study, 1 otherwise
Filtered = GRFData.substituteNaNs.lowPassFilter(20);
gaitEvents = trialData.gaitEvents;
FilteredF = Filtered;
FilteredS = Filtered;

% adding the force-plates data overground

forces = GRFData.labels(~contains(GRFData.labels , 'M'));
forces = forces(~contains(forces , 'H')); %Remove the handrail from the data

if strcmpi(trialData.metaData.type,'OG') || strcmpi(trialData.metaData.type,'NIM') 
    Allz = forces(contains(forces , 'z'));
    Ally = forces(contains(forces , 'y'));
%     Allz = {'FP4Fz','FP5Fz','FP6Fz','FP7Fz','LFz','RFz'};
%     Ally = {'FP4Fy','FP5Fy','FP6Fy','FP7Fy','LFy','RFy'};
else
    Allz = {'LFz','RFz'};
    Ally = {'LFy','RFy'};
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

FastLegOffSetData=nan(length(strideEvents.tSHS)-1,1);
SlowLegOffSetData=nan(length(strideEvents.tSHS)-1,1);
if Filtered.isaLabel('HFx')
    handrailData=Filtered.getDataAsTS({'HFy','HFz'});
elseif Filtered.isaLabel('XFx')
    handrailData=Filtered.getDataAsTS({'XFy','XFz'});
    warning('Handrail data was not found labeled as ''HFx'', using ''XFx'' instead (not sure if that IS the handrail!). This is probably an issue with force channel numbering mismatch while loading (c3d2mat).')
else
    handrailData=[];
    warning('Found no handrail force data.')
end

for j = 1:length(Ally)
    if Filtered.isaLabel(Ally{j})
        OGFP.(Ally{j}) = Filtered.getDataAsTS(Ally{j});
        FastLegOffSetData_OGFP.(Ally{j}) = nan(length(strideEvents.tSHS)-1,1);
        SlowLegOffSetData_OGFP.(Ally{j}) = nan(length(strideEvents.tSHS)-1,1);
    else
        OGFP.(Ally{j}) = [];
        FastLegOffSetData_OGFP.(Ally{j}) = nan(length(strideEvents.tSHS)-1,1);
        SlowLegOffSetData_OGFP.(Ally{j}) = nan(length(strideEvents.tSHS)-1,1);
    end
end

for i=1:length(strideEvents.tSHS)-1
    SHS=strideEvents.tSHS(i);
    FTO=strideEvents.tFTO(i);
    FHS=strideEvents.tFHS(i);
    STO=strideEvents.tSTO(i);
    FTO2=strideEvents.tFTO2(i);
    SHS2=strideEvents.tSHS2(i);
    
    if isnan(FTO) || isnan(FHS) || FTO>FHS
        %nop
    else
        FastLegOffSetData(i)=nanmedian(fFy.split(FTO, FHS).Data);
    end
    if isnan(STO) || isnan(SHS2)
        %nop
    else
        SlowLegOffSetData(i)=nanmedian(sFy.split(STO, SHS2).Data);
    end
    
    for j = 1:length(Ally)
        if Filtered.isaLabel(Ally{j})
        FastLegOffSetData_OGFP.(Ally{j})(i) = nanmedian(OGFP.(Ally{j}).split(FTO, FHS).Data);
        SlowLegOffSetData_OGFP.(Ally{j})(i) = nanmedian(OGFP.(Ally{j}).split(STO, SHS2).Data);
        end
    end
end
FastLegOffSet=round(nanmedian(FastLegOffSetData), 3);
SlowLegOffSet=round(nanmedian(SlowLegOffSetData), 3);
display(['Fast Leg Offset: ' num2str(FastLegOffSet) ', Slow Leg Offset: ' num2str(SlowLegOffSet)]);

Filtered.Data(:, find(strcmp(Filtered.getLabels, [fastleg 'Fy']))) = Filtered.getDataAsVector([fastleg 'Fy']) - FastLegOffSet;
Filtered.Data(:, find(strcmp(Filtered.getLabels, [slowleg 'Fy']))) = Filtered.getDataAsVector([slowleg 'Fy']) - SlowLegOffSet;


for j = 1:length(Ally)
    
    FastLegOffSet_OGFP.(Ally{j}) = round(nanmedian(FastLegOffSetData_OGFP.(Ally{j})), 3);
    FilteredF.Data(:, find(strcmp(FilteredF.getLabels,Ally{j}))) = FilteredF.getDataAsVector(Ally{j}) - FastLegOffSet_OGFP.(Ally{j});
    
    SlowLegOffSet_OGFP.(Ally{j}) = round(nanmedian(SlowLegOffSetData_OGFP.(Ally{j})), 3);
    FilteredS.Data(:, find(strcmp(FilteredS.getLabels,Ally{j}))) = FilteredS.getDataAsVector(Ally{j}) - SlowLegOffSet_OGFP.(Ally{j});
    
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

for j = 1:length(Ally)
    impactS_OGFP.(Ally{j}) = NaN(1, lenny); impactF_OGFP.(Ally{j}) = NaN(1, lenny);
    SB_OGFP.(Ally{j}) = NaN(1, lenny); SP_OGFP.(Ally{j}) = NaN(1, lenny); SZ_OGFP.(Ally{j}) = NaN(1, lenny); SX_OGFP.(Ally{j}) = NaN(1, lenny);
    FB_OGFP.(Ally{j}) = NaN(1, lenny); FP_OGFP.(Ally{j}) = NaN(1, lenny); FZ_OGFP.(Ally{j}) = NaN(1, lenny); FX_OGFP.(Ally{j}) = NaN(1, lenny);
    SBmax_OGFP.(Ally{j}) = NaN(1, lenny); SPmax_OGFP.(Ally{j}) = NaN(1, lenny); SZmax_OGFP.(Ally{j}) = NaN(1, lenny); SXmax_OGFP.(Ally{j}) = NaN(1, lenny);
    impactSmax_OGFP.(Ally{j}) = NaN(1, lenny); impactFmax_OGFP.(Ally{j}) = NaN(1, lenny);
    FBmax_OGFP.(Ally{j}) = NaN(1, lenny); FPmax_OGFP.(Ally{j}) = NaN(1, lenny); FZmax_OGFP.(Ally{j}) = NaN(1, lenny);FXmax_OGFP.(Ally{j}) = NaN(1, lenny);
end

endcutting = 150;
if strcmp(trialData.metaData.name,'TM slow')
    slow_frames = 800+endcutting;
    fast_frames = 800+endcutting;
elseif strcmp(trialData.metaData.name,'TM fast')
    slow_frames = 600+endcutting;
    fast_frames = 600+endcutting;
elseif strcmp(trialData.metaData.name,'adaptation')
    slow_frames = 800+endcutting;
    fast_frames = 600+endcutting;
elseif strcmp(trialData.metaData.name,'TM base') || strcmp(trialData.metaData.name,'TM post')
    slow_frames = 700+endcutting;
    fast_frames = 700+endcutting;
else
    slow_frames = 700+endcutting;
    fast_frames = 700+endcutting;
end


if strcmp(trialData.metaData.type,'OG') || strcmp(trialData.metaData.type,'NIM')
    filteredSlow_align = FilteredS.align(gaitEvents,{[slowleg 'HS'],[fastleg 'TO'],[fastleg 'HS']},[floor(0.2*slow_frames),floor(0.4*slow_frames),floor(0.4*slow_frames)]);
    filteredSlow_align.Data = filteredSlow_align.Data(1:slow_frames-endcutting,:,:);
    filteredFast_align = FilteredF.align(gaitEvents,{[fastleg 'HS'],[slowleg 'TO'],[slowleg 'HS']},[floor(0.2*fast_frames),floor(0.5*fast_frames),floor(0.3*fast_frames)]);
    filteredFast_align.Data = filteredFast_align.Data(1:fast_frames-endcutting,:,:);
else
    filteredSlow_align = FilteredS.align(gaitEvents,{[slowleg 'HS'],[fastleg 'TO'],[fastleg 'HS']},[floor(0.2*slow_frames),floor(0.4*slow_frames),floor(0.4*slow_frames)]);
    filteredSlow_align.Data = [filteredSlow_align.Data(slow_frames-19:end,:,:); filteredSlow_align.Data(1:slow_frames-40-endcutting,:,:)];
    
    filteredFast_align = FilteredF.align(gaitEvents,{[fastleg 'HS'],[slowleg 'TO'],[slowleg 'HS']},[floor(0.2*fast_frames),floor(0.4*fast_frames),floor(0.4*fast_frames)]);
    filteredFast_align.Data = [filteredFast_align.Data(fast_frames-19:end,:,:); filteredFast_align.Data(1:fast_frames-40-endcutting,:,:)];
end

i_slow = 0; i_fast = 0;
SlowCount_force = 0; SlowCount_no_force = 0;
FastCount_force = 0; FastCount_no_force = 0;

for i=1:min([length(strideEvents.tSHS)-1,length(filteredSlow_align.Data(1,1,:)),length(filteredFast_align.Data(1,1,:))])
    % get the filtered data for the slow and fast stance phases
    filteredSlowStance = FilteredS.split(SHS, STO);
    filteredFastStance = FilteredF.split(FHS, FTO2);

    % get the filtered data for the slow and fast single stance phases
    filteredSlowSingleStance = FilteredS.split(FTO, FHS);
    filteredFastSingleStance = FilteredF.split(STO, SHS2);
    
    % Getting the events
    SHS=strideEvents.tSHS(i); FTO=strideEvents.tFTO(i); FHS=strideEvents.tFHS(i); STO=strideEvents.tSTO(i); SHS2=strideEvents.tSHS2(i); FTO2=strideEvents.tFTO2(i);
    
    if isnan(SHS) || isnan(STO) % make sure the slow events are not empty
        striderSy_align = []; striderSz_align = [];
        for j = 1:length(Ally)
            striderSy_OGFP.(Ally{j}) = [];
            striderSy_OGFP_align.(Ally{j}) = [];
            striderSy_OGFP_SS.(Ally{j}) = [];
            
            striderSy_OGFP.(Allz{j}) = [];
            striderSy_OGFP_align.(Allz{j}) = [];
            striderSy_OGFP_SS.(Allz{j}) = [];
            
            striderSz_OGFP.(Ally{j}) = [];
            striderSz_OGFP_align.(Ally{j}) = [];
            striderSz_OGFP_SS.(Ally{j}) = [];
            
            striderSz_OGFP.(Allz{j}) = [];
            striderSz_OGFP_align.(Allz{j}) = [];
            striderSz_OGFP_SS.(Allz{j}) = [];
        end
        striderSy_OGFP_sum = []; striderSz_OGFP_sum = [];
        exist_SlowF(i) = 0;
        
    else %FILTERING
        striderSy_OGFP_sum = 0; striderSz_OGFP_sum = 0;
        
        for j = 1:length(Ally)
            % getting each force-plate value during stance
            striderSy_OGFP.(Ally{j}) = flipIT.*filteredSlowStance.getDataAsVector(Ally{j})/Normalizer;
            striderSz_OGFP.(Allz{j}) = flipIT.*filteredSlowStance.getDataAsVector(Allz{j})/Normalizer;
            
            striderSy_OGFP_align.(Ally{j}) = flipIT.*filteredSlow_align.getPartialDataAsATS(Ally{j}).Data(:,1,i)/Normalizer;
            striderSz_OGFP_align.(Allz{j}) = flipIT.*filteredSlow_align.getPartialDataAsATS(Allz{j}).Data(:,1,i)/Normalizer;
            
            % getting each force-plate value during single stance
            striderSy_OGFP_SS.(Ally{j}) = flipIT.*filteredSlowSingleStance.getDataAsVector(Ally{j})/Normalizer;
            striderSz_OGFP_SS.(Allz{j}) = flipIT.*filteredSlowSingleStance.getDataAsVector(Allz{j})/Normalizer;
            % adding all forces together
            striderSy_OGFP_sum = striderSy_OGFP_sum + striderSy_OGFP_SS.(Ally{j});
            striderSz_OGFP_sum = striderSz_OGFP_sum + striderSz_OGFP_SS.(Allz{j});

        end
        
        if abs(min(striderSz_OGFP_sum)) > bw_th_min
            sum_l = floor(length(striderSy_OGFP_sum)/2);
            if max(striderSy_OGFP_sum(1:sum_l)) > max(striderSy_OGFP_sum(sum_l:end))
                striderSy_OGFP_sum = -striderSy_OGFP_sum;
            end
        else
            striderSy_OGFP_sum = []; striderSz_OGFP_sum = [];
        end
        
        if abs(min(striderSz_OGFP_sum)) > 0.1 % checking if the force is avaliable
            SlowCount_force = SlowCount_force + 1;
            exist_SlowF(i) = 1;
        else
            SlowCount_no_force = SlowCount_no_force + 1;
            exist_SlowF(i) = 0;
        end
        
        slow_divider = floor(length(striderSz_OGFP_align.('LFz'))/divideri);
        good_counter = 0; OGFPy_slow = [];
        for j = 1:length(Allz)
            if isempty(striderSz_OGFP_align.(Allz{j})) == 0
                
                mini_1st.(Allz{j}) = abs(min(striderSz_OGFP_align.(Allz{j})(slow_divider:slow_divider*3)));
                mini_2nd.(Allz{j}) = abs(min(striderSz_OGFP_align.(Allz{j})(slow_divider*5:slow_divider*7)));           
                
                if mini_1st.(Allz{j}) >= bw_th_min && mini_2nd.(Allz{j}) >= bw_th_min && abs(striderSz_OGFP_align.(Allz{j})(1)) <= early_th && abs(striderSz_OGFP_align.(Allz{j})(end)) <= end_th
                    OGFPy_slow = Ally{j}; OGFPz_slow = Allz{j}; good_counter = good_counter + 1;
                end
            end
        end
        
        
        
        if good_counter == 1 && isempty(OGFPy_slow) == 0 % check if a stride has a good for at least on one of the force-plates
            
            %striderSy_align = flipIT.*filteredSlowStance.getDataAsVector(OGFPy_slow)/Normalizer;
            %striderSz_align = flipIT.*filteredSlowStance.getDataAsVector(OGFPz_slow)/Normalizer;
            
            striderSy_align = flipIT.*filteredSlow_align.getPartialDataAsATS(OGFPy_slow).Data(:,1,i)/Normalizer;
            striderSz_align = flipIT.*filteredSlow_align.getPartialDataAsATS(OGFPz_slow).Data(:,1,i)/Normalizer;
            
            slow_divider = floor(length(striderSy_align)/divideri);
            if isempty(striderSy_align)
                striderSz_align = [];
            elseif max(striderSy_align(slow_divider:slow_divider*3)) > max(striderSy_align(slow_divider*5:slow_divider*7)) 
                striderSy_align = -striderSy_align;
                striderSy_OGFP_SS.(OGFPy_slow) = -striderSy_OGFP_SS.(OGFPy_slow);
                
                if strcmpi(trialData.metaData.type,'IN') && strcmpi(trialData.metaData.name,'adaptation') && nanmean(striderSy_align) < 0
                    striderSy_align = -striderSy_align;
                    striderSy_OGFP_SS.(OGFPy_slow) = -striderSy_OGFP_SS.(OGFPy_slow);
                elseif max(striderSy_align(1:slow_divider*4)) > max(striderSy_align(slow_divider*4:end))
                    striderSy_align = -striderSy_align;
                    striderSy_OGFP_SS.(OGFPy_slow) = -striderSy_OGFP_SS.(OGFPy_slow);
                end
            end
        else
            striderSy_align=[]; striderSz_align = [];
        end
    end
    
    if isnan(FHS) || isnan(FTO2) % make sure the slow events are not empty
        striderFy_align = []; striderFz_align = [];
        for j = 1:length(Ally)
            striderFy_OGFP.(Ally{j}) = [];
            striderFy_OGFP_align.(Ally{j}) = [];
            striderFy_OGFP_SS.(Ally{j}) = [];
            
            striderFy_OGFP.(Allz{j}) = [];
            striderFy_OGFP_align.(Allz{j}) = [];
            striderFy_OGFP_SS.(Allz{j}) = [];
            
            striderFz_OGFP.(Ally{j}) = [];
            striderFz_OGFP_align.(Ally{j}) = [];
            striderFz_OGFP_SS.(Ally{j}) = [];
            
            striderFz_OGFP.(Allz{j}) = [];
            striderFz_OGFP_align.(Allz{j}) = [];
            striderFz_OGFP_SS.(Allz{j}) = [];
        end
        striderFy_OGFP_sum = []; striderFz_OGFP_sum = [];
        exist_FastF(i) = 0;
    else %FILTERING
        striderFy_OGFP_sum = 0; striderFz_OGFP_sum = 0;
        
        for j = 1:length(Ally)
            
            striderFy_OGFP.(Ally{j}) = flipIT.*filteredFastStance.getDataAsVector(Ally{j})/Normalizer;
            striderFz_OGFP.(Allz{j}) = flipIT.*filteredFastStance.getDataAsVector(Allz{j})/Normalizer;
            
            striderFy_OGFP_align.(Ally{j}) = flipIT.*filteredFast_align.getPartialDataAsATS(Ally{j}).Data(:,1,i)/Normalizer;
            striderFz_OGFP_align.(Allz{j}) = flipIT.*filteredFast_align.getPartialDataAsATS(Allz{j}).Data(:,1,i)/Normalizer;
            
            striderFy_OGFP_SS.(Ally{j}) = flipIT.*filteredFastSingleStance.getDataAsVector(Ally{j})/Normalizer;
            striderFz_OGFP_SS.(Allz{j}) = flipIT.*filteredFastSingleStance.getDataAsVector(Allz{j})/Normalizer;
            
            striderFy_OGFP_sum = striderFy_OGFP_sum + striderFy_OGFP_SS.(Ally{j});
            striderFz_OGFP_sum = striderFz_OGFP_sum + striderFz_OGFP_SS.(Allz{j});
            
        end
        
        if abs(min(striderFz_OGFP_sum)) > 0.1 % checking if the force is avaliable
            FastCount_force = FastCount_force + 1;
            exist_FastF(i) = 1;
            
            sum_l = floor(length(striderFy_OGFP_sum)/2);
            if max(striderFy_OGFP_sum(1:sum_l)) > max(striderFy_OGFP_sum(sum_l:end))
                striderFy_OGFP_sum = -striderFy_OGFP_sum;
            end
        else
            FastCount_no_force = FastCount_no_force + 1;
            exist_FastF(i) = 0;
            striderFy_OGFP_sum = []; striderFz_OGFP_sum = [];
        end
        
        midway_fast = floor(length(striderFz_OGFP_align.('LFz'))/divideri);
        good_counter = 0; OGFPy_fast = [];
        for j = 1:length(Allz)
            if isempty(striderFz_OGFP_align.(Allz{j})) == 0
                
                mini_1st.(Allz{j}) = abs(min(striderFz_OGFP_align.(Allz{j})(midway_fast:midway_fast*3)));
                mini_2nd.(Allz{j}) = abs(min(striderFz_OGFP_align.(Allz{j})(midway_fast*5:midway_fast*7)));
                
                if mini_1st.(Allz{j}) >= bw_th_min && mini_2nd.(Allz{j}) >= bw_th_min && abs(striderFz_OGFP_align.(Allz{j})(1)) <= early_th && abs(striderFz_OGFP_align.(Allz{j})(end)) <= end_th
                    OGFPy_fast = Ally{j}; OGFPz_fast = Allz{j}; good_counter = good_counter + 1;
                end
            end
        end
        
        if good_counter == 1 && isempty(OGFPy_fast) == 0
            
%             striderFy_align = flipIT.*filteredFastStance.getDataAsVector(OGFPy_fast)/Normalizer;
%             striderFz_align = flipIT.*filteredFastStance.getDataAsVector(OGFPz_fast)/Normalizer;
            
            striderFy_align = flipIT.*filteredFast_align.getPartialDataAsATS(OGFPy_fast).Data(:,1,i)/Normalizer;
            striderFz_align = flipIT.*filteredFast_align.getPartialDataAsATS(OGFPz_fast).Data(:,1,i)/Normalizer;
            
            if isempty(striderFy_align)
                striderFz_align = [];
            elseif max(striderFy_align(midway_fast:midway_fast*3)) > max(striderFy_align(midway_fast*5:midway_fast*7))
                striderFy_align = -striderFy_align;
                striderFy_OGFP_SS.(OGFPy_fast) = -striderFy_OGFP_SS.(OGFPy_fast);
                
                if strcmpi(trialData.metaData.type,'IN') && strcmpi(trialData.metaData.name,'adaptation') && nanmean(striderFy_align) < 0
                    striderFy_align = -striderFy_align;
                    striderFy_OGFP_SS.(OGFPy_fast) = -striderFy_OGFP_SS.(OGFPy_fast);
                elseif max(striderFy_align(1:midway_fast*4)) > max(striderFy_align(midway_fast*4:end))
                     striderFy_align = -striderFy_align;
                    striderFy_OGFP_SS.(OGFPy_fast) = -striderFy_OGFP_SS.(OGFPy_fast);
                end
            end
        else
            striderFy_align = []; striderFz_align = [];
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Check if the participant is holding the handrail %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ~isempty(handrailData)
        HandrailHolding(i)= .05 < sqrt(nanmean(sum(handrailData.split(SHS, SHS2).Data.^2,2)))/Normalizer;
    else
        HandrailHolding(i)=NaN;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% computing the parameters for the force plate that a good stance occures %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if isempty(striderSy_align) || all(striderSy_align==striderSy_align(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
        %This does nothing, as vars are initialized as nan:
    else
        if nanstd(striderSy_align)<0.01 && nanmean(striderSy_align)<0.01 %This is to get rid of places where there is only noise and no data
            
        else
            ns_align = find((striderSy_align-LevelofInterest)<0.1);%1:65
            ps_align = find((striderSy_align-LevelofInterest)>0);
            
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
            
            ImpactMagS_align = find((striderSy_align-LevelofInterest)==nanmax(striderSy_align(1:75)-LevelofInterest));%no longer percent of stride
            if isempty(ImpactMagS_align)%~=1
                postImpactS_align = ns_align(find(ns_align>ImpactMagS_align(end), 1, 'first'));
                if isempty(postImpactS_align)%~=1
                    ps_align(find(ps_align<postImpactS_align))=[];
                    ns_align(find(ns_align<postImpactS_align))=[];
                end
            end
            
            if isempty(ns_align)
                
            else
                SB_align(i) = FlipB.*(nanmean(striderSy_align(ns_align)-LevelofInterest));
                SBmax_align(i) = FlipB.*(nanmin(striderSy_align(ns_align)-LevelofInterest));
            end
            
            if isempty(ps_align)
                
            else
                SP_align(i)=nanmean(striderSy_align(ps_align)-LevelofInterest);
                SPmax_align(i)=nanmax(striderSy_align(ps_align)-LevelofInterest);
            end
            
            if exist('postImpactS_align')==0 || isempty(postImpactS_align)==1
                %                     impactS(i)=NaN;
                %                     impactSmax(i)=NaN;
            else
                impactS_align(i)=nanmean(striderSy_align(find((striderSy_align(SHS-SHS+1: postImpactS_align)-LevelofInterest)>0)))-LevelofInterest;
                if isempty(striderSy_align(find((striderSy_align(SHS-SHS+1: postImpactS_align)-LevelofInterest)>0)))
                    %impactSmax(i)=NaN;
                else
                    impactSmax_align(i)=nanmax(striderSy_align(find((striderSy_align(SHS-SHS+1: postImpactS_align)-LevelofInterest)>0)))-LevelofInterest;
                end
            end
            
            i_slow = i_slow+1;
            OGFPy_slowi(i_slow) = {OGFPy_slow};
            OGFPz_slowi(i_slow) = {OGFPz_slow};
            str_striderSy.([OGFPy_slow num2str(i_slow)]) = striderSy_align;
            str_striderSz.([OGFPz_slow num2str(i_slow)]) = striderSz_align;
            



            
%             h_slow = figure (trialData.metaData.condition*10-9)
%             hold on
%             plot(striderSy_align-LevelofInterest,'b')
%             if isempty(SBmax_align(i)) == 0 && isempty(SPmax_align(i)) == 0
%                 if  isempty(find(striderSy_align-LevelofInterest == SBmax_align(i))) || isempty(find(striderSy_align-LevelofInterest == SPmax_align(i)))
%                 else
%                     SBmax_ind(i_slow) = find(striderSy_align-LevelofInterest == SBmax_align(i));
%                     plot(SBmax_ind(i_slow),SBmax_align(i),'k*')
%                     SPmax_ind(i_slow) = find(striderSy_align-LevelofInterest == SPmax_align(i));
%                     plot(SPmax_ind(i_slow),SPmax_align(i),'k*')
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
%         SZ_align(i)=-1*nanmean(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'z']))/Normalizer;
%         SX_align(i)=nanmean(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'x']))/Normalizer;
%         SZmax_align(i)=-1*nanmin(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'z']))/Normalizer;
%         SXmax_align(i)=nanmin(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'x']))/Normalizer;

        SZ_align(i)=-1*nanmean(filteredSlow_align.getPartialDataAsATS([OGFPy_slow(1:end-1) 'z']).Data(:,1,i))/Normalizer;
        SX_align(i)=nanmean(filteredSlow_align.getPartialDataAsATS([OGFPy_slow(1:end-1) 'x']).Data(:,1,i))/Normalizer;
        SZmax_align(i)=-1*nanmin(filteredSlow_align.getPartialDataAsATS([OGFPy_slow(1:end-1) 'z']).Data(:,1,i))/Normalizer;
        SXmax_align(i)=nanmin(filteredSlow_align.getPartialDataAsATS([OGFPy_slow(1:end-1) 'x']).Data(:,1,i))/Normalizer;
        
        
        
    end
    
    %%Now for the fast leg...
    if isempty(striderFy_align) || all(striderFy_align==striderFy_align(1)) || isempty(FTO) || isempty(STO)
        
    else
        if nanstd(striderFy_align)<0.01 && nanmean(striderFy_align)<0.01 %This is to get rid of places where there is only noise and no data
            
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
            
            ImpactMagF_align=find((striderFy_align-LevelofInterest)==nanmax(striderFy_align(1:75)-LevelofInterest));%1:15
            if isempty(ImpactMagF_align)%~=1
                postImpactF_align=nf_align(find(nf_align>ImpactMagF_align(end), 1, 'first'));
                if isempty(postImpactF_align)%~=1
                    pf_align(find(pf_align<postImpactF_align))=[];
                    nf_align(find(nf_align<postImpactF_align))=[];
                end
            end
            
            if isempty(pf_align)
                
            else
                FP_align(i)=nanmean(striderFy_align(pf_align)-LevelofInterest);
                FPmax_align(i)=nanmax(striderFy_align(pf_align)-LevelofInterest);
            end
            if isempty(nf_align)
                
            else
                FB_align(i)=FlipB.*(nanmean(striderFy_align(nf_align)-LevelofInterest));
                FBmax_align(i)=FlipB.*(nanmin(striderFy_align(nf_align)-LevelofInterest));
            end
            
            if exist('postImpactF_align')==0 || isempty(postImpactF_align)==1
                
            else
                impactF_align(i)=nanmean(striderFy_align(find((striderFy_align(FHS-FHS+1: postImpactF_align)-LevelofInterest)>0)))-LevelofInterest;
                if isempty(striderFy_align(find((striderFy_align(FHS-FHS+1: postImpactF_align)-LevelofInterest)>0)))
                    
                else
                    impactFmax_align(i)=nanmax(striderFy_align(find((striderFy_align(FHS-FHS+1: postImpactF_align)-LevelofInterest)>0)))-LevelofInterest;
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
%             if isempty(FBmax_align(i)) == 0 && isempty(FPmax_align(i)) == 0
%                 if  isempty(find(striderFy_align-LevelofInterest == FBmax_align(i))) || isempty(find(striderFy_align-LevelofInterest == FPmax_align(i)))
%                 else
%                     FBmax_ind(i_fast) = find(striderFy_align-LevelofInterest == FBmax_align(i));
%                     plot(FBmax_ind(i_fast),FBmax_align(i),'k*')
%                     FPmax_ind(i_fast) = find(striderFy_align-LevelofInterest == FPmax_align(i));
%                     plot(FPmax_ind(i_fast),FPmax_align(i),'k*')
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
%         FZ_align(i)=-1*nanmean(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'z']))/Normalizer; %%[OGFPy_fast(1:end-1) 'z']
%         FX_align(i)=nanmean(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'x']))/Normalizer;
%         FZmax_align(i)=-1*nanmin(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'z']))/Normalizer;
%         FXmax_align(i)=nanmax(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'x']))/Normalizer;
        
        FZ_align(i)=-1*nanmean(filteredFast_align.getPartialDataAsATS([OGFPy_fast(1:end-1) 'z']).Data(:,1,i))/Normalizer;
        FX_align(i)=nanmean(filteredFast_align.getPartialDataAsATS([OGFPy_fast(1:end-1) 'x']).Data(:,1,i))/Normalizer;
        FZmax_align(i)=-1*nanmin(filteredFast_align.getPartialDataAsATS([OGFPy_fast(1:end-1) 'z']).Data(:,1,i))/Normalizer;
        FXmax_align(i)=nanmin(filteredFast_align.getPartialDataAsATS([OGFPy_fast(1:end-1) 'x']).Data(:,1,i))/Normalizer;
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% computing the parameters for adding all forces toghether %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isempty(striderSy_OGFP_sum) || all(striderSy_OGFP_sum==striderSy_OGFP_sum(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
        %This does nothing, as vars are initialized as nan:
        SBmax_OGFP_sum(i) = NaN;
        SPmax_OGFP_sum(i) = NaN;
    else
        if nanstd(striderSy_OGFP_sum)<0.01 && nanmean(striderSy_OGFP_sum)<0.01 %This is to get rid of places where there is only noise and no data
            
        else
            ns_OGFP_sum = find((striderSy_OGFP_sum-LevelofInterest)<0);%1:65
            ps_OGFP_sum = find((striderSy_OGFP_sum-LevelofInterest)>0);
            
            %             ImpactMagS_OGFP_sum = find((striderSy_OGFP_sum-LevelofInterest)==nanmax(striderSy_OGFP_sum(1:75)-LevelofInterest));%no longer percent of stride
            %             if isempty(ImpactMagS_OGFP_sum)~=1
            %                 postImpactS_OGFP_sum = ns_OGFP_sum(find(ns_OGFP_sum>ImpactMagS_OGFP_sum(end), 1, 'first'));
            %                 if isempty(postImpactS_OGFP_sum)~=1
            %                     ps_OGFP_sum(find(ps_OGFP_sum<postImpactS_OGFP_sum))=[];
            %                     ns_OGFP_sum(find(ns_OGFP_sum<postImpactS_OGFP_sum))=[];
            %                 end
            %             end
            
            if isempty(ns_OGFP_sum)
                SBmax_OGFP_sum(i) = NaN;
            else
                SB_OGFP_sum(i) = FlipB.*(nanmean(striderSy_OGFP_sum(ns_OGFP_sum)-LevelofInterest));
                SBmax_OGFP_sum(i) = FlipB.*(nanmin(striderSy_OGFP_sum(ns_OGFP_sum)-LevelofInterest));
            end
            if isempty(ps_OGFP_sum)
                SPmax_OGFP_sum(i)= NaN;
            else
                SP_OGFP_sum(i)=nanmean(striderSy_OGFP_sum(ps_OGFP_sum)-LevelofInterest);
                SPmax_OGFP_sum(i)=nanmax(striderSy_OGFP_sum(ps_OGFP_sum)-LevelofInterest);
            end
            
            if exist('postImpactS_OGFP_sum')==0 || isempty(postImpactS_OGFP_sum)==1 || isnan(SHS)
                %                     impactS(i)=NaN;
                %                     impactSmax(i)=NaN;
                impactSmax_OGFP_sum(i)= NaN;
            else
                impactS_OGFP_sum(i)=nanmean(striderSy_OGFP_sum(find((striderSy_OGFP_sum(SHS-SHS+1: postImpactS_OGFP_sum)-LevelofInterest)>0)))-LevelofInterest;
                if isempty(striderSy_OGFP_sum(find((striderSy_OGFP_sum(SHS-SHS+1: postImpactS_OGFP_sum)-LevelofInterest)>0)))
                    %impactSmax(i)=NaN;
                else
                    impactSmax_OGFP_sum(i)=nanmax(striderSy_OGFP_sum(find((striderSy_OGFP_sum(SHS-SHS+1: postImpactS_OGFP_sum)-LevelofInterest)>0)))-LevelofInterest;
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
        FBmax_OGFP_sum(i) = NaN;
        FPmax_OGFP_sum(i) = NaN;
    else
        if nanstd(striderFy_OGFP_sum)<0.01 && nanmean(striderFy_OGFP_sum)<0.01 %This is to get rid of places where there is only noise and no data
            
        else
            nf_OGFP_sum=find((striderFy_OGFP_sum-LevelofInterest)<0);%1:65
            pf_OGFP_sum=find((striderFy_OGFP_sum-LevelofInterest)>0);
            %             ImpactMagF_OGFP_sum=find((striderFy_OGFP_sum-LevelofInterest)==nanmax(striderFy_OGFP_sum(1:75)-LevelofInterest));%1:15
            %             if isempty(ImpactMagF_OGFP_sum)~=1
            %                 postImpactF_OGFP_sum=nf_OGFP_sum(find(nf_OGFP_sum>ImpactMagF_OGFP_sum(end), 1, 'first'));
            %                 if isempty(postImpactF_OGFP_sum)~=1
            %                     pf_OGFP_sum(find(pf_OGFP_sum<postImpactF_OGFP_sum))=[];
            %                     nf_OGFP_sum(find(nf_OGFP_sum<postImpactF_OGFP_sum))=[];
            %                 end
            %             end
            
            if isempty(pf_OGFP_sum)
                FPmax_OGFP_sum(i)= NaN;
            else
                FP_OGFP_sum(i)=nanmean(striderFy_OGFP_sum(pf_OGFP_sum)-LevelofInterest);
                FPmax_OGFP_sum(i)=nanmax(striderFy_OGFP_sum(pf_OGFP_sum)-LevelofInterest);
            end
            if isempty(nf_OGFP_sum)
                FBmax_OGFP_sum(i)= NaN;
            else
                FB_OGFP_sum(i)=FlipB.*(nanmean(striderFy_OGFP_sum(nf_OGFP_sum)-LevelofInterest));
                FBmax_OGFP_sum(i)=FlipB.*(nanmin(striderFy_OGFP_sum(nf_OGFP_sum)-LevelofInterest));
            end
            
            if exist('postImpactF_OGFP_sum')==0 || isempty(postImpactF_OGFP_sum)==1 || isnan(FHS)==1
                impactFmax_OGFP_sum(i) = NaN;
            else
                impactF_OGFP_sum(i)=nanmean(striderFy_OGFP_sum(find((striderFy_OGFP_sum(FHS-FHS+1: postImpactF_OGFP_sum)-LevelofInterest)>0)))-LevelofInterest;
                if isempty(striderFy_OGFP_sum(find((striderFy_OGFP_sum(FHS-FHS+1: postImpactF_OGFP_sum)-LevelofInterest)>0)))
                    
                else
                    impactFmax_OGFP_sum(i)=nanmax(striderFy_OGFP_sum(find((striderFy_OGFP_sum(FHS-FHS+1: postImpactF_OGFP_sum)-LevelofInterest)>0)))-LevelofInterest;
                end
            end
            
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% computing the parameters for each of the overground force-plates %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for j = 1:length(Ally)
        if isempty(striderSy_OGFP.(Ally{j})) || all(striderSy_OGFP.(Ally{j})==striderSy_OGFP.(Ally{j})(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
            %This does nothing, as vars are initialized as nan:
        else
            if nanstd(striderSy_OGFP.(Ally{j}))<0.01 && nanmean(striderSy_OGFP.(Ally{j}))<0.01 %This is to get rid of places where there is only noise and no data
                
            else
                ns_OGFP.(Ally{j}) = find((striderSy_OGFP.(Ally{j})-LevelofInterest)<0);%1:65
                ps_OGFP.(Ally{j}) = find((striderSy_OGFP.(Ally{j})-LevelofInterest)>0);
                
                ImpactMagS_OGFP.(Ally{j}) = find((striderSy_OGFP.(Ally{j})-LevelofInterest)==nanmax(striderSy_OGFP.(Ally{j})(1:75)-LevelofInterest));%no longer percent of stride
                if isempty(ImpactMagS_OGFP.(Ally{j})) ~= 1
                    postImpactS_OGFP.(Ally{j})=ns_OGFP.(Ally{j})(find(ns_OGFP.(Ally{j}) > ImpactMagS_OGFP.(Ally{j})(end), 1, 'first'));
                    if isempty(postImpactS_OGFP.(Ally{j}))~=1
                        ps_OGFP.(Ally{j})(find(ps_OGFP.(Ally{j})<postImpactS_OGFP.(Ally{j})))=[];
                        ns_OGFP.(Ally{j})(find(ns_OGFP.(Ally{j})<postImpactS_OGFP.(Ally{j})))=[];
                    end
                end
                
                if isempty(ns_OGFP.(Ally{j}))
                    
                else
                    SB_OGFP.(Ally{j})(i)=FlipB.*(nanmean(striderSy_OGFP.(Ally{j})(ns_OGFP.(Ally{j}))-LevelofInterest));
                    SBmax_OGFP.(Ally{j})(i)=FlipB.*(nanmin(striderSy_OGFP.(Ally{j})(ns_OGFP.(Ally{j}))-LevelofInterest));
                end
                if isempty(ps_OGFP.(Ally{j}))
                    
                else
                    SP_OGFP.(Ally{j})(i)=nanmean(striderSy_OGFP.(Ally{j})(ps_OGFP.(Ally{j}))-LevelofInterest);
                    SPmax_OGFP.(Ally{j})(i)=nanmax(striderSy_OGFP.(Ally{j})(ps_OGFP.(Ally{j}))-LevelofInterest);
                end
                
                if exist(['postImpactS_OGFP.' Ally{j}])==0 || isempty(postImpactS_OGFP.(Ally{j}))==1
                    %                     impactS(i)=NaN;
                    %                     impactSmax(i)=NaN;
                else
                    impactS_OGFP.(Ally{j})(i)=nanmean(striderSy_OGFP.(Ally{j})(find((striderSy_OGFP.(Ally{j})(SHS-SHS+1: postImpactS_OGFP.(Ally{j}))-LevelofInterest)>0)))-LevelofInterest;
                    if isempty(striderSy_OGFP.(Ally{j})(find((striderSy_OGFP.(Ally{j})(SHS-SHS+1: postImpactS_OGFP.(Ally{j}))-LevelofInterest)>0)))
                        %impactSmax(i)=NaN;
                    else
                        impactSmax_OGFP.(Ally{j})(i)=nanmax(striderSy_OGFP.(Ally{j})(find((striderSy_OGFP.(Ally{j})(SHS-SHS+1: postImpactS_OGFP.(Ally{j}))-LevelofInterest)>0)))-LevelofInterest;
                    end
                end
            end
            SZ_OGFP.(Ally{j})(i)=-1*nanmean(filteredSlowStance.getDataAsVector([Ally{j}(1:end-1) 'z']))/Normalizer;
            SX_OGFP.(Ally{j})(i)=nanmean(filteredSlowStance.getDataAsVector([Ally{j}(1:end-1) 'x']))/Normalizer;
            SZmax_OGFP.(Ally{j})(i)=-1*nanmin(filteredSlowStance.getDataAsVector([Ally{j}(1:end-1) 'z']))/Normalizer;
            SXmax_OGFP.(Ally{j})(i)=nanmin(filteredSlowStance.getDataAsVector([Ally{j}(1:end-1) 'x']))/Normalizer;
        end
        
        %%Now for the fast leg...
        if isempty(striderFy_OGFP.(Ally{j})) || all(striderFy_OGFP.(Ally{j})==striderFy_OGFP.(Ally{j})(1)) || isempty(FTO) || isempty(STO)
            
        else
            if nanstd(striderFy_OGFP.(Ally{j}))<0.01 && nanmean(striderFy_OGFP.(Ally{j}))<0.01 %This is to get rid of places where there is only noise and no data
                
            else
                nf_OGFP.(Ally{j}) = find((striderFy_OGFP.(Ally{j})-LevelofInterest)<0);%1:65
                pf_OGFP.(Ally{j}) = find((striderFy_OGFP.(Ally{j})-LevelofInterest)>0);
                ImpactMagF_OGFP.(Ally{j}) = find((striderFy_OGFP.(Ally{j})-LevelofInterest)==nanmax(striderFy_OGFP.(Ally{j})(1:75)-LevelofInterest));%1:15
                if isempty(ImpactMagF_OGFP.(Ally{j}))~=1
                    postImpactF_OGFP.(Ally{j}) = nf_OGFP.(Ally{j})(find(nf_OGFP.(Ally{j})>ImpactMagF_OGFP.(Ally{j})(end), 1, 'first'));
                    if isempty(postImpactF_OGFP.(Ally{j}))~=1
                        pf_OGFP.(Ally{j})(find(pf_OGFP.(Ally{j}) < postImpactF_OGFP.(Ally{j})))=[];
                        nf_OGFP.(Ally{j})(find(nf_OGFP.(Ally{j}) < postImpactF_OGFP.(Ally{j})))=[];
                    end
                end
                
                if isempty(pf_OGFP.(Ally{j}))
                    
                else
                    FP_OGFP.(Ally{j})(i)=nanmean(striderFy_OGFP.(Ally{j})(pf_OGFP.(Ally{j}))-LevelofInterest);
                    FPmax_OGFP.(Ally{j})(i)=nanmax(striderFy_OGFP.(Ally{j})(pf_OGFP.(Ally{j}))-LevelofInterest);
                end
                if isempty(nf_OGFP.(Ally{j}))
                    
                else
                    FB_OGFP.(Ally{j})(i)=FlipB.*(nanmean(striderFy_OGFP.(Ally{j})(nf_OGFP.(Ally{j}))-LevelofInterest));
                    FBmax_OGFP.(Ally{j})(i)=FlipB.*(nanmin(striderFy_OGFP.(Ally{j})(nf_OGFP.(Ally{j}))-LevelofInterest));
                end
                
                if exist(['postImpactF_OGFP.' Ally{j}])==0 || isempty(postImpactF_OGFP.(Ally{j}))==1
                    
                else
                    impactF_OGFP.(Ally{j})(i)=nanmean(striderFy_OGFP.(Ally{j})(find((striderFy_OGFP.(Ally{j})(FHS-FHS+1: postImpactF_OGFP.(Ally{j}))-LevelofInterest)>0)))-LevelofInterest;
                    if isempty(striderFy_OGFP.(Ally{j})(find((striderFy_OGFP.(Ally{j})(FHS-FHS+1: postImpactF_OGFP.(Ally{j}))-LevelofInterest)>0)))
                        
                    else
                        impactFmax_OGFP.(Ally{j})(i)=nanmax(striderFy_OGFP.(Ally{j})(find((striderFy_OGFP.(Ally{j})(FHS-FHS+1: postImpactF_OGFP.(Ally{j}))-LevelofInterest)>0)))-LevelofInterest;
                    end
                end
            end
            FZ_OGFP.(Ally{j})(i)=-1*nanmean(filteredFastStance.getDataAsVector([Ally{j}(1:end-1) 'z']))/Normalizer;
            FX_OGFP.(Ally{j})(i)=nanmean(filteredFastStance.getDataAsVector([Ally{j}(1:end-1) 'x']))/Normalizer;
            FZmax_OGFP.(Ally{j})(i)=-1*nanmin(filteredFastStance.getDataAsVector([Ally{j}(1:end-1) 'z']))/Normalizer;
            FXmax_OGFP.(Ally{j})(i)=nanmax(filteredFastStance.getDataAsVector([Ally{j}(1:end-1) 'x']))/Normalizer;
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
%     %         plot(str_striderSy.([OGFPy_slowi{i} num2str(i)]),'Color',(255-i)/255*[i/255,i/255,1])
%     %     elseif i > i_slow/2 && i_slow < 2*255
%     %         plot(str_striderSy.([OGFPy_slowi{i} num2str(i)]),'Color',(255-i_slow+i)/255*[1,i/255,i/255])
%     %     else
%     %         plot(str_striderSy.([OGFPy_slowi{i} num2str(i)]),'Color',[0,0,0])
%     %     end
%     if trialNum == 1 || trialNum == 4 || trialNum == 8 || trialNum == 11 %i<= i_slow/2
%         plot(str_striderSy.([OGFPy_slowi{i} num2str(i)]),'Color',[0,0,1])
%     elseif trialNum == 3 || trialNum == 6 || trialNum == 10 || trialNum == 13
%         plot(str_striderSy.([OGFPy_slowi{i} num2str(i)]),'Color',[1,0,0])
%     else
%         plot(str_striderSy.([OGFPy_slowi{i} num2str(i)]),'Color',[0,0,0])
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
%         plot(str_striderSz.([OGFPz_slowi{i} num2str(i)]),'k')
%     else
%         plot(str_striderSz.([OGFPz_slowi{i} num2str(i)]),'k')
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
%         plot(str_striderFy.([OGFPy_fasti{i} num2str(i)]),'b')
%     elseif trialNum == 3 || trialNum == 6 || trialNum == 10 || trialNum == 13
%         plot(str_striderFy.([OGFPy_fasti{i} num2str(i)]),'r')
%     else
%         plot(str_striderFy.([OGFPy_fasti{i} num2str(i)]),'k')
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
%         plot(str_striderFz.([OGFPz_fasti{i} num2str(i)]),'b')
%     else
%         plot(str_striderFz.([OGFPz_fasti{i} num2str(i)]),'r')
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

for j = 1:length(Ally)
    
    data_OGFP_temp = [[SBmax_OGFP.(Ally{j}) NaN]' [SPmax_OGFP.(Ally{j}) NaN]' [FBmax_OGFP.(Ally{j}) NaN]' [FPmax_OGFP.(Ally{j}) NaN]'];
    labels_OGFP_temp = {['FyBSmax_align_' Ally{j}], ['FyPSmax_align_' Ally{j}], ['FyBFmax_align_' Ally{j}], ['FyPFmax_align_' Ally{j}]};
    description_OGFP_temp = {[Ally{j} 'GRF-FYs max signed braking'], [Ally{j} 'GRF-FYs max signed propulsion'], [Ally{j} 'GRF-FYf max signed braking'], [Ally{j} 'GRF-FYf max signed propulsion']};
    
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
out = parameterSeries(data_align,labels_align,[],description_align);

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

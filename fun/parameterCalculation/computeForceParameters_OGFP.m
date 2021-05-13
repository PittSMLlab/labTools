function [out] = computeForceParameters_OGFP(strideEvents,GRFData,slowleg, fastleg,BW, trialData, markerData)
% CJS 2017: Here I am including the code that I have been using for the incline decline analysis.
% This code is a bit eccentric in the way that identifies the inclination for the TM.

%~~~~~~~ Here is where I am putting real stuffs ~~~~~~~~
trial=trialData.metaData.description;
%If I want all the forces to be unitless then set this to 9.81*BW, else set it
%to 1*BW
Normalizer=9.81*BW;
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
if strcmp(trialData.metaData.type, 'IN')
    ang = 8.5;
end
flipIT= 2.*(ang >= 0)-1; %This will be -1 when it was a decline study, 1 otherwise
Filtered=GRFData.lowPassFilter(20);
FilteredF = Filtered;
FilteredS = Filtered;


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

Allz = {'FP4Fz','FP5Fz','FP6Fz','FP7Fz','LFz','RFz'};
Ally = {'FP4Fy','FP5Fy','FP6Fy','FP7Fy','LFy','RFy'};
OGFPy_names = {'FP4Fy','FP5Fy','FP6Fy','FP7Fy'};
OGFPz_names = {'FP4Fz','FP5Fz','FP6Fz','FP7Fz'};


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

% pre-defining variables
lenny=length(strideEvents.tSHS)-1;
impactS_all=NaN(1, lenny); impactF_all=NaN(1, lenny);
SB_all=NaN(1, lenny); SP_all=NaN(1, lenny); SZ_all=NaN(1, lenny); SX_all=NaN(1, lenny);
FB_all=NaN(1, lenny); FP_all=NaN(1, lenny); FZ_all=NaN(1, lenny); FX_all=NaN(1, lenny);
HandrailHolding=NaN(1, lenny);
SBmax_all=NaN(1, lenny); SPmax_all=NaN(1, lenny); SZmax_all=NaN(1, lenny); SXmax_all=NaN(1, lenny);
impactSmax_all=NaN(1, lenny); impactFmax_all=NaN(1, lenny);
FBmax_all=NaN(1, lenny); FPmax_all=NaN(1, lenny); FZmax_all=NaN(1, lenny); FXmax_all=NaN(1, lenny);

for j = 1:length(Ally)
    impactS_OGFP.(Ally{j}) = NaN(1, lenny); impactF_OGFP.(Ally{j}) = NaN(1, lenny);
    SB_OGFP.(Ally{j}) = NaN(1, lenny); SP_OGFP.(Ally{j}) = NaN(1, lenny); SZ_OGFP.(Ally{j}) = NaN(1, lenny); SX_OGFP.(Ally{j}) = NaN(1, lenny);
    FB_OGFP.(Ally{j}) = NaN(1, lenny); FP_OGFP.(Ally{j}) = NaN(1, lenny); FZ_OGFP.(Ally{j}) = NaN(1, lenny); FX_OGFP.(Ally{j}) = NaN(1, lenny);
    SBmax_OGFP.(Ally{j}) = NaN(1, lenny); SPmax_OGFP.(Ally{j}) = NaN(1, lenny); SZmax_OGFP.(Ally{j}) = NaN(1, lenny); SXmax_OGFP.(Ally{j}) = NaN(1, lenny);
    impactSmax_OGFP.(Ally{j}) = NaN(1, lenny); impactFmax_OGFP.(Ally{j}) = NaN(1, lenny);
    FBmax_OGFP.(Ally{j}) = NaN(1, lenny); FPmax_OGFP.(Ally{j}) = NaN(1, lenny); FZmax_OGFP.(Ally{j}) = NaN(1, lenny);FXmax_OGFP.(Ally{j}) = NaN(1, lenny);
end

i_slow = 0; i_fast = 0;
SlowCount_force = 0; SlowCount_no_force = 0;
FastCount_force = 0; FastCount_no_force = 0;

for i=1:length(strideEvents.tSHS)-1
    % get the filtered data for the slow and fast stance phases
    filteredSlowStance = FilteredS.split(SHS, STO);
    filteredFastStance = FilteredF.split(FHS, FTO2);

    % get the filtered data for the slow and fast single stance phases
    filteredSlowSingleStance = FilteredS.split(FTO, FHS);
    filteredFastSingleStance = FilteredF.split(STO, SHS2);
    
    % Getting the events
    SHS=strideEvents.tSHS(i); FTO=strideEvents.tFTO(i); FHS=strideEvents.tFHS(i); STO=strideEvents.tSTO(i); SHS2=strideEvents.tSHS2(i); FTO2=strideEvents.tFTO2(i);
    
    if isnan(SHS) || isnan(STO) % make sure the slow events are not empty
        striderSy_all = []; striderSz_all = [];
        for j = 1:length(Ally)
            striderSy_OGFP.(Ally{j}) = [];
            striderSy_OGFP_SS.(Ally{j}) = [];
            
            striderSy_OGFP.(Allz{j}) = [];
            striderSy_OGFP_SS.(Allz{j}) = [];
        end
        striderSy_OGFP_sum = []; striderSz_OGFP_sum = [];
        exist_SlowF(i) = 0;
        
    else %FILTERING
        striderSy_OGFP_sum = 0; striderSz_OGFP_sum = 0;
        
        for j = 1:length(Ally)
            % getting each force-plate value during stance
            striderSy_OGFP.(Ally{j}) = flipIT.*filteredSlowStance.getDataAsVector(Ally{j})/Normalizer;
            striderSz_OGFP.(Allz{j}) = flipIT.*filteredSlowStance.getDataAsVector(Allz{j})/Normalizer;
            
            % getting each force-plate value during single stance
            striderSy_OGFP_SS.(Ally{j}) = flipIT.*filteredSlowSingleStance.getDataAsVector(Ally{j})/Normalizer;
            striderSz_OGFP_SS.(Allz{j}) = flipIT.*filteredSlowSingleStance.getDataAsVector(Allz{j})/Normalizer;
            % adding all forces together
            striderSy_OGFP_sum = striderSy_OGFP_sum + striderSy_OGFP_SS.(Ally{j});
            striderSz_OGFP_sum = striderSz_OGFP_sum + striderSz_OGFP_SS.(Allz{j});
%                         figure()
%                         plot(striderSy_OGFP.(Ally{j}))
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
        
        slow_divider = floor(length(striderSz_OGFP.('LFz'))/divideri);
        good_counter = 0; OGFPy_slow = [];
        for j = 1:length(Allz)
            if isempty(striderSz_OGFP.(Allz{j})) == 0
%                 mini_1st.(Allz{j}) = abs(min(striderSz_OGFP.(Allz{j})(1:end)));
                mini_1st.(Allz{j}) = abs(min(striderSz_OGFP.(Allz{j})(slow_divider:slow_divider*3)));
                mini_2nd.(Allz{j}) = abs(min(striderSz_OGFP.(Allz{j})(slow_divider*5:slow_divider*7)));
                
                if mini_1st.(Allz{j}) >= bw_th_min && mini_2nd.(Allz{j}) >= bw_th_min && abs(striderSz_OGFP.(Allz{j})(1)) <= early_th && abs(striderSz_OGFP.(Allz{j})(end)) <= end_th
                    OGFPy_slow = Ally{j}; OGFPz_slow = Allz{j}; good_counter = good_counter + 1;
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
                
                if strcmp(trialData.metaData.name,'adaptation') && nanmean(striderSy_all) < 0
                    striderSy_all = -striderSy_all;
                    striderSy_OGFP_SS.(OGFPy_slow) = -striderSy_OGFP_SS.(OGFPy_slow);
                end
            end
        else
            striderSy_all=[]; striderSz_all = [];
        end
    end
    
    if isnan(FHS) || isnan(FTO2) % make sure the slow events are not empty
        striderFy_all = []; striderFz_all = [];
        for j = 1:length(Ally)
            striderFy_OGFP.(Ally{j}) = [];
        end
        striderFy_OGFP_sum = []; striderFz_OGFP_sum = [];
        exist_FastF(i) = 0;
    else %FILTERING
        striderFy_OGFP_sum = 0; striderFz_OGFP_sum = 0;
        
        for j = 1:length(Ally)
            
            striderFy_OGFP.(Ally{j}) = flipIT.*filteredFastStance.getDataAsVector(Ally{j})/Normalizer;
            striderFz_OGFP.(Allz{j}) = flipIT.*filteredFastStance.getDataAsVector(Allz{j})/Normalizer;
            
            striderFy_OGFP_SS.(Ally{j}) = flipIT.*filteredFastSingleStance.getDataAsVector(Ally{j})/Normalizer;
            striderFz_OGFP_SS.(Allz{j}) = flipIT.*filteredFastSingleStance.getDataAsVector(Allz{j})/Normalizer;
            
            striderFy_OGFP_sum = striderFy_OGFP_sum + striderFy_OGFP_SS.(Ally{j});
            striderFz_OGFP_sum = striderFz_OGFP_sum + striderFz_OGFP_SS.(Allz{j});
            
%             [alignedTS,originalDurations] = stridedTSToAlignedTS(filteredFastStance,100) 
%             
%             filteredFastStance.stridedTSToAlignedTS(100);
%             filteredFastStance.align(gaitEvents,{'FHS','SHS2'},[15,30]);
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
        
        midway_fast = floor(length(striderFz_OGFP.('LFz'))/divideri);
        good_counter = 0; OGFPy_fast = [];
        for j = 1:length(Allz)
            if isempty(striderFz_OGFP.(Allz{j})) == 0
%                 mini_1st.(Allz{j}) = abs(min(striderFz_OGFP.(Allz{j})(1:end)));
                mini_1st.(Allz{j}) = abs(min(striderFz_OGFP.(Allz{j})(midway_fast:midway_fast*3)));
                mini_2nd.(Allz{j}) = abs(min(striderFz_OGFP.(Allz{j})(midway_fast*5:midway_fast*7)));
                
                if mini_1st.(Allz{j}) >= bw_th_min && mini_2nd.(Allz{j}) >= bw_th_min && abs(striderFz_OGFP.(Allz{j})(1)) <= early_th && abs(striderFz_OGFP.(Allz{j})(end)) <= end_th
                    OGFPy_fast = Ally{j}; OGFPz_fast = Allz{j}; good_counter = good_counter + 1;
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
        HandrailHolding(i)= .05 < sqrt(nanmean(sum(handrailData.split(SHS, SHS2).Data.^2,2)))/Normalizer;
    else
        HandrailHolding(i)=NaN;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% computing the parameters for the force plate that a good stance occures %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if isempty(striderSy_all) || all(striderSy_all==striderSy_all(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
        %This does nothing, as vars are initialized as nan:
    else
        if nanstd(striderSy_all)<0.01 && nanmean(striderSy_all)<0.01 %This is to get rid of places where there is only noise and no data
            
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
                
                
                ns_all(find(ns_all>=0.5*length(striderSy_all)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
                ps_all(find(ps_all<=0.5*length(striderSy_all)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
                
                ns_all(find(ns_all<=0.12*length(striderSy_all)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
                ps_all(find(ps_all>=0.95*length(striderSy_all)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
%             end
            
            ImpactMagS_all = find((striderSy_all-LevelofInterest)==nanmax(striderSy_all(1:75)-LevelofInterest));%no longer percent of stride
            if isempty(ImpactMagS_all)%~=1
                postImpactS_all = ns_all(find(ns_all>ImpactMagS_all(end), 1, 'first'));
                if isempty(postImpactS_all)%~=1
                    ps_all(find(ps_all<postImpactS_all))=[];
                    ns_all(find(ns_all<postImpactS_all))=[];
                end
            end
            
            if isempty(ns_all)
                
            else
                SB_all(i) = FlipB.*(nanmean(striderSy_all(ns_all)-LevelofInterest));
                SBmax_all(i) = FlipB.*(nanmin(striderSy_all(ns_all)-LevelofInterest));
            end
            if isempty(ps_all)
                
            else
                SP_all(i)=nanmean(striderSy_all(ps_all)-LevelofInterest);
                SPmax_all(i)=nanmax(striderSy_all(ps_all)-LevelofInterest);
            end
            
            if exist('postImpactS_all')==0 || isempty(postImpactS_all)==1
                %                     impactS(i)=NaN;
                %                     impactSmax(i)=NaN;
            else
                impactS_all(i)=nanmean(striderSy_all(find((striderSy_all(SHS-SHS+1: postImpactS_all)-LevelofInterest)>0)))-LevelofInterest;
                if isempty(striderSy_all(find((striderSy_all(SHS-SHS+1: postImpactS_all)-LevelofInterest)>0)))
                    %impactSmax(i)=NaN;
                else
                    impactSmax_all(i)=nanmax(striderSy_all(find((striderSy_all(SHS-SHS+1: postImpactS_all)-LevelofInterest)>0)))-LevelofInterest;
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
%             if isempty(SBmax_all(i)) == 0 && isempty(SPmax_all(i)) == 0
%                 if  isempty(find(striderSy_all-LevelofInterest == SBmax_all(i))) || isempty(find(striderSy_all-LevelofInterest == SPmax_all(i)))
%                 else
%                     SBmax_ind(i_slow) = find(striderSy_all-LevelofInterest == SBmax_all(i));
%                     plot(SBmax_ind(i_slow),SBmax_all(i),'k*')
%                     SPmax_ind(i_slow) = find(striderSy_all-LevelofInterest == SPmax_all(i));
%                     plot(SPmax_ind(i_slow),SPmax_all(i),'k*')
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
        SZ_all(i)=-1*nanmean(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'z']))/Normalizer;
        SX_all(i)=nanmean(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'x']))/Normalizer;
        SZmax_all(i)=-1*nanmin(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'z']))/Normalizer;
        SXmax_all(i)=nanmin(filteredSlowStance.getDataAsVector([OGFPy_slow(1:end-1) 'x']))/Normalizer;
    end
    
    %%Now for the fast leg...
    if isempty(striderFy_all) || all(striderFy_all==striderFy_all(1)) || isempty(FTO) || isempty(STO)
        
    else
        if nanstd(striderFy_all)<0.01 && nanmean(striderFy_all)<0.01 %This is to get rid of places where there is only noise and no data
            
        else
            nf_all=find((striderFy_all-LevelofInterest)<0.1);%1:65
            pf_all=find((striderFy_all-LevelofInterest)>0);
            
%             if strcmp(trialData.metaData.name,'adaptation')
%                 nf_all(find(nf_all>=0.5*length(striderFy_all)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
%                 pf_all(find(pf_all<=0.5*length(striderFy_all)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
%                 
%                 nf_all(find(nf_all<=0.12*length(striderFy_all)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
%                 pf_all(find(pf_all>=0.95*length(striderFy_all)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
%                 
%             else
                
                
                nf_all(find(nf_all>=0.5*length(striderFy_all)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
                pf_all(find(pf_all<=0.5*length(striderFy_all)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
                
                nf_all(find(nf_all<=0.12*length(striderFy_all)))=[]; % 2/14/2018 -- This is to prevent us from identifiying the tail end of the trace as teh braking force 4/11/2017 CJS
                pf_all(find(pf_all>=0.95*length(striderFy_all)))=[]; % 2/14/2018 -- This is to prevent the impulse from being identified.
%             end
            
            ImpactMagF_all=find((striderFy_all-LevelofInterest)==nanmax(striderFy_all(1:75)-LevelofInterest));%1:15
            if isempty(ImpactMagF_all)%~=1
                postImpactF_all=nf_all(find(nf_all>ImpactMagF_all(end), 1, 'first'));
                if isempty(postImpactF_all)%~=1
                    pf_all(find(pf_all<postImpactF_all))=[];
                    nf_all(find(nf_all<postImpactF_all))=[];
                end
            end
            
            if isempty(pf_all)
                
            else
                FP_all(i)=nanmean(striderFy_all(pf_all)-LevelofInterest);
                FPmax_all(i)=nanmax(striderFy_all(pf_all)-LevelofInterest);
            end
            if isempty(nf_all)
                
            else
                FB_all(i)=FlipB.*(nanmean(striderFy_all(nf_all)-LevelofInterest));
                FBmax_all(i)=FlipB.*(nanmin(striderFy_all(nf_all)-LevelofInterest));
            end
            
            if exist('postImpactF_all')==0 || isempty(postImpactF_all)==1
                
            else
                impactF_all(i)=nanmean(striderFy_all(find((striderFy_all(FHS-FHS+1: postImpactF_all)-LevelofInterest)>0)))-LevelofInterest;
                if isempty(striderFy_all(find((striderFy_all(FHS-FHS+1: postImpactF_all)-LevelofInterest)>0)))
                    
                else
                    impactFmax_all(i)=nanmax(striderFy_all(find((striderFy_all(FHS-FHS+1: postImpactF_all)-LevelofInterest)>0)))-LevelofInterest;
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
%             if isempty(FBmax_all(i)) == 0 && isempty(FPmax_all(i)) == 0
%                 if  isempty(find(striderFy_all-LevelofInterest == FBmax_all(i))) || isempty(find(striderFy_all-LevelofInterest == FPmax_all(i)))
%                 else
%                     FBmax_ind(i_fast) = find(striderFy_all-LevelofInterest == FBmax_all(i));
%                     plot(FBmax_ind(i_fast),FBmax_all(i),'k*')
%                     FPmax_ind(i_fast) = find(striderFy_all-LevelofInterest == FPmax_all(i));
%                     plot(FPmax_ind(i_fast),FPmax_all(i),'k*')
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
        FZ_all(i)=-1*nanmean(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'z']))/Normalizer; %%[OGFPy_fast(1:end-1) 'z']
        FX_all(i)=nanmean(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'x']))/Normalizer;
        FZmax_all(i)=-1*nanmin(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'z']))/Normalizer;
        FXmax_all(i)=nanmax(filteredFastStance.getDataAsVector([OGFPy_fast(1:end-1) 'x']))/Normalizer;
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

for j = 1:length(Ally)
    
    data_OGFP_temp = [[SBmax_OGFP.(Ally{j}) NaN]' [SPmax_OGFP.(Ally{j}) NaN]' [FBmax_OGFP.(Ally{j}) NaN]' [FPmax_OGFP.(Ally{j}) NaN]'];
    labels_OGFP_temp = {['FyBSmax_' Ally{j}], ['FyPSmax_' Ally{j}], ['FyBFmax_' Ally{j}], ['FyPFmax_' Ally{j}]};
    description_OGFP_temp = {[Ally{j} 'GRF-FYs max signed braking'], [Ally{j} 'GRF-FYs max signed propulsion'], [Ally{j} 'GRF-FYf max signed braking'], [Ally{j} 'GRF-FYf max signed propulsion']};
    
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
    labels_all=[labels_all outCOM.labels outCOP.labels];
    description_all=[description_all outCOM.description outCOP.description];
end

%out = parameterSeries(data_OGFP,labels_OGFP,[],description_OGFP);
out = parameterSeries(data_all,labels_all,[],description_all);

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
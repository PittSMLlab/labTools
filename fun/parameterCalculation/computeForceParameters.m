function [out] = computeForceParameters(strideEvents,GRFData,slowleg, fastleg,BW, trialData, markerData, subData, FyPSat)
% computeForceParameters -- analyzes kinetic treadmill data
%   inital reprocessing and any reprocessing will again analyze the kinetic
%   data.  Analysis is mostly focused on the anterior-posterior forces
%   which is the focus of the (Sombric et al. 2019) and (Sombric et. al
%   2020) papers.
    
%% Labels and descriptions:
aux={'TMAngle',             'Angle I think the study was run at';...
    'WalkingDirection',     'Identified as a decline trial with subjects walking backwards';...
    'FyBS',                 'GRF-FYs average signed braking';...
    'FyPS',                 'GRF-FYs average signed propulsion';...
    'FyBF',                 'GRF-FYf average signed braking';...
    'FyPF',                 'GRF-FYf average signed propulsion';...
    'FyBSym',               'GRF-FYs average signed Symmetry braking';...
    'FyPSym',               'GRF-FYs average signed Symmetry propulsion';...
    'FxS',                  'GRF-Fxs average force';...
    'FzS',                  'GRF-Fzs average force';...
    'FxF',                  'GRF-Fxf average force';...
    'FzF',                  'GRF-Fzf average force';... 
    'HandrailHolding',      'Handrail was being held onto';...
    'ImpactMagS',           'Max anterior-posterior impact force of the slow leg';... 
    'ImpactMagF',           'Max anterior-posterior impact force of the fast leg';...
    'FyBSmax',              'GRF-FYs max signed braking';...
    'FyPSmax',              'GRF-FYs max signed propulsion';...
    'FyBFmax',              'GRF-FYf max signed braking';...
    'FyPFmax',              'GRF-FYf max signed propulsion';...
    'FyBmaxSym',            'GRF-FYs max signed Symmetry braking (fast-slow)';...
    'FyPmaxSym',            'GRF-FYs max signed Symmetry propulsion (fast-slow)';...
    'FyBmaxRatio',          'GRF-FYs max signed Ratio braking (s/f)';... 
    'FyPmaxRatio',          'GRF-FYs max signed Ratio propulsion (s/f)';...
    'FyBmaxSymNorm',        'GRF-FYs max signed Normalized Ratio braking (abs(fast)-abs(slow))/(abs(fast)+abs(slow))';... 
    'FyPmaxSymNorm',        'GRF-FYs max signed Normalized Ratio propulsion (abs(fast)-abs(slow))/(abs(fast)+abs(slow))';...
    'FyBFmaxPer',             'Fast max Braking Percent';...
    'FyBSmaxPer',             'Slow max Braking Percent';...
    'FyPFmaxPer',             'Fast max Propulsion Percent';...
    'FyPSmaxPer',             'Slow max Propulsion Percent';...
    'Slow_Ipsi_FySym',      '[FyBSmax+FyPSmax]';...
    'Fast_Ipsi_FySym',      '[FyBFmax+FyPFmax]';...
    'SlowB_Contra_FySym',   '[FyBSmax+FyPFmax]';...
    'FastB_Contra_FySym',   '[FyBFmax+FyPSmax]';...
    'FyPSsum',                'Summed time normalized slow propulsion force';...
    'FyPFsum',                'Summed time normalized fast propulsion force';...
    'FyBSsum',                'Summed slow braking';... 
    'FyBFsum',                'Summed Fast braking';...
    'FxSmax',               'GRF-Fxs max force';... 
    'FzSmax',               'GRF-Fzs max force';...
    'FxFmax',               'GRF-Fxf max force';...
    'FzFmax',               'GRF-Fzf max force';...
    'FyBFmax_ABS',            'FyBFmax_ABS';...
    'FyBSmax_ABS',            'FyBSmax_ABS';...
    }; 
 
paramLabels=aux(:,1);
description=aux(:,2);
    
%% Gather initial information on the trial and do a preliminary filtering of the data

%Get the trial description because this has info on inclination
trial=trialData.description;

%If I want all the forces to be unitless then set this to 9.81*BW, else set it
%to 1*BW
Normalizer=9.81*BW;

FlipB=1; %7/21/2016, nevermind, making 1 8/1/2016 -- May want to change if you want braking magnitudes

if iscell(trial)
    trial=trial{1};
end

% If we identify that subjects are walking decline and thus backwards.
[ ang ] = DetermineTMAngle( trialData );
if strfind(lower(subData.ID), 'decline')% Decline are walking backwards on the treadmill 
    flipIT=-1;
else
    flipIT=1;
end

%Filter forces a bit before we get started
Filtered=GRFData.lowPassFilter(20);

%~~~~~~~~~~~~~~~~ REMOVE ANY OFFSETS IN THE DATA~~~~~~~~~~~~~~~~~~~~~~~~~~~
%New 8/5/2016 CJS: It came to my attenion that one of the decline subjects
%(LD30) one of the force plates was not properly zeroed.  Here I am
%manually shifting the forces.  I am assuming that the vertical forces have
%been properly been shifted during the c3d2mat process, otherwise the
%events are wrong and these lines of code will not save you. rats

%figure; plot(Filtered.getDataAsTS([s 'Fy']).Data, 'b'); hold on; plot(Filtered.getDataAsTS([f 'Fy']).Data, 'r');
for i=1:length(strideEvents.tSHS)-1
    timeGRF=round(Filtered.Time,6);
    SHS=strideEvents.tSHS(i);
    FTO=strideEvents.tFTO(i);
    FHS=strideEvents.tFHS(i);
    STO=strideEvents.tSTO(i);
    FTO2=strideEvents.tFTO2(i);
    SHS2=strideEvents.tSHS2(i);
    
    if isnan(FTO) || isnan(FHS) ||FTO>FHS
        %keyboard
        FastLegOffSetData(i)=NaN;
    else
        FastLegOffSetData(i)=nanmedian(Filtered.split(FTO, FHS).getDataAsTS([fastleg 'Fy']).Data);
    end
    if isnan(STO) || isnan(SHS2)
        SlowLegOffSetData(i)=NaN;
    else
        SlowLegOffSetData(i)=nanmedian(Filtered.split(STO, SHS2).getDataAsTS([slowleg 'Fy']).Data);
    end
end
FastLegOffSet=round(nanmedian(FastLegOffSetData), 3);
SlowLegOffSet=round(nanmedian(SlowLegOffSetData), 3);
display(['Fast Leg Off Set: ' num2str(FastLegOffSet) ', Slow Leg OffSet: ' num2str(SlowLegOffSet)]);

Filtered.Data(:, find(strcmp(Filtered.getLabels, [fastleg 'Fy'])))=Filtered.getDataAsVector([fastleg 'Fy'])-FastLegOffSet;
Filtered.Data(:, find(strcmp(Filtered.getLabels, [slowleg 'Fy'])))=Filtered.getDataAsVector([slowleg 'Fy'])-SlowLegOffSet;
%figure; plot(Filtered.getDataAsTS([slowleg 'Fy']).Data, 'b'); hold on; plot(Filtered.getDataAsTS([fastleg 'Fy']).Data, 'r');line([0 5*10^5], [0, 0])

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
LevelofInterest=0.5.*flipIT.*cosd(90-abs(ang)); %The actual angle of the incline

%Initalize data objects
lenny=length(strideEvents.tSHS);
TMAngle=repmat(ang, 1, lenny);
WalkingDirection=repmat(flipIT, 1,  lenny);
FyBS=NaN.*ones(1, lenny);
FyPS=NaN.*ones(1, lenny);
FzS=NaN.*ones(1, lenny);
FxS=NaN.*ones(1, lenny);
FyBF=NaN.*ones(1, lenny);
FyPF=NaN.*ones(1, lenny);
FzF=NaN.*ones(1, lenny);
FxF=NaN.*ones(1, lenny);
HandrailHolding=NaN.*ones(1, lenny);
FyBSmax=NaN.*ones(1, lenny);
FyPSmax=NaN.*ones(1, lenny);
FzSmax=NaN.*ones(1, lenny);
FxSmax=NaN.*ones(1, lenny);
FyBFmax=NaN.*ones(1, lenny);
FyPFmax=NaN.*ones(1, lenny);
FzFmax=NaN.*ones(1, lenny);
FxFmax=NaN.*ones(1, lenny);
FxFmax=NaN.*ones(1, lenny);
FyPSsum=NaN.*ones(1, lenny);
FyPFsum=NaN.*ones(1, lenny);
FyBSsum=NaN.*ones(1, lenny);
FyBFsum=NaN.*ones(1, lenny);
FyBSmax_ABS=NaN.*ones(1, lenny);
FyBFmax_ABS=NaN.*ones(1, lenny);
ImpactMagS=NaN.*ones(1, lenny);
ImpactMagF=NaN.*ones(1, lenny);

if ~isempty(regexp(trialData.type, 'TM')) %If overground (i.e., OG) then there will not be any forces to analyze
    for i=1:length(strideEvents.tSHS)-1
        %Get the entire stride of interest on BOTH sides (SHS-->SHS2, and
        %FHS--> FHS2)  Also flip it if decline people
        timeGRF=round(GRFData.Time,6);
        SHS=strideEvents.tSHS(i);
        FTO=strideEvents.tFTO(i);
        FHS=strideEvents.tFHS(i);
        STO=strideEvents.tSTO(i);
        FTO2=strideEvents.tFTO2(i);
        SHS2=strideEvents.tSHS2(i);
        
        % Get the slow step for this stride
        if isnan(SHS) || isnan(STO)
            striderS=[];
        else 
            striderS=flipIT.*Filtered.split(SHS, STO).getDataAsTS([slowleg 'Fy']).Data/Normalizer;
        end
        
        % Get the fast step for this strides
        if isnan(FHS) || isnan(FTO2)
            striderF=[];
        else
            striderF=flipIT.*Filtered.split(FHS, FTO2).getDataAsTS([fastleg 'Fy']).Data/Normalizer;
        end
        
        % Get the handrail data
        %Currently not defining handrail data because data integrity is
        %poor unless experimenter explictly collected this data.
        %HandrailHolding(i)= NaN;
        
        %% Slow Leg --  Compute some measures of anterior-posterior forces
        %Previously the following was part of a funciton called SeperateBP
        if ~isempty(striderS) && ~all(striderS==striderS(1)) && ~isempty(FTO) && ~isempty(STO) % Make sure there are no problems with the GRF
           if nanstd(striderS)>0.01 && nanmean(striderS)>0.01 %This is to get rid of places where there is only noise and no data

                [FyBS(i), FyBSsum(i), FyPS(i), FyPSsum(i), FyBSmax(i), FyBSmax_ABS(i),...
                    FyBSmaxQS(i), FyPSmax(i), FyPSmaxQS(i), ImpactMagS(i)] ...
                    = ComputeLegForceParameters(striderS,  LevelofInterest, FlipB, ['Epoch: ' trialData.name, '; Stide#:' num2str(i) '; SlowLeg']);
           end
            
            % Compute some measures of the vertical and medial-lateral forces
            FzS(i)=-1*nanmean(Filtered.split(SHS, STO).getDataAsTS([slowleg 'Fz']).Data)/Normalizer;
            FxS(i)=nanmean(Filtered.split(SHS, STO).getDataAsTS([slowleg 'Fx']).Data)/Normalizer;
            FzSmax(i)=-1*nanmin(Filtered.split(SHS, STO).getDataAsTS([slowleg 'Fz']).Data)/Normalizer;
            FxSmax(i)=nanmin(Filtered.split(SHS, STO).getDataAsTS([slowleg 'Fx']).Data)/Normalizer;
        end
        

        %% Fast Leg -- Compute some measures of anterior-posterior forces
        if ~isempty(striderF) && ~all(striderF==striderF(1)) && ~isempty(FTO) && ~isempty(STO)
             if nanstd(striderF)>0.01 || nanmean(striderF)>0.01 %This is to get rid of places where there is only noise and no data
                [FyBF(i), FyBFsum(i), FyPF(i), FyPFsum(i), FyBFmax(i), FyBFmax_ABS(i),...
                    FyBFmaxQS(i), FyPFmax(i),  FyPFmaxQS(i), ImpactMagF(i)] ...
                    = ComputeLegForceParameters(striderF,  LevelofInterest, FlipB, ['Epoch: ' trialData.name, '; Stide#:' num2str(i) '; FastLeg']);
             end
            
            % Compute some measures of the vertical and medial-lateral forces
            FzF(i)=-1*nanmean(Filtered.split(FHS, FTO2).getDataAsTS([fastleg 'Fz']).Data)/Normalizer;
            FxF(i)=nanmean(Filtered.split(FHS, FTO2).getDataAsTS([fastleg 'Fx']).Data)/Normalizer;
            FzFmax(i)=-1*nanmin(Filtered.split(FHS, FTO2).getDataAsTS([fastleg 'Fz']).Data)/Normalizer;
            FxFmax(i)=nanmax(Filtered.split(FHS, FTO2).getDataAsTS([fastleg 'Fx']).Data)/Normalizer;
        end
    end
end

%% Kinetic Symmetry Measures
FyBSym=FyBF-FyBS;
FyPSym=FyPF-FyPS;
FyBmaxSym=FyBFmax-FyBSmax;
FyPmaxSym=FyPFmax-FyPSmax;
FyBmaxRatio= FyBSmax./FyBFmax;
FyPmaxRatio=FyPSmax./FyPFmax;
FyBmaxSymNorm=(abs(FyBFmax)-abs(FyBSmax))./(abs(FyBFmax)+abs(FyBSmax));
FyPmaxSymNorm=(abs(FyPFmax)-abs(FyPSmax))./(abs(FyPFmax)+abs(FyPSmax));
FyBFmaxPer=(abs(FyBFmax))./(abs(FyBFmax)+abs(FyBSmax));
FyBSmaxPer=(abs(FyBSmax))./(abs(FyBFmax)+abs(FyBSmax));
FyPFmaxPer=(abs(FyPFmax))./(abs(FyPFmax)+abs(FyPSmax));
FyPSmaxPer=(abs(FyPSmax))./(abs(FyPFmax)+abs(FyPSmax));
Slow_Ipsi_FySym=FyBSmax+FyPSmax;
Fast_Ipsi_FySym=FyBFmax+FyPFmax;
SlowB_Contra_FySym=FyBSmax+FyPFmax;
FastB_Contra_FySym= FyBFmax+FyPSmax;

%% COM and COP -- Not robust enough for general code
%%COM:
%if ~isempty(markerData.getLabelsThatMatch('HAT'))
%    [ outCOM ] = computeCOM(strideEvents, markerData, BW, slowleg, fastleg, impactS, expData, gaitEvents, flipIT, FyPSat );
% else
outCOM.Data=[];
outCOM.labels=[];
outCOM.description=[];
% end

%%COP: not ready for real life
% if ~isempty(markerData.getLabelsThatMatch('LCOP'))
%     [outCOP] = computeCOPParams( strideEvents, markerData, BW, slowleg, fastleg, impactS, expData, gaitEvents );
% else
outCOP.Data=[];
outCOP.labels=[];
outCOP.description=[];
% end

% if isempty(markerData.getLabelsThatMatch('Hat'))
%     labels=[labels outCOM.labels outCOP.labels];
%     description=[description outCOM.description outCOP.description];
% end

%% Assign parameters to data matrix
data=nan(lenny,length(paramLabels));
for i=1:length(paramLabels)
    eval(['data(:,i)=' paramLabels{i} ';'])
end

%% Create parameterSeries
out=parameterSeries(data,paramLabels,[],description);        


end


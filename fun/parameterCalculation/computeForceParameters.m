function [out] = computeForceParameters(strideEvents,GRFData,slowleg, fastleg,BW, trialData, markerData)

% CJS 2017: Here I am including the code that I have been using for the incline decline analysis. 
% This code is a bit eccentric in the way that identifies the inclination for the TM.


%~~~~~~~ Here is where I am putting real stuffs ~~~~~~~~
trial=trialData.description;
%If I want all the forces to be unitless then set this to 9.81*BW, else set it
%to 1*BW
Normalizer=9.81*BW;

FlipB=1; %7/21/2016, nevermind, making 1 8/1/2016


if iscell(trial)
    trial=trial{1};
end

[ ang ] = DetermineTMAngle( trialData );
flipIT= 2.*(ang >= 0)-1; %This will be -1 when it was a decline study, 1 otherwise
Filtered=GRFData.lowPassFilter(20);

%~~~~~~~~~~~~~~~~ REMOVE ANY OFFSETS IN THE DATA~~~~~~~~~~~~~~~~~~~~~~~~~~~
%New 8/5/2016 CJS: It came to my attenion that one of the decline subjects
%(LD30) one of the force plates was not properly zeroed.  Here I am
%manually shifting the forces.  I am assuming that the vertical forces have
%been properly been shifted during the c3d2mat process, otherwise the
%events are wrong and these lines of code will not save you. rats

%figure; plot(Filtered.getDataAsTS([s 'Fy']).Data, 'b'); hold on; plot(Filtered.getDataAsTS([f 'Fy']).Data, 'r');
fFy=Filtered.getDataAsTS([fastleg 'Fy']);
sFy=Filtered.getDataAsTS([slowleg 'Fy']);
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

for i=1:length(strideEvents.tSHS)-1
        SHS=strideEvents.tSHS(i);
        FTO=strideEvents.tFTO(i);
        FHS=strideEvents.tFHS(i);
        STO=strideEvents.tSTO(i);
        FTO2=strideEvents.tFTO2(i);
        SHS2=strideEvents.tSHS2(i);
        
        if isnan(FTO) || isnan(FHS) ||FTO>FHS
            %nop
        else
            FastLegOffSetData(i)=nanmedian(fFy.split(FTO, FHS).Data);
        end
        if isnan(STO) || isnan(SHS2)
            %nop
        else
            SlowLegOffSetData(i)=nanmedian(sFy.split(STO, SHS2).Data);
        end
end
FastLegOffSet=round(nanmedian(FastLegOffSetData), 3);
SlowLegOffSet=round(nanmedian(SlowLegOffSetData), 3);
display(['Fast Leg Offset: ' num2str(FastLegOffSet) ', Slow Leg Offset: ' num2str(SlowLegOffSet)]);

Filtered.Data(:, find(strcmp(Filtered.getLabels, [fastleg 'Fy'])))=Filtered.getDataAsVector([fastleg 'Fy'])-FastLegOffSet;
Filtered.Data(:, find(strcmp(Filtered.getLabels, [slowleg 'Fy'])))=Filtered.getDataAsVector([slowleg 'Fy'])-SlowLegOffSet;
%figure; plot(Filtered.getDataAsTS([slowleg 'Fy']).Data, 'b'); hold on; plot(Filtered.getDataAsTS([fastleg 'Fy']).Data, 'r');line([0 5*10^5], [0, 0])
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
LevelofInterest=0.5.*flipIT.*cosd(90-abs(ang)); %The actual angle of the incline

lenny=length(strideEvents.tSHS)-1;
impactS=NaN(1, lenny);
SB=NaN(1, lenny);
SP=NaN(1, lenny);
SZ=NaN(1, lenny);
SX=NaN(1, lenny);
impactF=NaN(1, lenny);
FB=NaN(1, lenny);
FP=NaN(1, lenny);
FZ=NaN(1, lenny);
FX=NaN(1, lenny);
HandrailHolding=NaN(1, lenny);
SBmax=NaN(1, lenny);
SPmax=NaN(1, lenny);
SZmax=NaN(1, lenny);
SXmax=NaN(1, lenny);
impactSmax=NaN(1, lenny);
FBmax=NaN(1, lenny);
FPmax=NaN(1, lenny);
FZmax=NaN(1, lenny);
FXmax=NaN(1, lenny);
impactFmax=NaN(1, lenny);
if ~isempty(regexp(trial, 'OG')) || ~isempty(regexp(trialData.type, 'OG'))
 %nop
else
    for i=1:length(strideEvents.tSHS)-1
        filteredSlowStance=Filtered.split(SHS, STO);
        filteredFastStance=Filtered.split(FHS, FTO2);

        SHS=strideEvents.tSHS(i);
        FTO=strideEvents.tFTO(i);
        FHS=strideEvents.tFHS(i);
        STO=strideEvents.tSTO(i);
        FTO2=strideEvents.tFTO2(i);
        SHS2=strideEvents.tSHS2(i);
       if isnan(SHS) || isnan(STO)
            striderS=[];
        else %FILTERING
            striderS=flipIT.*filteredSlowStance.getDataAsVector([slowleg 'Fy'])/Normalizer;
        end
        if isnan(FHS) || isnan(FTO2)
            striderF=[];
        else%FILTERING
            striderF=flipIT.*filteredFastStance.getDataAsVector([fastleg 'Fy'])/Normalizer;
        end
        
        if ~isempty(handrailData)
            HandrailHolding(i)= .05 < sqrt(nanmean(sum(handrailData.split(SHS, SHS2).Data.^2,2)))/Normalizer;
        else
            HandrailHolding(i)=NaN;
        end
        
        %Previously the following was part of a funciton called SeperateBP
        if isempty(striderS) || all(striderS==striderS(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
            %This does nothing, as vars are initialized as nan:
        else
            if nanstd(striderS)<0.01 && nanmean(striderS)<0.01 %This is to get rid of places where there is only noise and no data

            else
                ns=find((striderS-LevelofInterest)<0);%1:65
                ps=find((striderS-LevelofInterest)>0);
       
                ImpactMagS=find((striderS-LevelofInterest)==nanmax(striderS(1:75)-LevelofInterest));%no longer percent of stride
                if isempty(ImpactMagS)~=1
                    postImpactS=ns(find(ns>ImpactMagS(end), 1, 'first'));
                    if isempty(postImpactS)~=1
                        ps(find(ps<postImpactS))=[];
                        ns(find(ns<postImpactS))=[];
                    end
                end
                
                if isempty(ns)

                else

                    SB(i)=FlipB.*(nanmean(striderS(ns)-LevelofInterest));
                    SBmax(i)=FlipB.*(nanmin(striderS(ns)-LevelofInterest));
                end
                if isempty(ps)

                else
                    SP(i)=nanmean(striderS(ps)-LevelofInterest);
                    SPmax(i)=nanmax(striderS(ps)-LevelofInterest);
                end
                
                if exist('postImpactS')==0 || isempty(postImpactS)==1
%                     impactS(i)=NaN;
%                     impactSmax(i)=NaN;
                else
                    impactS(i)=nanmean(striderS(find((striderS(SHS-SHS+1: postImpactS)-LevelofInterest)>0)))-LevelofInterest;
                    if isempty(striderS(find((striderS(SHS-SHS+1: postImpactS)-LevelofInterest)>0)))
                        %impactSmax(i)=NaN;
                    else
                        impactSmax(i)=nanmax(striderS(find((striderS(SHS-SHS+1: postImpactS)-LevelofInterest)>0)))-LevelofInterest;
                    end
                end
                
            end
           
SZ(i)=-1*nanmean(filteredSlowStance.getDataAsVector([slowleg 'Fz']))/Normalizer;
SX(i)=nanmean(filteredSlowStance.getDataAsVector([slowleg 'Fx']))/Normalizer;
SZmax(i)=-1*nanmin(filteredSlowStance.getDataAsVector([slowleg 'Fz']))/Normalizer;
SXmax(i)=nanmin(filteredSlowStance.getDataAsVector([slowleg 'Fx']))/Normalizer;
         end
        
        %%Now for the fast leg...
        if isempty(striderF) || all(striderF==striderF(1)) || isempty(FTO) || isempty(STO)

        else
            if nanstd(striderF)<0.01 && nanmean(striderF)<0.01 %This is to get rid of places where there is only noise and no data

            else
                 nf=find((striderF-LevelofInterest)<0);%1:65
                pf=find((striderF-LevelofInterest)>0);
                    ImpactMagF=find((striderF-LevelofInterest)==nanmax(striderF(1:75)-LevelofInterest));%1:15
                if isempty(ImpactMagF)~=1
                    postImpactF=nf(find(nf>ImpactMagF(end), 1, 'first'));
                    if isempty(postImpactF)~=1
                        pf(find(pf<postImpactF))=[];
                        nf(find(nf<postImpactF))=[];
                    end
                end
                
                if isempty(pf)

                else

                    FP(i)=nanmean(striderF(pf)-LevelofInterest);
                    FPmax(i)=nanmax(striderF(pf)-LevelofInterest);
                end
                if isempty(nf)

                else
                    FB(i)=FlipB.*(nanmean(striderF(nf)-LevelofInterest));
                    FBmax(i)=FlipB.*(nanmin(striderF(nf)-LevelofInterest));
                end
                
                if exist('postImpactF')==0 || isempty(postImpactF)==1

                else
                    impactF(i)=nanmean(striderF(find((striderF(FHS-FHS+1: postImpactF)-LevelofInterest)>0)))-LevelofInterest;
                    if isempty(striderF(find((striderF(FHS-FHS+1: postImpactF)-LevelofInterest)>0)))

                    else
                        impactFmax(i)=nanmax(striderF(find((striderF(FHS-FHS+1: postImpactF)-LevelofInterest)>0)))-LevelofInterest;
                    end
                end
            end
            FZ(i)=-1*nanmean(filteredFastStance.getDataAsVector([fastleg 'Fz']))/Normalizer;
            FX(i)=nanmean(filteredFastStance.getDataAsVector([fastleg 'Fx']))/Normalizer;
            FZmax(i)=-1*nanmin(filteredFastStance.getDataAsVector([fastleg 'Fz']))/Normalizer;
            FXmax(i)=nanmax(filteredFastStance.getDataAsVector([fastleg 'Fx']))/Normalizer;
        end
    end
end
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
data=[[impactS NaN]' [SB NaN]' [SP NaN]' [impactF NaN]' [FB NaN]' [FP NaN]' [FB-SB NaN]' [FP-SP NaN]' [SX NaN]' [SZ NaN]' [FX NaN]' [FZ NaN]' [HandrailHolding NaN]'...
    [impactSmax NaN]' [SBmax NaN]' [SPmax NaN]' [impactFmax NaN]' [FBmax NaN]' [FPmax NaN]' [SXmax NaN]' [SZmax NaN]' [FXmax NaN]' [FZmax NaN]' ...
    outCOM.Data outCOP.Data];
description={'GRF-FYs average signed impact force', 'GRF-FYs average signed braking', 'GRF-FYs average signed propulsion',...
        'GRF-FYf average signed impact force', 'GRF-FYf average signed braking', 'GRF-FYf average signed propulsion', ...
        'GRF-FYs average signed Symmetry braking', 'GRF-FYs average signed Symmetry propulsion',...
        'GRF-Fxs average force', 'GRF-Fzs average force',...
        'GRF-Fxf average force', 'GRF-Fzf average force', 'Handrail was being held onto'...
        'GRF-FYs max signed impact force', 'GRF-FYs max signed braking', 'GRF-FYs max signed propulsion',...
        'GRF-FYf max signed impact force', 'GRF-FYf max signed braking', 'GRF-FYf max signed propulsion', ...
        'GRF-Fxs max force', 'GRF-Fzs max force',...
        'GRF-Fxf max force', 'GRF-Fzf max force'};
labels={'FyImpactS', 'FyBS', 'FyPS', 'FyImpactF', 'FyBF', 'FyPF','FyBSym', 'FyPSym', 'FxS', 'FzS', 'FxF', 'FzF', 'HandrailHolding', 'FyImpactSmax', 'FyBSmax', 'FyPSmax', 'FyImpactFmax', 'FyBFmax', 'FyPFmax', 'FxSmax', 'FzSmax', 'FxFmax', 'FzFmax'};

if isempty(markerData.getLabelsThatMatch('Hat'))
    labels=[labels outCOM.labels outCOP.labels];
    description=[description outCOM.description outCOP.description];
end
out=parameterSeries(data,labels,[],description);
end

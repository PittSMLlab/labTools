function [out] = computeForceParameters(strideEvents,GRFData,slowleg, fastleg,BW, trialData, markerData)
%function [out] = computeForceParameters(GRFData,s,f,indSHS,indSTO,indFHS,indFTO,indSHS2,indFTO2)
% %UNTITLED4 Summary of this function goes here
% %   Detailed explanation goes here
%[GRFDataF, GRFDataS, GRFDataH] = getGRFs(GRFData,s,f);    
% %% COP range and symmetry
% [COP] = computeCOP(GRFDataS,GRFDataF,s,f);
%         %Mawase's way based on TO and HS
%         %COPrangeF(step)=COP(2,indFTO)-COP(2,indSHS);
%         %COPrangeS(step)=COP(2,indSTO)-COP(2,indFHS);
%         %May way based on TO and HS
% %         COPrangeF(step)=COP(2,indFTO)-COP(2,indFHS);
% %         COPrangeS(step)=COP(2,indSTO)-COP(2,indSHS);
%         %Mawase's ugly way:
%         COPrangeF=min(COP(2,indSHS:indFHS))-max(COP(2,max([indSHS-100,1]):indFTO));
%         COPrangeS=min(COP(2,indFHS:indSHS2))-max(COP(2,indFTO:indSTO));
%         COPsymM=(COPrangeF-COPrangeS)/(COPrangeF+COPrangeS);
%         %My very nice way:
%         COPrangeF=min(COP(2,indSHS:indFHS))-max(COP(2,indFTO:indSTO));
%         COPrangeS=min(COP(2,indFHS:indSHS2))-max(COP(2,indSTO:indFTO2)); 
%         COPsym=(COPrangeF-COPrangeS)/(COPrangeF+COPrangeS);
% 
% %% Hand holding
%handHolding=sum(mean(abs(GRFDataH)))>2;

%data=[];
%labels={};
%description={};
%out=parameterSeries(data,labels,[],description); 
%end

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

if ~isempty(regexp(trial, 'OG')) || ~isempty(regexp(trialData.type, 'OG'))
    lenny=length(strideEvents.tSHS)-1;
    impactS=NaN.*ones(1, lenny);
    SB=NaN.*ones(1, lenny);
    SP=NaN.*ones(1, lenny);
    SZ=NaN.*ones(1, lenny);
    SX=NaN.*ones(1, lenny);
    impactF=NaN.*ones(1, lenny);
    FB=NaN.*ones(1, lenny);
    FP=NaN.*ones(1, lenny);
    FZ=NaN.*ones(1, lenny);
    FX=NaN.*ones(1, lenny);
    HandrailHolding=NaN.*ones(1, lenny);
    SBmax=NaN.*ones(1, lenny);
    SPmax=NaN.*ones(1, lenny);
    SZmax=NaN.*ones(1, lenny);
    SXmax=NaN.*ones(1, lenny);
    impactSmax=NaN.*ones(1, lenny);
    FBmax=NaN.*ones(1, lenny);
    FPmax=NaN.*ones(1, lenny);
    FZmax=NaN.*ones(1, lenny);
    FXmax=NaN.*ones(1, lenny);
    impactFmax=NaN.*ones(1, lenny);
else
    for i=1:length(strideEvents.tSHS)-1
        %1.) get the entire stride of interest on BOTH sides (SHS-->SHS2, and
        %FHS--> FHS2)  Also flip it if declien people
        timeGRF=round(GRFData.Time,6);
        % %         SHS=find(timeGRF==round(strideEvents.tSHS(i),6));
        % %         FTO=find(timeGRF==round(strideEvents.tFTO(i),6));
        % %         FHS=find(timeGRF==round(strideEvents.tFHS(i),6));
        % %         STO=find(timeGRF==round(strideEvents.tSTO(i),6));
        % %         SHS2=find(timeGRF==round(strideEvents.tSHS2(i),6));
        % %         FTO2=find(timeGRF==round(strideEvents.tFTO2(i),6));
        % %         FHS2=find(timeGRF==round(strideEvents.tFHS2(i),6));
        SHS=strideEvents.tSHS(i);
        FTO=strideEvents.tFTO(i);
        FHS=strideEvents.tFHS(i);
        STO=strideEvents.tSTO(i);
        FTO2=strideEvents.tFTO2(i);
        SHS2=strideEvents.tSHS2(i);
        %         striderS=flipIT.*GRFData.Data(SHS:SHS2, find(strcmp(GRFData.labels, [slowleg 'Fy'])))/Normalizer;
        %         %striderF=flipIT.*GRFData.Data(FHS:FHS2, find(strcmp(GRFData.labels, [fastleg 'Fy'])))/Normalizer;
        %         striderF=flipIT.*GRFData.Data(FHS:FTO2, find(strcmp(GRFData.labels, [fastleg 'Fy'])))/Normalizer;
        %         striderS=flipIT.*GRFData.split(strideEvents.tSHS(i), strideEvents.tSTO(i)).getDataAsTS([slowleg 'Fy']).lowPassFilter(20).Data/Normalizer;
        %         striderF=flipIT.*GRFData.split(strideEvents.tFHS(i), strideEvents.tFTO2(i)).getDataAsTS([fastleg 'Fy']).lowPassFilter(20).Data/Normalizer;
        if isnan(SHS) || isnan(STO)
            striderS=[];
        else %FILTERING
            striderS=flipIT.*Filtered.split(SHS, STO).getDataAsTS([slowleg 'Fy']).Data/Normalizer;
            %striderS=flipIT.*GRFData.lowPassFilter(20).split(SHS, STO).getDataAsTS([slowleg 'Fy']).Data/Normalizer;
            %striderS=flipIT.*GRFData.split(SHS, STO).getDataAsTS([slowleg 'Fy']).Data/Normalizer;%
        end
        if isnan(FHS) || isnan(FTO2)
            striderF=[];
        else%FILTERING
            striderF=flipIT.*Filtered.split(FHS, FTO2).getDataAsTS([fastleg 'Fy']).Data/Normalizer;
            %striderF=flipIT.*GRFData.lowPassFilter(20).split(FHS, FTO2).getDataAsTS([fastleg 'Fy']).Data/Normalizer;
            %striderF=flipIT.*GRFData.split(FHS, FTO2).getDataAsTS([fastleg 'Fy']).Data/Normalizer;
        end
        
        %HandrailHolding(i)= .05 < sqrt(nanmean(GRFData.Data(SHS:SHS2, find(strcmp(GRFData.labels, ['HFy']))))^2+nanmean(GRFData.Data(SHS:SHS2, find(strcmp(GRFData.labels, ['HFz']))))^2)/Normalizer;
        %HandrailHolding(i)= .05 < sqrt(nanmean(Filtered.split(SHS, SHS2).getDataAsTS('HFy').Data).^2+nanmean(GRFData.split(SHS,SHS2).getDataAsTS('HFz').lowPassFilter(20).Data).^2)/Normalizer;
        if Filtered.isaLabel('HFx')
            HandrailHolding(i)= .05 < sqrt(nanmean(sum(Filtered.split(SHS, SHS2).getDataAsTS({'HFy','HFz'}).Data.^2,2)))/Normalizer;
        elseif Filtered.isaLabel('XFx')
            HandrailHolding(i)= .05 < sqrt(nanmean(sum(Filtered.split(SHS, SHS2).getDataAsTS({'XFy','XFz'}).Data.^2,2)))/Normalizer;
            warning('Handrail data was not found labeled as ''HFx'', using ''XFx'' instead (not sure if that IS the handrail!). This is probably an issue with force channel numbering mismatch while loading (c3d2mat).')
        else
            HandrailHolding(i)=NaN;
            warning('Found no handrail force data.')
        end
        
        %Previously the following was part of a funciton called SeperateBP
        if isempty(striderS) || all(striderS==striderS(1)) || isempty(FTO) || isempty(STO)% So if there is some sort of problem with the GRF, set everything to NaN
            impactS(i)=NaN;
            SB(i)=NaN;
            SP(i)=NaN;
            SZ(i)=NaN;
            SX(i)=NaN;
            SBmax(i)=NaN;
            SPmax(i)=NaN;
            SZmax(i)=NaN;
            SXmax(i)=NaN;
            impactSmax(i)=NaN;
        else
            if nanstd(striderS)<0.01 && nanmean(striderS)<0.01 %This is to get rid of places where there is only noise and no data
                impactS(i)=NaN;
                SB(i)=NaN;
                SP(i)=NaN;
                SZ(i)=NaN;
                SX(i)=NaN;
                SBmax(i)=NaN;
                SPmax(i)=NaN;
                SZmax(i)=NaN;
                SXmax(i)=NaN;
                impactSmax(i)=NaN;
            else
%               ns=find((striderS(SHS-SHS+1:STO-SHS+1)-LevelofInterest)<0);%1:65
%               ps=find((striderS(SHS-SHS+1:STO-SHS+1)-LevelofInterest)>0);
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
                    SB(i)=NaN;
                    SBmax(i)=NaN;
                else
%                     SB(i)=FlipB.*(nanmean(striderS(ns))-LevelofInterest);
%                     SBmax(i)=FlipB.*(nanmin(striderS(ns))-LevelofInterest);
                    SB(i)=FlipB.*(nanmean(striderS(ns)-LevelofInterest));
                    SBmax(i)=FlipB.*(nanmin(striderS(ns)-LevelofInterest));
                end
                if isempty(ps)
                    SP(i)=NaN;
                    SPmax(i)=NaN;
                else
%                     SP(i)=nanmean(striderS(ps))-LevelofInterest;
%                     SPmax(i)=nanmax(striderS(ps))-LevelofInterest;
                    SP(i)=nanmean(striderS(ps)-LevelofInterest);
                    SPmax(i)=nanmax(striderS(ps)-LevelofInterest);
                end
                
                if exist('postImpactS')==0 || isempty(postImpactS)==1
                    impactS(i)=NaN;
                    impactSmax(i)=NaN;
                else
                    impactS(i)=nanmean(striderS(find((striderS(SHS-SHS+1: postImpactS)-LevelofInterest)>0)))-LevelofInterest;
                    if isempty(striderS(find((striderS(SHS-SHS+1: postImpactS)-LevelofInterest)>0)))
                        impactSmax(i)=NaN;
                    else
                        impactSmax(i)=nanmax(striderS(find((striderS(SHS-SHS+1: postImpactS)-LevelofInterest)>0)))-LevelofInterest;
                    end
                end
                
            end
           

SZ(i)=-1*nanmean(Filtered.split(SHS, STO).getDataAsTS([slowleg 'Fz']).Data)/Normalizer;
SX(i)=nanmean(Filtered.split(SHS, STO).getDataAsTS([slowleg 'Fx']).Data)/Normalizer;
SZmax(i)=-1*nanmin(Filtered.split(SHS, STO).getDataAsTS([slowleg 'Fz']).Data)/Normalizer;
SXmax(i)=nanmin(Filtered.split(SHS, STO).getDataAsTS([slowleg 'Fx']).Data)/Normalizer;
         end
        
        %%Now for the fast leg...
        if isempty(striderF) || all(striderF==striderF(1)) || isempty(FTO) || isempty(STO)
            impactF(i)=NaN;
            FB(i)=NaN;
            FP(i)=NaN;
            FZ(i)=NaN;
            FX(i)=NaN;
            FBmax(i)=NaN;
            FPmax(i)=NaN;
            FZmax(i)=NaN;
            FXmax(i)=NaN;
            impactFmax(i)=NaN;
        else
            if nanstd(striderF)<0.01 && nanmean(striderF)<0.01 %This is to get rid of places where there is only noise and no data
                impactF(i)=NaN;
                FB(i)=NaN;
                FP(i)=NaN;
                FZ(i)=NaN;
                FX(i)=NaN;
                FBmax(i)=NaN;
                FPmax(i)=NaN;
                FZmax(i)=NaN;
                FXmax(i)=NaN;
                impactFmax(i)=NaN;
            else
%                 nf=find((striderF(FHS-FHS+1:FTO2-FHS+1)-LevelofInterest)<0);%1:65
%                 pf=find((striderF(FHS-FHS+1:FTO2-FHS+1)-LevelofInterest)>0);
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
                    FP(i)=NaN;
                    FPmax(i)=NaN;
                else
%                     FP(i)=nanmean(striderF(pf))-LevelofInterest;
%                     FPmax(i)=nanmax(striderF(pf))-LevelofInterest;
                    FP(i)=nanmean(striderF(pf)-LevelofInterest);
                    FPmax(i)=nanmax(striderF(pf)-LevelofInterest);
                end
                if isempty(nf)
                    FB(i)=NaN;
                    FBmax(i)=NaN;
                else
                    FB(i)=FlipB.*(nanmean(striderF(nf)-LevelofInterest));
                    FBmax(i)=FlipB.*(nanmin(striderF(nf)-LevelofInterest));
                end
                
                if exist('postImpactF')==0 || isempty(postImpactF)==1
                    impactF(i)=NaN;
                    impactFmax(i)=NaN;
                else
                    impactF(i)=nanmean(striderF(find((striderF(FHS-FHS+1: postImpactF)-LevelofInterest)>0)))-LevelofInterest;
                    if isempty(striderF(find((striderF(FHS-FHS+1: postImpactF)-LevelofInterest)>0)))
                        impactFmax(i)=NaN;
                    else
                        impactFmax(i)=nanmax(striderF(find((striderF(FHS-FHS+1: postImpactF)-LevelofInterest)>0)))-LevelofInterest;
                    end
                end
            end
                  
            FZ(i)=-1*nanmean(Filtered.split(FHS, FTO2).getDataAsTS([fastleg 'Fz']).Data)/Normalizer;
            FX(i)=nanmean(Filtered.split(FHS, FTO2).getDataAsTS([fastleg 'Fx']).Data)/Normalizer;
            FZmax(i)=-1*nanmin(Filtered.split(FHS, FTO2).getDataAsTS([fastleg 'Fz']).Data)/Normalizer;
            FXmax(i)=nanmax(Filtered.split(FHS, FTO2).getDataAsTS([fastleg 'Fx']).Data)/Normalizer;
        end
        %3.) Calculate some aspect of this stride based on the transition point
        %4.) Take care of any normalizing that might need to be done because I
        %am not time normalizing the data... if I average I don't have to do
        %this really...
    end
end
%For each stride (REMOVE THE BAD STRIDES?) --> No because the timecourses
%will remove these strides automatically

%Flip the decline people
%Normalize

%Define the transition --> No this is only for the SS
%Seperate BP


%Seperately need plotting functions to the early minus late stuff, this is
%just to get the timecourse!

%Plotting the needs to be done
%regular plotting, check
%Bar plots, early minus SS
%Traces of the GRF's, TODO!


%% Actually output and store stuff
data=[[impactS NaN]' [SB NaN]' [SP NaN]' [impactF NaN]' [FB NaN]' [FP NaN]' [FB-SB NaN]' [FP-SP NaN]' [SX NaN]' [SZ NaN]' [FX NaN]' [FZ NaN]' [HandrailHolding NaN]'...
    [impactSmax NaN]' [SBmax NaN]' [SPmax NaN]' [impactFmax NaN]' [FBmax NaN]' [FPmax NaN]' [SXmax NaN]' [SZmax NaN]' [FXmax NaN]' [FZmax NaN]' ];
labels={'FyImpactS', 'FyBS', 'FyPS', 'FyImpactF', 'FyBF', 'FyPF','FyBSym', 'FyPSym', 'FxS', 'FzS', 'FxF', 'FzF', 'HandrailHolding', 'FyImpactSmax', 'FyBSmax', 'FyPSmax', 'FyImpactFmax', 'FyBFmax', 'FyPFmax', 'FxSmax', 'FzSmax', 'FxFmax', 'FzFmax'};
description={'GRF-FYs average signed impact force', 'GRF-FYs average signed braking', 'GRF-FYs average signed propulsion',...
    'GRF-FYf average signed impact force', 'GRF-FYf average signed braking', 'GRF-FYf average signed propulsion', ...
    'GRF-FYs average signed Symmetry braking', 'GRF-FYs average signed Symmetry propulsion',...
    'GRF-Fxs average force', 'GRF-Fzs average force',...
    'GRF-Fxf average force', 'GRF-Fzf average force', 'Handrail was being held onto'...
    'GRF-FYs max signed impact force', 'GRF-FYs max signed braking', 'GRF-FYs max signed propulsion',...
    'GRF-FYf max signed impact force', 'GRF-FYf max signed braking', 'GRF-FYf max signed propulsion', ...
    'GRF-Fxs max force', 'GRF-Fzs max force',...
    'GRF-Fxf max force', 'GRF-Fzf max force',};
out=parameterSeries(data,labels,[],description);
end



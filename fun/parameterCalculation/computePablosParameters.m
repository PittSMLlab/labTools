function [rF,rS,cF,cS,TF,TS,phiF,phiS,AF,AS,rSym,cSym,phiSym,ASym] = computePablosParameters(markerData,s,f,timeSHS,timeSTO,timeFHS,timeFTO,timeSHS2,timeFTO2)
% 'rF',... %Stance time during last gait cycle, divided by stride time
% 'rS',... %Idem 
% 'cF',... %Average of ankle position at HS2 and previous TO
% 'cS',... %Idem
% 'TF',... %Stride time, time between consecutive HSs
% 'TS',... %Idem
% 'phiF',... %Time at HS, divided by stride time. Not meaningful by itself
% 'phiS',... %Idem
% 'AF',... %Ankle position at HS2 minus position at previous TO
% 'AS',... %Idem
sAnkPos= markerData.getDataAsTS([s 'ANK' markerData.orientation.foreaftAxis]);
fAnkPos= markerData.getDataAsTS([f 'ANK' markerData.orientation.foreaftAxis]);
sAnkPos.Data=sAnkPos.Data* markerData.orientation.foreaftSign;
fAnkPos.Data=fAnkPos.Data* markerData.orientation.foreaftSign;
%time=markerData.Time;

%Alternative 1: Compute everything ipsilaterally (caveat: bilateral
%measurements have a little less , pro: definitions are completely symmetrical)
% AS=sAnkPos(indSHS2)-sAnkPos(indSTO);
% AF=fAnkPos(indFHS)-fAnkPos(indFTO);
% cS=.5*(sAnkPos(indSHS2)+sAnkPos(indSTO));
% cF=.5*(fAnkPos(indFHS)+fAnkPos(indFTO));
% TS=time(indSHS2)-time(indSHS);
% TF=time(indFHS2)-time(indFHS);
% phiS=time(indSHS)/TS;
% phiF=time(indFHS)/TF;
% rS=(time(indSTO)-time(indSHS))/TS;
% rF=(time(indFTO2)-time(indFHS))/TF;

%Alternative 2: Get a single stride period (SHS->SHS2) and compute
%everything there (some of the quantities lose meaning, but bilaterality is more clear)
%The alternatives are equivalent on steady-state
AS=abs(sAnkPos.getSample(timeSHS2)-sAnkPos.getSample(timeSTO)); %Not elegant, but abs ensures that it is always positive, regardless of the direction of walking in OG trials.
AF=abs(fAnkPos.getSample(timeFHS)-fAnkPos.getSample(timeFTO));
cS=.5*(sAnkPos.getSample(timeSHS2)+sAnkPos.getSample(timeSTO));
cF=.5*(fAnkPos.getSample(timeFHS)+fAnkPos.getSample(timeFTO));
T=timeSHS2-timeSHS; %Only period that makes sense
phiS=timeSHS/T;
phiF=timeFHS/T;
rS=(timeSTO-timeSHS)/T;
rF=1 - (timeFHS-timeFTO)/T; %Computing stance time as the complement of swing time. It is equivalent to computing the stance time of fast leg is separated into two intervals: SHS -> FTO, and FHS -> SHS2
TS=T;
TF=T;
rSym=rF-rS;
cSym=cF-cS;
phiSym=phiF-phiS -.5; %To measure vs. ideal symmetry, which implies phiF-phiS=.5
ASym=AF-AS;
end


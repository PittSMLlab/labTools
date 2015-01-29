function [uS,yS,foreaftRatioS,utS,ytS,ytS_hat,uF,yF,foreaftRatioF,utF,ytF,ytF_hat] = computeGelsysParameters(markerData,s,f,timeSHS,timeFTO,timeFHS,timeSTO,timeSHS2,timeFTO2,timeFHS2,timeSTO2)
%Parameter description:


%Get relevant data
sAnkPos= markerData.getDataAsTS([s 'ANK' markerData.orientation.foreaftAxis]);
fAnkPos= markerData.getDataAsTS([f 'ANK' markerData.orientation.foreaftAxis]);
sHipPos= markerData.getDataAsTS([s 'HIP' markerData.orientation.foreaftAxis]);
fHipPos= markerData.getDataAsTS([f 'HIP' markerData.orientation.foreaftAxis]);
sAnkPos.Data=sAnkPos.Data* markerData.orientation.foreaftSign;
fAnkPos.Data=fAnkPos.Data* markerData.orientation.foreaftSign;
sHipPos.Data=sHipPos.Data* markerData.orientation.foreaftSign;
fHipPos.Data=fHipPos.Data* markerData.orientation.foreaftSign;

if isempty(sHipPos.Data) || isempty(fHipPos.Data) %Sometimes hip markers are missing altogether. This should probably be fixed elsewhere in the code.
    meanHipPos=labTimeSeries(NaN(size(sAnkPos.Data)),sAnkPos.Time(1),sAnkPos.sampPeriod,{'meanHipPos'});
    
else
    meanHipPos=labTimeSeries(.5*(sHipPos.Data+fHipPos.Data),sHipPos.Time(1),sHipPos.sampPeriod,{'meanHipPos'});
end
    sRelAnkPos=sAnkPos-meanHipPos;
    fRelAnkPos=fAnkPos-meanHipPos;

%Define parameters: (fast parameters occur temporally BEFORE slow
%parameters)
%% Spatial params

%Slow leg for this step
uS=sRelAnkPos.getSample(timeSHS2); %Motor action: leg forward placement at iHS, defined at SHS2 to coincide with temporal parameters
yS=sRelAnkPos.getSample(timeSTO2); %Measured value: leg trailing at end of this step (iTO)
%yS_hat=fRelAnkPos.getSample(timeFTO2); %Expected value: leg trailing at previous end of step (cTO)
%eS=yS-yS_hat;
foreaftRatioS=yS/uS;

%Slow leg for prev step (if we want to do correlation)
uSprev=sRelAnkPos.getSample(timeSHS);
ySprev=sRelAnkPos.getSample(timeSTO);
%yS_hatprev=fRelAnkPos.getSample(timeFTO);
%eSprev=ySprev-yS_hatprev;
%nS= (uS-uSprev)/eSprev;

%Fast leg for this step (is anterior to slow leg)
uF=fRelAnkPos.getSample(timeFHS);
yF=fRelAnkPos.getSample(timeFTO2);
%yF_hat=sRelAnkPos.getSample(timeSTO); %Cannot access the data at previous cTO
%eF=yF-yF_hat;
foreaftRatioF=yF/uF;

%Fast leg for next step
%Doxy


%% Temporal params
%Slow leg, this step
utS=timeSHS2-timeFHS; %Motor action: step time
ytS=timeSTO2-timeFHS2; %Measured output: double support of this stepe
ytS_hat=timeFTO2-timeSHS2; %Expected value: double support from previous step
%etS=ytS-ytS_hat;

%Slow leg,prev step
utSprev=NaN; %Not available
ytSprev=timeSTO-timeFHS; 
%ytS_hatprev=timeFTO-timeSHS; 
%etSprev=ytSprev-ytS_hatprev;
%ntS=(utS-utSprev)/etSprev;


%Fast leg, this step:
utF=timeFHS2-timeSHS2; 
ytF=NaN; %Not available: timeFTO3-timeSHS3;
ytF_hat=timeSTO2-timeFHS2;
%etF=ytF-ytF_hat;


end


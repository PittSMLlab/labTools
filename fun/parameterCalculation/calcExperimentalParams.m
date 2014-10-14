function out = calcExperimentalParams(in)
%in must be an object of the class processedlabData
%
%To add a new parameter, it must be added to the paramLabels
%cell and the label must be the same as the variable name the data is saved
%to. (ex: in paramlabels: 'swingTimeSlow', in code: swingTimeSlow(i)=timeSHS2-timeSTO;)

paramlabels = {'COPrangeS',... %Range of COP movement along step direction during a stance phase
'COPrangeF',...
'COPsym',... %Difference in COP ranges normalized by sum
'COPsymM',... %COPsym as defined by Mawase
'rF',... %Stance time during last gait cycle, divided by stride time
'rS',... %Idem 
'cF',... %Average of ankle position at HS2 and previous TO
'cS',... %Idem
'TF',... %Stride time, time between consecutive HSs
'TS',... %Idem
'phiF',... %Time at HS, divided by stride time. Not meaningful by itself
'phiS',... %Idem
'AF',... %Ankle position at HS2 minus position at previous TO
'AS',... %Idem
'rSym',... %rF-rS, 
'cSym',... %cF-cS, center of oscillation difference
'phiSym',... %phiF-phiS, relative heel-strike timing
'ASym'};  %Amplitude difference
%'stepTimeContribution2',...
% 'foreAftRatioF',... %Hip to ankle pos at HS, divided by hip to ankle pos  at following (?) TO
%'initTime',...
%'endTime',...


%make the time series have a time vectpr as small as possible so that
% a) it does not take up an unreasonable amount of space
% b) the paramaters can be plotted along with the GRF/kinematic data and
% the events used to create each data point can be distinguished.
sampPeriod=0.2;
f_params=1/sampPeriod;

if in.metaData.refLeg == 'R'
    s = 'R';
    f = 'L';
elseif in.metaData.refLeg == 'L'
    s = 'L';
    f = 'R';
else
    ME=MException('MakeParameters:refLegError','the refLeg property of metaData must be either ''L'' or ''R''.');
    throw(ME);
end



%% Find number of strides
good=in.adaptParams.getDataAsVector({'good'}); %Getting data from 'good' label
ts=~isnan(good);
good=good(ts);
Nstrides=length(good);%Using lenght of the 'good' parameter already calculated in calcParams

%% get events
f_events=in.gaitEvents.sampFreq;
events=in.gaitEvents.getDataAsVector({[s,'HS'],[f,'HS'],[s,'TO'],[f,'TO']});
eventsTime=in.gaitEvents.Time;

%% Initialize params
paramTSlength=floor(length(eventsTime)*f_params/f_events);
numParams=length(paramlabels);
for i=1:numParams
    eval([paramlabels{i},'=NaN(paramTSlength,1);'])
end

%% Calculate parameters
        
for step=1:Nstrides   
    %get indices and times
    [indSHS,indFTO,indFHS,indSTO,indSHS2,indFTO2,timeSHS,timeFTO,timeFHS,timeSTO,timeSHS2,timeFTO2] = getIndsForThisStep(events,eventsTime,step);
    t=round(mean([indSHS indFTO indFHS indSTO indSHS2 indFTO2])*f_params/f_events);
    
    if good(step)
        %[COPrangeF(t),COPrangeS(t),COPsym(t),COPsymM(t),handHolding(t)] = computeForceParameters(in.GRFData,s,f,indSHS,indSTO,indFHS,indFTO,indSHS2,indFTO2);
        [rF(t),rS(t),cF(t),cS(t),TF(t),TS(t),phiF(t),phiS(t),AF(t),AS(t),rSym(t),cSym(t),phiSym(t),ASym(t)] = computePablosParameters(in.markerData.split(timeSHS,timeFTO2),s,f,timeSHS,timeSTO,timeFHS,timeFTO,timeSHS2,timeFTO2);

        
        %Contributions
%                     % Compute spatial contribution (1D)
%             spatialFast=fAnkPos(indFHS) - sAnkPos(indSHS);
%             spatialSlow=sAnkPos(indSHS2) - fAnkPos(indFHS);
%             
%             % Compute spatial contribution (2D)
%             sAnkPosHS=norm(sAnkPos2D(indSHS,:)); 
%             fAnkPosHS=norm(fAnkPos2D(indFHS,:));
%             sAnkPosHS2=norm(sAnkPos2D(indSHS2,:));
%             spatialFast2D=fAnkPosHS - sAnkPosHS;
%             spatialSlow2D=sAnkPosHS2 - fAnkPosHS;
% 
%             % Compute temporal contributions (convert time to be consistent with
%             % kinematic sampling frequency)
%             ts=round((timeFHS2-timeSHS2)*f_kin)/f_kin; %This rounding should no longer be required, as we corrected indices for kinematic sampling frequency and computed the corresponding times
%             tf=round((timeSHS2-timeFHS)*f_kin)/f_kin; %This rounding should no longer be required, as we corrected indices for kinematic sampling frequency and computed the corresponding times
%             difft=ts-tf;
% 
%             dispSlow=abs(sAnkPos(indFHS2)-sAnkPos(indSHS2));
%             dispFast=abs(fAnkPos(indSHS2)-fAnkPos(indFHS));
% 
%             velocitySlow=dispSlow/ts; % Velocity of foot relative to hip, should be close to actual belt speed in TM trials
%             velocityFast=dispFast/tf;            
%             avgVel=mean([velocitySlow velocityFast]);           
%                      
%             stepTimeContribution2(t)=avgVel*difft;  
    end

end

%% Save all the params in the data matrix & generate labTimeSeries
for i=1:length(paramlabels)
    eval(['data(:,i)=',paramlabels{i},';'])
end

out=labTimeSeries(data,eventsTime(1),sampPeriod,paramlabels);

%% (?)
% try
%     if any(bad)
%         slashes=find(in.metaData.rawDataFilename=='\' | in.metaData.rawDataFilename=='/');
%         file=in.metaData.rawDataFilename((slashes(end)+1):end);
%         disp(['Warning: Non consistent event detection in ' num2str(sum(bad)) ' strides of ',file])    
%     end
% catch
%     [file] = getSimpleFileName(in.metaData.rawDataFilename);
%         disp(['Warning: No strides detected in ',file])
% end

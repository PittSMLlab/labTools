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
%'initTime',...
%'endTime',...
    }; 

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
SHS=events(:,1);
FHS=events(:,2);
STO=events(:,3);
FTO=events(:,4);
inds=find(SHS); 
eventsTime=in.gaitEvents.Time;

%% Initialize params
paramTSlength=floor(length(eventsTime)*f_params/f_events);
numParams=length(paramlabels);
for i=1:numParams
    eval([paramlabels{i},'=NaN(paramTSlength,1);'])
end

%% Calculate parameters

%Get GRFData & compute COP
        auxLabels={'Fx','Fy','Fz','Mx','My','Mz'};
        for i=1:6
            GRFLabels{i}=[s auxLabels{i}];
        end
        GRFDataS=in.GRFData.getDataAsVector(GRFLabels);
        [GRFDataS] = idealLPF(GRFDataS,10/in.GRFData.sampFreq);
        for i=1:6
            GRFLabels{i}=[f auxLabels{i}];
        end
        GRFDataF=in.GRFData.getDataAsVector(GRFLabels);
        [GRFDataF] = idealLPF(GRFDataF,10/in.GRFData.sampFreq);
        for i=1:6
            GRFLabels{i}=['H' auxLabels{i}];
        end
        GRFDataH=in.GRFData.getDataAsVector(GRFLabels);
        [GRFDataH] = idealLPF(GRFDataH,10/in.GRFData.sampFreq);
                LTransformationMatrix=[1,0,0,0;20,1,0,0;1612,0,-1,0;0,0,0,-1];
        RTransformationMatrix=[1,0,0,0;-944,-1,0,0;1612,0,-1,0;0,0,0,-1];
        eval(['STransformationMatrix=' s 'TransformationMatrix(2:end,2:end);' ])
        eval(['FTransformationMatrix=' f 'TransformationMatrix(2:end,2:end);' ])
        eval(['STransformationVec=' s 'TransformationMatrix(2:end,1);' ])
        eval(['FTransformationVec=' f 'TransformationMatrix(2:end,1);' ])
                relGRF=GRFDataS;

        clear COPS COPF
        COPS(:,2)=(-5*relGRF(:,2) + relGRF(:,4))./relGRF(:,3);
        COPS(:,1)=(-5*relGRF(:,1) - relGRF(:,5))./relGRF(:,3);
        COPS(:,3)=0;
        COPS=bsxfun(@plus, STransformationMatrix*COPS', STransformationVec);
        
        FzS=relGRF(:,3);
        relGRF=GRFDataF;
        COPF(:,2)=(-5*relGRF(:,2) + relGRF(:,4))./relGRF(:,3);
        COPF(:,1)=(-5*relGRF(:,1) - relGRF(:,5))./relGRF(:,3);
        COPF(:,3)=0;
        COPF=bsxfun(@plus, FTransformationMatrix*COPF', FTransformationVec);
        FzF=relGRF(:,3);
        COP=bsxfun(@rdivide,(bsxfun(@times,COPF,FzF') + bsxfun(@times,COPS,FzS')),(FzS'+FzF'));
        
for step=1:Nstrides
        %get indices and times
    indSHS=inds(step);
    timeSHS=eventsTime(indSHS);
    indFTO=find((eventsTime>timeSHS)&FTO,1);
    timeFTO=eventsTime(indFTO);
    indFHS=find((eventsTime>timeFTO)&FHS,1);
    timeFHS=eventsTime(indFHS);
    indSTO=find((eventsTime>timeFHS)&STO,1);
    timeSTO=eventsTime(indSTO);
    indSHS2=inds(step+1);
    timeSHS2=eventsTime(indSHS2);
    indFTO2=find((eventsTime>timeSHS2)&FTO,1);
    timeFTO2=eventsTime(indFTO2);
    
    t=round(mean([indSHS indFTO indFHS indSTO indSHS2 indFTO2])*f_params/f_events);
    
    if good(step)

        %My very nice way:
        COPrangeF(t)=min(COP(2,indSHS:indFHS))-max(COP(2,indFTO:indSTO));
        COPrangeS(t)=min(COP(2,indFHS:indSHS2))-max(COP(2,indSTO:indFTO2));
        
        %Mawase's way based on TO and HS
        %COPrangeF(step)=COP(2,indFTO)-COP(2,indSHS);
        %COPrangeS(step)=COP(2,indSTO)-COP(2,indFHS);
        %May way based on TO and HS
%         COPrangeF(step)=COP(2,indFTO)-COP(2,indFHS);
%         COPrangeS(step)=COP(2,indSTO)-COP(2,indSHS);
        COPsym(t)=(COPrangeF(t)-COPrangeS(t))/(COPrangeF(t)+COPrangeS(t));
        %Mawase's ugly way:
        COPrangeF(t)=min(COP(2,indSHS:indFHS))-max(COP(2,max([indSHS-100,1]):indFTO));
        COPrangeS(t)=min(COP(2,indFHS:indSHS2))-max(COP(2,indFTO:indSTO));
        COPsymM(t)=(COPrangeF(t)-COPrangeS(t))/(COPrangeF(t)+COPrangeS(t));
        handHolding(t)=sum(mean(abs(GRFDataH)))>2;
    end

end

for i=1:length(paramlabels)
    eval(['data(:,i)=',paramlabels{i},';'])
end

out=labTimeSeries(data,eventsTime(1),sampPeriod,paramlabels);

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

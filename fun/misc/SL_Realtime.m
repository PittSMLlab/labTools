% SL Realtime
%
%A script designed to be used by a Nexus 2 pipeline shortly after creation
%of a c3d file.
%
%The script opens the desired c3d and quickly computes the following
%parameters using the same methods as Labtools but without initializing the
%classes.
%
%Parameters: 
% 1. Average Step Length (ANK-ANK distance)
% 2. Cadence
%
%WDA 4/11/2016


%% Load Data

%Nexus must be open, offline, and the desired trial loaded
vicon = ViconNexus();
[path,filename] = vicon.GetTrialName;%Ask Nexus which trial is open
filename = [filename '.c3d'];

%use these two lines when processing c3d files not open in Nexus
% commandwindow()
% [filename,path] = uigetfile('*.c3d','Please select the c3d file of interest:');

H = btkReadAcquisition([path filename]);

%Using same method as Labtools, determine analog data
[analogs,analogsInfo] = btkGetAnalogs(H);

relData=[];
forceLabels ={};
units={};
fieldList=fields(analogs);
showWarning = false;
for j=1:length(fieldList);%parse analog channels by force, moment, cop
    %if strcmp(fieldList{j}(end-2),'F') || strcmp(fieldList{j}(end-2),'M') %Getting fields that end in F.. or M.. only
    if strcmp(fieldList{j}(1),'F') || strcmp(fieldList{j}(1),'M') || ~isempty(strfind(fieldList{j},'Force')) || ~isempty(strfind(fieldList{j},'Moment'))
        if ~strcmpi('x',fieldList{j}(end-1)) && ~strcmpi('y',fieldList{j}(end-1)) && ~strcmpi('z',fieldList{j}(end-1))
            warning(['loadTrials:GRFs','Found force/moment data that does not correspond to any of the expected directions (x,y or z). Discarding channel ' fieldList{j}])
        else
            switch fieldList{j}(end)%parse devices
                case '1' %Forces/moments ending in '1' area assumed to be of left treadmill belt
                    forceLabels{end+1} = ['L',fieldList{j}(end-2:end-1)];
                    units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
                    relData=[relData,analogs.(fieldList{j})];
                case '2' %Forces/moments ending in '2' area assumed to be of right treadmill belt
                    forceLabels{end+1} = ['R',fieldList{j}(end-2:end-1)];
                    units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
                    relData=[relData,analogs.(fieldList{j})];
                case '4'%Forces/moments ending in '4' area assumed to be of handrail
                    forceLabels{end+1} = ['H',fieldList{j}(end-2:end-1)];
                    units{end+1}=eval(['analogsInfo.units.',fieldList{j}]);
                    relData=[relData,analogs.(fieldList{j})];
                otherwise
                    showWarning=true;%%HH moved warning outside loop on 6/3/2015 to reduce command window output
            end
            analogs=rmfield(analogs,fieldList{j}); %Just to save memory space
        end
    end
end
if showWarning
    warning(['loadTrials:GRFs','Found force/moment data in trial ' filename ' that does not correspond to any of the expected channels (L=1, R=2, H=4). Data discarded.'])
end

forces = relData;

clear analogs* %Save memory space, no longer need analog data, it was already loaded
clear relData



%Get marker data
[markers,markerInfo]=btkGetMarkers(H);
relData=[];
fieldList=fields(markers);
markerList={};

%Check marker labels are good in .c3d files
mustHaveLabels={'LHIP','RHIP','LANK','RANK','RHEE','LHEE','LTOE','RTOE','RKNE','LKNE'};%we don't really care if there is RPSIS RASIS LPSIS LASIS or anything else really
labelPresent=false(1,length(mustHaveLabels));
for i=1:length(fieldList)
    newFieldList{i}=findLabel(fieldList{i});
    labelPresent=labelPresent+ismember(mustHaveLabels,newFieldList{i});
end
for j=1:length(fieldList);
    if length(fieldList{j})>2 && ~strcmp(fieldList{j}(1:2),'C_')  %Getting fields that do NOT start with 'C_' (they correspond to unlabeled markers in Vicon naming)
        relData=[relData,markers.(fieldList{j})];
        markerLabel=findLabel(fieldList{j});%make sure that the markers are always named the same after this point (ex - if left hip marker is labeled LGT, LHIP, or anyhting else it always becomes LHIP.)
        markerList{end+1}=[markerLabel 'x'];
        markerList{end+1}=[markerLabel 'y'];
        markerList{end+1}=[markerLabel 'z'];
    end
    markers=rmfield(markers,fieldList{j}); %Save memory
end

markers = relData;
clear H
%*******************************************************************************
%% Extract Events

[~,~,lfz] = intersect('LFz',forceLabels);
[~,~,rfz] = intersect('RFz',forceLabels);

[LHS,RHS,LTO,RTO] = getEventsFromForces(forces(:,lfz),forces(:,rfz),100);

%% Compute parameters

%up sample to match forceplate data
%check sampling frequency of forces (could be 1000 or 2000 Hz)
if length(forces)/1000 == length(markers)/100
    markers1000 = interp1(markers,[1:1/10:length(markers)]);
elseif length(forces)/2000 == length(markers)/100
    markers1000 = interp1(markers,[1:1/20:length(markers)]);
else
    disp('Warning: Unknown sampling frequency in analog data!');
end
markers1000(end,:)=[];

[~,rank,~] = intersect(markerList,'RANKy');
[~,lank,~] = intersect(markerList,'LANKy');

RANKY = markers1000(:,rank);
LANKY = markers1000(:,lank);

% figure(1)
% plot(0:10:length(markers)*10-1,markers(:,rank),'LineWidth',3);
% hold on
% plot(0:length(RANKY)-1,RANKY)

RHS = find(RHS);
LHS = find(LHS);

short = min([length(RHS) length(LHS)]);
if short<0.75*max([length(RHS) length(LHS)])%check to see if one of the legs has significantly less data than the other
    disp(['Warning!! Missing significant # of steps. Large disparity in # of steps calculated between limbs, please verify data is accurate.']);
end

%step lengths*********************************************
Rgamma = LANKY(RHS(1:short))-RANKY(RHS(1:short));
Lgamma = RANKY(LHS(1:short))-LANKY(LHS(1:short));

%remove erroneous data
Rgamma(Rgamma==0)=[];
Lgamma(Lgamma==0)=[];
Rgamma(Rgamma<0)=[];
Lgamma(Lgamma<0)=[];
Rgamma(1:5)=[];
Lgamma(1:5)=[];
Rgamma(end-5:end)=[];
Lgamma(end-5:end)=[];

Rgammamean = nanmean(Rgamma);
Rgammastd = nanstd(Rgamma);
Lgammamean = nanmean(Lgamma);
Lgammastd = nanstd(Lgamma);

figure(2)
subplot(6,1,1)
plot(Rgamma,'Color',[195/255,4/255,4/255]);
title('Right Leg Step Lengths (mm)');
subplot(6,1,2)
plot(Lgamma,'Color',[15/255,129/255,6/255]);
title('Left Leg Step Lengths (mm)');

%Cadence**********************************************
if length(forces)/1000 == length(markers)/100
    duration = length(RANKY)/1000;
    time = 0:0.001:duration;
elseif length(forces)/2000 == length(markers)/100
    duration = length(RANKY)/2000;
    time = 0:0.0005:duration;
else
    disp('Warning: Unknown sampling frequency in analog data!');
end
    

time(end)=[];
Rcadence = 60./diff(time(RHS));
Lcadence = 60./diff(time(LHS));

%remove erroneous data
Rcadence(1:5) = [];
Lcadence(1:5) = [];
Rcadence(end-5:end)=[];
Lcadence(end-5:end)=[];
Rcadence(Rcadence<0)=[];
Lcadence(Lcadence<0)=[];
Rcadence(Rcadence>75)=[];
Lcadence(Lcadence>75)=[];

Rcadmean = nanmean(Rcadence);
Lcadmean = nanmean(Lcadence);
Rcadstd = nanstd(Rcadence);
Lcadstd = nanstd(Lcadence);

%*****************************************
%Step times
HS = [RHS; LHS];
HS = sort(HS);

[~,rind,~] = intersect(HS,RHS);
[~,lind,~] = intersect(HS,LHS);

%check to make sure events are spliced in the correct alternating order
%???

if HS(1) == RHS(1)%first event is RHS
    for z = 1:length(HS)-2
        Lsteptime(z) = time(HS(z+1))-time(HS(z));
        Rsteptime(z) = time(HS(z+2))-time(HS(z+1));
    end
else
    for z = 1:length(HS)-2
        Rsteptime(z) = time(HS(z+1))-time(HS(z));
        Lsteptime(z) = time(HS(z+2))-time(HS(z+1));
    end
end

Rsteptime(Rsteptime<=0)=[];
Lsteptime(Lsteptime<=0)=[];
Rsteptime(1:4) = [];
Lsteptime(1:4) = [];
Rsteptime(end-4:end)=[];
Lsteptime(end-4:end)=[];

rstmean = nanmean(Rsteptime);
lstmean = nanmean(Lsteptime);
rststd = nanstd(Rsteptime);
lststd = nanstd(Lsteptime);

figure(2)
subplot(6,1,3)
plot(Rcadence,'.-','Color',[195/255,4/255,4/255]);
title('Right Leg Cadence (steps/min)');
subplot(6,1,4)
plot(Lcadence,'.-','Color',[15/255,129/255,6/255]);
title('Left Leg Cadence (steps/min)');
subplot(6,1,5)
plot(Rsteptime,'Color',[195/255,4/255,4/255]);
title('Right Leg Step Time (s)');
ylim([0 1]);
subplot(6,1,6)
plot(Lsteptime,'Color',[15/255,129/255,6/255]);
title('Left Leg Step Time (s)');
ylim([0 1]);

%report the data
mesg = 'Mean R Step Length: ';
mesg = [mesg num2str(Rgammamean) ' stdev: ' num2str(Rgammastd)];
mesg = [mesg sprintf('\n')];
mesg = [mesg 'Mean L Step Length: ' num2str(Lgammamean) ' stdev: ' num2str(Lgammastd)];
mesg = [mesg sprintf('\n\n')];
mesg = [mesg 'Mean R Cadence: ' num2str(Rcadmean) ' stdev: ' num2str(Rcadstd)];
mesg = [mesg sprintf('\n')];
mesg = [mesg 'Mean L Cadence: ' num2str(Lcadmean) ' stdev: ' num2str(Lcadstd)];
mesg = [mesg sprintf('\n\n')];
mesg = [mesg 'Mean R Step Time: ' num2str(rstmean) ' stedev: ' num2str(rststd)];
mesg = [mesg sprintf('\n')];
mesg = [mesg 'Mean L Step Time: ' num2str(lstmean) ' stedev: ' num2str(lststd)];
H = msgbox(mesg,'Metrics');

disp(mesg)

%% Save data

try
RTdata = struct();%initialize save structure
RTdata.trialname = filename;
RTdata.path = path;
RTdata.creationdate = clock;
RTdata.forcedata = forces;
RTdata.forcelabels = forceLabels;
RTdata.markerdata = markers;
RTdata.markerlabels = markerList;
RTdata.Rsteplengths = Rgamma;
RTdata.Lsteplengths = Lgamma;
RTdata.Rcadence = Rcadence;
RTdata.Lcadence = Lcadence;
RTdata.Rsteptime = Rsteptime;
RTdata.Lsteptime = Lsteptime;
RTdata.time = time;

fn = strrep(datestr(clock),'-','');

filesave = [path fn(1:9) '_' filename(1:end-4) '_SL_Realtime'];

save(filesave,'RTdata');

catch ME
    
    throw(ME)
    
end


% clear all














%% SL Realtime Alpha — Step Length, Cadence, and Alpha Computation
% author: WDA
% date: 4/11/2016
% purpose: Extended version of SL_Realtime that also computes alpha
%   (hip-to-ankle distance) and X (cross-limb hip-to-ankle) parameters.
%   Designed to be run by a Nexus 2 pipeline shortly after c3d file
%   creation.
%
% Parameters computed:
%   1. Average Step Length (ANK-ANK distance)
%   2. Cadence
%   3. Step time
%   4. Alpha (hip COM to leading ankle at heel strike)
%   5. X (cross-limb alpha)

%% Load Data

% Nexus must be open, offline, and the desired trial loaded
vicon = ViconNexus();
[path, filename] = vicon.GetTrialName;  % ask Nexus which trial is open
filename = [filename '.c3d'];

%use these two lines when processing c3d files not open in Nexus
% commandwindow()
% [filename,path] = uigetfile('*.c3d','Please select the c3d file of interest:');

H = btkReadAcquisition([path filename]);

% use same method as labTools to determine analog data
[analogs, analogsInfo] = btkGetAnalogs(H);

relData      = [];
forceLabels  = {};
units        = {};
fieldList    = fields(analogs);
showWarning  = false;

for jj = 1:length(fieldList)   % parse analog channels by force/moment
    fld = fieldList{jj};
    if strcmp(fld(1), 'F') || strcmp(fld(1), 'M') || ...
            ~isempty(strfind(fld, 'Force')) || ...
            ~isempty(strfind(fld, 'Moment'))
        if ~strcmpi('x', fld(end-1)) && ~strcmpi('y', fld(end-1)) ...
                && ~strcmpi('z', fld(end-1))
            warning(['loadTrials:GRFs', 'Found force/moment data ' ...
                'that does not correspond to any expected direction ' ...
                '(x, y or z). Discarding channel ' fld])
        else
            switch fld(end)     % parse by device number
                case '1'        % left treadmill belt
                    forceLabels{end+1} = ['L', fld(end-2:end-1)]; %#ok<AGROW>
                    units{end+1} = eval(['analogsInfo.units.' fld]); %#ok<AGROW>
                    relData = [relData, analogs.(fld)]; %#ok<AGROW>
                case '2'        % right treadmill belt
                    forceLabels{end+1} = ['R', fld(end-2:end-1)]; %#ok<AGROW>
                    units{end+1} = eval(['analogsInfo.units.' fld]); %#ok<AGROW>
                    relData = [relData, analogs.(fld)]; %#ok<AGROW>
                case '4'        % handrail
                    forceLabels{end+1} = ['H', fld(end-2:end-1)]; %#ok<AGROW>
                    units{end+1} = eval(['analogsInfo.units.' fld]); %#ok<AGROW>
                    relData = [relData, analogs.(fld)]; %#ok<AGROW>
                otherwise
                    showWarning = true; % warn outside loop to reduce output
            end
            analogs = rmfield(analogs, fld); % free memory
        end
    end
end
if showWarning
    warning(['loadTrials:GRFs', 'Found force/moment data in trial ' ...
        filename ' that does not correspond to any expected channel ' ...
        '(L=1, R=2, H=4). Data discarded.'])
end

forces = relData;
clear analogs* relData

%% Load Marker Data
[markers, markerInfo] = btkGetMarkers(H); %#ok<ASGLU>
relData    = [];
fieldList  = fields(markers);
markerList = {};

% verify required marker labels are present
mustHaveLabels = {'LHIP','RHIP','LANK','RANK','RHEE','LHEE', ...
    'LTOE','RTOE','RKNE','LKNE'};
labelPresent = false(1, length(mustHaveLabels));
for ii = 1:length(fieldList)
    newFieldList{ii} = findLabel(fieldList{ii}); %#ok<AGROW>
    labelPresent = labelPresent + ...
        ismember(mustHaveLabels, newFieldList{ii});
end
for j=1:length(fieldList);
    if length(fieldList{j})>2 && ~strcmp(fieldList{j}(1:2),'C_')  %Getting fields that do NOT start with 'C_' (they correspond to unlabeled markers in Vicon naming)
        relData=[relData,markers.(fieldList{j})];
        markerLabel=findLabel(fieldList{j});%make sure that the markers are always named the same after this point (ex - if left hip marker is labeled LGT, LHIP, or anyhting else it always becomes LHIP.)
        markerList{end+1}=[markerLabel 'x'];
        markerList{end+1}=[markerLabel 'y'];
        markerList{end+1}=[markerLabel 'z'];

    end
    markers = rmfield(markers, fld);        % free memory
end

markers = relData;
clear H

%% Extract Events
[~, ~, lfz] = intersect('LFz', forceLabels);
[~, ~, rfz] = intersect('RFz', forceLabels);

[LHS, RHS, LTO, RTO] = getEventsFromForces( ...  %#ok<ASGLU>
    forces(:,lfz), forces(:,rfz), 100);

%% Compute Parameters

if length(forces)/1000 == length(markers)/100
    markers1000 = interp1(markers,[1:1/10:length(markers)]);
elseif length(forces)/2000 == length(markers)/100
    markers1000 = interp1(markers,[1:1/20:length(markers)]);
% upsample markers to match force plate sampling rate
else
    disp('Warning: Unknown sampling frequency in analog data!');
end
markers1000(end, :) = [];

[~, rank, ~] = intersect(markerList, 'RANKy');
[~, lank, ~] = intersect(markerList, 'LANKy');
[~, rhip, ~] = intersect(markerList, 'RHIPy');
[~, lhip, ~] = intersect(markerList, 'LHIPy');

RANKY = markers1000(:, rank);
LANKY = markers1000(:, lank);
RHIPY = markers1000(:, rhip);
LHIPY = markers1000(:, lhip);

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

%alpha *********************************************
Ralpha = ((LHIPY(RHS(1:short))+RHIPY(RHS(1:short)))./2)-RANKY(RHS(1:short)); 
Lalpha = ((LHIPY(LHS(1:short))+RHIPY(LHS(1:short)))./2)-LANKY(LHS(1:short));

%remove erroneous data
Ralpha(Ralpha==0)=[];
Lalpha(Lalpha==0)=[];
Ralpha(Ralpha<0)=[];
Lalpha(Lalpha<0)=[];
Ralpha(1:5)=[];
Lalpha(1:5)=[];
Ralpha(end-5:end)=[];
Lalpha(end-5:end)=[];

Ralphamean = nanmean(Ralpha);
Ralphastd = nanstd(Ralpha);
Lalphamean = nanmean(Lalpha);
Lalphastd = nanstd(Lalpha);

%X *********************************************
RX = ((LHIPY(LHS(1:short))+RHIPY(LHS(1:short)))./2)-RANKY(LHS(1:short)); 
LX = ((LHIPY(RHS(1:short))+RHIPY(RHS(1:short)))./2)-LANKY(RHS(1:short)); 


%remove erroneous data
RX(RX==0)=[];
LX(LX==0)=[];
RX(RX>0)=[];
LX(LX>0)=[];
RX(1:5)=[];
LX(1:5)=[];
RX(end-5:end)=[];
LX(end-5:end)=[];

RXmean = nanmean(RX);
RXstd = nanstd(RX);
LXmean = nanmean(LX);
LXstd = nanstd(LX);
% 
% figure(2)
% subplot(6,1,1)
% plot(Rgamma,'Color',[195/255,4/255,4/255]);
% title('Right Leg Step Lengths (mm)');
% subplot(6,1,2)
% plot(Lgamma,'Color',[15/255,129/255,6/255]);
% title('Left Leg Step Lengths (mm)');

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

mesg = [mesg sprintf('\n\n')];
mesg = [mesg 'Mean R alpha: ' num2str(Ralphamean) ' stdev: ' num2str(Ralphastd)];
mesg = [mesg sprintf('\n')];
mesg = [mesg 'Mean L alpha: ' num2str(Lalphamean) ' stdev: ' num2str(Lalphastd)];

mesg = [mesg sprintf('\n\n')];
mesg = [mesg 'Mean R X: ' num2str(RXmean) ' stdev: ' num2str(RXstd)];
mesg = [mesg sprintf('\n')];
mesg = [mesg 'Mean L X: ' num2str(LXmean) ' stdev: ' num2str(LXstd)];

mesg = [mesg sprintf('\n\n')];
mesg = [mesg 'Mean R R: ' num2str(RXmean/Ralphamean)];
mesg = [mesg sprintf('\n')];
mesg = [mesg 'Mean L R: ' num2str(LXmean/Lalphamean)];



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














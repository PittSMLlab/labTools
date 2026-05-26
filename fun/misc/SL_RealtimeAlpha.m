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

for jj = 1:length(fieldList)
    fld = fieldList{jj};
    % skip unlabeled markers (Vicon names them with 'C_' prefix)
    if length(fld) > 2 && ~strcmp(fld(1:2), 'C_')
        relData = [relData, markers.(fld)]; %#ok<AGROW>
        markerLabel = findLabel(fld);       % normalize marker name
        markerList{end+1} = [markerLabel 'x']; %#ok<AGROW>
        markerList{end+1} = [markerLabel 'y']; %#ok<AGROW>
        markerList{end+1} = [markerLabel 'z']; %#ok<AGROW>
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

% upsample markers to match force plate sampling rate
markerHz = 100;                 % marker capture rate (Hz)
forceHz1 = 1000;                % possible force plate rate 1 (Hz)
forceHz2 = 2000;                % possible force plate rate 2 (Hz)
if length(forces) / forceHz1 == length(markers) / markerHz
    markers1000 = interp1(markers, 1:1/10:length(markers));
elseif length(forces) / forceHz2 == length(markers) / markerHz
    markers1000 = interp1(markers, 1:1/20:length(markers));
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
stepDisparityThresh = 0.75;     % flag if short leg has <75% of other's steps
if short < stepDisparityThresh * max([length(RHS) length(LHS)])
    disp(['Warning!! Missing significant # of steps. Large disparity ' ...
        'in # of steps between limbs. Please verify data.']);
end

Rgamma(1:5)=[];
Lgamma(1:5)=[];
Rgamma(end-5:end)=[];
Lgamma(end-5:end)=[];
%% Step Lengths
Rgamma = LANKY(RHS(1:short)) - RANKY(RHS(1:short));
Lgamma = RANKY(LHS(1:short)) - LANKY(LHS(1:short));

Rgamma(Rgamma == 0) = [];
Lgamma(Lgamma == 0) = [];
Rgamma(Rgamma < 0)  = [];
Lgamma(Lgamma < 0)  = [];

Rgammamean = mean(Rgamma, 'omitnan');
Rgammastd  = std(Rgamma, 0, 'omitnan');
Lgammamean = mean(Lgamma, 'omitnan');
Lgammastd  = std(Lgamma, 0, 'omitnan');

figure(2)
subplot(6, 1, 1)
plot(Rgamma, 'Color', [195/255, 4/255, 4/255]);
title('Right Leg Step Lengths (mm)');
subplot(6, 1, 2)
plot(Lgamma, 'Color', [15/255, 129/255, 6/255]);
title('Left Leg Step Lengths (mm)');

Ralpha(1:5)=[];
Lalpha(1:5)=[];
Ralpha(end-5:end)=[];
Lalpha(end-5:end)=[];
RX(1:5)=[];
LX(1:5)=[];
RX(end-5:end)=[];
LX(end-5:end)=[];
if length(forces)/1000 == length(markers)/100
    duration = length(RANKY)/1000;
%% Alpha (hip COM to leading ankle at heel strike)
Ralpha = ((LHIPY(RHS(1:short)) + RHIPY(RHS(1:short))) ./ 2) ...
    - RANKY(RHS(1:short));
Lalpha = ((LHIPY(LHS(1:short)) + RHIPY(LHS(1:short))) ./ 2) ...
    - LANKY(LHS(1:short));

Ralpha(Ralpha == 0) = [];
Lalpha(Lalpha == 0) = [];
Ralpha(Ralpha < 0)  = [];
Lalpha(Lalpha < 0)  = [];

Ralphamean = mean(Ralpha, 'omitnan');
Ralphastd  = std(Ralpha, 0, 'omitnan');
Lalphamean = mean(Lalpha, 'omitnan');
Lalphastd  = std(Lalpha, 0, 'omitnan');

%% X (cross-limb hip COM to trailing ankle at heel strike)
RX = ((LHIPY(LHS(1:short)) + RHIPY(LHS(1:short))) ./ 2) ...
    - RANKY(LHS(1:short));
LX = ((LHIPY(RHS(1:short)) + RHIPY(RHS(1:short))) ./ 2) ...
    - LANKY(RHS(1:short));

RX(RX == 0) = [];
LX(LX == 0) = [];
RX(RX > 0)  = [];
LX(LX > 0)  = [];

RXmean = mean(RX, 'omitnan');
RXstd  = std(RX, 0, 'omitnan');
LXmean = mean(LX, 'omitnan');
LXstd  = std(LX, 0, 'omitnan');

%% Cadence
    time = 0:0.001:duration;
elseif length(forces)/2000 == length(markers)/100
    duration = length(RANKY)/2000;
    time = 0:0.0005:duration;
else
    disp('Warning: Unknown sampling frequency in analog data!');
end
Rcadence(1:5) = [];
Lcadence(1:5) = [];
Rcadence(end-5:end)=[];
Lcadence(end-5:end)=[];

time(end)  = [];
Rcadence   = 60 ./ diff(time(RHS));
Lcadence   = 60 ./ diff(time(LHS));

Rcadence(Rcadence < 0) = [];
Lcadence(Lcadence < 0) = [];
maxCadence = 75;                % discard obviously erroneous cadence (steps/min)
Rcadence(Rcadence > maxCadence) = [];
Lcadence(Lcadence > maxCadence) = [];

Rcadmean = mean(Rcadence, 'omitnan');
Lcadmean = mean(Lcadence, 'omitnan');
Rcadstd  = std(Rcadence, 0, 'omitnan');
Lcadstd  = std(Lcadence, 0, 'omitnan');

%% Step Times
HS = sort([RHS; LHS]);

[~, rind, ~] = intersect(HS, RHS); %#ok<ASGLU>
[~, lind, ~] = intersect(HS, LHS); %#ok<ASGLU>

if HS(1) == RHS(1)              % first event is RHS
    for ii = 1:length(HS)-2
        Lsteptime(ii) = time(HS(ii+1)) - time(HS(ii));   %#ok<AGROW>
        Rsteptime(ii) = time(HS(ii+2)) - time(HS(ii+1)); %#ok<AGROW>
    end
else
    for ii = 1:length(HS)-2
        Rsteptime(ii) = time(HS(ii+1)) - time(HS(ii));   %#ok<AGROW>
        Lsteptime(ii) = time(HS(ii+2)) - time(HS(ii+1)); %#ok<AGROW>
    end
end

Rsteptime(1:4) = [];
Lsteptime(1:4) = [];
Rsteptime(end-4:end)=[];
Lsteptime(end-4:end)=[];
Rsteptime(Rsteptime <= 0)     = [];
Lsteptime(Lsteptime <= 0)     = [];

rstmean = mean(Rsteptime, 'omitnan');
lstmean = mean(Lsteptime, 'omitnan');
rststd  = std(Rsteptime, 0, 'omitnan');
lststd  = std(Lsteptime, 0, 'omitnan');

figure(2)
subplot(6, 1, 3)
plot(Rcadence, '.-', 'Color', [195/255, 4/255, 4/255]);
title('Right Leg Cadence (steps/min)');
subplot(6, 1, 4)
plot(Lcadence, '.-', 'Color', [15/255, 129/255, 6/255]);
title('Left Leg Cadence (steps/min)');
subplot(6, 1, 5)
plot(Rsteptime, 'Color', [195/255, 4/255, 4/255]);
title('Right Leg Step Time (s)');
ylim([0 1]);
subplot(6, 1, 6)
plot(Lsteptime, 'Color', [15/255, 129/255, 6/255]);
title('Left Leg Step Time (s)');
ylim([0 1]);

%% Report Results
mesg = 'Mean R Step Length: ';
mesg = [mesg num2str(Rgammamean) ' stdev: ' num2str(Rgammastd)];
mesg = [mesg sprintf('\n')];
mesg = [mesg 'Mean L Step Length: ' ...
    num2str(Lgammamean) ' stdev: ' num2str(Lgammastd)];
mesg = [mesg sprintf('\n\n')];
mesg = [mesg 'Mean R Cadence: ' ...
    num2str(Rcadmean) ' stdev: ' num2str(Rcadstd)];
mesg = [mesg sprintf('\n')];
mesg = [mesg 'Mean L Cadence: ' ...
    num2str(Lcadmean) ' stdev: ' num2str(Lcadstd)];
mesg = [mesg sprintf('\n\n')];
mesg = [mesg 'Mean R Step Time: ' ...
    num2str(rstmean) ' stdev: ' num2str(rststd)];
mesg = [mesg sprintf('\n')];
mesg = [mesg 'Mean L Step Time: ' ...
    num2str(lstmean) ' stdev: ' num2str(lststd)];
mesg = [mesg sprintf('\n\n')];
mesg = [mesg 'Mean R alpha: ' ...
    num2str(Ralphamean) ' stdev: ' num2str(Ralphastd)];
mesg = [mesg sprintf('\n')];
mesg = [mesg 'Mean L alpha: ' ...
    num2str(Lalphamean) ' stdev: ' num2str(Lalphastd)];
mesg = [mesg sprintf('\n\n')];
mesg = [mesg 'Mean R X: ' num2str(RXmean) ' stdev: ' num2str(RXstd)];
mesg = [mesg sprintf('\n')];
mesg = [mesg 'Mean L X: ' num2str(LXmean) ' stdev: ' num2str(LXstd)];
mesg = [mesg sprintf('\n\n')];
mesg = [mesg 'Mean R R: ' num2str(RXmean / Ralphamean)];
mesg = [mesg sprintf('\n')];
mesg = [mesg 'Mean L R: ' num2str(LXmean / Lalphamean)];

H = msgbox(mesg, 'Metrics');    %#ok<NASGU>
disp(mesg)

%% Save Data
try
    RTdata              = struct();
    RTdata.trialname    = filename;
    RTdata.path         = path;
    RTdata.creationdate = clock;
    RTdata.forcedata    = forces;
    RTdata.forcelabels  = forceLabels;
    RTdata.markerdata   = markers;
    RTdata.markerlabels = markerList;
    RTdata.Rsteplengths = Rgamma;
    RTdata.Lsteplengths = Lgamma;
    RTdata.Rcadence     = Rcadence;
    RTdata.Lcadence     = Lcadence;
    RTdata.Rsteptime    = Rsteptime;
    RTdata.Lsteptime    = Lsteptime;
    RTdata.time         = time;

    fn       = strrep(datestr(clock), '-', '');
    filesave = [path fn(1:9) '_' filename(1:end-4) '_SL_Realtime'];
    save(filesave, 'RTdata');
catch ME
    throw(ME)
end

function stance = getStanceFromToeAndHeel(ankKin, toeKin, fsample)
%GETSTANCEFROMTOENANDHEEL Estimate stance phase from ankle and toe kinematics.
%
%   Combines two stance detection methods — velocity thresholding
% (getStance) and acceleration thresholding (getStance3) — and removes
% short phases. getStance2 (Hough-transform based) is available as an
% alternative but is currently disabled.
%
% Inputs:
%   ankKin  - N×3 double, ankle marker position (mm)
%   toeKin  - N×3 double, toe marker position (mm)
%   fsample - scalar double, sampling frequency (Hz)
%
% Outputs:
%   stance - N×1 logical, stance phase (true = stance)
%
% Toolbox Dependencies: None
%
% See also GETSTANCEFROMFORCES, DELETESHORTPHASES, GETEVENTSFROMTOENANDHEEL.

stance3 = getStance3(ankKin, toeKin, fsample); % threshold accelerations
% stance2 = getStance2(ankKin, toeKin, fsample); % Hough + thresholding
stance1 = getStance(ankKin, toeKin, fsample);   % threshold velocities
% stance1 = stance2;
% stance3 = stance2;

% stance = (stance1 & stance2) | (stance1 & stance3) | (stance3 & stance2);
stance = stance1;
% remove stance phases of less than 200 ms
stance = deleteShortPhases(stance, fsample, 0.2);

%IDEA: instead of using pure (classical) logic, use fuzzy logic, with a
%smoothing kernel, so that all samples in a neighbourhood get a say on the
%value of a particular sample.
%This might be particularly helpful to get rid of quantization noise
%(kernel with support of 3 samples: the central one, and one to each side),
%and also with some other types of noise (NOT SURE: it might make it more
%sensible to big errors in only one of the estimations)
end

%% Method 1: try to find full stance points and threshold relative speed
function stance = getStance(ankKin, toeKin, fsample)
%GETSTANCE Estimate stance from ankle and toe marker velocity.
%
%   Identifies core stance (full foot contact) as periods of low relative
% speed between ankle and toe markers, determines ground reference speed,
% then classifies stance when ankle or toe speed relative to ground falls
% below empirical thresholds.
%
% Inputs:
%   ankKin  - N×3 double, ankle marker position (mm)
%   toeKin  - N×3 double, toe marker position (mm)
%   fsample - scalar double, sampling frequency (Hz)
%
% Outputs:
%   stance - N×1 logical, stance phase (true = stance)

%% Step 1: calculate speed
% va(:,1)=derive(ankKin(:,1),fsample);
% va(:,2)=derive(ankKin(:,2),fsample);
% vt(:,1)=derive(toeKin(:,1),fsample);
% vt(:,2)=derive(toeKin(:,2),fsample);
va = fsample * diff(ankKin);
va(end+1, :) = va(end, :);
vt = fsample * diff(toeKin);
vt(end+1, :) = vt(end, :);
fcut = 0.5 * 10 / fsample; % half-Nyquist for 10 Hz cutoff
va(isnan(va)) = 10000;
vt(isnan(vt)) = 10000;
vaf = idealLPF(va, fcut);
vtf = idealLPF(vt, fcut);

%% Step 2: get core stance (full feet on ground) speed
relV    = vaf - vtf;                           % relative speed (mm/s)
modRelV = sqrt(sum(relV .^ 2, 2));             % magnitude of relative speed
coreStanceSpeedThresh = 150;                   % max relative speed for core stance (mm/s)
coreStance = (modRelV < coreStanceSpeedThresh);
coreStance = deleteShortPhases(coreStance, fsample, 0.05); % min core stance duration (s)

stanceSpeed = mode(10 * round(va(coreStance, :) / 10)); % most common stance speed, rounded to nearest cm/s

%% Step 3: threshold speed relative to ground for stance candidates
ankV = va - ones(size(va, 1), 1) * stanceSpeed; % ankle speed relative to ground
toeV = vt - ones(size(vt, 1), 1) * stanceSpeed; % toe speed relative to ground

modAnkV = sqrt(sum(ankV .^ 2, 2));
modToeV = sqrt(sum(toeV .^ 2, 2));

%% Step 4: classify stance from ankle OR toe stance
velThreshA = 0.8 * median(modAnkV); % empirical threshold, see commented line below
velThreshA = 500;                    % ankle velocity threshold (mm/s)
velThreshT = 0.8 * median(modToeV); % empirical threshold, see commented line below
velThreshT = 250;                    % toe velocity threshold (mm/s)
ankStance  = modAnkV < velThreshA;
toeStance  = modToeV < velThreshT;

stance = ankStance | toeStance;

%% Eliminate stance and swing phases shorter than 200 ms
stance = deleteShortPhases(stance, fsample, 0.2);
%
% figure
% hold on
% %plot(aa)
% %plot(at)
% plot(modAnkV,'m')
% %plot(modAnkAf,'b')
% plot(modToeV,'r')
% %plot(modToeAf,'k')
% plot(mean(modAnkV)*double(stance),'g')
% hold off

end

%% Method 2: find full stance points and threshold relative distance
%Get stance from plane floor + thresholding
%getEvents Extracts heel-strike/toe-off events from the relative position
%of the heel marker to the hip marker

%INPUTS:
%Lheel,Rheel,Lhip,Rhip: 3xN matrices with 3D marker location
%fsample: sampling frequency

function stance = getStance2(Rheel, Rtoe, fsample)
backwards = false; % direction flag; stance detection should not be direction-dependent
thetas    = [-90:0.2:-70, 70:0.2:89.8]; % Hough transform angle search range (deg)
rho_res   = 0.5;
for jj = 1:2
    flag = false;
    clear raux aux1 dist2Floor RHO THETA H A th r m n
    switch jj
        case 1
            relevantKin = medfilt1(Rheel); % non-strict filtering to kill far outliers
            tol  = 4;  % threshold to surely catalogue a point as 'on floor'
            tol2 = 8;  % min distance to catalogue as 'toe-off' or 'heel-strike'
            N    = 3;
            N2   = 1;
        case 2
            relevantKin = medfilt1(Rtoe);
            tol  = 4;
            tol2 = 10;
            N    = 15;
            N2   = 1;
    end

    relevantKin(abs(relevantKin(:, 1) - median(relevantKin(:, 1))) ...
        > 5 * std(relevantKin(:, 1)), 1) = 0;
    relevantKin(abs(relevantKin(:, 2) - median(relevantKin(:, 2))) ...
        > 5 * std(relevantKin(:, 2)), 2) = 0;
    raux = round(relevantKin);

    %In y: limit values to a 500mm range
    %In x: limit values to a 2000mm range
    %Throw everything outside those limits

    %A=zeros(max(raux(:,1)-min(raux(:,1))+1),(max(raux(:,2)-min(raux(:,2))+1)));
    %for i=1:length(raux(:,1))
    %A(raux(i,1)-min(raux(:,1))+1,raux(i,2)-min(raux(:,2))+1)=A(raux(i,1)-min(raux(:,1))+1,raux(i,2)-min(raux(:,2))+1)+1;
    %end
    A = sparse(raux(:, 1) - min(raux(:, 1)) + 1, ...
               raux(:, 2) - min(raux(:, 2)) + 1, 1);
    try
        [H, THETA, RHO] = hough(full(A)', 'RhoResolution', rho_res, ...
            'Theta', thetas);
    catch
        disp('Caught exception when computing Hough transform');
    end
    [~, ind] = max(H(:));
    [m, n]   = ind2sub(size(H), ind);
    th = -THETA(n) / 90 * pi / 2;
    r  = RHO(m);
    dist2Floor = (relevantKin(:, 1) - min(relevantKin(:, 1)) + 1) * cos(th) ...
        - (relevantKin(:, 2) - min(relevantKin(:, 2)) + 1) * sin(th) - r + 1;

    aux1   = relevantKin(:, 1) * sin(th) + relevantKin(:, 2) * cos(th); % projection over the floor
    stance = (abs(dist2Floor) < tol) & ([0; diff(aux1)] < 0); % points on the floor for sure

    if sum(stance) < 3
        % probable backwards trial
        disp('Warning: probable backwards trial')
        flag   = true;
        stance = (abs(dist2Floor) < tol) & ([0; diff(aux1)] > 0);
    end
    CoM_x = mean(relevantKin(stance, 1));
    CoM_y = mean(relevantKin(stance, 2));
    M = pca(relevantKin(stance, 1:2));
    try
        dist2Floor = (relevantKin(:, 1) - CoM_x) * M(1, 2) ...
            + (relevantKin(:, 2) - CoM_y) * M(2, 2); % corrected floor distance
    catch
        disp('Caught exception when computing distance to floor.');
    end

    if (~backwards) && (~flag)
        swing = ([0; diff(aux1)] > 0); % elements surely off the floor
    else
        swing = ([0; diff(aux1)] < 0);
    end
    % eliminate spurious swing samples
    swing = conv(double(swing), ones(2*N+1, 1), 'same') == 2*N+1; % erode
    swing = conv(double(swing), ones(2*N+1, 1), 'same') >= 1;     % dilate

    %%
    change = true;
    while change
        stance3 = conv(double(stance), ones(3, 1), 'same') >= 1;  % dilate
        stance4 = stance3 & ~swing;
        thresh  = max([3 * median(abs(dist2Floor(stance))), tol2]);
        stance5 = (abs(dist2Floor) < thresh);
        stance4 = stance4 & stance5;
        if any(stance4 ~= stance)
            stance = stance4;
            CoM_x  = mean(relevantKin(stance, 1));
            CoM_y  = mean(relevantKin(stance, 2));
            M      = pca(relevantKin(stance, 1:2));
            try
                dist2Floor = (relevantKin(:, 1) - CoM_x) * M(1, 2) ...
                    + (relevantKin(:, 2) - CoM_y) * M(2, 2);
            catch
                disp('Caught exception when computing distance to floor.');
            end
        else
            change = false;
            stance = conv(double(stance4), ones(2*N2+1, 1), 'same') == 2*N2+1; % erode by N2
        end
    end

    % assign corresponding stance
    switch jj
        case 1
            stanceAnk = stance;
        case 2
            stanceToe = stance;
    end
end

% stance is when either toe or ankle is on the floor
stance = stanceAnk | stanceToe;

% delete short stance phases
stance = deleteShortPhases(stance, fsample, 0.25);
end

%% Method 3: get stance from marker acceleration (during stance, acc=0)
function stance = getStance3(ankKin,toeKin,fsample)
%Get stance from acceleration

%% Step 1: low pass filter and calculate acceleration
% Get velocities:
% va(:,1)=derive(ankKin(:,1),fsample); %fore-aft axis
% va(:,2)=derive(ankKin(:,2),fsample); %up-down axis
% vt(:,1)=derive(toeKin(:,1),fsample);
% vt(:,2)=derive(toeKin(:,2),fsample);
% Get accelerations:
% aa(:,1)=derive(va(:,1),fsample);
% aa(:,2)=derive(va(:,2),fsample);
% at(:,1)=derive(vt(:,1),fsample);
% at(:,2)=derive(vt(:,2),fsample);
aa=fsample^2*diff(diff(ankKin));
aa=[aa(1,:);aa;aa(end,:)];
at=fsample^2*diff(diff(toeKin));
at=[at(1,:);at;at(end,:)];
aa(isnan(aa))=100000;
at(isnan(at))=100000;

%% STEP 3: By thresholding difference with ground speed, get toe and ank stance candidates (sine qua non condition)
fcut=.5*30/fsample;
aaf(:,1)=idealLPF(aa(:,1),fcut);
aaf(:,2)=idealLPF(aa(:,2),fcut);
atf(:,1)=idealLPF(at(:,1),fcut);
atf(:,2)=idealLPF(at(:,2),fcut);
modAnkA=sqrt(sum(aaf.^2,2));
modToeA=sqrt(sum(atf.^2,2));

%filter=hann(50);
%modAnkAf=conv(modAnkA,filter,'same')/sum(filter);
%modToeAf=conv(modToeA,filter,'same')/sum(filter);
%toeThresh=.1*mean(modToeA(10:end-10));
%ankThresh=.1*mean(modAnkA(10:end-10));
accThresh = 5000; % acceleration threshold (mm/s²); empirical

%% Step 4: classify stance from ankle OR toe stance
ankStance = modAnkA < accThresh;
toeStance = modToeA < accThresh;

%ankStance = deleteShortPhases(ankStance,fsample,0.25);
%toeStance = deleteShortPhases(toeStance,fsample,0.25);
stance = ankStance | toeStance;

%% Eliminate stance and swing phases shorter than 200 ms
stance = deleteShortPhases(stance, fsample, 0.2);

% figure
% hold on
% %plot(aa)
% %plot(at)
% plot(modAnkA,'m')
% %plot(modAnkAf,'b')
% plot(modToeA,'r')
% %plot(modToeAf,'k')
% plot(.5*max(modAnkA)*double(stance),'g')
% hold off

end

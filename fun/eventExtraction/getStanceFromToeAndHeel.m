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

NAN_FILL_VEL          = 10000; % large sentinel to suppress NaN in idealLPF (mm/s)
VEL_THRESH_ANK        = 500;   % ankle speed threshold for stance (mm/s); empirical
VEL_THRESH_TOE        = 250;   % toe speed threshold for stance (mm/s); empirical
coreStanceSpeedThresh = 150;   % max relative ankle–toe speed for core stance (mm/s)

%% Step 1: calculate speed
% va(:,1)=derive(ankKin(:,1),fsample);
% va(:,2)=derive(ankKin(:,2),fsample);
% vt(:,1)=derive(toeKin(:,1),fsample);
% vt(:,2)=derive(toeKin(:,2),fsample);
ankleVel = fsample * diff(ankKin);
ankleVel(end+1, :) = ankleVel(end, :);
toeVel = fsample * diff(toeKin);
toeVel(end+1, :) = toeVel(end, :);
fcut = 10 / (2 * fsample); % ideal lowpass cutoff, normalized (10 Hz)
ankleVel(isnan(ankleVel)) = NAN_FILL_VEL;
toeVel(isnan(toeVel))     = NAN_FILL_VEL;
ankleVelFilt = idealLPF(ankleVel, fcut);
toeVelFilt   = idealLPF(toeVel, fcut);

%% Step 2: get core stance (full feet on ground) speed
relV    = ankleVelFilt - toeVelFilt;           % relative speed (mm/s)
modRelV = sqrt(sum(relV .^ 2, 2));             % magnitude of relative speed
coreStance = (modRelV < coreStanceSpeedThresh);
coreStance = deleteShortPhases(coreStance, fsample, 0.05); % min core stance duration (s)

% most common stance speed, rounded to nearest cm/s
stanceSpeed = mode(10 * round(ankleVel(coreStance, :) / 10));

%% Step 3: threshold speed relative to ground for stance candidates
ankV = ankleVel - ones(size(ankleVel, 1), 1) * stanceSpeed; % ankle speed relative to ground
toeV = toeVel   - ones(size(toeVel,   1), 1) * stanceSpeed; % toe   speed relative to ground

modAnkV = sqrt(sum(ankV .^ 2, 2));
modToeV = sqrt(sum(toeV .^ 2, 2));

%% Step 4: classify stance from ankle OR toe stance
% velThreshA = 0.8 * median(modAnkV); % empirical threshold, see commented line below
% velThreshT = 0.8 * median(modToeV); % empirical threshold, see commented line below
ankStance = modAnkV < VEL_THRESH_ANK;
toeStance = modToeV < VEL_THRESH_TOE;

stance = ankStance | toeStance;

%% Eliminate stance and swing phases shorter than 200 ms
stance = deleteShortPhases(stance, fsample, 0.2);
%
% figure
% hold on
% %plot(ankleAcc)
% %plot(toeAcc)
% plot(modAnkV,'m')
% %plot(ankleAccFilt,'b')
% plot(modToeV,'r')
% %plot(toeAccFilt,'k')
% plot(mean(modAnkV)*double(stance),'g')
% hold off

end

%% Method 2: find full stance points and threshold relative distance
function stance = getStance2(Rheel, Rtoe, fsample)
%GETSTANCE2 Estimate stance via Hough transform floor-plane detection.
%
%   Finds the floor plane using the Hough transform on 2D projections of
% heel and toe positions, then iteratively grows a set of "on-floor"
% points until they cover the full stance interval. This method is
% currently disabled in the calling function.
%
% Inputs:
%   Rheel   - N×3 double, heel marker position (mm)
%   Rtoe    - N×3 double, toe marker position (mm)
%   fsample - scalar double, sampling frequency (Hz)
%
% Outputs:
%   stance - N×1 logical, stance phase (true = stance)

% Named constants for Hough-based floor-plane detection
HOUGH_ANGLES    = [-90:0.2:-70, 70:0.2:89.8]; % angle search range (deg)
HOUGH_RHO_RES   = 0.5;  % Hough ρ resolution (mm)
OUTLIER_SD_MULT = 5;     % std-dev multiplier for outlier rejection

% Per-marker tolerance constants (mm)
HEEL_FLOOR_TOL      = 4;  % certain floor contact threshold, heel (mm)
HEEL_EVENT_TOL      = 8;  % heel-strike/toe-off boundary, heel (mm)
HEEL_ERODE_RADIUS   = 3;  % morphological erosion half-width, heel (samples)
TOE_FLOOR_TOL       = 4;  % certain floor contact threshold, toe (mm)
TOE_EVENT_TOL       = 10; % heel-strike/toe-off boundary, toe (mm)
TOE_ERODE_RADIUS    = 15; % morphological erosion half-width, toe (samples)
EVENT_DILATE_RADIUS = 1;  % final dilation half-width after convergence (samples)

backwards = false; % direction flag; stance detection should not be direction-dependent
for jj = 1:2
    flag = false;
    clear roundedKin projOnFloor dist2Floor RHO THETA H A th r m n
    switch jj
        case 1
            relevantKin = medfilt1(Rheel); % non-strict filtering to kill far outliers
            tol  = HEEL_FLOOR_TOL;
            tol2 = HEEL_EVENT_TOL;
            N    = HEEL_ERODE_RADIUS;
            N2   = EVENT_DILATE_RADIUS;
        case 2
            relevantKin = medfilt1(Rtoe);
            tol  = TOE_FLOOR_TOL;
            tol2 = TOE_EVENT_TOL;
            N    = TOE_ERODE_RADIUS;
            N2   = EVENT_DILATE_RADIUS;
    end

    relevantKin(abs(relevantKin(:, 1) - median(relevantKin(:, 1))) ...
        > OUTLIER_SD_MULT * std(relevantKin(:, 1)), 1) = 0;
    relevantKin(abs(relevantKin(:, 2) - median(relevantKin(:, 2))) ...
        > OUTLIER_SD_MULT * std(relevantKin(:, 2)), 2) = 0;
    roundedKin = round(relevantKin);

    %In y: limit values to a 500mm range
    %In x: limit values to a 2000mm range
    %Throw everything outside those limits

    %A=zeros(max(roundedKin(:,1)-min(roundedKin(:,1))+1),(max(roundedKin(:,2)-min(roundedKin(:,2))+1)));
    %for i=1:length(roundedKin(:,1))
    %A(roundedKin(i,1)-min(roundedKin(:,1))+1,roundedKin(i,2)-min(roundedKin(:,2))+1)=A(roundedKin(i,1)-min(roundedKin(:,1))+1,roundedKin(i,2)-min(roundedKin(:,2))+1)+1;
    %end
    A = sparse(roundedKin(:, 1) - min(roundedKin(:, 1)) + 1, ...
               roundedKin(:, 2) - min(roundedKin(:, 2)) + 1, 1);
    try
        [H, THETA, RHO] = hough(full(A)', 'RhoResolution', HOUGH_RHO_RES, ...
            'Theta', HOUGH_ANGLES);
    catch
        disp('Caught exception when computing Hough transform');
    end
    [~, ind] = max(H(:));
    [m, n]   = ind2sub(size(H), ind);
    th = -THETA(n) / 90 * pi / 2;
    r  = RHO(m);
    dist2Floor = (relevantKin(:, 1) - min(relevantKin(:, 1)) + 1) * cos(th) ...
        - (relevantKin(:, 2) - min(relevantKin(:, 2)) + 1) * sin(th) - r + 1;

    projOnFloor = relevantKin(:, 1) * sin(th) + relevantKin(:, 2) * cos(th); % projection over the floor
    stance = (abs(dist2Floor) < tol) & ([0; diff(projOnFloor)] < 0); % points on the floor for sure

    if sum(stance) < 3
        % probable backwards trial
        disp('Warning: probable backwards trial')
        flag   = true;
        stance = (abs(dist2Floor) < tol) & ([0; diff(projOnFloor)] > 0);
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
        swing = ([0; diff(projOnFloor)] > 0); % elements surely off the floor
    else
        swing = ([0; diff(projOnFloor)] < 0);
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

%% Method 3: get stance from marker acceleration (during stance, acc ≈ 0)
function stance = getStance3(ankKin, toeKin, fsample)
%GETSTANCE3 Estimate stance by thresholding marker acceleration.
%
%   Computes the second finite difference of ankle and toe positions to
% approximate acceleration. Classifies a sample as stance when the
% acceleration magnitude is below an empirical threshold.
%
% Inputs:
%   ankKin  - N×3 double, ankle marker position (mm)
%   toeKin  - N×3 double, toe marker position (mm)
%   fsample - scalar double, sampling frequency (Hz)
%
% Outputs:
%   stance - N×1 logical, stance phase (true = stance)

NAN_FILL_ACC = 100000; % large sentinel to suppress NaN in idealLPF (mm/s²)
accThresh    = 5000;   % acceleration threshold (mm/s²); empirical

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
ankleAcc = fsample ^ 2 * diff(diff(ankKin));
ankleAcc = [ankleAcc(1, :); ankleAcc; ankleAcc(end, :)];
toeAcc   = fsample ^ 2 * diff(diff(toeKin));
toeAcc   = [toeAcc(1, :); toeAcc; toeAcc(end, :)];
ankleAcc(isnan(ankleAcc)) = NAN_FILL_ACC;
toeAcc(isnan(toeAcc))     = NAN_FILL_ACC;

%% Step 3: low-pass filter accelerations then threshold for stance candidates
fcut = 30 / (2 * fsample); % ideal lowpass cutoff, normalized (30 Hz)
ankleAccFilt(:, 1) = idealLPF(ankleAcc(:, 1), fcut);
ankleAccFilt(:, 2) = idealLPF(ankleAcc(:, 2), fcut);
toeAccFilt(:, 1)   = idealLPF(toeAcc(:, 1),   fcut);
toeAccFilt(:, 2)   = idealLPF(toeAcc(:, 2),   fcut);
modAnkA = sqrt(sum(ankleAccFilt .^ 2, 2));
modToeA = sqrt(sum(toeAccFilt   .^ 2, 2));

%filter=hann(50);
%modAnkAf=conv(modAnkA,filter,'same')/sum(filter);
%modToeAf=conv(modToeA,filter,'same')/sum(filter);
%toeThresh=.1*mean(modToeA(10:end-10));
%ankThresh=.1*mean(modAnkA(10:end-10));

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
% %plot(ankleAcc)
% %plot(toeAcc)
% plot(modAnkA,'m')
% %plot(ankleAccFilt,'b')
% plot(modToeA,'r')
% %plot(toeAccFilt,'k')
% plot(.5*max(modAnkA)*double(stance),'g')
% hold off

end

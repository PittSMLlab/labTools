function [ out ] = computeCOM( strideEvents, markerData, BW, slowleg, fastleg, impactS, expData, gaitEvents, flipIT )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
timeSHS=strideEvents.tSHS;
timeFTO=strideEvents.tFTO;
timeFHS=strideEvents.tFHS;
timeSTO=strideEvents.tSTO;
timeSHS2=strideEvents.tSHS2;
timeFTO2=strideEvents.tFTO2;
timeFHS2=strideEvents.tFHS2;
timeSTO2=strideEvents.tSTO2;
eventTimes=[timeSHS timeFTO timeFHS timeSTO timeSHS2 timeFTO2 timeFHS2 timeSTO2];
SHS=1; FTO=2; FHS=3; STO=4; SHS2=5; FTO2=6; FHS2=7; STO2=8; %numbers correspond to column of eventTimes matrix
% 2.) Convert to ankle centric reference frame.  (can use
% "getKinematicData" as a template as this converts everything into hip
% centered.
if isempty(markerData.getLabelsThatMatch('BCOM'))
    [markerData] = COMCalculator(markerData, 9.81*BW);
end
%animate(markerData)

% 3.) Rotate with respect to the ankle
[rotatedMarkerData_F]=getKinematicData_respect2Ank(markerData, {[fastleg, 'ANK']});
[rotatedMarkerData_S]=getKinematicData_respect2Ank(markerData, {[slowleg, 'ANK']});
%animate(rotatedMarkerData_F)

% ROTATED
[COMTS_FANK] = getDataAsTS(rotatedMarkerData_F, {'BCOMx' 'BCOMy' 'BCOMz'});
[COMTS_SANK] =getDataAsTS(rotatedMarkerData_S, {'BCOMx' 'BCOMy' 'BCOMz'});

% 4.) Aquire the speed of the COMTS in ankle specific CS for that ankles
% heel strike
T=length(timeSHS);

veloCOM_F_unfilteredY=COMTS_FANK.derivate.getDataAsTS({'d/dt BCOMy'});
veloCOM_S_unfilteredY=COMTS_SANK.derivate.getDataAsTS({'d/dt BCOMy'});
veloCOM_F_unfilteredZ=COMTS_FANK.derivate.getDataAsTS({'d/dt BCOMz'});
veloCOM_S_unfilteredZ=COMTS_SANK.derivate.getDataAsTS({'d/dt BCOMz'});


veloCOM_FY=veloCOM_F_unfilteredY.substituteNaNs.lowPassFilter(5);
veloCOM_SY=veloCOM_S_unfilteredY.substituteNaNs.lowPassFilter(5);
veloCOM_FZ=veloCOM_F_unfilteredZ.substituteNaNs.lowPassFilter(5);
veloCOM_SZ=veloCOM_S_unfilteredZ.substituteNaNs.lowPassFilter(5);

SHSTimer=NaN.*ones(length(veloCOM_FY.Data), 1);
FHSTimer=NaN.*ones(length(veloCOM_FY.Data), 1);

%Time Normalied -- Rotated -- COM position
AlignedCOMTS_F=COMTS_FANK.align(gaitEvents, {[fastleg, 'HS'], [slowleg, 'TO'], [slowleg, 'HS'], [fastleg, 'TO']},  [15 30 15 40]);
AlignedCOMTS_S=COMTS_SANK.align(gaitEvents,  {[slowleg, 'HS'], [fastleg, 'TO'], [fastleg, 'HS'], [slowleg, 'TO']},  [15 30 15 40]);
%Time Normalied -- Rotated -- COM velocity
AlignedCOMVelo_FY=veloCOM_FY.align(gaitEvents, {[fastleg, 'HS'], [slowleg, 'TO'], [slowleg, 'HS'], [fastleg, 'TO']},  [15 30 15 40]);
AlignedCOMVelo_SY=veloCOM_SY.align(gaitEvents,  {[slowleg, 'HS'], [fastleg, 'TO'], [fastleg, 'HS'], [slowleg, 'TO']},  [15 30 15 40]);
AlignedCOMVelo_FZ=veloCOM_FZ.align(gaitEvents, {[fastleg, 'HS'], [slowleg, 'TO'], [slowleg, 'HS'], [fastleg, 'TO']},  [15 30 15 40]);
AlignedCOMVelo_SZ=veloCOM_SZ.align(gaitEvents,  {[slowleg, 'HS'], [fastleg, 'TO'], [fastleg, 'HS'], [slowleg, 'TO']},  [15 30 15 40]);

for i=1:T
    SHS=strideEvents.tSHS(i);
    FHS=strideEvents.tFHS(i);
    if ~isnan(SHS) && ~isnan(FHS)
        % Rotated at heel strike
        COMveloFY(i)=veloCOM_FY.Data(veloCOM_FY.getIndexClosestToTimePoint(FHS));
        COMveloSY(i)=veloCOM_SY.Data(veloCOM_SY.getIndexClosestToTimePoint(SHS));
        COMveloFZ(i)=veloCOM_FZ.Data(veloCOM_FZ.getIndexClosestToTimePoint(FHS));
        COMveloSZ(i)=veloCOM_SZ.Data(veloCOM_SZ.getIndexClosestToTimePoint(SHS));
        
        COMFY(i)=flipIT.*COMTS_FANK.Data(veloCOM_FY.getIndexClosestToTimePoint(FHS), 2);
        COMSY(i)=flipIT.*COMTS_SANK.Data(veloCOM_SY.getIndexClosestToTimePoint(SHS), 2);
        COMFZ(i)=flipIT.*COMTS_FANK.Data(veloCOM_FZ.getIndexClosestToTimePoint(FHS), 3);
        COMSZ(i)=flipIT.*COMTS_SANK.Data(veloCOM_SZ.getIndexClosestToTimePoint(SHS), 3);
        
        %Max/Min
        if T>10 && i<=T-5
            % AVERAGE: Time Normalied -- Rotated -- COM position and Velocity
            COMFY_Norm_Rot_mean(i)=flipIT.*nanmean(AlignedCOMTS_F.Data(8:23, 2, i));
            COMSY_Norm_Rot_mean(i)=flipIT.*nanmean(AlignedCOMTS_S.Data(8:23, 2, i));
            COMFZ_Norm_Rot_mean(i)=flipIT.*nanmean(AlignedCOMTS_F.Data(8:23, 3, i));
            COMSZ_Norm_Rot_mean(i)=flipIT.*nanmean(AlignedCOMTS_S.Data(8:23, 3, i));
            
            COMveloFY_Norm_Rot_mean(i)=flipIT.*nanmean(AlignedCOMVelo_FY.Data(8:23, 1, i));
            COMveloSY_Norm_Rot_mean(i)=flipIT.*nanmean(AlignedCOMVelo_SY.Data(8:23, 1, i));
            COMveloFZ_Norm_Rot_mean(i)=flipIT.*nanmean(AlignedCOMVelo_FZ.Data(8:23, 1, i));
            COMveloSZ_Norm_Rot_mean(i)=flipIT.*nanmean(AlignedCOMVelo_SZ.Data(8:23, 1, i));
            
            % AVERAGE: Time Normalied -- Rotated -- COM position and Velocity
            COMFY_Norm_Rot_DSmean(i)=flipIT.*nanmean(AlignedCOMTS_F.Data(8:15, 2, i));
            COMSY_Norm_Rot_DSmean(i)=flipIT.*nanmean(AlignedCOMTS_S.Data(8:15, 2, i));
            COMFZ_Norm_Rot_DSmean(i)=flipIT.*nanmean(AlignedCOMTS_F.Data(8:15, 3, i));
            COMSZ_Norm_Rot_DSmean(i)=flipIT.*nanmean(AlignedCOMTS_S.Data(8:15, 3, i));
            
            % WHOLE AVERAGE: Time Normalied -- Rotated -- COM position and Velocity
            COMFY_Norm_Rot_WHOLEmean(i)=flipIT.*nanmean(AlignedCOMTS_F.Data(:, 2, i));
            COMSY_Norm_Rot_WHOLEmean(i)=flipIT.*nanmean(AlignedCOMTS_S.Data(:, 2, i));
            COMFZ_Norm_Rot_WHOLEmean(i)=flipIT.*nanmean(AlignedCOMTS_F.Data(:, 3, i));
            COMSZ_Norm_Rot_WHOLEmean(i)=flipIT.*nanmean(AlignedCOMTS_S.Data(:, 3, i));
            
            COMveloFY_Norm_Rot_WHOLEmean(i)=flipIT.*nanmean(AlignedCOMVelo_FY.Data(:, 1, i));
            COMveloSY_Norm_Rot_WHOLEmean(i)=flipIT.*nanmean(AlignedCOMVelo_SY.Data(:, 1, i));
            COMveloFZ_Norm_Rot_WHOLEmean(i)=flipIT.*nanmean(AlignedCOMVelo_FZ.Data(:, 1, i));
            COMveloSZ_Norm_Rot_WHOLEmean(i)=flipIT.*nanmean(AlignedCOMVelo_SZ.Data(:, 1, i));
            
            % Little Bump Average First Attemps: Time Normalied -- Rotated -- COM position and Velocity
            COMFZ_Norm_Rot_Retraction(i)=flipIT.*nanmin(AlignedCOMTS_F.Data(90:100, 3, i));
            COMSZ_Norm_Rot_Retraction(i)=flipIT.*nanmin(AlignedCOMTS_S.Data(90:100, 3, i));
            COMveloFZ_Norm_Rot_Retraction(i)=flipIT.*nanmin(AlignedCOMVelo_FZ.Data(90:100, 1, i));
            COMveloSZ_Norm_Rot_Retraction(i)=flipIT.*nanmin(AlignedCOMVelo_SZ.Data(90:100, 1, i));
            
            %Time Normalied -- Rotated -- COM position and Velocity
            [COMFY_Norm_Rot_max(i) COMFY_Norm_Rot_maxIndex(i)]=nanmax(flipIT.*AlignedCOMTS_F.Data(:, 2, i));
            [COMSY_Norm_Rot_max(i) COMSY_Norm_Rot_maxIndex(i)]=nanmax(flipIT.*AlignedCOMTS_S.Data(:, 2, i));
            [COMFY_Norm_Rot_min(i) COMFY_Norm_Rot_minIndex(i)]=nanmin(flipIT.*AlignedCOMTS_F.Data(:, 2, i));
            [COMSY_Norm_Rot_min(i) COMSY_Norm_Rot_minIndex(i)]=nanmin(flipIT.*AlignedCOMTS_S.Data(:, 2, i));
            
            [COMFZ_Norm_Rot_max(i) COMFZ_Norm_Rot_maxIndex(i)]=nanmax(AlignedCOMTS_F.Data(:, 3, i));
            [COMSZ_Norm_Rot_max(i) COMSZ_Norm_Rot_maxIndex(i)]=nanmax(AlignedCOMTS_S.Data(:, 3, i));
            [COMFZ_Norm_Rot_min(i) COMFZ_Norm_Rot_minIndex(i)]=nanmin(AlignedCOMTS_F.Data(:, 3, i));
            [COMSZ_Norm_Rot_min(i) COMSZ_Norm_Rot_minIndex(i)]=nanmin(AlignedCOMTS_S.Data(:, 3, i));
            
            [COMveloFY_Norm_Rot_max(i) COMveloFY_Norm_Rot_maxIndex(i)]=nanmax(flipIT.*AlignedCOMVelo_FY.Data(:, 1, i));
            [COMveloSY_Norm_Rot_max(i) COMveloSY_Norm_Rot_maxIndex(i)]=nanmax(flipIT.*AlignedCOMVelo_SY.Data(:, 1, i));
            [COMveloFY_Norm_Rot_min(i) COMveloFY_Norm_Rot_minIndex(i)]=nanmin(flipIT.*AlignedCOMVelo_FY.Data(:, 1, i));
            [COMveloSY_Norm_Rot_min(i) COMveloSY_Norm_Rot_minIndex(i)]=nanmin(flipIT.*AlignedCOMVelo_SY.Data(:, 1, i));
            
            [COMveloFZ_Norm_Rot_max(i) COMveloFZ_Norm_Rot_maxIndex(i)]=nanmax(AlignedCOMVelo_FZ.Data(:, 1, i));
            [COMveloSZ_Norm_Rot_max(i) COMveloSZ_Norm_Rot_maxIndex(i)]=nanmax(AlignedCOMVelo_SZ.Data(:, 1, i));
            [COMveloFZ_Norm_Rot_min(i) COMveloFZ_Norm_Rot_minIndex(i)]=nanmin(AlignedCOMVelo_FZ.Data(:, 1, i));
            [COMveloSZ_Norm_Rot_min(i) COMveloSZ_Norm_Rot_minIndex(i)]=nanmin(AlignedCOMVelo_SZ.Data(:, 1, i));
            
        else
            COMFZ_Norm_Rot_minIndex(i)=NaN;
            COMSZ_Norm_Rot_minIndex(i)=NaN;
            
            % AVERAGE: Time Normalied -- Rotated -- COM position and Velocity
            COMFY_Norm_Rot_mean(i)=NaN;
            COMSY_Norm_Rot_mean(i)=NaN;
            COMFZ_Norm_Rot_mean(i)=NaN;
            COMSZ_Norm_Rot_mean(i)=NaN;
            
            COMveloFY_Norm_Rot_mean(i)=NaN;
            COMveloSY_Norm_Rot_mean(i)=NaN;
            COMveloFZ_Norm_Rot_mean(i)=NaN;
            COMveloSZ_Norm_Rot_mean(i)=NaN;
            
            COMFY_Norm_Rot_DSmean(i)=NaN;
            COMSY_Norm_Rot_DSmean(i)=NaN;
            COMFZ_Norm_Rot_DSmean(i)=NaN;
            COMSZ_Norm_Rot_DSmean(i)=NaN;
            
            
            
            COMFY_Norm_Rot_WHOLEmean(i)=NaN;
            COMSY_Norm_Rot_WHOLEmean(i)=NaN;
            COMFZ_Norm_Rot_WHOLEmean(i)=NaN;
            COMSZ_Norm_Rot_WHOLEmean(i)=NaN;
            
            COMveloFY_Norm_Rot_WHOLEmean(i)=NaN;
            COMveloSY_Norm_Rot_WHOLEmean(i)=NaN;
            COMveloFZ_Norm_Rot_WHOLEmean(i)=NaN;
            COMveloSZ_Norm_Rot_WHOLEmean(i)=NaN;
            
            % Little Bump Average First Attemps: Time Normalied -- Rotated -- COM position and Velocity
            COMFZ_Norm_Rot_Retraction(i)=NaN;
            COMSZ_Norm_Rot_Retraction(i)=NaN;
            COMveloFZ_Norm_Rot_Retraction(i)=NaN;
            COMveloSZ_Norm_Rot_Retraction(i)=NaN;
            
            %Time Normalied -- Rotated -- COM position and Velocity
            COMFY_Norm_Rot_max(i)=NaN; COMFY_Norm_Rot_maxIndex(i)=NaN;
            COMSY_Norm_Rot_max(i)=NaN; COMSY_Norm_Rot_maxIndex(i)=NaN;
            COMFY_Norm_Rot_min(i)=NaN; COMFY_Norm_Rot_minIndex(i)=NaN;
            COMSY_Norm_Rot_min(i)=NaN; COMSY_Norm_Rot_minIndex(i)=NaN;
            
            COMFZ_Norm_Rot_max(i)=NaN; COMFZ_Norm_Rot_maxIndex(i)=NaN;
            COMSZ_Norm_Rot_max(i)=NaN; COMSZ_Norm_Rot_maxIndex(i)=NaN;
            COMFZ_Norm_Rot_min(i)=NaN; COMFZ_Norm_Rot_minIndex(i)=NaN;
            COMSZ_Norm_Rot_min(i)=NaN; COMSZ_Norm_Rot_minIndex(i)=NaN;
            
            COMveloFY_Norm_Rot_max(i)=NaN; COMveloFY_Norm_Rot_maxIndex(i)=NaN;
            COMveloSY_Norm_Rot_max(i)=NaN; COMveloSY_Norm_Rot_maxIndex(i)=NaN;
            COMveloFY_Norm_Rot_min(i)=NaN; COMveloFY_Norm_Rot_minIndex(i)=NaN;
            COMveloSY_Norm_Rot_min(i)=NaN; COMveloSY_Norm_Rot_minIndex(i)=NaN;
            
            COMveloFZ_Norm_Rot_max(i)=NaN; COMveloFZ_Norm_Rot_maxIndex(i)=NaN;
            COMveloSZ_Norm_Rot_max(i)=NaN; COMveloSZ_Norm_Rot_maxIndex(i)=NaN;
            COMveloFZ_Norm_Rot_min(i)=NaN; COMveloFZ_Norm_Rot_minIndex(i)=NaN;
            COMveloSZ_Norm_Rot_min(i)=NaN; COMveloSZ_Norm_Rot_minIndex(i)=NaN;
        end
    end
    clear tempFHS tempSHS
end

COMveloY=COMveloFY-COMveloSY;
COMveloZ=COMveloFZ-COMveloSZ;

COMY=COMFY-COMSY;
COMZ=COMFZ-COMSZ;

COMsymY_Norm_Rot_mean=COMFY_Norm_Rot_mean-COMSY_Norm_Rot_mean;
COMsymZ_Norm_Rot_mean=COMFZ_Norm_Rot_mean-COMSZ_Norm_Rot_mean;
COMveloSYMY_Norm_Rot_mean=COMveloFY_Norm_Rot_mean-COMveloSY_Norm_Rot_mean;
COMveloSYMZ_Norm_Rot_mean=COMveloFZ_Norm_Rot_mean-COMveloSZ_Norm_Rot_mean;

COMsymY_Norm_Rot_DSmean=COMFY_Norm_Rot_DSmean-COMSY_Norm_Rot_DSmean;
COMsymZ_Norm_Rot_DSmean=COMFZ_Norm_Rot_DSmean-COMSZ_Norm_Rot_DSmean;

COMsymY_Norm_Rot_WHOLEmean=COMFY_Norm_Rot_WHOLEmean-COMSY_Norm_Rot_WHOLEmean;
COMsymZ_Norm_Rot_WHOLEmean=COMFZ_Norm_Rot_WHOLEmean-COMSZ_Norm_Rot_WHOLEmean ;
COMveloSymY_Norm_Rot_WHOLEmean=COMveloFY_Norm_Rot_WHOLEmean-COMveloSY_Norm_Rot_WHOLEmean;
COMveloSymZ_Norm_Rot_WHOLEmean=COMveloFZ_Norm_Rot_WHOLEmean-COMveloSZ_Norm_Rot_WHOLEmean;

%Time Normalied -- Rotated -- COM position and Velocity
COMsymY_Norm_Rot_max=COMFY_Norm_Rot_max-COMSY_Norm_Rot_max;
COMsymY_Norm_Rot_min=COMFY_Norm_Rot_min-COMSY_Norm_Rot_min;
COMsymZ_Norm_Rot_max=COMFZ_Norm_Rot_max-COMSZ_Norm_Rot_max;
COMsymZ_Norm_Rot_min=COMFZ_Norm_Rot_min-COMSZ_Norm_Rot_min;

COMveloSYMY_Norm_Rot_max=COMveloFY_Norm_Rot_max-COMveloSY_Norm_Rot_max;
COMveloSYMY_Norm_Rot_min=COMveloFY_Norm_Rot_min-COMveloSY_Norm_Rot_min;
COMveloSYMZ_Norm_Rot_max=COMveloFZ_Norm_Rot_max-COMveloSZ_Norm_Rot_max;
COMveloSYMZ_Norm_Rot_min=COMveloFZ_Norm_Rot_min-COMveloSZ_Norm_Rot_min;


data=[COMveloY' COMveloFY' COMveloSY' COMveloZ' ...
    COMveloFZ' COMveloSZ' ...
    COMY' COMFY' COMSY' COMZ' COMFZ' COMSZ' ...
    COMsymY_Norm_Rot_mean' COMFY_Norm_Rot_mean' COMSY_Norm_Rot_mean'...
    COMsymZ_Norm_Rot_mean' COMFZ_Norm_Rot_mean' COMSZ_Norm_Rot_mean'...
    COMveloSYMY_Norm_Rot_mean' COMveloFY_Norm_Rot_mean' COMveloSY_Norm_Rot_mean'...
    COMveloSYMZ_Norm_Rot_mean' COMveloFZ_Norm_Rot_mean' COMveloSZ_Norm_Rot_mean'...
    COMsymY_Norm_Rot_DSmean' COMFY_Norm_Rot_DSmean' COMSY_Norm_Rot_DSmean'...
    COMsymZ_Norm_Rot_DSmean' COMFZ_Norm_Rot_DSmean' COMSZ_Norm_Rot_DSmean'...
    COMsymY_Norm_Rot_WHOLEmean' COMFY_Norm_Rot_WHOLEmean' COMSY_Norm_Rot_WHOLEmean'...
    COMsymZ_Norm_Rot_WHOLEmean' COMFZ_Norm_Rot_WHOLEmean' COMSZ_Norm_Rot_WHOLEmean'...
    COMveloSymY_Norm_Rot_WHOLEmean' COMveloFY_Norm_Rot_WHOLEmean' COMveloSY_Norm_Rot_WHOLEmean'...
    COMveloSymZ_Norm_Rot_WHOLEmean' COMveloFZ_Norm_Rot_WHOLEmean' COMveloSZ_Norm_Rot_WHOLEmean'...
    COMFZ_Norm_Rot_minIndex' COMSZ_Norm_Rot_minIndex' COMFZ_Norm_Rot_Retraction' COMSZ_Norm_Rot_Retraction'...
    COMveloFZ_Norm_Rot_Retraction' COMveloSZ_Norm_Rot_Retraction'...
    COMsymY_Norm_Rot_max' COMFY_Norm_Rot_max' COMSY_Norm_Rot_max'...%%Time Normalied -- Rotated -- COM position and Velocity
    COMsymY_Norm_Rot_min' COMFY_Norm_Rot_min' COMSY_Norm_Rot_min'...
    COMsymZ_Norm_Rot_max' COMFZ_Norm_Rot_max' COMSZ_Norm_Rot_max'...
    COMsymZ_Norm_Rot_min' COMFZ_Norm_Rot_min' COMSZ_Norm_Rot_min'...
    COMveloSYMY_Norm_Rot_max' COMveloFY_Norm_Rot_max' COMveloSY_Norm_Rot_max'...
    COMveloSYMY_Norm_Rot_min' COMveloFY_Norm_Rot_min' COMveloSY_Norm_Rot_min'...
    COMveloSYMZ_Norm_Rot_max' COMveloFZ_Norm_Rot_max' COMveloSZ_Norm_Rot_max'...
    COMveloSYMZ_Norm_Rot_min' COMveloFZ_Norm_Rot_min' COMveloSZ_Norm_Rot_min'];

labels={'COMveloY' 'COMveloFY' 'COMveloSY' 'COMveloZ' ...
    'COMveloFZ' 'COMveloSZ' ...
    'COMY' 'COMFY' 'COMSY' 'COMZ' 'COMFZ' 'COMSZ' ...
    'COMsymY_Norm_Rot_mean' 'COMFY_Norm_Rot_mean' 'COMSY_Norm_Rot_mean'...
    'COMsymZ_Norm_Rot_mean' 'COMFZ_Norm_Rot_mean' 'COMSZ_Norm_Rot_mean'...
    'COMveloSYMY_Norm_Rot_mean' 'COMveloFY_Norm_Rot_mean' 'COMveloSY_Norm_Rot_mean'...
    'COMveloSYMZ_Norm_Rot_mean' 'COMveloFZ_Norm_Rot_mean' 'COMveloSZ_Norm_Rot_mean'...
    'COMsymY_Norm_Rot_DSmean' 'COMFY_Norm_Rot_DSmean' 'COMSY_Norm_Rot_DSmean'...
    'COMsymZ_Norm_Rot_DSmean' 'COMFZ_Norm_Rot_DSmean' 'COMSZ_Norm_Rot_DSmean'...
    'COMsymY_Norm_Rot_WHOLEmean' 'COMFY_Norm_Rot_WHOLEmean' 'COMSY_Norm_Rot_WHOLEmean'...
    'COMsymZ_Norm_Rot_WHOLEmea' 'COMFZ_Norm_Rot_WHOLEmean' 'COMSZ_Norm_Rot_WHOLEmean'...
    'COMveloSymY_Norm_Rot_WHOLEmean' 'COMveloFY_Norm_Rot_WHOLEmean' 'COMveloSY_Norm_Rot_WHOLEmean'...
    'COMveloSymZ_Norm_Rot_WHOLEmean' 'COMveloFZ_Norm_Rot_WHOLEmean' 'COMveloSZ_Norm_Rot_WHOLEmean'...
    'COMFZ_Norm_Rot_minIndex' 'COMSZ_Norm_Rot_minIndex' 'COMFZ_Norm_Rot_Retraction' 'COMSZ_Norm_Rot_Retraction'...
    'COMveloFZ_Norm_Rot_Retraction' 'COMveloSZ_Norm_Rot_Retraction'...
    'COMsymY_Norm_Rot_max' 'COMFY_Norm_Rot_max' 'COMSY_Norm_Rot_max'...%%Time Normalied -- Rotated -- COM position and Velocity
    'COMsymY_Norm_Rot_min' 'COMFY_Norm_Rot_min' 'COMSY_Norm_Rot_min'...
    'COMsymZ_Norm_Rot_max' 'COMFZ_Norm_Rot_max' 'COMSZ_Norm_Rot_max'...
    'COMsymZ_Norm_Rot_min' 'COMFZ_Norm_Rot_min' 'COMSZ_Norm_Rot_min'...
    'COMveloSYMY_Norm_Rot_max' 'COMveloFY_Norm_Rot_max' 'COMveloSY_Norm_Rot_max'...
    'COMveloSYMY_Norm_Rot_min' 'COMveloFY_Norm_Rot_min' 'COMveloSY_Norm_Rot_min'...
    'COMveloSYMZ_Norm_Rot_max' 'COMveloFZ_Norm_Rot_max' 'COMveloSZ_Norm_Rot_max'...
    'COMveloSYMZ_Norm_Rot_min' 'COMveloFZ_Norm_Rot_min' 'COMveloSZ_Norm_Rot_min'};

%% Actually output and store stuff
if length(impactS)==length(COMveloFY)
    data=[data; NaN(1, size(data, 2)) ];
end
description=cell(1, size(data, 2)); description(:)={''};
out=parameterSeries(data,labels,[],description);
end


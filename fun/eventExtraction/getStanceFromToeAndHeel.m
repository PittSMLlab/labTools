function [ stance] = getStanceFromToeAndHeel(ankKin, toeKin, fsample)

[stance3] = getStance3(ankKin, toeKin, fsample); %Acceleration thresholding
%[stance2] = getStance2(ankKin, toeKin, fsample); %Hough + thresholding
[stance1] = getStance(ankKin, toeKin, fsample); %Velocity thresholding
%stance1=stance2;
%stance3=stance2;

%stance =  (stance1 & stance2) | (stance1 & stance3) | (stance3 & stance2);
stance = stance1;
stance = deleteShortPhases(stance,fsample,0.2); %Not allowing stance phases of less than 200ms

%IDEA: instead of using pure (classical) logic, use fuzzy logic, with a
%smoothing kernel, so that all samples in a neighboorhood get a say on the
%value of a particular sample.
%This might be particularly helpful to get rid of quantization noise
%(kernel with support of 3 samples: the central one, and one to each side),
%and also with some other types of noise (NOT SURE: it might make it more
%sensible to big errors in only one of the estimations)
end

%% Method 1: try to find full stance points and threshold relative speed to that
function [stance] = getStance(ankKin, toeKin, fsample)
%This function returns an estimation of which samples of a given kinematic
%trajectory for ankle and toe markers correspond to the stance phase
%In order to do so, it estimates the phase in which the ankle and toe
%markers are not moving with respect to each other (full stance) and
%calculates foot speed. By comparing this speed with toe and ankle speed,
%it is possible to assert whether the ankle or toe are in contact with the
%ground

%% STEP 1: calculate speed

%va(:,1)=derive(ankKin(:,1),fsample);
% va(:,2)=derive(ankKin(:,2),fsample);
% vt(:,1)=derive(toeKin(:,1),fsample);
% vt(:,2)=derive(toeKin(:,2),fsample);
va=fsample*diff(ankKin);
va(end+1,:)=va(end,:);
vt=fsample*diff(toeKin);
vt(end+1,:)=vt(end,:);
fcut=.5*10/fsample;
va(isnan(va))=10000;
vt(isnan(vt))=10000;
vaf=idealLPF(va,fcut);
vtf=idealLPF(vt,fcut);


%% STEP 2: get core stance (full feet on ground) speed
relV=vaf-vtf; %Relative speed in m/s
modRelV=sqrt(sum(relV.^2,2)); %Module of relative speed
coreStance=(modRelV<150); %Find time indexes that are candidates for core stance
coreStance = deleteShortPhases(coreStance,fsample,0.05);

stanceSpeed=mode(10*round(va(coreStance,:)/10)); %Most common stance speed, rounded to closest cm/s


%% STEP 3: By thresholding difference with ground speed, get toe and ank stance candidates (sine qua non condition)
ankV=va-ones(size(va,1),1)*stanceSpeed; %Relative speed to stance
toeV=vt-ones(size(vt,1),1)*stanceSpeed; %Relative speed to stance

modAnkV=sqrt(sum(ankV.^2,2));
modToeV=sqrt(sum(toeV.^2,2));

%% STEP 4: Get stance from the ank stance OR toe stance
velThreshA=.8*median(modAnkV); %500 is a good value
velThreshA=500;
velThreshT=.8*median(modToeV); %250 is a good value
velThreshT=250;
ankStance=modAnkV<velThreshA;
toeStance=modToeV<velThreshT;

stance  = ankStance | toeStance;



%% STEP N: Eliminate stance & swing phases shorter than 200 ms
stance = deleteShortPhases(stance,fsample,0.2);
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
function [stance] = getStance2(Rheel, Rtoe, fsample)
%Get stance from plane floor + thresholding
%getEvents Extracts heel-strike/toe-off events from the relative position
%of the heel marker to the hip marker

%INPUTS:
%Lheel,Rheel,Lhip,Rhip: 3xN matrices with 3D marker location
%fsample: sampling frequency


% Find floor plane
backwards=false; %This should go, stance detection should not be direction-dependent
thetas=[-90:.2:-70,70:.2:89.8];
rho_res=.5;
for j=1:2
    flag=false;
    %Contact start & end detection
clear raux aux aux2  RHO THETA H A th r m n
    switch j
        case 1
            relevantKin=medfilt1(Rheel); %Non-strict Filtering to kill far outliers
            tol=4; %Threshold to surely catalogue a point as 'on floor'
            tol2=8; %Minimum distance to catalogue as 'toe-off' or 'heel-strike'
            N=3;
            N2=1;
        case 2
            relevantKin=medfilt1(Rtoe);
            tol=4;
            tol2=10;
            N=15;
            N2=1;
    end
    
    relevantKin(abs(relevantKin(:,1)-median(relevantKin(:,1)))>5*std(relevantKin(:,1)),1)=0;
    relevantKin(abs(relevantKin(:,2)-median(relevantKin(:,2)))>5*std(relevantKin(:,2)),2)=0;
    raux=round(relevantKin);
    
    %In y: limit values to a 500mm range
    %In x: limit values to a 2000mm range
    %Throw everything outside those limits
    

%A=zeros(max(raux(:,1)-min(raux(:,1))+1),(max(raux(:,2)-min(raux(:,2))+1)));
%for i=1:length(raux(:,1))
%A(raux(i,1)-min(raux(:,1))+1,raux(i,2)-min(raux(:,2))+1)=A(raux(i,1)-min(raux(:,1))+1,raux(i,2)-min(raux(:,2))+1)+1;
%end
A=sparse(raux(:,1)-min(raux(:,1))+1,raux(:,2)-min(raux(:,2))+1,1);
%size(A)
try
    [H, THETA, RHO] = hough(full(A)','RhoResolution',rho_res,'Theta',thetas);
catch
    disp('Caught exception when computing Hough transform');
end
[~,ind] = max(H(:));
[m,n] = ind2sub(size(H),ind);
th=-THETA(n)/90 *pi/2;
r=RHO(m);
dist2Floor=(relevantKin(:,1)-min(relevantKin(:,1))+1)*cos(th)-(relevantKin(:,2)-min(relevantKin(:,2))+1)*sin(th)-r+1; %First guess at floor

%Find all points on a distance less than 1mm to the line (there ought to be
%some on every step, on normal walk)

aux1=relevantKin(:,1)*sin(th)+relevantKin(:,2)*cos(th);%projection over the floor
stance=(abs(dist2Floor)<tol)&([0;diff(aux1)]<0); %Points on the floor for sure

if sum(stance)<3
    %Probable backwards trial
    disp('Warning: probable backwards trial')
    flag=true;
    stance=(abs(dist2Floor)<tol)&([0;diff(aux1)]>0); %Points on the floor for sure
end
CoM_x=mean(relevantKin(stance,1));
CoM_y=mean(relevantKin(stance,2));
M=pca(relevantKin(stance,1:2));
try
    dist2Floor=(relevantKin(:,1)-CoM_x)*M(1,2)+(relevantKin(:,2)-CoM_y)*M(2,2); %Corrected guess at floor
catch
    disp('Caught exception when computing distance to floor.');
end

if (~backwards)&&(~flag)
    swing=([0;diff(aux1)]>0); %Elments surely off the floor
else
    swing=([0;diff(aux1)]<0);
end
%Eliminate spurious
swing=conv(double(swing),ones(2*N+1,1),'same')==2*N+1; %Erode aux2 %Elements that have at least one off the floor element on the 'off the floor' side
swing=conv(double(swing),ones(2*N+1,1),'same')>=1; %Dilate aux2 %Elements that have at least one off the floor elements N elements to each side

%%
change=true;
while change
    stance3=conv(double(stance),ones(3,1),'same')>=1; %Dilate aux
    stance4=stance3&~swing; %Make sure it doesn't reach the 'off the floor' threshold
    thresh=max([3*median(abs(dist2Floor(stance))),tol2]); %I think the median is too big for any consecutive steps
    stance5=(abs(dist2Floor)<thresh);
    stance4=stance4&stance5; %Erase new element if its twice above the median (or at least 5mm)
    if any(stance4~=stance)
        stance=stance4;
        CoM_x=mean(relevantKin(stance,1));
        CoM_y=mean(relevantKin(stance,2));
        M=pca(relevantKin(stance,1:2));
        try
        dist2Floor=(relevantKin(:,1)-CoM_x)*M(1,2)+(relevantKin(:,2)-CoM_y)*M(2,2); %Corrected guess at floor
        catch
            disp('Caught exception when computing distance to floor.');
        end
    else
        change=false;
        stance=conv(double(stance4),ones(2*N2+1,1),'same')==2*N2+1; %Erode aux, leaves a N2 element distance
    end
end

%Assign corresponding stance
switch j 
    case 1
        stanceAnk=stance;
    case 2
        stanceToe=stance;
end

end

% Stance is when either toe or ank is in the floor
stance = stanceAnk | stanceToe;

%Delete short stance phases
stance = deleteShortPhases(stance,fsample,0.25);
end

%% Method 3: get stance from marker acceleration (during stance, acc=0)

function [stance] = getStance3(ankKin, toeKin, fsample)
%Get stance from acceleration

%% STEP 1: low pass filter & calculate speed

%Get vels:
% va(:,1)=derive(ankKin(:,1),fsample); %fore-aft axis
% va(:,2)=derive(ankKin(:,2),fsample); %up-down axis
% vt(:,1)=derive(toeKin(:,1),fsample);
% vt(:,2)=derive(toeKin(:,2),fsample);
% %Get acc:
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
toeThresh=5000;%m/s^2
ankThresh=5000;%m/s^2


%% STEP 4: Get stance from the ank stance OR toe stance
ankStance=modAnkA<ankThresh;
toeStance=modToeA<toeThresh;

%ankStance = deleteShortPhases(ankStance,fsample,0.25);
%toeStance = deleteShortPhases(toeStance,fsample,0.25);
stance  = ankStance | toeStance;



%% STEP N: Eliminate stance & swing phases shorter than 200 ms
stance = deleteShortPhases(stance,fsample,0.2);


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
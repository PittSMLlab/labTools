function [COPTS] = COPCalculator(GRFData)

%% Filter the GRFs
or=GRFData.orientation;
GRFData=GRFData.medianFilter(3);
GRFData=GRFData.lowPassFilter(25);

%% Define the force data
labs={'LFx','LFy','LFz','LMx','LMy','LMz','RFx','RFy','RFz','RMx','RMy','RMz'};
aux=GRFData.getDataAsVector(labs);
for i=1:length(labs)
    eval([labs{i} '=aux(:,i);']);
end
clear aux

% Define the Calibration Matrices that were experimentally calculated based
%on Dr. Collins' method
%These are now loaded from .mat file:
%LeftCalibrationMatrix=[0.977443018179296,0.0265878123782286,0.00727178625926090,-4.01453477495388e-06,6.40955506816272e-06,-6.37851553161149e-06;-0.0268315126953482,1.00295568287710,-0.000701042994051120,-1.14416377324098e-06,-1.32448870901600e-05,1.30878158412852e-05;0.212020149923397,-0.0599681540847165,0.936220974404682,-3.35889204404071e-07,-4.22088717230903e-05,0.000198374222897077;87.9775199583949,-82.7205462087585,-31.2294587953683,0.968979166120067,-0.0310407162599708,0.103337032656768;56.2959837326107,-18.7996561497853,4.75495955638203,-0.000983104515514435,0.955214717752167,0.0582797232696294;23.3601483862054,-18.3109163366889,-1.34627847663656,-0.00190791038185259,-0.00108948397982946,0.999613747815472];
%RightCalibrationMatrix=[1.03281907786820,0.0256265922835897,-0.00660442602474871,-3.01056674606954e-06,-2.31116205395644e-05,4.91854505069932e-06;-0.0195416552881650,0.998677907839746,-0.0127518171776215,3.81267049815018e-06,-2.69134385473006e-05,1.66884053275253e-05;0.0314488158391576,-0.185105961633033,0.888218372383029,-1.37726138481357e-05,-8.76750841846458e-05,6.89770726674376e-05;160.545873625969,-151.874973474082,-71.5811766262873,0.941945649494691,-0.0793439412178859,0.150522165903692;37.0330639923679,43.4298820739839,34.9546221913499,-0.00251366842359346,0.967371637874083,0.00298515313557242;-44.0833555096415,-21.8181696241636,8.11732968729231,0.00423294702847277,0.0369328291807189,0.995967448976484];
load('coordinateTransformation_06022017.mat') % contains LeftCalibrationMatrix, RightCalibrationMatrix LTransformationMatrix, RTransformationMatrix
% Apply the calibration matrices to the force and moment data
OldLeftForces=[LFx';LFy';LFz';LMx';LMy';LMz'];
OldRightForces=[RFx';RFy';RFz';RMx';RMy';RMz'];
NewLeftForces=LeftCalibrationMatrix*OldLeftForces;
NewRightForces=RightCalibrationMatrix*OldRightForces;
GRFxL=-1*NewLeftForces(1,:);
GRFyL=-1*NewLeftForces(2,:);
GRFzL=-1*NewLeftForces(3,:);
GRMxL=-1*NewLeftForces(4,:);
GRMyL=-1*NewLeftForces(5,:);
GRFxR=-1*NewRightForces(1,:);
GRFyR=-1*NewRightForces(2,:);
GRFzR=-1*NewRightForces(3,:);
GRMxR=-1*NewRightForces(4,:);
GRMyR=-1*NewRightForces(5,:);

% Apply filters to the Force data collected. Data collected prior to
% Summer 2014 is very noisy due to the lack of a true ground and needs
% a heavy duty filter. Should not drastically affect other data.
FiltDesign=fdesign.lowpass('N,F3db',6,25/1000);
TheDesign=design(FiltDesign,'butter');
GRFxL = filtfilthd(TheDesign,GRFxL');
GRFyL = filtfilthd(TheDesign,GRFyL');
GRFzL = filtfilthd(TheDesign,GRFzL');
GRFxR = filtfilthd(TheDesign,GRFxR');
GRFyR = filtfilthd(TheDesign,GRFyR');
GRFzR = filtfilthd(TheDesign,GRFzR');

% Apply a filter to the moment data collected as well.
[Bmom, Amom]=butter(4,10/(1000/2));
GRMxL=filtfilt(Bmom, Amom, GRMxL)';
GRMyL=filtfilt(Bmom, Amom, GRMyL)';
GRMxR=filtfilt(Bmom, Amom, GRMxR)';
GRMyR=filtfilt(Bmom, Amom, GRMyR)';

% Calculate the center of pressure for the data.
COPxL=[(((-.005.*GRFxL-GRMyL./1000)./GRFzL))]*1000;%millimeters
COPyL=[(((-.005.*GRFyL+GRMxL./1000)./GRFzL))]*1000;
COPxR=[(((-.005.*-1.*GRFxR+GRMyR./1000)./GRFzR))]*1000;
COPyR=[(((-.005.*GRFyR+GRMxR./1000)./GRFzR))]*1000;

% Transform the center of pressure data from the local treadmill
% coordinate system to the global vicon coordinate system.
%These are now loaded from .mat file:
%LTransformationMatrix=[1,0,0,0;20,1,0,0;1612,0,-1,0;0,0,0,-1];
%RTransformationMatrix=[1,0,0,0;-944,-1,0,0;1612,0,-1,0;0,0,0,-1];
for i=1:length(COPxR)
    LeftCOP=[1;COPxL(i);COPyL(i);0];
    RightCOP=[1;COPxR(i);COPyR(i);0];
    NewLeftCOP=LTransformationMatrix*LeftCOP;
    NewRightCOP=RTransformationMatrix*RightCOP;
    NewCOPxL(i)=NewLeftCOP(2);
    NewCOPyL(i)=NewLeftCOP(3);
    NewCOPxR(i)=NewRightCOP(2);
    NewCOPyR(i)=NewRightCOP(3);
end

% substitute NaNs, by doing a linear interpolation:
ll={'NewCOPxL','NewCOPxR','NewCOPyL','NewCOPyR'};
for i=1:length(ll)
    eval(['aux=' ll{i} ';']);
    badInds(i,:)=isnan(aux);
    goodInds=~badInds(i,:);
    if any(goodInds) %% HH temproary fix.
        aux=interp1(find(~badInds(i,:)),aux(~badInds(i,:)),1:length(aux),'linear','extrap');
        eval([ll{i} '=aux;']);
    end    
end

[Bcop,Acop]=butter(1,3/100/2);
[Bcopy,Acopy]=butter(1,3/100/2);
NewCOPxL=filtfilt(Bcop,Acop,NewCOPxL);
NewCOPxR=filtfilt(Bcop,Acop,NewCOPxR);
NewCOPyL=filtfilt(Bcopy,Acopy,NewCOPyL);
NewCOPyR=filtfilt(Bcopy,Acopy,NewCOPyR);

% replace NaNs, by doing a linear interpolation:
ll={'NewCOPxL','NewCOPxR','NewCOPyL','NewCOPyR'};
for i=1:length(ll)
    eval(['aux=' ll{i} ';']);
    aux(badInds(i,:))=NaN;
    eval([ll{i} '=aux;']);
end

COPData=[NewCOPxL' NewCOPyL' zeros(size(NewCOPxL))' NewCOPxR' NewCOPyR' zeros(size(NewCOPxR))' GRFxL GRFyL GRFzL GRFxR GRFyR GRFzR GRMxL GRMyL zeros(size(GRMyL)) GRMxR GRMyR zeros(size(GRMyL))];
COPTS=orientedLabTimeSeries(COPData,GRFData.Time(1),GRFData.sampPeriod,{'LCOPx','LCOPy','LCOPz','RCOPx','RCOPy','RCOPz', 'LGRFx','LGRFy','LGRFz','RGRFx','RGRFy','RGRFz','LGRMx','LGRMy','LGRMz','RGRMx','RGRMy','RGRMz'},or);


end


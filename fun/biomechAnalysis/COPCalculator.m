function COPTS = COPCalculator(GRFData)
%COPCALCULATOR Calculate the center of pressure time series from GRF data

%% Filter the GRF Time Series Data
or = GRFData.orientation;               % retrieve GRF orientation data
GRFData = GRFData.medianFilter(3);      % eliminate outliers
GRFData = GRFData.lowPassFilter(25);    % 25 Hz cutoff frequency

%% Define the Force Data
labs ={'LFx','LFy','LFz','LMx','LMy','LMz', ...
    'RFx','RFy','RFz','RMx','RMy','RMz'};
aux = GRFData.getDataAsVector(labs);    % retrieve left and right FP data
for ii = 1:length(labs)                 % for each FP sensor, ...
    eval([labs{ii} ' = aux(:,ii);']);   % assign data
end
clear aux;

% Define the Calibration Matrices that were experimentally calculated based
%on Dr. Collins' method
%These are now loaded from .mat file:
%LeftCalibrationMatrix=[0.977443018179296,0.0265878123782286,0.00727178625926090,-4.01453477495388e-06,6.40955506816272e-06,-6.37851553161149e-06;-0.0268315126953482,1.00295568287710,-0.000701042994051120,-1.14416377324098e-06,-1.32448870901600e-05,1.30878158412852e-05;0.212020149923397,-0.0599681540847165,0.936220974404682,-3.35889204404071e-07,-4.22088717230903e-05,0.000198374222897077;87.9775199583949,-82.7205462087585,-31.2294587953683,0.968979166120067,-0.0310407162599708,0.103337032656768;56.2959837326107,-18.7996561497853,4.75495955638203,-0.000983104515514435,0.955214717752167,0.0582797232696294;23.3601483862054,-18.3109163366889,-1.34627847663656,-0.00190791038185259,-0.00108948397982946,0.999613747815472];
%RightCalibrationMatrix=[1.03281907786820,0.0256265922835897,-0.00660442602474871,-3.01056674606954e-06,-2.31116205395644e-05,4.91854505069932e-06;-0.0195416552881650,0.998677907839746,-0.0127518171776215,3.81267049815018e-06,-2.69134385473006e-05,1.66884053275253e-05;0.0314488158391576,-0.185105961633033,0.888218372383029,-1.37726138481357e-05,-8.76750841846458e-05,6.89770726674376e-05;160.545873625969,-151.874973474082,-71.5811766262873,0.941945649494691,-0.0793439412178859,0.150522165903692;37.0330639923679,43.4298820739839,34.9546221913499,-0.00251366842359346,0.967371637874083,0.00298515313557242;-44.0833555096415,-21.8181696241636,8.11732968729231,0.00423294702847277,0.0369328291807189,0.995967448976484];
load('coordinateTransformation_06022017.mat'); % contains LeftCalibrationMatrix, RightCalibrationMatrix LTransformationMatrix, RTransformationMatrix
% apply the calibration matrices to the force and moment data
OldLeftForces = [LFx'; LFy'; LFz'; LMx'; LMy'; LMz'];
OldRightForces = [RFx'; RFy'; RFz'; RMx'; RMy'; RMz'];
NewLeftForces = LeftCalibrationMatrix * OldLeftForces;
NewRightForces = RightCalibrationMatrix * OldRightForces;
GRFxL = -NewLeftForces(1,:);
GRFyL = -NewLeftForces(2,:);
GRFzL = -NewLeftForces(3,:);
GRMxL = -NewLeftForces(4,:);
GRMyL = -NewLeftForces(5,:);
GRFxR = -NewRightForces(1,:);
GRFyR = -NewRightForces(2,:);
GRFzR = -NewRightForces(3,:);
GRMxR = -NewRightForces(4,:);
GRMyR = -NewRightForces(5,:);

% Calculate the center of pressure for the data.
COPxL = [(((-.005.*GRFxL-GRMyL./1000)./GRFzL))]*1000;%milimeters
COPyL = [(((-.005.*GRFyL+GRMxL./1000)./GRFzL))]*1000;
COPxR = [(((-.005.*-1.*GRFxR+GRMyR./1000)./GRFzR))]*1000;
COPyR = [(((-.005.*GRFyR+GRMxR./1000)./GRFzR))]*1000;

% Transform the center of pressure data from the local treadmill
% coordinate system to the global vicon coordinate system.
%These are now loaded from .mat file:
%LTransformationMatrix=[1,0,0,0;20,1,0,0;1612,0,-1,0;0,0,0,-1];
%RTransformationMatrix=[1,0,0,0;-944,-1,0,0;1612,0,-1,0;0,0,0,-1];
NewLeftCOP=LTransformationMatrix*[ones(size(COPxL));COPxL; COPyL; zeros(size(COPxL))];
NewCOPxL=NewLeftCOP(2,:);
NewCOPyL=NewLeftCOP(3,:);
NewRightCOP=RTransformationMatrix*[ones(size(COPxR));COPxR; COPyR; zeros(size(COPxR))];
NewCOPxR=NewRightCOP(2,:);
NewCOPyR=NewRightCOP(3,:);
% for i=1:length(COPxR)
%     LeftCOP=[1;COPxL(i);COPyL(i);0];
%     RightCOP=[1;COPxR(i);COPyR(i);0];
%     NewLeftCOP=LTransformationMatrix*LeftCOP;
%     NewRightCOP=RTransformationMatrix*RightCOP;
%     NewCOPxL(i)=NewLeftCOP(2);
%     NewCOPyL(i)=NewLeftCOP(3);
%     NewCOPxR(i)=NewRightCOP(2);
%     NewCOPyR(i)=NewRightCOP(3);
% end

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

%I don't think this smoothing is needed:
% [Bcop,Acop]=butter(1,3/100/2);
% [Bcopy,Acopy]=butter(1,3/100/2);
% NewCOPxL=filtfilt(Bcop,Acop,NewCOPxL);
% NewCOPxR=filtfilt(Bcop,Acop,NewCOPxR);
% NewCOPyL=filtfilt(Bcopy,Acopy,NewCOPyL);
% NewCOPyR=filtfilt(Bcopy,Acopy,NewCOPyR);

% replace NaNs, by doing a linear interpolation:
ll = {'NewCOPxL','NewCOPxR','NewCOPyL','NewCOPyR'};
for ii = 1:length(ll)
    eval(['aux = ' ll{ii} ';']);
    aux(badInds(ii,:)) = NaN;
    eval([ll{ii} ' = aux;']);
end

COPData=[NewCOPxL' NewCOPyL' zeros(size(NewCOPxL))' NewCOPxR' NewCOPyR' zeros(size(NewCOPxR))' GRFxL' GRFyL' GRFzL' GRFxR' GRFyR' GRFzR' GRMxL' GRMyL' zeros(size(GRMyL))' GRMxR' GRMyR' zeros(size(GRMyL))'];
COPTS=orientedLabTimeSeries(COPData,GRFData.Time(1),GRFData.sampPeriod,{'LCOPx','LCOPy','LCOPz','RCOPx','RCOPy','RCOPz', 'LGRFx','LGRFy','LGRFz','RGRFx','RGRFy','RGRFz','LGRMx','LGRMy','LGRMz','RGRMx','RGRMy','RGRMz'},or);

end


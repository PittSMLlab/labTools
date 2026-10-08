function COMTS = COMCalculator(markerData)
%COMCALCULATOR Compute segment center-of-mass time series from marker data.
%
%   Computes the center of mass of six lower-body segments (foot, shank,
% and thigh bilaterally) using fixed anthropometric fractions. Segment
% COMs are stored as an orientedLabTimeSeries with labels
% RfCOM/LfCOM/RsCOM/LsCOM/RtCOM/LtCOM (x/y/z components). This
% function is used by TorqueCalculator to provide the COM time series
% needed for joint torque estimation.
%
%   Marker names are resolved by regex to accommodate label variants
% such as RKNEx and RKNEEx. Missing markers are replaced with NaN
% columns and a warning is issued.
%
% Inputs:
%   markerData - orientedLabTimeSeries of 3-D marker positions;
%                should contain RHip, LHip, RAnk, LAnk, RKne, LKne,
%                RToe, and LToe (with x/y/z axis suffixes)
%
% Outputs:
%   COMTS - orientedLabTimeSeries with 18 channels (6 segments × 3
%           axes): RfCOMx/y/z, LfCOMx/y/z, RsCOMx/y/z, LsCOMx/y/z,
%           RtCOMx/y/z, LtCOMx/y/z
%
% Toolbox Dependencies:
%   None
%
% See also TORQUECALCULATOR, APPENDBODYCOM, ORIENTEDLABTIMESERIES.

arguments
    markerData (1,1)
end

%% Get Orientation
if isempty(markerData.orientation)          % if no orientation data, ...
    warning('Assuming default orientation of axes for marker data.');
    orientation = orientationInfo( ...
        [0 0 0], 'x', 'y', 'z', 1, 1, 1);  % default
else                                        % otherwise, ...
    orientation = markerData.orientation;   % use specified orientation
end

%% Retrieve Segment Marker Positions
u          = [orientation.sideSign orientation.foreaftSign ...
    orientation.updownSign];
markerList = {'RHip','LHip','RAnk','LAnk','RKne','LKne','RToe','LToe'};
for mrkr = markerList                           % for each marker, ...
    % get marker name allowing for variants like RKNEx and RKNEEx
    name = markerData.getLabelsThatMatch( ...
        ['^' upper(mrkr{1}) '*x$']);
    if ~isempty(name)                           % if a match was found, ...
        name = name{1}(1:end-1);                % retrieve marker name
        aux = markerData.getDataAsVector({ ...
            [name orientation.sideAxis], ...
            [name orientation.foreaftAxis], ...
            [name orientation.updownAxis]});
        aux = aux .* u;                         % reorienting marker data
    else                                        % otherwise, ...
        aux = nan(length(markerData.Time), 3);  % marker missing from trial
        warning(['Marker ' mrkr{1} ...             (it happens)
            ' was missing from markerData.']);
    end
    eval([mrkr{1} ' = aux;']);
    % below is more elegant (and recommended) than 'eval' but does not work
    % assignin('base',markerList{i},aux);
end

% RHip=markerData.getDataAsVector({['RHIP' orientation.sideAxis], ...
%    ['RHIP' orientation.foreaftAxis],['RHIP' orientation.updownAxis]});
% RHip=RHip.*u;
% RHip=[orientation.sideSign*RHip(:,1), ...
%    orientation.foreaftSign*RHip(:,2),orientation.updownSign*RHip(:,3)];
% LHip=markerData.getDataAsVector({['LHIP' orientation.sideAxis], ...
%    ['LHIP' orientation.foreaftAxis],['LHIP' orientation.updownAxis]});
% LHip=[orientation.sideSign*LHip(:,1), ...
%    orientation.foreaftSign*LHip(:,2),orientation.updownSign*LHip(:,3)];
% %get ankle position
% RAnk=markerData.getDataAsVector({['RANK' orientation.sideAxis], ...
%    ['RANK' orientation.foreaftAxis],['RANK' orientation.updownAxis]});
% RAnk=[orientation.sideSign*RAnk(:,1), ...
%    orientation.foreaftSign*RAnk(:,2),orientation.updownSign*RAnk(:,3)];
% LAnk=markerData.getDataAsVector({['LANK' orientation.sideAxis], ...
%    ['LANK' orientation.foreaftAxis],['LANK' orientation.updownAxis]});
% LAnk=[orientation.sideSign*LAnk(:,1), ...
%    orientation.foreaftSign*LAnk(:,2),orientation.updownSign*LAnk(:,3)];
% %get knee position
% RkneeName=markerData.getLabelsThatMatch('^RKNE');
% RkneeName=RkneeName{1}(1:end-1); %Removing axis suffix
% RKnee=markerData.getDataAsVector({[RkneeName orientation.sideAxis], ...
%    [RkneeName orientation.foreaftAxis], ...
%    [RkneeName orientation.updownAxis]});
% RKnee=[orientation.sideSign*RKnee(:,1), ...
%    orientation.foreaftSign*RKnee(:,2),orientation.updownSign*RKnee(:,3)];
%
% LkneeName=markerData.getLabelsThatMatch('^LKNE');
% LkneeName=LkneeName{1}(1:end-1); %Removing axis suffix
% LKnee=markerData.getDataAsVector({[LkneeName orientation.sideAxis], ...
%    [LkneeName orientation.foreaftAxis], ...
%    [LkneeName orientation.updownAxis]});
% LKnee=[orientation.sideSign*LKnee(:,1), ...
%    orientation.foreaftSign*LKnee(:,2),orientation.updownSign*LKnee(:,3)];
% %get toe position
% RToe=markerData.getDataAsVector({['RTOE' orientation.sideAxis], ...
%    ['RTOE' orientation.foreaftAxis],['RTOE' orientation.updownAxis]});
% RToe=[orientation.sideSign*RToe(:,1), ...
%    orientation.foreaftSign*RToe(:,2),orientation.updownSign*RToe(:,3)];
% LToe=markerData.getDataAsVector({['LTOE' orientation.sideAxis], ...
%    ['LTOE' orientation.foreaftAxis],['LTOE' orientation.updownAxis]});
% LToe=[orientation.sideSign*LToe(:,1), ...
%    orientation.foreaftSign*LToe(:,2),orientation.updownSign*LToe(:,3)];

shankComFraction = 0.394;  % TODO: source? (COM position along the shank)
thighComFraction = 0.567;  % TODO: source? (COM position along the thigh)

%% Compute Segment Centers of Mass
% foot:
fcomR = (RAnk + RToe) / 2;
fcomL = (LAnk + LToe) / 2;
% fcomxR=(RAnk(:,1)-RToe(:,1)).*.5+RToe(:,1); %m
% fcomxL=(LAnk(:,1)-LToe(:,1)).*.5+LToe(:,1); %m
% fcomyR=(RAnk(:,2)-RToe(:,2)).*.5+RToe(:,2); %m
% fcomzR=(RAnk(:,3)-RToe(:,3)).*.5+RToe(:,3); %m
% fcomyL=(LAnk(:,2)-LToe(:,2)).*.5+LToe(:,2); %m
% fcomzL=(LAnk(:,3)-LToe(:,3)).*.5+LToe(:,3); %m
% fcomR=[fcomxR,fcomyR,fcomzR]; %foot
% fcomL=[fcomxL,fcomyL,fcomzL];

% shank:
scomR = (RKne - RAnk) + shankComFraction * RAnk;
scomL = (LKne - LAnk) + shankComFraction * LAnk;
% scomxR=(RKnee(:,1)-RAnk(:,1)).*.394+RAnk(:,1);
% scomxL=(LKnee(:,1)-LAnk(:,1)).*.394+LAnk(:,1);
% scomyR=(RKnee(:,2)-RAnk(:,2)).*.394+RAnk(:,2);
% scomzR=(RKnee(:,3)-RAnk(:,3)).*.394+RAnk(:,3);
% scomyL=(LKnee(:,2)-LAnk(:,2)).*.394+LAnk(:,2);
% scomzL=(LKnee(:,3)-LAnk(:,3)).*.394+LAnk(:,3);
% scomR=[scomxR,scomyR,scomzR]; %Shank
% scomL=[scomxL,scomyL,scomzL];

% thigh:
tcomR = (RHip - RKne) + thighComFraction * RKne;
tcomL = (LHip - LKne) + thighComFraction * LKne;
% tcomxR=(RHip(:,1)-RKnee(:,1)).*.567+RKnee(:,1);
% tcomxL=(LHip(:,1)-LKnee(:,1)).*.567+LKnee(:,1);
% tcomyR=(RHip(:,2)-RKnee(:,2)).*.567+RKnee(:,2);
% tcomzR=(RHip(:,3)-RKnee(:,3)).*.567+RKnee(:,3);
% tcomyL=(LHip(:,2)-LKnee(:,2)).*.567+LKnee(:,2);
% tcomzL=(LHip(:,3)-LKnee(:,3)).*.567+LKnee(:,3);
% tcomR=[tcomxR,tcomyR,tcomzR]; %Thigh
% tcomL=[tcomxL,tcomyL,tcomzL];

%% Assemble Output as orientedLabTimeSeries
COMData = [fcomR fcomL scomR scomL tcomR tcomL];
% COM accelerations for each leg segment in each directions

labels = {'RfCOM','LfCOM','RsCOM','LsCOM','RtCOM','LtCOM'};
labels = [strcat(labels,'x'); strcat(labels,'y'); strcat(labels,'z')];

% create 'orientedLabTS' object to output
COMTS = orientedLabTimeSeries(COMData, markerData.Time(1), ...
    markerData.sampPeriod, labels(:), markerData.orientation);

end


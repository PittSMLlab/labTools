function  gaitMovieHH(subject,trial,start,stop)
%GAITMOVIE  Make .avi movie of bilateral gait
%   Run GAITMOVIE in folder containing .2ld file(s)
%   .2ld - 3D positions for 12 markers
%   .vlt - beltspeeds
%   .txt - title, captions and footnotes
%GTO Last edited May, 16th 2013 (cleaned up commented stuff)
%
%HH edit 6/2013 - changed avifile funtion to writeVideo function
% added bar graphs below animations to show alpha and w*t values
%
%This function plots both contributions as horizontal bars on the same plot
%but on opposite sides of vertical axis
%

%Load subject
load([subject '.mat'])

%get trial to animate
trialData=expData.data{trial};

%adjust input times to samples
start=round(start*trialData.markerData.sampFreq);
stop=round(stop*trialData.markerData.sampFreq);

%reduce sampling rate by factor 10
f = 1.5; % 15 would make the file smaller %5 was chosen for presentation movies

%create object that stores movie data to .avi file
videoObj = VideoWriter(subject);
videoObj.FrameRate = 100/f;
videoObj.Quality = 100;
open(videoObj);

%extract and orgaize data from .2ld file and Evants matrix

orientation=trialData.markerData.orientation;

Marker.RMT.X = -trialData.getMarkerData(['RTOE' orientation.foreaftAxis]);
Marker.RMT.Z = trialData.getMarkerData(['RTOE' orientation.updownAxis]);
Marker.RMT.Y = trialData.getMarkerData(['RTOE' orientation.sideAxis]);
Marker.RAnkle.X = -trialData.getMarkerData(['RANK' orientation.foreaftAxis]);
Marker.RAnkle.Z = trialData.getMarkerData(['RANK' orientation.updownAxis]);
Marker.RAnkle.Y = trialData.getMarkerData(['RANK' orientation.sideAxis]);
Marker.RKnee.X = -trialData.getMarkerData(['RKNEE' orientation.foreaftAxis]);
Marker.RKnee.Z = trialData.getMarkerData(['RKNEE' orientation.updownAxis]);
Marker.RKnee.Y = trialData.getMarkerData(['RKNEE' orientation.sideAxis]);
Marker.RHip.X = -trialData.getMarkerData(['RHIP' orientation.foreaftAxis]);
Marker.RHip.Z = trialData.getMarkerData(['RHIP' orientation.updownAxis]);
Marker.RHip.Y = trialData.getMarkerData(['RHIP' orientation.sideAxis]);
Marker.RPelvis.X = -trialData.getMarkerData(['RASIS' orientation.foreaftAxis]);
Marker.RPelvis.Z = trialData.getMarkerData(['RASIS' orientation.updownAxis]);
Marker.RPelvis.Y = trialData.getMarkerData(['RASIS' orientation.sideAxis]);

Marker.LMT.X = -trialData.getMarkerData(['LTOE' orientation.foreaftAxis]);
Marker.LMT.Z = trialData.getMarkerData(['LTOE' orientation.updownAxis]);
Marker.LMT.Y = trialData.getMarkerData(['LTOE' orientation.sideAxis]);
Marker.LAnkle.X = -trialData.getMarkerData(['LANK' orientation.foreaftAxis]);
Marker.LAnkle.Z = trialData.getMarkerData(['LANK' orientation.updownAxis]);
Marker.LAnkle.Y = trialData.getMarkerData(['LANK' orientation.sideAxis]);
Marker.LKnee.X = -trialData.getMarkerData(['LKNEE' orientation.foreaftAxis]);
Marker.LKnee.Z = trialData.getMarkerData(['LKNEE' orientation.updownAxis]);
Marker.LKnee.Y = trialData.getMarkerData(['LKNEE' orientation.sideAxis]);
Marker.LHip.X = -trialData.getMarkerData(['LHIP' orientation.foreaftAxis]);
Marker.LHip.Z = trialData.getMarkerData(['LHIP' orientation.updownAxis]);
Marker.LHip.Y = trialData.getMarkerData(['LHIP' orientation.sideAxis]);
Marker.LPelvis.X = -trialData.getMarkerData(['LASIS' orientation.foreaftAxis]);
Marker.LPelvis.Z = trialData.getMarkerData(['LASIS' orientation.updownAxis]);
Marker.LPelvis.Y = trialData.getMarkerData(['LASIS' orientation.sideAxis]);


%Make animation
color = [0.4 0.4 0.4];

%colors
blue = [11 132 199]/255;
%blue = [0 160 198]/255;
orange = [255 153 0]/255;
fadeblue = [152 212 228]/255;
fadeorange = [255 210 142]/255;
grey = [.4 .4 .4];

opengl software

h_fig = figure;
set(h_fig,'Position',[933 73 339 605],...  %HH laptop [500   50   500   600] desktop [1440 135 400 800]
    'Color',[1 1 1],...
    'Renderer','OpenGL');
%'DoubleBuffer','on');
%'Renderer','OpenGL',... %'Renderer','zbuffer',...

Xlim = [min([Marker.LAnkle.X(start:stop); Marker.RAnkle.X(start:stop)])-200 max([Marker.LMT.X(start:stop); Marker.RMT.X(start:stop)])+200];
Ylim = [min([Marker.LAnkle.Y(start:stop); Marker.RAnkle.Y(start:stop)])-200 max([Marker.LAnkle.Y(start:stop); Marker.RAnkle.Y(start:stop)])+200];
Zlim = [min([Marker.LMT.Z(start:stop); Marker.RMT.Z(start:stop)])-200 max([Marker.LPelvis.Z(start:stop); Marker.RPelvis.Z(start:stop)])+200];
    
set(gca,'XLim',Xlim,... %[-100 1200] needs to change
    'YLim',Ylim,...
    'ZLim',Zlim,... %[-400 2000]%catch
    'Visible','off',...
    'Position',[0.13 0.11 0.775 0.815],...
    'DataAspectRatio',[1 1 1],...
    'CameraPosition',[-1213.04 -8746.45 1140.87],... %'CameraPosition',[0 -10000 500]
    'CameraTarget',[-780.782 -498.523 441.085],...'CameraTarget',[0 0 1000],...  % worked [500 0 1000] old [300 0 750]
    'Projection','perspective',...
    'View',[-0.646214 1.02951],...
    'NextPlot', 'add');


%set(h_sub1,'Position',[-0.15 0.055 1.1 1.3]) 
% desktop [0.1 0.01 0.8 1.45] 
%LN440  
%LN0444 [-0.025 0.055 1.1 1.3]
%LN0452 [-0.065 0.025 1.05 1.3]


for i = start:stop
    h_person = findobj(gca,'Type','surface');
    delete(h_person)
    
    %draw legs - thigh,shank,foot
    for side = 1:2
        if side==1
            s = 'R';
            colorLegs=blue;
            %colorLegs=[0 0 0];
        elseif side==2
            s = 'L';
            colorLegs=orange;
            %colorLegs=[1 1 1];
        end
        for seg = 1:3
            if seg==1
                joint1 = 'MT';
                joint2 = 'Ankle';
                radius = [1 .5 .5];
            elseif seg==2
                joint1 = 'Ankle';
                joint2 = 'Knee';
                radius = [1 .25 .25];
            elseif seg==3
                joint1 = 'Knee';
                joint2 = 'Hip';
                radius = [1 .35 .35];
            end
            X = [Marker.([s joint1]).X(i) Marker.([s joint2]).X(i)];
            Y = [Marker.([s joint1]).Y(i) Marker.([s joint2]).Y(i)];
            Z = [Marker.([s joint1]).Z(i) Marker.([s joint2]).Z(i)];
            drawsegment(gca,X,Y,Z,radius,colorLegs)
        end
        %draw hip joints
        X = Marker.([s 'Hip']).X(i);
        Y = Marker.([s 'Hip']).Y(i);
        Z = Marker.([s 'Hip']).Z(i);
        drawball(gca,X,Y,Z,50,color)        
    end
    %draw pelvis
    X = [Marker.RHip.X(i) Marker.LHip.X(i)];
    Y = [Marker.RHip.Y(i) Marker.LHip.Y(i)];
    Z = [Marker.RHip.Z(i) Marker.LHip.Z(i)];
    drawsegment(gca,X,Y,Z,[1 .4 .4],color)  
  
    h_light = camlight('headlight');
    set(findobj(gca,'type','surface'),...
        'FaceLighting','gouraud',...
        'AmbientStrength',.3,...
        'DiffuseStrength',.8,...
        'SpecularStrength',.8,...
        'SpecularExponent',25,...
        'BackFaceLighting','reverselit')
    
    %save image as next frame in video file
    
    frame = getframe(h_fig);
    writeVideo(videoObj,frame);
    
    pause(.0001) %forces refresh    
    delete(h_light)       
end

close(videoObj);

function drawsegment(h_axes,X1,Y1,Z1,a,color)
%draw an ellipsoid aligned to line defined by 2 points
%a defines relative length of the ellipsoid radii
O = [X1(1) Y1(1) Z1(1)]; %vector origin
V = [X1(2)-X1(1) Y1(2)-Y1(1) Z1(2)-Z1(1)]; %vector
[theta,phi,r] = cart2sph(V(1),V(2),V(3)); %theta is angle with x-axis, phi is angle with z-axis, r is length of segment
%build segment surface and rotate/translate
[X,Y,Z] = ellipsoid(r/2,0,0,r/2,r/2*a(2)/a(1),r/2*a(3)/a(1)); %build segment surface about origin
h = surf(h_axes,X,Y,Z,'FaceColor',color,'EdgeColor','none');
t = hgtransform('Parent',h_axes);
set(h,'Parent',t)
Ry = makehgtform('yrotate',-phi);
Rz = makehgtform('zrotate',theta);
Tx = makehgtform('translate',O);
set(t,'Matrix',Tx*Rz*Ry)
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
function drawball(h_axes,X1,Y1,Z1,radius,color)
%draw a ball centered at a defined point
O = [X1 Y1 Z1]; %vector origin
%build ball surface and translate
[X,Y,Z] = sphere; %build segment surface about origin
h = surf(h_axes,X,Y,Z,'FaceColor',color,'EdgeColor','none');
t = hgtransform('Parent',h_axes);
set(h,'Parent',t)
S = makehgtform('scale',radius);
Tx = makehgtform('translate',O);
set(t,'Matrix',Tx*S)
%--------------------------------------------------------------------------





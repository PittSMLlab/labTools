function [Pa,Li] = nanJackKnife(varargin)
% JACKKNIFE plots jackknife errorbars around a given curve
%
%     [Pa,Li,t] = JACKKNIFE(x,y,L,U,'r','g')
%     JACKKNIFE(x,y,se,colorMean,colorShade)
%     x= vector 1:points
%     y= each row is mean of a condition
%
%     Plots a gray Jackknife around the line displayed in black very useful for
%     funky nature style error bars which are shaded.
%
%         Pa is a patch object for more help on patch objects see below
%         Li is a line object, more help on line object is available in MATLAB
%
%     USAGE :
%              1)   [Pa,Li] = JackKnife(x,y,E)
%                    Calculates the Lower and upper errorbars as
%                    L = Y-E and U = Y+E. It then takes a default gray color
%                    as patch color, and the line color as black and plots
%                    it around the line using a patch object.
%
%              2)   [Pa,Li] = JackKnife(x,y,E,LineColor,PatchColor)
%                    Calculates the Lower and upper errorbars as
%                    L = Y-E and U = Y+E. It then takes PatchColor
%                    as patch color, and the Line Color from the LineColor
%                    variable. It then plots it around the line
%                    using a patch object.
%
%              3)   [Pa,Li] = JackKnife(x,y,L,U)
%                    User Supplied bounds are taken as L and U, It then takes
%                    a default gray color as patch color, and the line color
%                    as black and plots it around the line using a patch object.
%
%              4)   [Pa,Li] = JackKnife(x,y,L,U,LineColor,PatchColor)
%                    User Supplied bounds are taken as L and U, It then takes
%                    PatchColor as patch color, and the Line Color from the LineColor
%                    variable. It then plots it around the line using a
%                    patch object.
%      CAVEATS
%                 1) Can be Slow sometimes for length(Array) > 10000,
%                 2) Needs better vectorization
%      EXAMPLE
%                         t = [-5:0.05:5];
%                         Y = sin(t);
%                         E = 0.4*rand(1,length(t));
%                         [Pa,Li] = JackKnife(t,Y,E);
%                         xlabel('time');
%                         ylabel('Amplitude');
%                         title('Using Errors alone');
%
%                         figure;
%                         L = Y - E;
%                         U = Y + E;
%                         [Pa,Li] = JackKnife(t,Y,L,U);
%                         xlabel('time');
%                         ylabel('Amplitude');
%                         title('Using Lower and Upper Confidence Intervals');
%                         hold on;
%
%                         Y1 = 2*Y;
%                         L = Y1 - 0.2;
%                         U = Y1 + 0.2;
%                         [Pa,Li] = JackKnife(t,Y1,L,U,[255 51 51]./255,[255 153 102]./255);
%                         hold on;
%                         [Pa,Li] = JackKnife(t,Y1*2,E,[51 51 153]./255,[102 153 204]./255);
%                         [Pa,Li] = JackKnife(t,Y1*2,E,'r','g');
%
% See also ERRORBAR, PATCH, LINE
%
%
% Version 0.001 Chandramouli Chandrasekaran (Chandt) - 13 April 2006.


switch(nargin)
    case 3,
        % If there are 3 inputs it means its just the errors
        x = varargin{1};
        y = varargin{2};
        E = varargin{3};
        x(isnan(y))=[];
        E(isnan(y))=[];
        y(isnan(y))=[];
        L = y - E;
        U = y + E;
        LineColor = 'k';
        PatchColor = [0.85 0.85 0.85];
        Opacity=1;
    case 4,
        % If there are 4 inputs it means they entered the Lower and upper
        % bounds
        x = varargin{1};
        y = varargin{2};
        L = varargin{3};
        U = varargin{4};
        x(isnan(y))=[];
        L(isnan(y))=[];
        U(isnan(y))=[];
        y(isnan(y))=[];
        LineColor = 'k';
        PatchColor = [0.85 0.85 0.85];
        Opacity=1;
    case 5,
        x = varargin{1};
        y = varargin{2};
        E = varargin{3};
        x(isnan(y))=[];
        E(isnan(y))=[];
        y(isnan(y))=[];
        L = y - E;
        U = y + E;
        LineColor =  varargin{4};
        EdgeColor=LineColor-0.5.*abs(LineColor);
        PatchColor = varargin{5};
        Opacity=1;
    case 6,
        % If there are 6 inputs then
        x = varargin{1};
        y = varargin{2};
        E = varargin{3};
        x(isnan(y))=[];
        E(isnan(y))=[];
        y(isnan(y))=[];
        L = y - E;
        U = y + E;
        LineColor =  varargin{4};
        EdgeColor=LineColor-0.5.*abs(LineColor);
        PatchColor = varargin{5};
        Opacity= varargin{6};
    case 7,
        % If there are 6 inputs then
    
        x = varargin{1};
        y = varargin{2};
        E = varargin{3};
        x(isnan(y))=[];
        E(isnan(y))=[];
        y(isnan(y))=[];
        L = y - E;
        U = y + E;
        LineColor =  varargin{4};
        EdgeColor = LineColor-0.5.*abs(LineColor);
        PatchColor = varargin{5};
        Opacity= varargin{6};
        w=varargin{7};
%         Opacity= varargin{7};
end
Xcoords = [x x(end:-1:1)];
Ycoords = [U+0.001 L(end:-1:1)];

% Pa = patch(Xcoords,Ycoords,PatchColor);
% set(Pa,'linestyle','-','linewidth',1,'EdgeColor',LineColor,'FaceAlpha',Opacity);
hold on;
%Li = plot(x,y,'color',LineColor,'linewidth',2);
if nargin<7
    Pa = patch(Xcoords,Ycoords,PatchColor);
    set(Pa,'linestyle','-','linewidth',1,'EdgeColor',LineColor,'FaceAlpha',Opacity);
    Li = plot(x,y,'o','MarkerSize',5,'LineWidth',1,'MarkerEdgeColor',EdgeColor,'MarkerFaceColor',LineColor);
elseif nargin>=7
    % Pa = patch(Xcoords,Ycoords,'w');
    % Pa=[];
    Pa = patch(Xcoords,Ycoords,PatchColor);
    for l=1:length(x)        
        if w(l)==0;
            set(Pa,'linestyle','-','linewidth',1,'EdgeColor',LineColor,'FaceAlpha',Opacity);
            Li = plot(x(l),y(l),'o','MarkerSize',8,'LineWidth',1,'MarkerEdgeColor',EdgeColor,'MarkerFaceColor',[0 0 0]);
            % Li = plot(x(l),y(l),'o','MarkerSize',5,'LineWidth',1,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0 0 0]);
        else
            set(Pa,'linestyle','-','linewidth',1,'EdgeColor',LineColor,'FaceAlpha',Opacity);
            Li = plot(x(l),y(l),'o','MarkerSize',8,'LineWidth',1,'MarkerEdgeColor',EdgeCOlor,'MarkerFaceColor',LineColor);
            % Li = plot(x(l),y(l),'o','MarkerSize',5,'LineWidth',1,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',LineColor);
        end
    end
end

hold on;





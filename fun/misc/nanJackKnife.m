function [Pa,Li] = nanJackKnife(varargin)
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
        % If there are 7 inputs then
    
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
        EdgeColor = 'none';
        PatchColor = varargin{5};
        Opacity= varargin{6};
        w=varargin{7}; %Binary flag to make some markers white (?)
%         Opacity= varargin{7};
end
Xcoords = [x x(end:-1:1)];
Ycoords = [U L(end:-1:1)];
Pa=[];
% Pa = patch(Xcoords,Ycoords,PatchColor);
% set(Pa,'linestyle','-','linewidth',1,'EdgeColor',LineColor,'FaceAlpha',Opacity);
hold on;
%Li = plot(x,y,'color',LineColor,'linewidth',2);
if nargin<7
    if ~all(U==L)
    Pa = patch(Xcoords,Ycoords,PatchColor);
    set(Pa,'linestyle','-','linewidth',1,'EdgeColor',LineColor,'FaceAlpha',Opacity);
    end
    Li = plot(x,y,'o','MarkerSize',5,'LineWidth',1,'MarkerEdgeColor',EdgeColor,'MarkerFaceColor',LineColor);
elseif nargin>=7
    % Pa = patch(Xcoords,Ycoords,'w');

    if ~all(U==L)
        Pa = patch(Xcoords,Ycoords,PatchColor);
        set(Pa,'linestyle','-','linewidth',1,'EdgeColor',LineColor,'FaceAlpha',Opacity);
    end
    for l=1:length(x)        
        if w(l)==0;
            Li = plot(x(l),y(l),'o','MarkerSize',8,'LineWidth',1,'MarkerEdgeColor',EdgeColor,'MarkerFaceColor',[0 0 0]);
            % Li = plot(x(l),y(l),'o','MarkerSize',5,'LineWidth',1,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',[0 0 0]);
        else
            Li = plot(x(l),y(l),'o','MarkerSize',8,'LineWidth',1,'MarkerEdgeColor',EdgeColor,'MarkerFaceColor',LineColor);
            % Li = plot(x(l),y(l),'o','MarkerSize',5,'LineWidth',1,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',LineColor);
        end
    end
end

hold on;




%NANJACKKNIFE Plot shaded error-bar patches around a data curve.
%
%   Plots a shaded patch representing jackknife (or generic) error
% bounds around a line. Supports 3–7 arguments. Based on the original
% JackKnife by Chandramouli Chandrasekaran (2006).
%
% Usage:
%   [Pa,Li] = nanJackKnife(x, y, E)
%   [Pa,Li] = nanJackKnife(x, y, L, U)
%   [Pa,Li] = nanJackKnife(x, y, E, LineColor, PatchColor)
%   [Pa,Li] = nanJackKnife(x, y, L, U, LineColor, PatchColor)
%   [Pa,Li] = nanJackKnife(x, y, E, LineColor, PatchColor, Opacity)
%   [Pa,Li] = nanJackKnife(x, y, E, LineColor, PatchColor, Opacity, w)
%
% Inputs:
%   x          - 1×N position vector
%   y          - 1×N mean values
%   E          - 1×N symmetric error (L = y-E, U = y+E)
%   L, U       - 1×N lower and upper bounds (alternative to E)
%   LineColor  - color for the mean line (default 'k')
%   PatchColor - color for the error patch (default [0.85 0.85 0.85])
%   Opacity    - patch transparency FaceAlpha (default 1)
%   w          - (optional) 1×N binary flag; 0 = black fill, 1 = line
%                color fill for each marker
%
% Outputs:
%   Pa - patch object (or [] if U == L everywhere)
%   Li - line/marker object from the last plotted point
%
% Toolbox Dependencies: None
%
% See also ERRORBAR, PATCH, LINE.

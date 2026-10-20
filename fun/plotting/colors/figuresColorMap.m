%% Figures color map
% Script. Builds the diverging color map `map` (red to white to blue) and
% the default condition colors `condColors` used by prettyBarPlot and
% the plotting functions. The CoolWarmMap.mat map that is loaded first
% is overwritten by the map built from the two extreme colors.
%
% Inputs:
%   none
%
% Outputs:
%   map        - (workspace) 202 x 3 diverging color map
%   condColors - (workspace) 3 x 3 colors of the default conditions
%   ex1, ex2   - (workspace) extreme colors of the map
%   gamma      - (workspace) gamma of the interpolation
%
% Side effects: loads CoolWarmMap.mat (must be on the path).
%
% Toolbox Dependencies: None
%
% See also PRETTYBARPLOT, NICEMAP.

ex1   = [0.85,0,0.1];
ex2   = [0,0.1,0.6];
gamma = 0.5;
map   = [bsxfun(@plus,ex1,bsxfun(@times,1-ex1,[0:0.01:1]')); ...
    bsxfun(@plus,ex2,bsxfun(@times,1-ex2,[1:-0.01:0]'))].^gamma;

%Alt: use external function:
%map=diverging_map([0:.01:1],round(ex1),round(ex2));

load('CoolWarmMap.mat')
map = CoolWarmMap/255; %This uses gray in the middle

%Same extreme colors, but white in the middle:
%ex1=map(1,:);
%ex2=map(end,:);
ex2 = [0.2314    0.2980    0.7529];
ex1 = [0.7255    0.0863    0.1608];
%ex1=[12,35,64]/255; %Pitt blue
%ex2=[179, 163, 105]/255; %Pitt gold
%[203,192,130]/255 %Pitt gold from swanson logo

map = [bsxfun(@plus,ex1.^(1/gamma),bsxfun(@times,1-ex1.^(1/gamma), ...
    [0:0.01:1]'));bsxfun(@plus,ex2.^(1/gamma), ...
    bsxfun(@times,1-ex2.^(1/gamma),[1:-0.01:0]'))].^gamma;

condColors = [0.4,0.4,0.4; 0,0.5,0.4; 0.55,0,0.65];

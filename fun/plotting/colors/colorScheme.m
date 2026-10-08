%% Color scheme
% Script. Defines the lab color palette and the colors of the events,
% conditions, and groups in plots. The palette columns below are listed
% as RGB rows (0-255) divided by 255; the named p_* colors are cleared at
% the end.
%
% Inputs:
%   none
%
% Outputs:
%   color_palette - (workspace) 29 x 3 RGB palette (0-1)
%   colorEvents   - (workspace) RGB color of the events
%   colorConds    - (workspace) cell array of condition colors
%   colorGroups   - (workspace) cell array of group colors
%
% Toolbox Dependencies: None
%
% See also POSTER_COLORS, FIGURESCOLORMAP.
%               1          2          3          4          5          6
%             red   fade red      green fade green       blue  fade blue
%               7          8          9         10         11         12
%           black       gray     yellow     orange       plum       lime

%color_palette = [255 0 0; 255 150 150; 0 114 54; 153 255 102; 0 0 255; ...
%    44 176 207; 0 0 0; 155 155 155; 255 153 0; 255 185 0; 153 51 102; ...
%    171 218 77]*(1/255);
%new colors
%color_palette = [255 0 0; 255 185 0; 153 255 102; 44 176 207; ...
%    129 23 136; 0 114 54; 255 150 150; 29 14 130; 153 153 210; ...
%    151 15 0; 102 126 0; 255 51 102; 0 0 255; 71 38 0; 255 102 0; ...
%    171 218 77; 155 155 155; 0 0 0]*(1/255);
color_palette = [255 0 0; 255 150 150; 0 114 54; 153 255 102; 0 0 255; ...
    44 176 207; 0 0 0; 155 155 155; 255 153 0; 255 185 0; 153 51 102; ...
    171 218 77; 255 185 0; 153 255 102; 44 176 207; 129 23 136; ...
    0 114 54; 255 150 150; 29 14 130; 153 153 210; 151 15 0; 102 126 0; ...
    255 51 102; 0 0 255; 71 38 0; 255 102 0; 171 218 77; 155 155 155; ...
    0 0 0]*(1/255);
p_red         = color_palette(1,:);
p_fade_red    = color_palette(2,:);
p_fade_green  = color_palette(4,:);
p_blue        = color_palette(5,:);
p_fade_blue   = color_palette(6,:);
p_black       = color_palette(18,:);
p_green       = color_palette(17,:);
p_yellow      = color_palette(9,:);
p_orange      = color_palette(10,:);
p_plum        = color_palette(11,:);
p_lime        = color_palette(12,:);
p_gray        = [0.6,0.6,0.6];

colorEvents = [0,0.5,0.3];
colorConds  = {p_fade_blue, p_green,p_gray, p_orange, p_plum, p_lime, ...
    p_red, p_blue,p_yellow,p_black};
colorGroups = {[0,0,0],[0.5,0.5,0.1],[0.8,0,0.5],[0.6,0.6,0.6]};
clear p_*
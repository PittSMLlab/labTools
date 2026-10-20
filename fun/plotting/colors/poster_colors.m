%% Poster colors
% Script. Defines the lab color palette and the named colors p_red,
% p_fade_red, p_green, p_fade_green, p_blue, p_fade_blue, p_black,
% p_gray, p_yellow, p_orange, p_plum, and p_lime used by plotEMGtraces and
% optimizedSubPlot. The comment table lists the colors of palette rows
% 1-12.
%
% Inputs:
%   none
%
% Outputs:
%   color_palette - (workspace) 29 x 3 RGB palette (0-1)
%   p_*           - (workspace) named RGB colors
%
% Toolbox Dependencies: None
%
% See also COLORSCHEME, POSTER_COLORSHH.
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
p_green       = color_palette(3,:);
p_fade_green  = color_palette(4,:);
p_blue        = color_palette(5,:);
p_fade_blue   = color_palette(6,:);
p_black       = color_palette(18,:);
p_gray        = color_palette(17,:);
p_yellow      = color_palette(9,:);
p_orange      = color_palette(10,:);
p_plum        = color_palette(11,:);
p_lime        = color_palette(12,:);


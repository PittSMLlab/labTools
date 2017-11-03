% Define color scheme
%                  1          2          3          4          5          6          7        8           9        10            11        12
%                red     fade red     green    fade green    blue     fade blue   black     gray       yellow    orange        plum      lime
%color_palette= [255 0 0; 255 150 150; 0 114 54; 153 255 102; 0 0 255; 44 176 207; 0 0 0; 155 155 155; 255 153 0; 255 185 0; 153 51 102; 171 218 77]*(1/255);
%new colors
%color_palette= [255 0 0; 255 185 0; 153 255 102; 44 176 207; 129 23 136;0 114 54;255 150 150;29 14 130 ;153 153 210 ;151 15 0; 102 126 0;255 51 102; 0 0 255; 71 38 0; 255 102 0; 171 218 77; 155 155 155;0 0 0]*(1/255);
color_palette= [255 0 0; 255 150 150; 0 114 54; 153 255 102; 0 0 255; 44 176 207; 0 0 0; 155 155 155; 255 153 0; 255 185 0; 153 51 102; 171 218 77;255 185 0; 153 255 102; 44 176 207; 129 23 136;0 114 54;255 150 150;29 14 130 ;153 153 210 ;151 15 0; 102 126 0;255 51 102; 0 0 255; 71 38 0; 255 102 0; 171 218 77; 155 155 155;0 0 0]*(1/255);
p_red=color_palette(1,:);
p_fade_red=color_palette(2,:);
p_fade_green=color_palette(4,:);
p_blue=color_palette(5,:);
p_fade_blue=color_palette(6,:);
p_black=color_palette(18,:);
p_green=color_palette(17,:);
p_yellow=color_palette(9,:);
p_orange=color_palette(10,:);
p_plum=color_palette(11,:);
p_lime=color_palette(12,:);
p_gray=[.6,.6,.6];

colorEvents=[0,.5,.3];
colorConds={p_fade_blue, p_green,p_gray, p_orange, p_plum, p_lime, p_red, p_blue,p_yellow,p_black};
colorGroups={[0,0,0],[.5,.5,.1],[.8,0,.5],[.6,.6,.6]};
clear p_*
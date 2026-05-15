function drawball(h_axes, X1, Y1, Z1, radius, color)
%drawball  Draws 3D sphere
%
%   drawball(h_axes, X1, Y1, Z1, radius, color) draws sphere at
%   specified point
%
%   Inputs:
%       h_axes - axes handle
%       X1 - x-coordinate of center
%       Y1 - y-coordinate of center
%       Z1 - z-coordinate of center
%       radius - sphere radius
%       color - RGB color vector
%
%   Note: Helper function for animate methods
%
%   See also: drawsegment, drawcylinder, animate

% Hidden Static
% draw a ball centered at a defined point
O = [X1 Y1 Z1]; % vector origin
% build ball surface and translate build segment surface about origin
[X, Y, Z] = sphere;
h = surf(X, Y, Z, 'FaceColor', color, 'EdgeColor', 'none');
t = hgtransform('Parent', h_axes);
set(h, 'Parent', t);
S = makehgtform('scale', radius);
Tx = makehgtform('translate', O);
set(t, 'Matrix', Tx * S);
end


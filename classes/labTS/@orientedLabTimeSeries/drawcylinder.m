function drawcylinder(h_axes, X1, Y1, Z1, radius, color)
%drawcylinder  Draws 3D cylinder
%
%   drawcylinder(h_axes, X1, Y1, Z1, radius, color) draws cylinder
%   between two points
%
%   Inputs:
%       h_axes - axes handle
%       X1 - x-coordinates of endpoints [x1 x2]
%       Y1 - y-coordinates of endpoints [y1 y2]
%       Z1 - z-coordinates of endpoints [z1 z2]
%       radius - cylinder radii (can vary for coned cylinder)
%       color - RGB color vector
%
%   Note: Helper function for animate methods
%
%   See also: drawsegment, drawball, animate

% Hidden Static
% draw a cylinder centered around line defined by 2 points radius
% defines the radii of the coned-cylinder
O = [X1(1) Y1(1) Z1(1)]; % vector origin
V = [X1(2) - X1(1) Y1(2) - Y1(1) Z1(2) - Z1(1)]; % vector
% build surface and rotate/translate theta is angle with x-axis, phi
% is angle with z-axis, r is length of segment
[theta, phi, r] = cart2sph(V(1), V(2), V(3));
[X, Y, Z] = cylinder(radius); % build segment surface about origin
h = surf(X, Y, Z, 'FaceColor', color, 'EdgeColor', 'none');
t = hgtransform('Parent', h_axes);
set(h, 'Parent', t);
Sz = makehgtform('scale', [1, 1, r]);
Ry1 = makehgtform('yrotate', pi / 2);
Ry2 = makehgtform('yrotate', -phi);
Rz = makehgtform('zrotate', theta);
Tx = makehgtform('translate', O);
set(t, 'Matrix', Tx * Rz * Ry2 * Ry1 * Sz);
end


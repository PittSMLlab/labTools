function drawsegment(h_axes, X1, Y1, Z1, a, color)
%drawsegment  Draws 3D ellipsoid segment
%
%   drawsegment(h_axes, X1, Y1, Z1, a, color) draws ellipsoid aligned
%   to line between two points
%
%   Inputs:
%       h_axes - axes handle
%       X1 - x-coordinates of endpoints [x1 x2]
%       Y1 - y-coordinates of endpoints [y1 y2]
%       Z1 - z-coordinates of endpoints [z1 z2]
%       a - relative radii [1 a2 a3] defining ellipsoid shape
%       color - RGB color vector
%
%   Note: Helper function for animate methods
%
%   See also: drawball, drawcylinder, animate

% Hidden Static
% Auxiliar functions for this.animate()
% draw an ellipsoid aligned to line defined by 2 points a defines
% relative length of the ellipsoid radii
O = [X1(1) Y1(1) Z1(1)]; % vector origin
V = [X1(2) - X1(1) Y1(2) - Y1(1) Z1(2) - Z1(1)]; % vector
% theta is angle with x-axis, phi is angle with z-axis, r is length of
% segment
[theta, phi, r] = cart2sph(V(1), V(2), V(3));
% build segment surface and rotate/translate build segment surface
% about origin
[X, Y, Z] = ellipsoid(r / 2, 0, 0, r / 2, r / 2 * a(2) / a(1), ...
    r / 2 * a(3) / a(1));
h = surf(X, Y, Z, 'FaceColor', color, 'EdgeColor', 'none');
t = hgtransform('Parent', h_axes);
set(h, 'Parent', t);
Ry = makehgtform('yrotate', -phi);
Rz = makehgtform('zrotate', theta);
Tx = makehgtform('translate', O);
set(t, 'Matrix', Tx * Rz * Ry);
end


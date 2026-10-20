function map = niceMap(extreme,gamma)
%NICEMAP Colormap from white to a given color.
%
%   Builds a 101-row colormap that goes from white to extreme. The
% interpolation is linear for gamma = 1 and non-linear otherwise.
%
% Inputs:
%   extreme - RGB triplet of the end color
%   gamma   - (optional) gamma of the interpolation (default: 1)
%
% Outputs:
%   map - 101 x 3 colormap
%
% Toolbox Dependencies: None

if nargin < 2
    gamma = 1;
end
newEx = extreme.^(1/gamma);
map   = [newEx+(1-newEx).*[0:0.01:1]'].^gamma;
end
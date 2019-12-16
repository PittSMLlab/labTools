function map=niceMap(extreme,gamma)
%Generates a colormap from white to any given extreme color
%The interpolation is linear for gamma=1 (default) nonlinear for other
%gamma
if nargin<2
    gamma=1;
end
newEx=extreme.^(1/gamma);
map=[newEx+(1-newEx).*[0:.01:1]'].^gamma;
end
%Colormap:
ex1=[.85,0,.1];
ex2=[0,.1,.6];
gamma=.5;
map=[bsxfun(@plus,ex1,bsxfun(@times,1-ex1,[0:.01:1]'));bsxfun(@plus,ex2,bsxfun(@times,1-ex2,[1:-.01:0]'))].^gamma;

%Alt: use external function:
%map=diverging_map([0:.01:1],round(ex1),round(ex2));

load('CoolWarmMap.mat')
map=CoolWarmMap/255; %This uses gray in the middle

%Same extreme colors, but white in the middle:
%ex1=map(1,:);
%ex2=map(end,:);
ex2=[0.2314    0.2980    0.7529];
ex1=[0.7255    0.0863    0.1608];
%ex1=[12,35,64]/255; %Pitt blue
%ex2=[179, 163, 105]/255; %Pitt gold
%[203,192,130]/255 %Pitt gold from swanson logo

map=[bsxfun(@plus,ex1.^(1/gamma),bsxfun(@times,1-ex1.^(1/gamma),[0:.01:1]'));bsxfun(@plus,ex2.^(1/gamma),bsxfun(@times,1-ex2.^(1/gamma),[1:-.01:0]'))].^gamma;

condColors=[.4,.4,.4; 0,.5,.4; .55,0,.65];

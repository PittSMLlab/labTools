function pp = polyfit1PCA(x,y,varNormalizeFlag)
%POLYFIT1PCA Best-fit line through two variables using PCA.
%
%   pp = POLYFIT1PCA(x,y) fits y = pp(1)*x + pp(2) as the first principal
% component of the centered data, which minimizes the orthogonal distance
% to the line instead of the vertical one.
%
%   pp = POLYFIT1PCA(x,y,1) first divides each variable by its standard
% deviation, so both contribute equally to the fit.
%
% Inputs:
%   x                - vector of x values
%   y                - vector of y values (same length as x)
%   varNormalizeFlag - (optional) 1 to normalize by the standard deviations
%                      (default: no normalization)
%
% Outputs:
%   pp - [slope intercept] of the fitted line
%
% Toolbox Dependencies: Statistics and Machine Learning Toolbox (pca)
%
% See also POLYFIT, PCA.

my = mean(y);
y  = y(:)'-my;
mx = mean(x);
x  = x(:)'-mx;
if nargin > 2 && ~isempty(varNormalizeFlag) && varNormalizeFlag == 1
    vx = std(x);
    vy = std(y);
else
    vx = 1;
    vy = 1;
end
[~,ccc,~] = pca([x/vx; y/vy],'Centered',false);
ccc = ccc(:,1);
pp(1) = ccc(2)*vy/(ccc(1)*vx);
pp(2) = my-mx*pp(1);

end

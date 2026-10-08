function [a,b] = getFigStruct(N)
%GETFIGSTRUCT Layout to arrange N plots on a 16:9 screen.
%
%   Finds the integer layout a x b with a*b >= N whose ratio is closest to
% 16:9, to place N graphs in one figure.
%
% Inputs:
%   N - number of graphs
%
% Outputs:
%   a - larger dimension of the layout (a*b >= N)
%   b - smaller dimension of the layout
%
% Toolbox Dependencies: None
%
% See also SUBPLOTSIZE, OPTIMIZEDSUBPLOT.

%2x1
%2x2
%3x2
%4x2
%4x3
%5x3
%

a = 1;
b = 1;

%while (a*b)<N
%   if (((a+1)/b-16/9)^2 > (a/(b+1)-16/9)^2 )
%       b=b+1;
%   else
%       a=a+1;
%   end
%end

r = 16/9;
%Get real numbers with exact ratio r, and exact product N
a0 = sqrt(N*r);
b0 = sqrt(N/r);

%Now, find the closest integer approximation
%There are three candidates: round a0 up, and b0 down, the opposite, and
%round both of them up. (rounding both down gives less than N as product).
if ceil(a0)*floor(b0) >= N
    if ceil(b0)*floor(a0) >= N
        %Both are options, choose the one with best ratio
        if (ceil(a0)/(r*floor(b0))-1)^2 < (floor(a0)/(r*ceil(b0))-1)^2
            a = ceil(a0);
            b = floor(b0);
        else
            a = floor(a0);
            b = ceil(b0);
        end
    else
        %Only 1 is option, choose it
        a = ceil(a0);
        b = floor(b0);
    end
else
    if ceil(b0)*floor(a0) >= N
        %Only 2 is option, choose it
        a = floor(a0);
        b = ceil(b0);
    else
        %Neither is option, go with ceil ceil
        a = ceil(a0);
        b = ceil(b0);
    end
end


end


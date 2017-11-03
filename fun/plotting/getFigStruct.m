function [a,b] = getFigStruct(N)
%UNTITLED Calculate best subfigure divide (a x b) for showing N graphs
%When you want to plot N graphs in a single figure, you first have to
%decide how the plots will be arranged in rows & columns. This function
%determines the optimal number of rows and columns for a 16:9 monitor
%resolution ratio.

%2x1
%2x2
%3x2
%4x2
%4x3
%5x3
%

a=1;
b=1;

%while (a*b)<N
%   if (((a+1)/b-16/9)^2 > (a/(b+1)-16/9)^2 )
%       b=b+1;
%   else
%       a=a+1;
%   end
%end

r=16/9;
%Get real numbers with exact ratio r, and exact product N
a0=sqrt(N*r);
b0=sqrt(N/r);

%Now, find the closest integer approximation
%There are three candidates: round a0 up, and b0 down, the opposite, and
%round both of them up. (rounding both down gives less than N as product).
if ceil(a0)*floor(b0)>=N
    if ceil(b0)*floor(a0)>=N
        %Both are options, choose the one with best ratio
        if (ceil(a0)/(r*floor(b0))-1)^2 < (floor(a0)/(r*ceil(b0))-1)^2
            a=ceil(a0);
            b=floor(b0);
        else
            a=floor(a0);
            b=ceil(b0);
        end
    else
        %Only 1 is option, choose it
        a=ceil(a0);
        b=floor(b0);
    end
else
    if ceil(b0)*floor(a0)>=N
        %Only 2 is option, choose it
        a=floor(a0);
        b=ceil(b0);
    else
        %Neither is option, go with ceil ceil
        a=ceil(a0);
        b=ceil(b0);
    end
end


end


function [xnew, xnewstd]=binData(x,binwidth)

if ~isempty(x)
    if binwidth==1
        xnew=x;
        xnewstd=zeros(size(x,1),size(x,2));
    elseif binwidth>size(x,1)
        ME=MException('binData:InvalidInput','binwidth is larger than x.');
        throw(ME);
    else
        bstart=1:size(x,1)-(binwidth-1);
        bend=bstart+binwidth-1;
        if any(bend>size(x,1))
            bend(bend>size(x,1))=size(x,1);
            warning('The end elements of binned data may not be averages of binwidth elements')
        end
        
        for i=1:length(bstart)
            t1 = bstart(i);
            t2 = bend(i);
            if t2==t1; %would this ever happen?
                xnew(i,:)=NaN*zeros(1,size(x,2));
                xnewstd(i,:)=NaN*zeros(1,size(x,2));
                %xnew(l,:)=x(t1,:);
                %xnewstd(l,:)=zeros(1,size(x,2));
            else
                xnew(i,:) = nanmean(x(t1:t2,:));
                xnewstd(i,:) = nanstd(x(t1:t2,:));
            end
        end
    end
else
    xnew=[];
    xnewstd=[];
end
%BINDATA Compute a running average and standard deviation of columns.
%
%   Averages binwidth-element windows of the columns in x and returns
% both the average and the standard deviation. Returned arrays have
% N - (binwidth - 1) rows, where N = size(x, 1).
%
% Inputs:
%   x        - Numeric matrix (rows × columns) or column vector
%   binwidth - Integer window width; must be ≤ size(x, 1)
%
% Outputs:
%   xnew    - Running-average matrix, same number of columns as x
%   xnewstd - Running standard deviation, same size as xnew
%
% Toolbox Dependencies: None
%
% See also BIN_DATAV1, SMOOTHEDMAX.

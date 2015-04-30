function [xnew, xnewstd]=binData(x,binwidth)
%BINDATA computes a running average
%
%   [xnew,xnewstd]=binData(x,binwidth) averages binwidth elements of the
%   columns in x and returns the average (xnew) and standard deviations (xnewstd).
%   The returned variables have columns that are length N-(binwidth-1) where N
%   is the number of elements in a row of x.
% 
%writen by GTO April 14th 2009

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

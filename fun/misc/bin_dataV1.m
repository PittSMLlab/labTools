function [xnew, xnewstd]=bin_dataV1(x,binwidth)
% writen based on bin_data
% function does running average. xnew averages rows of x
% binwidth indicates the duration of each time bin
%writen by GTO April 14th 2009

if size(x,1)>=binwidth
    if binwidth==1
        xnew=x;
        xnewstd=zeros(size(x,1),size(x,2));
    else
        bstart=[1:size(x,1)-(binwidth-1)]; %First value to be considered, 
        bend=[bstart+binwidth-1]; %Last value to be considered in the window for each element
        bend((bend>size(x,1)))=size(x,1); %This should do nothing. Changed to logical indexing 9/16/16. Pablo

        for  l=1:length(bstart)
            t1 = bstart(l);
            t2 = bend(l);
            if t2==t1;
                xnew(l,:)=NaN*zeros(1,size(x,2));
                xnewstd(l,:)=NaN*zeros(1,size(x,2));
                
                %xnew(l,:)=x(t1,:);
                %xnewstd(l,:)=zeros(1,size(x,2));             

            else
                xnew(l,:) = nanmean(x(t1:t2,:));
                xnewstd(l,:) = nanstd(x(t1:t2,:));
            end
        end
    end
else %Averaging how ever many strides we have even if it is very few
    warning(['Running average could not use the provided binwidth (' num2str(binwidth) ') because of too little strides (' num2str(size(x,1)) '). Using available strides only.'])
    xnew=nanmean(x);
    xnewstd=nanstd(x);
end

%Alt function:
%Computes running average along the first dimension of x, but doesn't deal
%with NaNs
%if size(x,1)>=binwidth %We can do it!
%   N=binwidth;
%   xnew=conv2(x,ones(N,1)/N,'valid');
%   xnewstd=conv2(x.^2,ones(N,1)/N,'valid') -xnew.^2;
%end

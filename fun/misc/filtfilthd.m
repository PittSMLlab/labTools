function [filteredData] = filtfilthd(filterObj,data,method)

%Filters data along dim=1 with filterObj first forwards, and then
%backwards.
%It is an implementation of filtfilt that works with filter objects from
%the DSP toolbox.
%Uses 'reflect' method for dealing with borders.

M=size(data,1);

if nargin<3
    method='reflect'; %Default
end
    switch method
        case 'reflect'
            pre=[data(end:-1:1,:)];
            post=[data(end:-1:1,:)];
        otherwise         
            pre=[];
            post=[];
    end
filteredData=filter(filterObj,[pre;data;post]);
filteredData=filter(filterObj,filteredData(end:-1:1,:));
filteredData=filteredData(end:-1:1,:);
filteredData=filteredData([size(pre,1)+1:size(pre,1)+M],:);

end


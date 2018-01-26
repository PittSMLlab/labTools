function [signals] = clipSignals(signals,percentile)
%Clips the top and bottom percentile of signals. Acts along columns
for i=1:size(signals,2)
    lims=prctile(signals(:,i),[percentile,100-percentile]);
    signals(signals(:,i)<lims(1),i)=lims(1);
    signals(signals(:,i)>lims(2),i)=lims(2);
end


end


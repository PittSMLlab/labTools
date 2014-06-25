function [filteredData] = idealLPF(data,fcut)
%Implements an idealLPF with zero lag
%fcut is in normalized freq, needs to be in [0,.5]

[Fdata,fvector] = DiscreteTimeFourierTransform(data,1);
Fdata=Fdata.*repmat((abs(fvector)<=fcut),1,size(Fdata,2));

filteredData=ifft(ifftshift(Fdata,1));


end


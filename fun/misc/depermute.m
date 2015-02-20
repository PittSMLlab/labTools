function [B] = depermute(A,order)
%DEPERMUTE is the inverse function of permute, given the order parameter,
%so that if A=permute(C,order) [Matlab embedded function], and B=depermute(A,order), then B=C.

newOrder(order)=order;
B=permute(A,newOrder);


end


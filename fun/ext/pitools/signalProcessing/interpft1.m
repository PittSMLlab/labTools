function y = interpft1(x,N,dim)
%INTERPFT1 Fourier interpolation with mirrored extension.
%
%   y = INTERPFT1(x,N,dim) replaces INTERPFT: the signal is first extended
% with its mirror image, so the interpolation is circularly continuous,
% interpolated to 2*N points and cut to the first N points.
%
% Inputs:
%   x   - array to interpolate
%   N   - number of points of the result along dim
%   dim - (optional) dimension to interpolate along (default: 1)
%
% Outputs:
%   y - interpolated array, N points along dim
%
% Toolbox Dependencies: None
%
% See also INTERPFT, DEPERMUTE.

if nargin < 3
    dim = 1;
end

%% To work for all dimensions
% %Generate a string to properly ask for extension
% str=[];
% M=size(x);
% for i=1:length(M)
%     if i~=dim
%     str=[str,num2str(size(x,i)),','];
%     else
%         str=[str,num2str(2*size(x,i)),',']
%     end
%     str(end)=';';
% end
%
% %Initialize extended version
% eval(['x2=zeros(', str, ');']);
%
% %Fill x2 with copies of x
%
%
% %Do the interpolation
%
% %Get the relevant part of the interpolation

%% To work with only dim=1

x = permute(x,[dim 1:dim-1 dim+1:ndims(x)]);

x2 = [x;flipud(x)];
y2 = interpft(x2,2*N,1);
%y=y2(1:N,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:,:);
y = y2;
y(N+1:end,:) = [];

y = depermute(y,[dim 1:dim-1 dim+1:ndims(x)]);

end

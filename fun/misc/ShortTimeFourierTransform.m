function [STFT,F,T] = ShortTimeFourierTransform(data,Nwindow,Noverlap,Nfft,dim,fs,window)
%ShortTimeFourierTransform returns the fourier transform of the signal
%applied in short time windows. This is useful to make time-freq analysis
%of non-stationary signals
%Data input needs to be a 2-D array (vectors accepted). The Fourier
%transform works along the first non-singleton dimension by default.
%All other inputs are optional. Omit with [].
%If the data length (size(data,dim)) is not a multiple of half the window size
%(Nwindow/2), the signal is padded with 0's at the end.

Nfft=[]; %Ignoring Nfft input. All ffts are computed with the length equal to Nwindow. This needs to be fixed to support different Nfft. 

if nargin<6 || isempty(fs)
    fs=1;
end
if nargin<5 || isempty(dim)
    if numel(data)==length(data) %is vector
        if size(data,1)==1
            dim=2;
        else
            dim=1;
        end
    else
        dim=1;
    end
end
if nargin<2 || isempty(Nwindow)
    Nwindow=2*round(size(data,dim)/16);
end
if nargin<4 || isempty(Nfft)
    Nfft=Nwindow;
end
if nargin<3 || isempty(Noverlap)
    Noverlap=round(Nwindow/2);
end
if nargin<7 || isempty(window)
    window=ones(Nwindow,1);
end

M=ndims(data);
data=permute(data,[dim 1:dim-1 dim+1:M]); %Permute dimensions to get the relevant dimension first
Q=Nwindow-Noverlap;
P=ceil(size(data,1)/Q);
data(end+1:P*Q,:)=0; %Padding zeros
STFT=zeros(Nfft,P,size(data,2));
for j=1:size(data,2) %Iterate through al data columns present
    for i=1:P %Iterate through time windows of interest
        windowData=data((i-1)*Q+1:i*Q,j).*window;
        [Fdata,fvector] = DiscreteTimeFourierTransform(windowData,fs); 
        STFT(:,i,j)=Fdata;
    end
end
F=fvector;
T=([0:P-1]*Q + Nwindow/2)/fs;

end


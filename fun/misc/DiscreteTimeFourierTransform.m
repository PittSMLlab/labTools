function [Fdata,fvector] = DiscreteTimeFourierTransform(data,fs)
%DiscreteTimeFourierTransform Implements the DTFT through the fft. Returns
%both the spectral content (fft) and the points at which the spectrum is
%sampled.

Fdata=fft(data);
N=size(data,1);
if mod(N,2)==0 %Even case:
    fvector=fs/N * [-N/2:N/2-1]';
else %Odd case: we don't get the sample that would correspond to +-fs/2. We can inferr it?
    fvector=fs/N * [(-N+1)/2:(N-1)/2]';
end

Fdata=fftshift(Fdata,1);
%fvector=ifftshift(fvector);


end


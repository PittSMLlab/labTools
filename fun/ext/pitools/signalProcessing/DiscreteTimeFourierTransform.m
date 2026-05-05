function [Fdata,fvector] = DiscreteTimeFourierTransform(data,fs)
%DISCRETETIMEFOURIERTRANSFORM Compute DTFT via FFT with frequency vector.
%
%   Computes the discrete-time Fourier transform of data using MATLAB's
% fft, then constructs the corresponding centered frequency vector in
% units of fs. The output spectrum is shifted so that zero frequency
% is at the center (fftshift convention).
%
% Inputs:
%   data - (N x C) double array; transform is applied along rows (dim 1)
%   fs   - sampling frequency used to scale the frequency vector
%
% Outputs:
%   Fdata   - centered complex spectrum, same size as data
%   fvector - (N x 1) frequency vector in the same units as fs,
%             ranging from -fs/2 to just below fs/2
%
% Toolbox Dependencies: None
%
% See also IDEALHPF.

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


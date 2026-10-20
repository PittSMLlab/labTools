function [newSignal, filter] = whitenEMG(signal,fs)
%WHITENEMG Estimate whitening filters for EMG channels.
%
%   For each channel, fits a 20th-order autoregressive model with the
% Yule-Walker equations (ARestim) and returns the magnitude of the
% frequency response of the model coefficients as the whitening filter.
%
% NOTE: newSignal is declared as an output but never assigned.
%
% Inputs:
%   signal - samples x channels
%   fs     - sampling frequency (Hz)
%
% Outputs:
%   newSignal - declared output, not assigned
%   filter    - samples x channels magnitude response of the AR model
%
% Toolbox Dependencies: None
%
% See also ARESTIM.

[N,M] = size(signal);
filter = zeros(N,M);
%[fft1,ff]=DiscreteTimeFourierTransform(signal,fs);

%Step 2: Estimate whitening filters
for ii = 1:M
    %Using some toolbox:
    %mfb=ar(signal(:,i),6,'Ts',1/fs,'TimeUnit', ...
    %    'seconds'); %6th-order AR model estimation, ...
    %    as recommended in Merletti and Parker.
    %[PS,~]=spectrum(mfb,2*pi*ff); %Evaluating PSD at a given frequency
    %vector
    %filter(:,i)=sqrt(PS(ff==0))./sqrt(squeeze(PS)); %Gain 1 at DC

    %Solving Yule-Walker directly: (more efficient)
    [a,sigma] = ARestim(signal(:,ii),20);
    filter(:,ii) = abs(fft(a,N));
    filter(:,ii) = filter(:,ii)/min(filter(:,ii));
end

%Step 3: Whiten!
newSignal = ifft(fft(signal).*filter,'symmetric');

%Remove border effects
newSignal(1:3,:) = 0;
newSignal(end-2:end,:) = 0;



end


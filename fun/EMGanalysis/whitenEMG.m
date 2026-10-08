function [newSignal, filter] = whitenEMG(signal,fs)

%Step 1: initialize
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


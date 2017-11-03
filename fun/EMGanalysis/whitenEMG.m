function [newSignal, filter] = whitenEMG(signal,fs)

%Step 1: initialize
[N,M]=size(signal);
filter=zeros(N,M);
%[fft1,ff]=DiscreteTimeFourierTransform(signal,fs);

%Step 2: Estimate whitening filters
for i=1:M
    %Using some toolbox:
    %mfb=ar(signal(:,i),6,'Ts',1/fs,'TimeUnit','seconds'); %6th-order AR model estimation, as recommended in Merletti and Parker.
    %[PS,~]=spectrum(mfb,2*pi*ff); %Evaluating PSD at a given frequency vector
    %filter(:,i)=sqrt(PS(ff==0))./sqrt(squeeze(PS)); %Gain 1 at DC
    
    %Solving Yule-Walker directly: (more efficient)
    [a,sigma] = ARestim(signal(:,i),20);
    filter(:,i)=abs(fft(a,N));
    filter(:,i)=filter(:,i)/min(filter(:,i));
end

%Step 3: Whiten!
newSignal=ifft(fft(signal).*filter,'symmetric');

%Remove border effects
newSignal(1:3,:)=0;
newSignal(end-2:end,:)=0;



end


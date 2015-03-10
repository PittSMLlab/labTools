function [ amplitude,procList ] = amp_estim(signal,fs,mod_ord,cutoff)
%Estimation of amplitude of a given EMG signal (envelope detection).
%Following guidelines in Merletti & Parker's book Elctromyography (Section
%6.4, First Edition, p. 139).

N=size(signal,1);

%% Stage 1: whitening
%[emg2, filter] = whitenEMG(signal,fs);
%procList{1}=filter; %Whitening filter
%No whitening:
emg2=signal;
procList{1}=[];

%% Stage 2: rectification
emg3=abs(emg2).^mod_ord;
procList{2}=['Rectification, order=' num2str(mod_ord)];
%Alternative: instead of rectification and re-linearization, we could just
%take the hilbert transform:
%mod_ord=1;
%procList{2}='hilbert';
%emg3=abs(hilbert(egm2));

%% Stage 4: smoothing
%lowPassFilter=design(fdesign.lowpass('Nb,Na,Fp,Fst',10,5,2*cutoff/fs,2*1.1*cutoff/fs));
%aux=lowPassFilter.convert('df2');
%emg4=filtfilt(aux.Numerator,aux.Denominator,emg3);
%emg4=lowpassfiltering(emg3, cutoff, 5, fs);
Wn=2*cutoff/fs;
procList{3}=fdesign.lowpass('Fp,Fst,Ap,Ast',Wn,2*Wn,3,10);
lowPassFilter=design(procList{3},'butter');
emg4=filtfilthd(lowPassFilter,emg3);

%Alternative smoothing: convolving with a moving window (as suggested in
%Merletti & Parker)

% M=round((72/(8 *fs^2)* median(emg3.^2)/median(diff(diff(emg3)).^2))^.2);
% if mod(M,2)==0
%     M=M+1; %making sure it is an odd number
% end
% procList{3}= ['Moving Average, rect. window, size=' num2str(M)];
% window=ones(M,1)/M;
% %window=hanning(M);
% fwin=fft(circshift(window,[-round(M/2),0]),N);
% emg4=zeros(size(signal));
% for i=1:size(signal,2)
%     emg4(:,4)=ifft(fft(emg3).*fwin,'symmetric');
% end

%% Stage 5: relinearization
amplitude=abs(emg4.^(1/mod_ord)); %This effectively does nothing if mod_ord=1, unless there are negative samples;
procList{2}=['Relinearization, order=' num2str(mod_ord)];

end


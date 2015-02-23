function [ amplitude ] = amp_estim(signal,fs,mod_ord,cutoff)
%Estimation of amplitude of a given EMG signal (envelope detection).
%Following guidelines in Merletti & Parker's book Elctromyography (Section
%6.4, First Edition, p. 139).



%% Stage 1: whitening
emg2=signal; %ToDo

%% Stage 2: rectification
emg3=abs(emg2).^mod_ord;

%% Stage 4: smoothing
%lowPassFilter=design(fdesign.lowpass('Nb,Na,Fp,Fst',10,5,2*cutoff/fs,2*1.1*cutoff/fs));
%aux=lowPassFilter.convert('df2');
%emg4=filtfilt(aux.Numerator,aux.Denominator,emg3);
%emg4=lowpassfiltering(emg3, cutoff, 5, fs);
Wn=2*cutoff/fs;
lowPassFilter=design(fdesign.lowpass('Fp,Fst,Ap,Ast',Wn,2*Wn,3,10),'butter');
emg4=filtfilthd(lowPassFilter,emg3);

%Alternative smoothing: convolving with a moving window (as suggested in
%Merletti & Parker)
M=round((72/(8 *fs^2)* median(emg3.^2)/median(diff(diff(emg3)).^2))^.2);
if mod(M,2)==0
    M=M+1; %making sure it is an odd number
end
window=ones(M,1)/M;
%window=hanning(M);
fwin=fft(circshift(window,[-round(M/2),0]),N);
emg4=ifft(fft(emg3).*fwin,'symmetric');

%% Stage 5: relinearization
amplitude=abs(emg4.^(1/mod_ord));


%% Alt process: hilbert transform
%emg3=abs(hilbert(signal));
%amplitude=lowpassfiltering(emg3, cutoff, 5, fs);
end


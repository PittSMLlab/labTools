function [ amplitude ] = amp_estim(signal,fs,mod_ord,cutoff)
%EMG AMPLITUDE ESTIMATION Summary of this function goes here
%   Detailed explanation goes here


%% Stage 1: whitening
emg2=signal; %ToDo

%% Stage 2: rectification
emg3=abs(emg2).^mod_ord;

%% Stage 4: estimation (low-pass filtering)
%lowPassFilter=design(fdesign.lowpass('Nb,Na,Fp,Fst',10,5,2*cutoff/fs,2*1.1*cutoff/fs));
%aux=lowPassFilter.convert('df2');
%emg4=filtfilt(aux.Numerator,aux.Denominator,emg3);
%emg4=lowpassfiltering(emg3, cutoff, 5, fs);
Wn=2*cutoff/fs;
lowPassFilter=design(fdesign.lowpass('Fp,Fst,Ap,Ast',Wn,2*Wn,3,10),'butter');
emg4=filtfilthd(lowPassFilter,emg3);

%% Stage 5: relinearization
amplitude=abs(emg4.^(1/mod_ord));


%% Alt process: hilbert transform
%emg3=abs(hilbert(signal));
%amplitude=lowpassfiltering(emg3, cutoff, 5, fs);
end


function [ amplitude,procList ] = amp_estim(signal,fs,mod_ord,cutoff)
%AMP_ESTIM Amplitude estimate (envelope) of an EMG signal.
%
%   [amplitude,procList] = AMP_ESTIM(signal,fs,mod_ord,cutoff) rectifies the
% signal (absolute value raised to mod_ord), smooths it with a zero-phase
% Butterworth lowpass filter (filtfilthd_short with reflected boundaries)
% and relinearizes it, following the guidelines in Merletti & Parker's book
% Electromyography (Section 6.4, First Edition, p. 139). No whitening is
% applied.
%
% Inputs:
%   signal  - samples x channels EMG signal
%   fs      - sampling frequency (Hz)
%   mod_ord - order of the rectification (1 is plain rectification)
%   cutoff  - cutoff frequency of the smoothing filter (Hz)
%
% Outputs:
%   amplitude - samples x channels amplitude estimate
%   procList  - cell array describing the processing stages (whitening,
%               rectification, the lowpass filter design)
%
% Toolbox Dependencies: Signal Processing Toolbox (fdesign.lowpass, design)
%
% See also FILTFILTHD_SHORT, LOWPASSFILTERING.

N = size(signal,1);

%% Stage 1: whitening
%[emg2, filter] = whitenEMG(signal,fs);
%procList{1}=filter; %Whitening filter
%No whitening:
emg2 = signal;
procList{1} = [];

%% Stage 2: rectification
emg3 = abs(emg2).^mod_ord;
procList{2} = ['Rectification, order=' num2str(mod_ord)];
%Alternative: instead of rectification and re-linearization, we could just
%take the hilbert transform:
%mod_ord=1;
%procList{2}='hilbert';
%emg3=abs(hilbert(egm2));

%% Stage 4: smoothing
%lowPassFilter=design(fdesign.lowpass('Nb,Na,Fp,Fst',10,5,2*cutoff/fs, ...
%    2*1.1*cutoff/fs));
%aux=lowPassFilter.convert('df2');
%emg4=filtfilt(aux.Numerator,aux.Denominator,emg3);
%emg4=lowpassfiltering(emg3, cutoff, 5, fs);
Wn = 2*cutoff/fs;
procList{3} = fdesign.lowpass('Fp,Fst,Ap,Ast',Wn,2*Wn,3,10);
lowPassFilter = design(procList{3},'butter');
%1 sec of data for reflective boundaries
emg4          = filtfilthd_short(lowPassFilter,emg3,'reflect',fs);

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
%This effectively does nothing if mod_ord=1, unless there are negative
%samples;
amplitude = abs(emg4.^(1/mod_ord));
procList{2} = ['Relinearization, order=' num2str(mod_ord)];

end


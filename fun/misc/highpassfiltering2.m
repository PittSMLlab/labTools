function data1 = highpassfiltering2(datafile, cutoff, complexity, fs)

%lowpassfilter function
%SMM 02/2004

%pass the 'lowpassfilter' function:  1) a data array for filtering,
                                    %2) the freqency you want removed, and
                                    %3) the sampling frequency
%'lowpassfilter' function returns the data array that has been filtered with a
%lowpass Butterworth filter, with the specified complexity and cutoff frequency


dataAux=[datafile;datafile(end:-1:1,:)]; %Mirroring to avoid edge effects

[b,a]=butter(complexity, (cutoff/(.5*fs)),'high');   %get highpass filter vectors
h = filter(b,a,[1;zeros(size(dataAux,1)-1,1)]); %Get impulse response

data2 = fft(dataAux) .* abs(fft(h*ones(1,size(datafile,2)))).^2;

data=ifft(data2);
data1=data(1:size(datafile,1),:);


%Filter characteristics
% figure
% plot(abs(fft(h)))
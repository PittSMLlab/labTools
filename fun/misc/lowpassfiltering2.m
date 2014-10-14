function data1 = lowpassfiltering2(datafile, cutoff, complexity, fs)

%lowpassfilter function, making sure that there is continuity on borders
%(mirror/circular continuity)
%PI 07/2013

%pass the 'lowpassfilter' function:  1) a data array for filtering,
                                    %2) the freqency you want removed, and
                                    %3) the sampling frequency
%'lowpassfilter' function returns the data array that has been filtered with a
%lowpass Butterworth filter, with the specified complexity and cutoff frequency

dataAux=[datafile;datafile(end:-1:1,:)];

[b,a]=butter(complexity, (cutoff/(.5*fs)));   %get lowpass filter vectors
h = filter(b,a,[1;zeros(size(dataAux,1)-1,1)]);

data2 = fft(dataAux) .* abs(fft(h*ones(1,size(datafile,2)))).^2;

data=ifft(data2);
data1=data(1:size(datafile,1),:);


%Filter characteristics
% figure
% plot(abs(fft(h)))


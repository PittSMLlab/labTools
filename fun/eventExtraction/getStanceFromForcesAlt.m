 function [stance] = getStanceFromForcesAlt(Fz, lowThreshold, fsample)
%Get stance from acceleration
forces1=medfilt1(Fz,round(.0025*fsample)); %Median filter with 2.5ms window, to get rid of some quantization noise
fcut=25;
forces=lowpassfiltering2(forces1,fcut,2,fsample); %Lowpass filter, to get rid of high-freq noise and smooth the signal. 25Hz seems like a reasonable bandwidth that preserves the transitions properly
forceSign=sign(mean(Fz));
forces=forces*forceSign; %Forcing forces to be positive on average (if not, it depends on how the z-axis is defined)

bodyWeight=2 * mean(abs(forces-mean(forces))); %Estimate of bodyWeight to do thresholding

%highThreshold=prctile(abs(forceDiff),80); % Choosing threshold such that only 20% of samples are above it
forceDiff=diff(forces)*fsample;
lowThreshold=bodyWeight;
loading=forceDiff>3*bodyWeight;
unloading=forceDiff<-4*bodyWeight;
unstance=abs(forceDiff)<lowThreshold; %Threshold is in N/s

%Expand loading zone rightwards and unloading leftwards until they reach each other:
counter=0;
while any(diff(loading)==-1 & ~unloading(1:end-1))
    %counter=counter+1
    %Inward expansion:
    loading(2:end)=loading(2:end)|(loading(1:end-1) & ~unloading(1:end-1));
    unloading(1:end-1)=unloading(1:end-1)|(unloading(2:end) & ~loading(2:end));
end
counter=0;
while any(diff(loading)==1 & ~unstance(1:end-1)) ||  any(diff(unloading)==-1 & ~unstance(2:end))
    %counter=counter+1
    %Outward expansion:
    loading(1:end-1) = loading(1:end-1) | (loading(2:end) & ~unstance(1:end-1));
    unloading(2:end) = unloading(2:end) | (unloading(1:end-1) & ~unstance(2:end));
end
stance=loading | unloading;

%% Step n-1: shorten the stance phases to compensate for the low resolution discrimination introduced by the lowpassfiltering
N=round(.5*fsample/fcut);
stance = conv(double(stance), ones(N,1),'same')>N-1;

%% STEP N: Eliminate stance & swing phases shorter than 100 ms
stance = deleteShortPhases(stance,fsample,0.1); %Used to be 200ms, but that is too long for stroke subjects



%% Plot some stuff to check
% figure
% hold on
% plot([1:length(forces)]/fsample,forces)
% plot((.5+[1:length(forces)-1])/fsample,forceDiff)
% plot((.5+[1:length(forces)-1])/fsample,stance*max(forces))
% plot([1,length(forces)]/fsample,lowThreshold*[1,1],'k--')
% plot([1:length(forces)]/fsample,Fz*forceSign)
% xlabel('Time (ms)')
% legend('Filtered forces','Force derivative','Detected Stance','Low threshold','Raw forces')
% hold off

end


 function [stance] = getStanceFromForces(Fz, threshold, fsample)
%Get stance from acceleration
forces1=medfilt1(Fz,round(.01*fsample)); %Median filter with 10ms window, to get rid of some quantization noise
forces=lowpassfiltering2(forces1,25,5,fsample); %Lowpass filter, to get rid of high-freq noise and smooth the signal. 25Hz seems like a reasonable bandwidth that preserves the transitions properly
forceSign=sign(mean(Fz));
forces=forces*forceSign; %Forcing forces to be positive on average (if not, it depends on how the z-axis is defined)

stance=forces>threshold;


%% STEP N: Eliminate stance & swing phases shorter than 100 ms
stance = deleteShortPhases(stance,fsample,0.1); %Used to be 200 ms, but that is too long for stroke subjects, who spend relatively short single stance times on their paretic leg.

%% Plot some stuff to check
% figure
% hold on
% plot([1:length(forces)]/fsample,forces)
% plot(([1:length(forces)])/fsample,stance*max(forces))
% plot([1,length(forces)]/fsample,threshold*[1,1],'k--')
% plot([1:length(forces)]/fsample,Fz*forceSign)
% xlabel('Time (ms)')
% legend('Filtered forces','Detected Stance','threshold','Raw forces')
% hold off

end


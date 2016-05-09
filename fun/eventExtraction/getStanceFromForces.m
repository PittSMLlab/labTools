 function [stance] = getStanceFromForces(Fz, threshold, fsample)
%  %% If Fz is sampled >2000Hz, downsample to somewhere in the [1000-2000)Hz
%  %range (for computational cost reduction, no other reason).
%  
%  M=1;
%  if fsample>2000
%      M=floor(fsample/1000);
%      Fz=Fz(1:M:end);
%      fsample=fsample/M;
%  end
 
 
%% Get stance from forces
N=round(.01*fsample); %Median filter with 10ms window, to get rid of some quantization noise
if mod(N,2)==0
    N=N+1;
end
N1=round(.005*fsample); %Median filter with 5ms window, to get rid of some quantization noise
if mod(N1,2)==0
    N1=N1+1;
end
forces=medfilt1(Fz,N1);
forces=medfilt1(forces,N); 
%forces=lowpassfiltering2(forces,25,5,fsample); %Lowpass filter, to get rid of high-freq noise and smooth the signal. 25Hz seems like a reasonable bandwidth that preserves the transitions properly
forceSign=sign(nanmean(Fz));
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


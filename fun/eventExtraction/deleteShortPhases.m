function [stance] = deleteShortPhases(stance,fsample,minDuration)

N=ceil(minDuration*fsample);
stance1=stance;
%%Dilate stance, and erode
%dilStance=conv(double(stance),ones(N,1),'same')>0;
%eroStance=conv(double(dilStance),ones(N,1),'same')>=N;

%Dilate swing, and erode
%dilSwing=conv(double(~eroStance),ones(N,1),'same')>0;
%eroSwing=conv(double(dilSwing),ones(N,1),'same')>=N;

%stance=~eroSwing;


%Idea: first get rid of isolated stance/swing samples, then get rid of
%groups of two, so on and so forth until we got rid of all groups of N-1 or
%smaller size

%Simple implementation:
% Commented out by Pablo on 25/II/2015 because of more efficient
% implementation
%tic
if ~isempty(stance)
   for i=1:N %Slowly dilating/eroding stance phases, until there is no possiblity for
       stance=conv(double(stance),ones(2*i+1,1),'same')>i; %At least half+1 of the samples in the window are stance
   end
end
% toc
% tic
% stance2=gpuArray(stance);
% if ~isempty(stance)
%    for i=1:N %Slowly dilating/eroding stance phases, until there is no possiblity for
%        aux=gpuArray(ones(2*i+1,1));
%        stance2=conv(double(stance2),aux,'same')>i; %At least half+1 of the samples in the window are stance
%    end
% end
% stance2=gather(stance);
% toc


%Equivalent efficient implementation: (it is actually NOT efficient, for
%some reason the conv is much faster, I guess it has to do with the fact
%that one of the vectors is much smaller than the other)
% stance2=stance1;
% if ~isempty(stance2)
%     for i=1:N
%         
%         %stance2=ifft(fft(double(stance2)).*(fft(ones(2*i+1,1),length(stance))),'symmetric')>(i+.5); %FIXME: need to consider border-effects
%         aaa=double(stance2);
%         aux=effconvn(aaa,ones(2*i+1,1),'same');
%         stance2=real(aux)>(i+.5); %The +.5 is needed to cover for rounding errors that come from the fft-implemented convolution
%         
%     end
%         aaa=double(stance1);
%         aux=effconvn(aaa,ones(2*N+1,1),'same');
%         stance3=real(aux)>(i+.5); %The +.5 is needed to cover for rounding errors that come from the fft-implemented convolution
% end
%If we wanted to compare the simple and efficient implementations:
% if any(stance~=stance2)
%     ME=MException('deleteShortPhases:efficientImplementation','Results from the classical and the efficient implementation do not match');
%     throw(ME);
% end

end


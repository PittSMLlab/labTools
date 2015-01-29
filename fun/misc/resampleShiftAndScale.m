function newSignals = resampleShiftAndScale(signals,timeScaleFactor,lagInSamples,scaleGain)
%Function that does the same thing as matchSignals, but when the
%parameters are given/known


[M,N]=size(signals);

%% Resample: (not using 'resample' function because i'm interested in very
%small resampling rates, on the order of 1+-1e-6
if abs(timeScaleFactor-1)>.5/M %Only resampling if there is at least a half a sample shift during the full timecourse
    for i=1:N
        newSignals(:,i)=interp1(1:M,signals(:,i),timeScaleFactor*[1:floor(M/timeScaleFactor)],'linear')';
        newSignals(1,i)=signals(1,i); %For same reason interp1 returns NaN when evaluating at same position
    end
else
    newSignals=signals;
end

%% Time-shift
aux=round(lagInSamples); 
d=lagInSamples-aux;
%First shift an integer number of samples:
if lagInSamples<0
    newSignals=newSignals(abs(aux)+1:end,:); %Throw first samples
else
    newSignals=[zeros(abs(aux),N); newSignals]; %Pad zeros to add samples
end

%Then, correct for sub-sample interpolation.
% k=1000;
% F=fft([newSignals;zeros(k,size(newSignals,2))]);
% Fd=exp(1i*2*pi*[0:size(F,1)-1]/size(F,1)).^d;
% newSignals=ifft(bsxfun(@times,F,Fd'),'symmetric');
% newSignals=newSignals(1:end-k,:);


%% Scale:
newSignals=newSignals/scaleGain;

end


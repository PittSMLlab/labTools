function [signalStats] = rawEMGhealthCheck(rawExperimentData)

signalBW=[20,450];

for trial=1:length(rawExperimentData.data)
    if ~isempty(rawExperimentData.data{trial})
        %Computing noise structure on the raw signal:
        data=rawExperimentData.data{trial}.EMGData.Data;
        [Fdata,fVector]=DiscreteTimeFourierTransform(data,rawExperimentData.data{trial}.EMGData.sampFreq);

        Fdata=Fdata/size(Fdata,1);
        offset=Fdata(fVector==0,:); %Mean value of data
        HFdata=Fdata(abs(fVector)>signalBW(2),:); %Get high-frequency data, assuming it is all noise above this level.
        k=sum(abs(fVector)>signalBW(1))/size(HFdata,1);
        backNoise=sqrt(k*sum(abs(HFdata).^2,1)); %In volts!
        movement= sqrt(sum(abs(Fdata(abs(fVector)<signalBW(1) & abs(fVector)>0,:)).^2,1)); %In volts!
        s2=sum(abs(fVector)>=signalBW(1) & abs(fVector)<=signalBW(2));
        k2=s2/sum(abs(fVector)>signalBW(1))';
        signal=sqrt(sum(abs(Fdata((abs(fVector)>=signalBW(1) & abs(fVector)<=signalBW(2)),:)).^2,1)-k2.*backNoise.^2);%In volts!
        snr= 10*log10(signal.^2 ./ (backNoise.^2 + movement.^2)); %In dB
        
        
        signalStats{trial}.noiseLevelRMS=backNoise; % Background noise estimation on the full signal
        signalStats{trial}.lowFreqSignalRMS=movement; %Movement artifacts RMS values
        signalStats{trial}.signalRMS=signal; %Actual signal RMS value
        signalStats{trial}.offset=offset; %Offset
        signalStats{trial}.SNR=snr; %Signal to background noise ratio

        %If this is consistent, then:
        %a1=signalStats{trial}.noiseLevelRMS;
        %a2=signalStats{trial}.lowFreqSignalRMS;
        %a3=signalStats{trial}.signalRMS;
        %a4=signalStats{trial}.offset;
        %sqrt(a1.^2+a2.^2+a3.^2+a4.^2)
        %sqrt(sum(data.^2,1)/size(data,1))
        %dataRMS = sqrt(sum(data.^2,1)/size(data,1)) =sqrt(a1.^2+a2.^2+a3.^2+a4.^2);
        
        %Computing noise structure on the filtered signal (what we actually
        %want to know!)
        data=filterEMG(data,rawExperimentData.data{trial}.EMGData.sampFreq,signalBW);
        [Fdata,fVector]=DiscreteTimeFourierTransform(data,rawExperimentData.data{trial}.EMGData.sampFreq);
        Fdata=Fdata/size(Fdata,1);
        offset=Fdata(fVector==0,:); %Mean value of filtered data, should be 0 or very close to.
        k=sum(abs(fVector)>signalBW(1) & abs(fVector)<signalBW(2))/sum(abs(fVector)>signalBW(1));
        backNoise=sqrt(k*backNoise.^2); %New background noise estimation for the surviving frequency range
        movement= sqrt(sum(abs(Fdata(abs(fVector)<signalBW(1) & abs(fVector)>0,:)).^2,1)); %In volts!, because of the filtering should be very close to 0
        signal=sqrt(sum(abs(Fdata((abs(fVector)>=signalBW(1) & abs(fVector)<=signalBW(2)),:)).^2,1)-backNoise.^2);%In volts!
        ignorableSignal=sqrt(sum(abs(Fdata((abs(fVector)>=signalBW(2)),:)).^2,1)); %Should be very close to 0 because of filters.
        snr= 10*log10(signal.^2 ./ (backNoise.^2 )); %In dB
        
        signalStats{trial}.filteredNoiseLevelRMS=backNoise; % Background noise estimation on the full signal
        signalStats{trial}.filteredSignalRMS=signal; %Actual signal RMS value
        signalStats{trial}.filteredlowFreqSignalRMS=movement; %Movement artifacts RMS values
        signalStats{trial}.filteredOffset=offset; %Offset
        signalStats{trial}.filteredSNR=snr; %Signal to background noise ratio
        
        %It should still be true that:
%         a1=signalStats{trial}.filteredNoiseLevelRMS;
%         a2=signalStats{trial}.filteredlowFreqSignalRMS; %Movement artifacts RMS values
%         a3=signalStats{trial}.filteredSignalRMS;
%         a4=signalStats{trial}.filteredOffset;
%         a5=ignorableSignal;
%         decomposedSignalAmplitudeRMS=sqrt(a1.^2+a2.^2+a3.^2+a4.^2 +a5.^2);
%         actualSignalAmplitudeRMS=sqrt(sum(data.^2,1)/size(data,1));
        %dataRMS = actualSignalAmplitudeRMS =decomposedSignalAmplitudeRMS
    end
end





end


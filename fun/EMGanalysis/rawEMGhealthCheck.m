function [signalStats] = rawEMGhealthCheck(rawExperimentData)

%% Compute stats
signalBW=[50,450];

for trial=1:length(rawExperimentData.data)
    clear energy LFrms HFrms MFrms EMGrms SNR
    if ~isempty(rawExperimentData.data{trial})
        %Computing noise structure on the raw signal:
        auxTS=rawExperimentData.data{trial}.EMGData;
        data=auxTS.Data;
        offset=mean(data);
        data=demean(data);
        winTime=.128; %128 ms windows
        Nwin=round(winTime*rawExperimentData.data{trial}.EMGData.sampFreq);
        Noverlap=7*Nwin/8;
        Nfft=Nwin; %Warning: if this ratio changes, I'm not sure how energy calculations need to change when computed from FFT
        fs=rawExperimentData.data{trial}.EMGData.sampFreq;
        window=hann(Nwin);
        %window=ones(Nwin,1);
        for ch=1:size(data,2)
            [Pdata,fVector,tVector] = spectrogram(data(:,ch),window,Noverlap,Nfft,fs); 
            
            %See spectrogram:
%             figure
%             h(1)=subplot(5,5,[2:5 7:10 12:15 17:20]);
%             hold on
%             imagesc(tVector,fVector,sqrt(abs(Pdata.^2)));
%             view(2)
%             %set(h(1),'YTickLabel',{},'XTickLabel',{});
%             axis tight
%             hold off
%             h(2)=subplot(5,5,[1:5:16]);
%             hold on
%             aux=abs(fft(data(:,ch),Nfft));
%             plot(aux(1:length(fVector)),fVector);
%             hold off
%             h(3)=subplot(5,5,[22:25]);
%             hold on
%             plot([0:size(data,1)-1]/fs,data(:,ch));
%             hold off
%             linkaxes(h([1:2]),'y')
%             linkaxes(h([1,3]),'x')

            Pdata=sqrt(2)*Pdata/sqrt(Nfft); %Normalization of fft data so that Parseval's theorem holds. Reminder: Pdata contains only positive frequency components, and DC component was removed a priori.
            
            %Separate bands and compute energy in each for every
            %time-window
            U20data=Pdata(abs(fVector)<20,:);                       %Low-freq band: recommended filtering out
            U50data=Pdata(abs(fVector)<50 & abs(fVector)>=20,:);    %Mixed band: EMG lives here but so may artifacts
            U450data=Pdata(abs(fVector)<450 & abs(fVector)>=50,:);  %EMG band
            UInfdata=Pdata(abs(fVector)>=450,:);                    %High-freq range
            energy(1,:)=sum(abs(U20data).^2); 
            energy(2,:)=sum(abs(U50data).^2);  
            energy(3,:)=sum(abs(U450data).^2); 
            energy(4,:)=sum(abs(UInfdata).^2); 
            
            %Compute rms values and snr
            k=size(Pdata,1)/size(UInfdata,1); %Scaling term for the HF energy, assuming that HF noise is only part of some additive white (equally present in all freqs) gaussian noise.
            SNR(ch,:)=10*log10(energy(3,:)./(energy(1,:)+energy(4,:)));  %Estimating noise energy as two-times the LF artifacts energy (there is more energy not in the 0-20Hz band) plus HF estimation. Although both these signals will be filtered out, we have reason to believe that an equivalent amount of noise lies in the band of interest (EMG band). HF represents white noise (present in all bands) and the LF artifacts usually are not limited to the [0,20] range.
            avgSNR(ch)=10*log10(sum(energy(3,:))/sum(energy(1,:)+energy(4,:)));
            LFrms(ch,:)=sqrt(2*energy(1,:)/Nfft);                   %Movement artifacts estimation
            HFrms(ch,:)=sqrt(k*energy(4,:)/Nfft);                   %HF noise scaled to full-band (white) noise
            EMGrms(ch,:)=sqrt(energy(3,:)/Nfft);                    %EMG signal
            MFrms(ch,:)=sqrt(energy(2,:)/Nfft);                     %Mixed band (artifacts+EMG)
            
            %Check sanity:
            origEnergy=sum(data(:,ch).^2); %Original signal energy
            summedWindowAndBandEnergy=sum((LFrms(ch,:).^2)/2+(HFrms(ch,:).^2)/k +MFrms(ch,:).^2+EMGrms(ch,:).^2)*(Nwin-Noverlap); %Summing energy in all bands and all windows (scaled down to compensate for window overlap)
            windowFactor=sum(window.^2)/Nwin; %Because of windowing, the sum of all windows/bands is only a fraction of the original signal. If the window used were to be ones(Nwin,1) (effectively no window) then this factor would not be needed
            if abs(summedWindowAndBandEnergy/windowFactor - origEnergy)>.1*origEnergy; %Checking that both quantities above match to a certain precision (10%) (because of border effects, and that the window Factor is just an approximation)
                warning(['Total signal energy and estimated band/window decomposition energies do not match for channel ' num2str(ch) ' in trial ' num2str(trial)])
            end
            
        end
        
        %Save computations into a structure
        t0=auxTS.Time(1)+winTime/2;
        Ts=winTime*(Nwin-Noverlap)/Nwin;
        signalStats{trial}.noiseLevelRMS=labTimeSeries(HFrms',t0,Ts,auxTS.labels); % Background noise estimation on the full signal
        signalStats{trial}.lowFreqSignalRMS=labTimeSeries(LFrms',t0,Ts,auxTS.labels); %Movement artifacts RMS values
        signalStats{trial}.signalRMS=labTimeSeries(EMGrms',t0,Ts,auxTS.labels); %Actual signal RMS value
        signalStats{trial}.offset=offset; %Offset
        signalStats{trial}.SNR=labTimeSeries(SNR',t0,Ts,auxTS.labels); %Signal to background noise ratio
        signalStats{trial}.avgSNR=avgSNR;
        
        %eventsTS=rawExperimentData.data{trial}.gaitEvents;
        %stridedTS=splitByEvents(auxTS,eventsTS,'LHS'); %Get strides individually in a cell array
        %alignedTS=labTimeSeries.stridedTSToAlignedTS(stridedTS,4096); %Creates an alignedTS object!
        %[decomposition,~,avgStride,~] =energyDecomposition(alignedTS);
        %signalStats{trial}.avgStride=avgStride;
        %signalStats{trial}.energyDecomp=decomposition;
        signalStats{trial}.rawCrossCorr=corr(rawExperimentData.data{trial}.EMGData.Data);
        signalStats{trial}.rawMean=mean(rawExperimentData.data{trial}.EMGData.Data);
        signalStats{trial}.rawVar=var(rawExperimentData.data{trial}.EMGData.Data);
        if rawExperimentData.isProcessed==1
            signalStats{trial}.procMean=mean(rawExperimentData.data{trial}.procEMGData.Data);
            signalStats{trial}.procVar=var(rawExperimentData.data{trial}.procEMGData.Data);
            signalStats{trial}.procCrossCorr=corr(rawExperimentData.data{trial}.procEMGData.Data);
        end
        
        %Do some plotting
%         snrStrided=splitByEvents(signalStats{trial}.SNR,eventsTS,'LHS');
%         snrAligned=labTimeSeries.stridedTSToAlignedTS(snrStrided,100); 
%         %Raw data plot:
%         [fh,ph]=plot(alignedTS); %Using the alignedTimeSeries plot function
%         linkaxes(ph,'xy')
%         axis(ph(1),[0 1 -2e-4 2e-4])
%         set(ph,'YTickLabel',{num2str(-200) 0 num2str(200)}) %Need to fix, so it shows reasonable numbers when re-scaled
%         figure(fh)
%         set(fh,'Name',['Raw EMG, trial ' num2str(trial)])
%         for i=1:size(decomposition,2)
%             subplot(ph(i))
%             hold on
%             plot([0:size(alignedTS.Data,1)-1]/size(alignedTS.Data,1),4*mean(abs(alignedTS.Data(:,i,:)),3),'m')
%             plot([0:size(alignedTS.Data,1)-1]/size(alignedTS.Data,1),-4*mean(abs(alignedTS.Data(:,i,:)),3),'m')
%             plot([0:size(snrAligned.Data,1)-1]/size(snrAligned.Data,1),mean(snrAligned.Data(:,i,:),3)*1e-5,'k.')
%             text(.7,-1e-4,['Avg. RMS ' num2str(round(1e6*decomposition(2,i))) 'uV'])
%             text(.7,-1.5e-4,['RMS ' num2str(round(1e6*decomposition(3,i))) 'uV'])
%             hold off
%         end
%         saveFig(fh,['../fig/' rawExperimentData.subData.ID],['rawEMGTrial' num2str(trial)])
%         close(fh)
%         %Filtered plot:
%         this=rawExperimentData.data{trial}.EMGData;
%         this.Data=filterEMG(this.Data,this.sampFreq,signalBW);
%         stridedTS=splitByEvents(this,eventsTS,'LHS'); %Get strides individually in a cell array
%         alignedTS=labTimeSeries.stridedTSToAlignedTS(stridedTS,4096); %Creates an alignedTS object!
%         [decomposition,~,~,~] =energyDecomposition(alignedTS);
%         alignedTS.Data=bsxfun(@minus,alignedTS.Data,mean(alignedTS.Data,1)); %Subtracting mean along first (time) dimension
%         [fh,ph]=plot(alignedTS); %Using the alignedTimeSeries plot function
%         linkaxes(ph,'xy')
%         axis(ph(1),[0 1 -2e-4 2e-4])
%         set(ph,'YTickLabel',{num2str(-200) 0 num2str(200)})
%         figure(fh)
%         set(fh,'Name',['Filtered EMG, trial ' num2str(trial)])
%         for i=1:size(decomposition,2)
%             subplot(ph(i))
%             hold on
%             plot([0:size(alignedTS.Data,1)-1]/size(alignedTS.Data,1),4*mean(abs(alignedTS.Data(:,i,:)),3),'m')
%             plot([0:size(alignedTS.Data,1)-1]/size(alignedTS.Data,1),-4*mean(abs(alignedTS.Data(:,i,:)),3),'m')
%             plot([0:size(snrAligned.Data,1)-1]/size(snrAligned.Data,1),mean(snrAligned.Data(:,i,:),3)*1e-5,'k.')
%             text(.7,-1e-4,['Avg. RMS ' num2str(round(1e6*decomposition(2,i))) 'uV'])
%             text(.7,-1.5e-4,['RMS ' num2str(round(1e6*decomposition(3,i))) 'uV'])
%             hold off
%         end
%         saveFig(fh,['../fig/' rawExperimentData.subData.ID],['filteredEMGTrial' num2str(trial)])
%         close(fh)
        
    end
end


end


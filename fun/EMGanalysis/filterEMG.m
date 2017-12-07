function [filteredData,filterList] = filterEMG(data,fs,BW,notchList)

if nargin<3 || isempty(BW)
    %BW=[20,450]; %As per recommendations on De Luca et al. 2010 (Filtering the surface EMG signal: Movement artifact and baseline noise contamination).
    %BW=[50,450]; %Changed on Sept 23 2014, by Pablo, because of artifacts detected in P0001. This should not alter the envelope detected for actual EMG activity.
    %BW=[30,450]; %Changed on Feb 20 2015, by Pablo, following recommendations on the book Electromyography by Merletti and Parker (Section 5.6, First Edition, p.121)
    BW=[200,450]; % On March 18th, decided to make this the default behavior, based on Potvin & Brown 2004. Not sure this is optimal, but seems better than 30.
    BW=[30,450]; %On Nov 6th 2017, I moved to this BW to make publication easier by sticking to a field standard. 
end
if nargin<4 || isempty(notchList)
    %notchList=[23.5,60,120,180,100,200,300,400];
    notchList=[]; %Changed on Sept 23 2014, by Pablo, not sure we need all these notch filters. On Merletti & Parker (see above) notchFilters are discouraged, more strongly for online filtering because of phase distortion.
end
filterList={};
    
    % Pre-filter:
    %Some filter design basics:
    %In what follows we define a 'pass' frequency that we will allow to be
    %attenuated 1.5dB at most.  Since we do filtfilt (dual-pass), we get at 
    %most a 3dB fall, which is 1/sqrt(2) in amplitude.
    %We also define 'stop' frequencies, that we will require are attenuated
    %at least 10dB. Once again, because of filtfilt, this means 20dB
    %minimum attenuation for this frequency, which is 1/10 in amplitude.
    %Stop frequency is defined as passfreq/2 for the high-pass filter
    %(creating effectively a 20dB/octave fall after filtfilt), and as 20%
    %higher than the remaining spectrum for low-pass filters.
    % HF noise 
    Wn=2*BW(2)/fs;
    filterList{1}=fdesign.lowpass('Fp,Fst,Ap,Ast',Wn,Wn+.2*(1-Wn),1.5,20); %Ast=10dB (/octave) results in a 4th order Butterworth filter (-80dB/dec fall).
    lowPassFilter=design(filterList{1},'butter'); %Changed on Oct 21, 2014 to have less ripple in impulse response. This is a 4th order filter.

    % LF noise 
    Wn=2*BW(1)/fs;
    filterList{2}=fdesign.highpass('Fst,Fp,Ast,Ap',Wn/2,Wn,20,1.5); %Ast=10dB (/octave) results in a 2nd order Butter filter (~-40dB/dec), while setting Ast=20dB would result in a 4th order.
    highPassFilter=design(filterList{2},'butter'); %Changed on Oct 21, 2014 to have less ripple in impulse response. This is a 2nd order filter.
    
    % Notch filters for electrical interference.
    for i=1:length(notchList)
        filterList{2+i}=fdesign.notch(10,fz,1000*fz);
        fz=2*notchList(i)/fs;
        notchFilter=design(filterList{2+1}); 
    end
    
%     data=filtfilthd(lowPassFilter,data);  %Ext function
%     data=filtfilthd(highPassFilter,data); 
%     if ~isempty(notchList)
%         data=filtfilthd(notchFilter,data); 
%     end
    %Alt: (slightly more efficient)
    allFilters=cascade(lowPassFilter,highPassFilter);
    if ~isempty(notchList)
        allFilters=allFilters.addStage(notchFilter);
    end
    filteredData=filtfilthd_short(allFilters,data,'reflect',fs); %1sec of data samples for reflective boundaries
    
end


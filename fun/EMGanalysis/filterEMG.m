function [filteredData,BW,notchList] = filterEMG(data,fs,BW,notchList)

if nargin<3 || isempty(BW)
    %BW=[20,450]; %As per recommendations on De Luca et al. 2010 (Filtering the surface EMG signal: Movement artifact and baseline noise contamination).
    BW=[50,450]; %Changed on Sept 23 2014, by Pablo, because of artifacts detected in P0001. This should not alter the envelope detected for actual EMG activity.
end
if nargin<4 || isempty(notchList)
    %notchList=[23.5,60,120,180,100,200,300,400];
    notchList=[]; %Changed on Sept 23 2014, by Pablo, not sure we need all these notch filters
end

    
    % Pre-filter:
    % HF noise 
    Wn=2*BW(2)/fs;
    %lowPassFilter=design(fdesign.lowpass('N,F3dB,Ap,Ast',10,Wn,.5,40));
    lowPassFilter=design(fdesign.lowpass('Fp,Fst,Ap,Ast',Wn,Wn+.2*(1-Wn),3,10),'butter'); %Changed on Oct 21, 2014 to have less ripple in impulse response. This is a 4th order filter.
    data=filtfilthd(lowPassFilter,data);  %Ext function
    % LF noise 
    Wn=2*BW(1)/fs;
    %highPassFilter=design(fdesign.highpass('N,F3dB,Ast,Ap',10,Wn,60,.5)); %Changed Fp to 2*1.1*BW(1)*... from 2*BW(2)*... on 28/5/2014 becuase I think it was not correct.
    highPassFilter=design(fdesign.highpass('Fst,Fp,Ast,Ap',Wn/2,Wn,10,3),'butter'); %Changed on Oct 21, 2014 to have less ripple in impulse response. This is a 2nd order filter.
    data=filtfilthd(highPassFilter,data); 
    
    % Notch filters for electrical interference.
    for i=1:length(notchList)
        fz=2*notchList(i)/fs;
        notchFilter=design(fdesign.notch(10,fz,1000*fz));
        data=filtfilthd(notchFilter,data); 
    end

filteredData=data;
end


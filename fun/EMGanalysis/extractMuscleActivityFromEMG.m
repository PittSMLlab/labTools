function [procData,f_cut,BW,notchList] =extractMuscleActivityFromEMG(data,fs,f_cut,BW,notchList)
% Extract EMG amplitude

N=size(data,2); %Number of channels
if nargin<3
    f_cut=10;
end
if nargin<4
    BW=[20,200];
end
if nargin<5
    notchList=[23.5,60,120,180,100,200];
end

    
    % Pre-filter:
    % HF noise 
    lowPassFilter=design(fdesign.lowpass('Nb,Na,Fp,Fst',10,5,2*BW(2)/fs,2*1.1*BW(2)/fs));
    data=filtfilthd(lowPassFilter,data); %External function
    % LF noise 
    highPassFilter=design(fdesign.highpass('Nb,Na,Fst,Fp',10,5,2*0.9*BW(1)/fs,2*BW(1)/fs)); %Changed Fp to 2*1.1*BW(1)*... from 2*BW(2)*... on 28/5/2014 becuase I think it was not correct.
    data=filtfilthd(highPassFilter,data); %External function
    
    % Notch filters for electrical interference.
    for i=1:length(notchList)
        fz=2*notchList(i)/fs;
        notchFilter=design(fdesign.notch(10,fz,1000*fz));
        data=filtfilthd(notchFilter,data); %External function
    end
    
    amp=amp_estim(data,fs,1,f_cut); %linear estimator
    
    procData=(amp>=0).*amp; %kills negative samples, which should not ocurr anyway
    
end


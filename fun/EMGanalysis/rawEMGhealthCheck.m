function [ output_args ] = rawEMGhealthCheck(rawExperimentData)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

for trial=1:length(rawExperimentData.data)
    data=rawExperimentData.data{trial}.EMGData.Data;
    [Fdata,fVector]=DiscreteTimeFourierTransform(data,rawExperimentData.data{trial}.EMGData.sampFrequency);
    
    offset{trial}=Fdata(1,:)/size(Fdata,1); %Mean value of data
    noiseLevelRMS{trial}=; %In volts!
    th=find(fVector<20,1,'last');
    lowFreqSignalRMS= sum(abs(Fdata(2:th,:)).^2,1)/size(Fdata,1); %In volts!
    signalRMS= ; %In volts!
    SNR= ; %In dB
end





end


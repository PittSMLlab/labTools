function [filteredData,filterList] = filterEMG(data,fs,BW,notchList)
%FILTEREMG Band-pass and notch filter EMG with zero phase.
%
%   Designs a Butterworth low-pass (high-frequency noise) and high-pass
% (movement artifact) filter for the pass band BW, adds optional notch
% filters, cascades them, and filters the data forward and backward with
% filtfilthd_short using reflective boundaries of one second.
%
% Inputs:
%   data      - EMG, samples x channels
%   fs        - sampling frequency (Hz)
%   BW        - (optional) pass band [low high] (Hz) (default: [30,450],
%               the field standard for publication)
%   notchList - (optional) notch frequencies (Hz) (default: none, since
%               notch filters distort phase and are discouraged by
%               Merletti & Parker)
%
% Outputs:
%   filteredData - filtered EMG
%   filterList   - cell array of the designed filter specifications
%
% NOTE: the notch loop uses fz before it is assigned and designs from
%   filterList{3} on every pass, so it fails or misbehaves when notchList
%   is not empty.
%
% Toolbox Dependencies: Signal Processing Toolbox (low confidence: fdesign
%   and the dfilt cascade may need the DSP System Toolbox)
%
% See also EXTRACTMUSCLEACTIVITYFROMEMG, FILTFILTHD_SHORT.

if nargin < 3 || isempty(BW)
    % The default [30,450] Hz is the field standard (Merletti and Parker,
    % Electromyography, Section 5.6, p.121). Others tried: [20,450] (De
    % Luca et al. 2010), [50,450] (removes artifacts without changing the
    % envelope), [200,450] (Potvin & Brown 2004).
    %BW=[20,450];
    %BW=[50,450];
    BW = [200,450];     % overwritten by the next line
    BW = [30,450];
end
if nargin < 4 || isempty(notchList)
    %notchList=[23.5,60,120,180,100,200,300,400];
    % Off by default: notch filters distort the phase, more so when
    % filtering online (Merletti and Parker).
    notchList = [];
end
filterList = {};
passRippleDb   = 1.5;   % dB, max pass-band attenuation (3 dB with filtfilt)
stopAttenDb    = 20;    % dB, stop-band attenuation
lowPassStopGap = 0.2;   % low-pass stop edge, fraction of spectrum above Wn
notchOrder     = 10;    % TODO: source?
notchQ         = 1000;  % TODO: source?

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
Wn = 2*BW(2)/fs;
%Ast=10dB (/octave) results in a 4th order Butterworth filter (-80dB/dec
%fall).
filterList{1} = fdesign.lowpass('Fp,Fst,Ap,Ast',Wn, ...
    Wn+lowPassStopGap*(1-Wn),passRippleDb,stopAttenDb);
%Butterworth design (less ripple in the impulse response); 4th order.
lowPassFilter = design(filterList{1},'butter');

% LF noise
Wn = 2*BW(1)/fs;
%Ast=10dB (/octave) results in a 2nd order Butter filter (~-40dB/dec), while
%setting Ast=20dB would result in a 4th order.
filterList{2} = fdesign.highpass('Fst,Fp,Ast,Ap',Wn/2,Wn, ...
    stopAttenDb,passRippleDb);
%Butterworth design (less ripple in the impulse response); 2nd order.
highPassFilter = design(filterList{2},'butter');

% Notch filters for electrical interference.
for ii = 1:length(notchList)
    filterList{2+ii} = fdesign.notch(notchOrder,fz,notchQ*fz);
    fz          = 2*notchList(ii)/fs;
    notchFilter = design(filterList{2+1});
end

%     data=filtfilthd(lowPassFilter,data);  %Ext function
%     data=filtfilthd(highPassFilter,data);
%     if ~isempty(notchList)
%         data=filtfilthd(notchFilter,data);
%     end
%Alt: (slightly more efficient)
allFilters = cascade(lowPassFilter,highPassFilter);
if ~isempty(notchList)
    allFilters = allFilters.addStage(notchFilter);
end
%1sec of data samples for reflective boundaries
filteredData = filtfilthd_short(allFilters,data,'reflect',fs);

end

